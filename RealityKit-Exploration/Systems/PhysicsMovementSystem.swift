import RealityKit
import Foundation

class PhysicsMovementSystem: System {
    static let query = EntityQuery(where: .has(PhysicsMovementComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var physics = entity.components[PhysicsMovementComponent.self] else { continue }
            
            // Apply friction
            physics.velocity *= physics.friction
            
            // Apply velocity to position
            entity.position += physics.velocity * deltaTime
            
            // Keep on arena surface level (but allow movement beyond edges)
            if let constraintEntity = physics.constrainedTo {
                let arenaY = constraintEntity.position.y + constraintEntity.scale.y / 2.0
                let arenaSize = constraintEntity.scale.x / 2.0
                let arenaCenter = constraintEntity.position
                
                if physics.isOnGround {
                    entity.position.y = arenaY + physics.groundLevel
                }
                
                // Check if entity has been pushed off the arena platform
                let distanceFromCenter = distance(SIMD2<Float>(entity.position.x, entity.position.z), 
                                                 SIMD2<Float>(arenaCenter.x, arenaCenter.z))
                
                if distanceFromCenter > arenaSize + GameConfig.arenaEdgeBuffer {
                    // Handle immediate fall
                    handleEntityFall(entity, context: context)
                    continue
                }
            }
            
            // Check if fallen below arena threshold
            if entity.position.y < GameConfig.arenaFallThreshold {
                handleEntityFall(entity, context: context)
                continue
            }
            
            entity.components[PhysicsMovementComponent.self] = physics
        }
    }
    
    private func handleEntityFall(_ entity: Entity, context: SceneUpdateContext) {
        // Check if it's an enemy
        if let enemyComponent = entity.components[EnemyCapsuleComponent.self] {
            // Award points to player
            updatePlayerScore(points: enemyComponent.scoreValue, context: context)
            // Remove the fallen enemy
            entity.removeFromParent()
            // Post notification for UI update
            NotificationCenter.default.post(name: .enemyDefeated, object: enemyComponent.scoreValue)
        }
        
        // Check if it's the player
        if entity.components[GameStateComponent.self] != nil {
            // Player fell - game over
            NotificationCenter.default.post(name: .playerFell, object: nil)
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
}

extension Notification.Name {
    static let entityFell = Notification.Name("entityFell")
}
