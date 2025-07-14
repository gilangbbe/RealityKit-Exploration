import RealityKit
import Foundation

class EnemyCapsuleSystem: System {
    static let query = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var enemyComponent = entity.components[EnemyCapsuleComponent.self] else { continue }
            
            // Find the player (entity with HealthComponent)
            if enemyComponent.target == nil {
                enemyComponent.target = findPlayer(in: context)
                entity.components[EnemyCapsuleComponent.self] = enemyComponent
            }
            
            guard let target = enemyComponent.target else { continue }
            
            // Move toward the player
            moveTowardTarget(enemy: entity, target: target, speed: enemyComponent.speed, deltaTime: Float(context.deltaTime))
            
            // Check for collision with player
            if checkCollision(between: entity, and: target) {
                handleCollision(enemy: entity, player: target, damage: enemyComponent.damage)
            }
        }
    }
    
    private func findPlayer(in context: SceneUpdateContext) -> Entity? {
        let playerQuery = EntityQuery(where: .has(HealthComponent.self))
        for entity in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            return entity
        }
        return nil
    }
    
    private func moveTowardTarget(enemy: Entity, target: Entity, speed: Float, deltaTime: Float) {
        let direction = normalize(target.position - enemy.position)
        let velocity = direction * speed * deltaTime
        
        // Keep the enemy on the surface (same Y as target)
        enemy.position.x += velocity.x
        enemy.position.z += velocity.z
        enemy.position.y = target.position.y
    }
    
    private func checkCollision(between entity1: Entity, and entity2: Entity) -> Bool {
        let distance = distance(entity1.position, entity2.position)
        return distance < 0.1 // Collision threshold
    }
    
    private func handleCollision(enemy: Entity, player: Entity, damage: Int) {
        // Damage the player
        if var healthComponent = player.components[HealthComponent.self] {
            healthComponent.takeDamage(damage)
            player.components[HealthComponent.self] = healthComponent
        }
        
        // Remove the enemy after collision
        enemy.removeFromParent()
    }
}
