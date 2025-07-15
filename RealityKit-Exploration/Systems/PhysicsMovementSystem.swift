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
                // Get actual cube bounds for precise edge detection
                let cubeBounds = constraintEntity.visualBounds(relativeTo: nil)
                let cubeCenter = constraintEntity.position
                let cubeTopY = cubeCenter.y + (cubeBounds.max.y - cubeBounds.min.y) / 2.0
                
                // Calculate actual arena boundaries
                let arenaMinX = cubeCenter.x + cubeBounds.min.x
                let arenaMaxX = cubeCenter.x + cubeBounds.max.x
                let arenaMinZ = cubeCenter.z + cubeBounds.min.z
                let arenaMaxZ = cubeCenter.z + cubeBounds.max.z
                
                // Check if entity is within arena boundaries
                let isWithinXBounds = entity.position.x >= arenaMinX && entity.position.x <= arenaMaxX
                let isWithinZBounds = entity.position.z >= arenaMinZ && entity.position.z <= arenaMaxZ
                let isOnArenaPlane = isWithinXBounds && isWithinZBounds
                
                let heightBelowArena = cubeTopY - entity.position.y
                
                // Apply gravity when entity is beyond arena boundaries
                if !isOnArenaPlane {
                    physics.velocity.y -= GameConfig.gravityStrength * Float(context.deltaTime)
                    physics.isOnGround = false
                }
                
                // Fall detection with precise boundary checking
                let isBeyondHorizontalEdge = !isOnArenaPlane && (
                    entity.position.x < arenaMinX - GameConfig.arenaEdgeBuffer ||
                    entity.position.x > arenaMaxX + GameConfig.arenaEdgeBuffer ||
                    entity.position.z < arenaMinZ - GameConfig.arenaEdgeBuffer ||
                    entity.position.z > arenaMaxZ + GameConfig.arenaEdgeBuffer
                )
                let isBelowArenaHeight = heightBelowArena > GameConfig.arenaFallHeightThreshold
                let isFarBelowArena = entity.position.y < cubeTopY - 1.0
                
                if isBeyondHorizontalEdge || isBelowArenaHeight || isFarBelowArena {
                    // Debug: Log why entity is falling
                    if isBeyondHorizontalEdge {
                        print("Entity fell: Beyond horizontal edge (x: \(entity.position.x), z: \(entity.position.z), arena bounds: x[\(arenaMinX)-\(arenaMaxX)], z[\(arenaMinZ)-\(arenaMaxZ)])")
                    }
                    if isBelowArenaHeight {
                        print("Entity fell: Below arena height (height below: \(heightBelowArena), limit: \(GameConfig.arenaFallHeightThreshold))")
                    }
                    if isFarBelowArena {
                        print("Entity fell: Far below arena (y: \(entity.position.y), arena top: \(cubeTopY))")
                    }
                    
                    handleEntityFall(entity, context: context)
                    continue
                }
                
                // Keep entities on arena surface if they're still on the platform
                if physics.isOnGround && isOnArenaPlane {
                    entity.position.y = cubeTopY + physics.groundLevel
                } else if isOnArenaPlane {
                    // Reset ground state if back on platform
                    physics.isOnGround = true
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
            // Update wave progress
            updateWaveProgress(context: context)
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
}

extension Notification.Name {
    static let entityFell = Notification.Name("entityFell")
    static let waveCompleted = Notification.Name("waveCompleted")
}
