import RealityKit
import Foundation

class GameManagementSystem: System {
    static let query = EntityQuery(where: .has(GameStateComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Handle fallen entities
        NotificationCenter.default.addObserver(
            forName: .entityFell,
            object: nil,
            queue: .main
        ) { notification in
            guard let fallenEntity = notification.object as? Entity else { return }
            self.handleFallenEntity(fallenEntity, in: context)
        }
    }
    
    private func handleFallenEntity(_ entity: Entity, in context: SceneUpdateContext) {
        // Check if it's an enemy
        if var enemyComponent = entity.components[EnemyCapsuleComponent.self] {
            enemyComponent.hasFallen = true
            entity.components[EnemyCapsuleComponent.self] = enemyComponent
            
            // Award points to player
            updatePlayerScore(points: enemyComponent.scoreValue, in: context)
            
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
    
    private func updatePlayerScore(points: Int, in context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var gameState = entity.components[GameStateComponent.self] else { continue }
            gameState.score += points
            gameState.enemiesDefeated += 1
            entity.components[GameStateComponent.self] = gameState
            
            // Notify UI about score change
            NotificationCenter.default.post(name: .scoreChanged, object: gameState.score)
            break
        }
    }
}

extension Notification.Name {
    static let enemyDefeated = Notification.Name("enemyDefeated")
    static let playerFell = Notification.Name("playerFell")
    static let scoreChanged = Notification.Name("scoreChanged")
}
