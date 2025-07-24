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
            
            // Check if enemy is already falling
            if let fallingComp = entity.components[EnemyFallingComponent.self], fallingComp.isFalling {
                return // Already falling, let the falling system handle it
            }
            
            // Start falling animation instead of immediate removal
            EnemyFallingSystem.startFalling(for: entity)
            return
        }
        
        // Check if it's the player
        if entity.components[GameStateComponent.self] != nil {
            // Player fell - game over
            NotificationCenter.default.post(name: .playerFell, object: nil)
        }
    }
}

extension Notification.Name {
    static let enemyDefeated = Notification.Name("enemyDefeated")
    static let playerFell = Notification.Name("playerFell")
    static let scoreChanged = Notification.Name("scoreChanged")
}
