import RealityKit
import Foundation

struct PlayerFallingSystem: System {
    static let query = EntityQuery(where: .has(PlayerFallingComponent.self) && .has(GameStateComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var fallingComp = entity.components[PlayerFallingComponent.self] else { continue }
            
            if fallingComp.isFalling {
                // Apply falling animation effects
                updateFallingAnimation(for: entity, fallingComponent: &fallingComp, deltaTime: Float(context.deltaTime))
                
                // Check if falling animation is complete and should trigger game over
                if fallingComp.shouldTriggerGameOver && !fallingComp.hasTriggeredGameOver {
                    fallingComp.hasTriggeredGameOver = true
                    entity.components[PlayerFallingComponent.self] = fallingComp
                    
                    // Trigger game over after fall animation completes
                    NotificationCenter.default.post(name: .playerFell, object: nil)
                    print("Player fall animation completed - triggering game over")
                } else {
                    entity.components[PlayerFallingComponent.self] = fallingComp
                }
            }
        }
    }
    
    private func updateFallingAnimation(for entity: Entity, fallingComponent: inout PlayerFallingComponent, deltaTime: Float) {
        // Update fall progress
        fallingComponent.updateProgress(deltaTime: deltaTime)
        let progress = fallingComponent.fallProgress
        
        // Accelerating downward movement
        let fallSpeed = GameConfig.playerFallSpeed * (1.0 + progress * 1.5) // Accelerate as it falls
        entity.position.y -= fallSpeed * deltaTime
        
        // Add some rotation for dramatic effect (less dramatic than enemies)
        let rotationSpeed = GameConfig.playerFallRotationSpeed * progress
        let rotationDelta = rotationSpeed * deltaTime
        let currentRotation = entity.orientation
        let rotationIncrement = simd_quatf(angle: rotationDelta, axis: SIMD3<Float>(0, 0, 1)) // Rotate around Z-axis
        entity.orientation = simd_mul(currentRotation, rotationIncrement)
        
        // Optional: Slight scale reduction as player falls (less than enemies)
        let scaleReduction = 1.0 - (progress * 0.1) // Reduce to 90% of original size
        entity.scale = SIMD3<Float>(repeating: max(scaleReduction, 0.8))
        
        // Stop any player animations
        if let animationComp = entity.components[PlayerAnimationComponent.self] {
            if let animationEntity = entity.findEntity(named: GameConfig.playerChildEntityName) {
                if progress < 0.1 { // Only stop animations once at the beginning
                    animationEntity.stopAllAnimations()
                    print("Stopped player animations during fall")
                }
            }
        }
    }
    
    // Static method to start falling animation for the player
    static func startFalling(for entity: Entity) {
        if var fallingComp = entity.components[PlayerFallingComponent.self] {
            fallingComp.startFalling()
            entity.components[PlayerFallingComponent.self] = fallingComp
        } else {
            // Add falling component if it doesn't exist
            var newFallingComp = PlayerFallingComponent()
            newFallingComp.startFalling()
            entity.components[PlayerFallingComponent.self] = newFallingComp
        }
        
        // Stop all movement by zeroing out physics velocity
        if var physics = entity.components[PhysicsMovementComponent.self] {
            physics.velocity = SIMD3<Float>(0, 0, 0) // Stop all movement
            entity.components[PhysicsMovementComponent.self] = physics
        }
        
        print("Started player falling animation - stopped all movement")
    }
}
