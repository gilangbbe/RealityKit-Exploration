import RealityKit
import Foundation

class EnemyCapsuleSystem: System {
    static let query = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var enemyComponent = entity.components[EnemyCapsuleComponent.self] else { continue }
            
            // Find the player (entity with GameStateComponent)
            if enemyComponent.target == nil {
                enemyComponent.target = findPlayer(in: context)
                entity.components[EnemyCapsuleComponent.self] = enemyComponent
            }
            
            guard let target = enemyComponent.target else { continue }
            
            // Move toward the player aggressively
            moveTowardTarget(enemy: entity, target: target, speed: enemyComponent.speed, deltaTime: deltaTime)
            
            // Check for collision with player
            if checkCollision(between: entity, and: target) {
                handleCollision(enemy: entity, player: target)
            }
        }
    }
    
    private func findPlayer(in context: SceneUpdateContext) -> Entity? {
        let playerQuery = EntityQuery(where: .has(GameStateComponent.self))
        for entity in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            return entity
        }
        return nil
    }
    
    private func moveTowardTarget(enemy: Entity, target: Entity, speed: Float, deltaTime: Float) {
        let direction = normalize(target.position - enemy.position)
        
        // Apply movement force to physics component if available
        if var physics = enemy.components[PhysicsMovementComponent.self] {
            let force = direction * speed * deltaTime * GameConfig.collisionForceMultiplier
            physics.velocity += force
            enemy.components[PhysicsMovementComponent.self] = physics
        } else {
            // Fallback to direct position update
            let velocity = direction * speed * deltaTime
            enemy.position.x += velocity.x
            enemy.position.z += velocity.z
        }
    }
    
    private func checkCollision(between entity1: Entity, and entity2: Entity) -> Bool {
        let distance = distance(entity1.position, entity2.position)
        return distance < 0.05 // Collision threshold
    }
    
    private func handleCollision(enemy: Entity, player: Entity) {
        // Calculate collision force direction (from enemy to player)
        let collisionDirection = normalize(player.position - enemy.position)
        
        // Get masses for realistic collision response
        let playerMass = player.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.playerMass
        let enemyMass = enemy.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.enemyMass
        
        // Calculate forces based on mass difference and strength multipliers
        let baseForce = GameConfig.bounceForceMultiplier
        let playerForce = collisionDirection * baseForce * GameConfig.enemyPushForceMultiplier * (enemyMass / playerMass) * GameConfig.playerResistance
        let enemyForce = -collisionDirection * baseForce * GameConfig.playerPushForceMultiplier * (playerMass / enemyMass)
        
        // Apply force to player (reduced due to higher mass and resistance)
        if var playerPhysics = player.components[PhysicsMovementComponent.self] {
            playerPhysics.velocity += playerForce
            player.components[PhysicsMovementComponent.self] = playerPhysics
        }
        
        // Apply stronger opposite force to enemy
        if var enemyPhysics = enemy.components[PhysicsMovementComponent.self] {
            enemyPhysics.velocity += enemyForce
            enemy.components[PhysicsMovementComponent.self] = enemyPhysics
        }
    }
}
