import RealityKit
import Foundation

class PlayerAnimationSystem: System {
    static let query = EntityQuery(where: .has(PlayerAnimationComponent.self) && .has(PhysicsMovementComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var animationComp = entity.components[PlayerAnimationComponent.self],
                  let physicsComp = entity.components[PhysicsMovementComponent.self] else { continue }
            
            // Check if attack animation has finished
            if animationComp.isAttacking && currentTime >= animationComp.attackAnimationEndTime {
                stopAttackAnimation(entity: entity, animationComp: &animationComp)
            }
            
            // Check if shockwave animation has finished
            if animationComp.isUsingShockwave && currentTime >= animationComp.shockwaveAnimationEndTime {
                stopShockwaveAnimation(entity: entity, animationComp: &animationComp)
            }
            
            // Only handle walking/idle animation if not currently attacking or using shockwave
            if !animationComp.isAttacking && !animationComp.isUsingShockwave {
                // Calculate current movement magnitude
                let currentMovement = length(physicsComp.velocity)
                let isMovingNow = currentMovement > GameConfig.minMovementForWalkAnimation
                
                // Handle animation state changes
                if isMovingNow && !animationComp.isWalking {
                    // Start walking, stop idle
                    startWalkingAnimation(entity: entity, animationComp: &animationComp)
                } else if !isMovingNow && animationComp.isWalking {
                    // Stop walking, start idle
                    stopWalkingAnimation(entity: entity, animationComp: &animationComp)
                    startIdleAnimation(entity: entity, animationComp: &animationComp)
                } else if !isMovingNow && !animationComp.isWalking && !animationComp.isIdle {
                    // Ensure idle animation is playing when not moving and not walking
                    startIdleAnimation(entity: entity, animationComp: &animationComp)
                }
                
                // Update the component
                animationComp.lastMovementMagnitude = currentMovement
            }
            
            entity.components[PlayerAnimationComponent.self] = animationComp
        }
    }
    
    private func startWalkingAnimation(entity: Entity, animationComp: inout PlayerAnimationComponent) {
        guard !animationComp.isWalking else { return } // Already walking
        
                // Find the child entity that contains the animations (named 'player')
        guard let playerChild = entity.findEntity(named: GameConfig.playerChildEntityName) else {
            print("Warning: Could not find child entity named '\(GameConfig.playerChildEntityName)' in player_root")
            
            return
        }
        
        do {
            // Access the walk animation by index (row 6 = index 5, since arrays are 0-based)
            let walkAnimationIndex = GameConfig.walkAnimationIndex
            let availableAnimations = playerChild.availableAnimations
            
            // Check if the walk animation index is valid
            guard walkAnimationIndex < availableAnimations.count else {
                print("Warning: Walk animation index \(walkAnimationIndex) is out of range. Available animations count: \(availableAnimations.count)")
                return
            }
            
            // Get the walk animation by index
            let walkAnimation = availableAnimations[walkAnimationIndex]
            
            // Stop any existing animation
            animationComp.currentAnimationController?.stop()
            
            // Play the walking animation with repeat on the child entity
            let controller = playerChild.playAnimation(walkAnimation.repeat())
            animationComp.currentAnimationController = controller
            animationComp.isWalking = true
            animationComp.isIdle = false
            
        } catch {
            print("Error starting walking animation: \(error)")
        }
    }
    
    private func stopWalkingAnimation(entity: Entity, animationComp: inout PlayerAnimationComponent) {
        guard animationComp.isWalking else { return } // Already not walking
        
        // Stop the current animation
        animationComp.currentAnimationController?.stop()
        animationComp.currentAnimationController = nil
        animationComp.isWalking = false
    }
    
    private func startIdleAnimation(entity: Entity, animationComp: inout PlayerAnimationComponent) {
        guard !animationComp.isIdle else { return } // Already idle
        
        // Find the child entity that contains the animations (named 'player')
        guard let playerChild = entity.findEntity(named: GameConfig.playerChildEntityName) else {
            print("Warning: Could not find child entity named '\(GameConfig.playerChildEntityName)' for idle animation")
            return
        }
        
        let idleAnimationIndex = GameConfig.idleAnimationIndex
        let availableAnimations = playerChild.availableAnimations
        
        // Check if the idle animation index is valid
        guard idleAnimationIndex < availableAnimations.count else {
            print("Warning: Idle animation index \(idleAnimationIndex) is out of range. Available animations count: \(availableAnimations.count)")
            return
        }
        
        // Get the idle animation by index
        let idleAnimation = availableAnimations[idleAnimationIndex]
        
        // Stop any existing animation
        animationComp.currentAnimationController?.stop()
        
        // Play the idle animation with repeat on the child entity
        let controller = playerChild.playAnimation(idleAnimation.repeat())
        animationComp.currentAnimationController = controller
        animationComp.isIdle = true
        animationComp.isWalking = false
        
    }
    
    private func stopIdleAnimation(entity: Entity, animationComp: inout PlayerAnimationComponent) {
        guard animationComp.isIdle else { return } // Already not idle
        
        // Stop the current animation
        animationComp.currentAnimationController?.stop()
        animationComp.currentAnimationController = nil
        animationComp.isIdle = false
    }
    
    // Public function to trigger attack animation from collision system
    static func triggerAttackAnimation(for entity: Entity, currentTime: TimeInterval) {
        guard var animationComp = entity.components[PlayerAnimationComponent.self] else { return }
        
        // Don't interrupt an ongoing attack animation
        if animationComp.isAttacking && currentTime < animationComp.attackAnimationEndTime {
            return
        }
        
        // Find the child entity that contains the animations
        guard let playerChild = entity.findEntity(named: GameConfig.playerChildEntityName) else {
            print("Warning: Could not find child entity named '\(GameConfig.playerChildEntityName)' for attack animation")
            return
        }
        
        // Stop any current animation
        animationComp.currentAnimationController?.stop()
        animationComp.isWalking = false
        
        // Randomly select an attack animation index
        let attackIndices = GameConfig.attackAnimationIndices
        guard let randomAttackIndex = attackIndices.randomElement() else {
            print("Warning: No attack animation indices configured")
            return
        }
        
        let availableAnimations = playerChild.availableAnimations
        
        // Check if the attack animation index is valid
        guard randomAttackIndex < availableAnimations.count else {
            print("Warning: Attack animation index \(randomAttackIndex) is out of range. Available animations count: \(availableAnimations.count)")
            return
        }
        
        // Get and play the attack animation
        let attackAnimation = availableAnimations[randomAttackIndex]
        
        do {
            // Play the attack animation once (no repeat)
            let controller = playerChild.playAnimation(attackAnimation)
            animationComp.currentAnimationController = controller
            animationComp.isAttacking = true
            animationComp.attackAnimationEndTime = currentTime + GameConfig.attackAnimationDuration
            
            // Update the component
            entity.components[PlayerAnimationComponent.self] = animationComp
            
        } catch {
            print("Error starting attack animation: \(error)")
        }
    }
    
    // Public function to trigger shockwave animation from lootbox system
    static func triggerShockwaveAnimation(for entity: Entity, currentTime: TimeInterval) {
        guard var animationComp = entity.components[PlayerAnimationComponent.self] else { return }
        
        // Don't interrupt an ongoing shockwave animation
        if animationComp.isUsingShockwave && currentTime < animationComp.shockwaveAnimationEndTime {
            return
        }
        
        // Find the child entity that contains the animations
        guard let playerChild = entity.findEntity(named: GameConfig.playerChildEntityName) else {
            print("Warning: Could not find child entity named '\(GameConfig.playerChildEntityName)' for shockwave animation")
            return
        }
        
        // Stop any current animation
        animationComp.currentAnimationController?.stop()
        animationComp.isWalking = false
        animationComp.isAttacking = false
        
        // Stop player movement immediately by zeroing velocity
        if var physicsComp = entity.components[PhysicsMovementComponent.self] {
            physicsComp.velocity = SIMD3<Float>(0, 0, 0)
            entity.components[PhysicsMovementComponent.self] = physicsComp
        }
        
        let shockwaveIndex = GameConfig.shockwaveAnimationIndex
        let availableAnimations = playerChild.availableAnimations
        
        // Check if the shockwave animation index is valid
        guard shockwaveIndex < availableAnimations.count else {
            print("Warning: Shockwave animation index \(shockwaveIndex) is out of range. Available animations count: \(availableAnimations.count)")
            return
        }
        
        // Get and play the shockwave animation
        let shockwaveAnimation = availableAnimations[shockwaveIndex]
        
        do {
            // Play the shockwave animation once (no repeat)
            let controller = playerChild.playAnimation(shockwaveAnimation)
            animationComp.currentAnimationController = controller
            animationComp.isUsingShockwave = true
            animationComp.shockwaveAnimationEndTime = currentTime + GameConfig.shockwaveAnimationDuration
            
            print("Started shockwave animation at index \(shockwaveIndex) - player immobilized for \(GameConfig.shockwaveAnimationDuration) seconds")
            
            // Update the component
            entity.components[PlayerAnimationComponent.self] = animationComp
            
        } catch {
            print("Error starting shockwave animation: \(error)")
        }
    }
    
    private func stopAttackAnimation(entity: Entity, animationComp: inout PlayerAnimationComponent) {
        guard animationComp.isAttacking else { return }
        
        // Stop the current animation
        animationComp.currentAnimationController?.stop()
        animationComp.currentAnimationController = nil
        animationComp.isAttacking = false
        animationComp.attackAnimationEndTime = 0.0
        
        print("Attack animation finished for player")
    }
    
    private func stopShockwaveAnimation(entity: Entity, animationComp: inout PlayerAnimationComponent) {
        guard animationComp.isUsingShockwave else { return }
        
        // Stop the current animation
        animationComp.currentAnimationController?.stop()
        animationComp.currentAnimationController = nil
        animationComp.isUsingShockwave = false
        animationComp.shockwaveAnimationEndTime = 0.0
    
    }
}
