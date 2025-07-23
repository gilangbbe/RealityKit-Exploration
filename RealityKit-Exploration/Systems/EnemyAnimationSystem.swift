import RealityKit
import Foundation

struct EnemyAnimationSystem: System {
    static let query = EntityQuery(where: .has(EnemyAnimationComponent.self) && .has(EnemyCapsuleComponent.self) && .has(PhysicsMovementComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var animationComp = entity.components[EnemyAnimationComponent.self],
                  let physics = entity.components[PhysicsMovementComponent.self] else { continue }
            
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
}
