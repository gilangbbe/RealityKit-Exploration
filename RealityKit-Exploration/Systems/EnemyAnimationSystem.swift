import RealityKit
import Foundation
import QuartzCore

struct EnemyAnimationSystem: System {
    static let query = EntityQuery(where: .has(EnemyAnimationComponent.self) && .has(EnemyCapsuleComponent.self) && .has(PhysicsMovementComponent.self))
    static let playerQuery = EntityQuery(where: .has(PhysicsMovementComponent.self) && .has(GameStateComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        let currentTime = CACurrentMediaTime()
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var animationComp = entity.components[EnemyAnimationComponent.self],
                  let physics = entity.components[PhysicsMovementComponent.self] else { continue }
            
            // Check if time slow is active by looking for PowerUpComponent on player entities (same as LootBoxSystem)
            let players = context.scene.performQuery(Self.playerQuery)
            let isTimeSlowActive = players.compactMap { $0.components[PowerUpComponent.self] }
                .first?
                .isTimeSlowActive(currentTime: currentTime) ?? false
            
            print(isTimeSlowActive ? "Time slow is active" : "Time slow is not active")
            // Handle time slow animation state changes
            if isTimeSlowActive && !animationComp.isSlowed {
                // Start slow animation
                animationComp.isSlowed = true
                startSlowAnimation(for: entity, animationComponent: animationComp)
                entity.components[EnemyAnimationComponent.self] = animationComp
                continue
            } else if !isTimeSlowActive && animationComp.isSlowed {
                // End slow animation, return to normal walking
                animationComp.isSlowed = false
                stopSlowAnimation(for: entity, animationComponent: animationComp)
                entity.components[EnemyAnimationComponent.self] = animationComp
                // Don't continue here, let it fall through to normal walking logic
            }
            
            // Handle normal walking animation (only if not slowed)
            if !animationComp.isSlowed {
                // Check if enemy is moving
                let velocity = physics.velocity
                let movementMagnitude = length(velocity)
                let isCurrentlyMoving = movementMagnitude > GameConfig.minEnemyMovementForWalkAnimation
                
                // Update animation based on movement state
                if isCurrentlyMoving != animationComp.isWalking {
                    animationComp.isWalking = isCurrentlyMoving
                    animationComp.lastMovementTime = currentTime
                    
                    if isCurrentlyMoving {
                        startWalkingAnimation(for: entity, animationComponent: animationComp)
                    } else {
                        stopWalkingAnimation(for: entity, animationComponent: animationComp)
                    }
                    
                    entity.components[EnemyAnimationComponent.self] = animationComp
                }
            }
        }
    }
    
    private func startWalkingAnimation(for enemy: Entity, animationComponent: EnemyAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = enemy.findEntity(named: animationComponent.animationChildEntityName) else {
            print("Warning: Animation child entity '\(animationComponent.animationChildEntityName)' not found for enemy")
            return
        }
        
        // Get available animations from the child entity
        let availableAnimations = animationEntity.availableAnimations
        
        // Check if walking animation exists at index 0
        guard GameConfig.enemyWalkAnimationIndex < availableAnimations.count else {
            print("Warning: Enemy walking animation not found at index \(GameConfig.enemyWalkAnimationIndex)")
            return
        }
        
        // Play walking animation at index 0
        let walkingAnimation = availableAnimations[GameConfig.enemyWalkAnimationIndex]
        
        // Create looping animation controller
        let animationController = animationEntity.playAnimation(
            walkingAnimation.repeat(),
            transitionDuration: 0.2,
            startsPaused: false
        )
        
        // Store the controller for potential future use
        print("Started walking animation for enemy type: \(animationComponent.animationChildEntityName)")
    }
    
    private func stopWalkingAnimation(for enemy: Entity, animationComponent: EnemyAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = enemy.findEntity(named: animationComponent.animationChildEntityName) else {
            return
        }
        
        // Stop all animations on the animation entity
        animationEntity.stopAllAnimations()
        
        print("Stopped walking animation for enemy type: \(animationComponent.animationChildEntityName)")
    }
    
    private func startSlowAnimation(for enemy: Entity, animationComponent: EnemyAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = enemy.findEntity(named: animationComponent.animationChildEntityName) else {
            print("Warning: Animation entity '\(animationComponent.animationChildEntityName)' not found for slow animation")
            return
        }
        
        // Get available animations from the child entity
        let availableAnimations = animationEntity.availableAnimations
        
        // Check if slow animation exists at index 1
        guard availableAnimations.count > 1 else {
            print("Warning: Enemy slow animation not found at index 1 for \(animationComponent.animationChildEntityName)")
            return
        }
        
        // Play slow animation at index 1
        let slowAnimation = availableAnimations[1]
        
        animationEntity.playAnimation(
            slowAnimation.repeat(),
            transitionDuration: 0.3,
            startsPaused: false
        )
        
        print("Started slow animation for enemy type: \(animationComponent.animationChildEntityName)")
    }
    
    private func stopSlowAnimation(for enemy: Entity, animationComponent: EnemyAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = enemy.findEntity(named: animationComponent.animationChildEntityName) else {
            return
        }
        
        // Stop all animations on the animation entity
        animationEntity.stopAllAnimations()
        
        // Check if enemy should be walking based on current movement
        if let physics = enemy.components[PhysicsMovementComponent.self] {
            let velocity = physics.velocity
            let movementMagnitude = length(velocity)
            let isCurrentlyMoving = movementMagnitude > GameConfig.minEnemyMovementForWalkAnimation
            
            // Start appropriate animation based on movement state
            if isCurrentlyMoving {
                // Start walking animation
                let availableAnimations = animationEntity.availableAnimations
                guard GameConfig.enemyWalkAnimationIndex < availableAnimations.count else {
                    print("Warning: Enemy walking animation not found at index \(GameConfig.enemyWalkAnimationIndex)")
                    return
                }
                
                let walkingAnimation = availableAnimations[GameConfig.enemyWalkAnimationIndex]
                animationEntity.playAnimation(
                    walkingAnimation.repeat(),
                    transitionDuration: 0.3,
                    startsPaused: false
                )
                print("Transitioned from slow to walking animation for enemy type: \(animationComponent.animationChildEntityName)")
            } else {
                print("Transitioned from slow to idle state for enemy type: \(animationComponent.animationChildEntityName)")
            }
        }
        
        print("Stopped slow animation for enemy type: \(animationComponent.animationChildEntityName)")
    }
}
