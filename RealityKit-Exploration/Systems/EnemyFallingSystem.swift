import RealityKit
import Foundation

struct EnemyFallingSystem: System {
    static let query = EntityQuery(where: .has(EnemyFallingComponent.self) && .has(EnemyCapsuleComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var fallingComp = entity.components[EnemyFallingComponent.self],
                  let enemyComp = entity.components[EnemyCapsuleComponent.self] else { continue }
            
            if fallingComp.isFalling {
                // Apply falling animation effects
                updateFallingAnimation(for: entity, fallingComponent: &fallingComp, deltaTime: Float(context.deltaTime))
                
                // Check if falling animation is complete
                if fallingComp.shouldRemove && !fallingComp.hasTriggeredCleanup {
                    fallingComp.hasTriggeredCleanup = true
                    entity.components[EnemyFallingComponent.self] = fallingComp
                    
                    // Award points and clean up
                    handleEnemyCleanup(entity: entity, enemyComponent: enemyComp, context: context)
                } else {
                    entity.components[EnemyFallingComponent.self] = fallingComp
                }
            }
        }
    }
    
    private func updateFallingAnimation(for entity: Entity, fallingComponent: inout EnemyFallingComponent, deltaTime: Float) {
        let progress = fallingComponent.fallProgress
        
        // Accelerating downward movement
        let fallSpeed = GameConfig.enemyFallSpeed * (1.0 + progress * 2.0) // Accelerate as it falls
        entity.position.y -= fallSpeed * deltaTime
        
        // Add some rotation for dramatic effect
        let rotationSpeed = GameConfig.enemyFallRotationSpeed * progress
        let rotationDelta = rotationSpeed * deltaTime
        let currentRotation = entity.orientation
        let rotationIncrement = simd_quatf(angle: rotationDelta, axis: SIMD3<Float>(1, 0, 1))
        entity.orientation = simd_mul(currentRotation, rotationIncrement)
        
        // Scale down as it falls (optional visual effect)
        let scaleReduction = 1.0 - (progress * 0.3) // Reduce to 70% of original size
        entity.scale = SIMD3<Float>(repeating: max(scaleReduction, 0.1))
        
        // Optional: Add slight transparency
        // Note: This requires the entity to have appropriate materials
        if let modelComp = entity.components[ModelComponent.self] {
            // We can modify opacity if materials support it
            // This is a simplified approach - in practice you'd want to modify specific materials
        }
    }
    
    private func handleEnemyCleanup(entity: Entity, enemyComponent: EnemyCapsuleComponent, context: SceneUpdateContext) {
        // Award points to player
        updatePlayerScore(points: enemyComponent.scoreValue, context: context)
        
        // Update wave progress
        updateWaveProgress(context: context)
        
        // Remove the enemy entity
        entity.removeFromParent()
        
        // Post notification for UI update
        NotificationCenter.default.post(name: .enemyDefeated, object: enemyComponent.scoreValue)
        
        print("Enemy \(enemyComponent.enemyType.name) finished falling and was removed")
    }
    
    private func updateWaveProgress(context: SceneUpdateContext) {
        let waveQuery = EntityQuery(where: .has(WaveComponent.self))
        for entity in context.entities(matching: waveQuery, updatingSystemWhen: .rendering) {
            guard var wave = entity.components[WaveComponent.self] else { continue }
            wave.enemyDefeated()
            entity.components[WaveComponent.self] = wave
            
            // Check if wave is complete
            if !wave.isWaveActive {
                NotificationCenter.default.post(name: .waveCompleted, object: wave.currentWave)
            }
            break
        }
    }
    
    private func updatePlayerScore(points: Int, context: SceneUpdateContext) {
        let playerQuery = EntityQuery(where: .has(GameStateComponent.self))
        for playerEntity in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            guard var gameState = playerEntity.components[GameStateComponent.self] else { continue }
            gameState.score += points
            gameState.enemiesDefeated += 1
            playerEntity.components[GameStateComponent.self] = gameState
            
            // Notify UI about score change
            NotificationCenter.default.post(name: .scoreChanged, object: gameState.score)
            break
        }
    }
    
    // Static method to start falling animation for an enemy
    static func startFalling(for entity: Entity) {
        if var fallingComp = entity.components[EnemyFallingComponent.self] {
            fallingComp.startFalling()
            entity.components[EnemyFallingComponent.self] = fallingComp
        } else {
            // Add falling component if it doesn't exist
            var newFallingComp = EnemyFallingComponent()
            newFallingComp.startFalling()
            entity.components[EnemyFallingComponent.self] = newFallingComp
        }
        
        // Stop all horizontal movement by zeroing out physics velocity
        if var physics = entity.components[PhysicsMovementComponent.self] {
            physics.velocity = SIMD3<Float>(0, 0, 0) // Stop all movement
            entity.components[PhysicsMovementComponent.self] = physics
        }
        
        // Stop any walking animations
        if let animationComp = entity.components[EnemyAnimationComponent.self] {
            if let animationEntity = entity.findEntity(named: animationComp.animationChildEntityName) {
                animationEntity.stopAllAnimations()
            }
        }
        
        print("Started falling animation for enemy - stopped all movement and animations")
    }
}
