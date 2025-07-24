import RealityKit
import Foundation

class EnemyCapsuleSystem: System {
    static let query = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        let deltaTime = Float(context.deltaTime)
        let allEnemies = Array(context.entities(matching: Self.query, updatingSystemWhen: .rendering))
        
        // Process movement and player collisions
        for entity in allEnemies {
            guard var enemyComponent = entity.components[EnemyCapsuleComponent.self] else { continue }
            
            // Skip movement if enemy is falling
            if let fallingComp = entity.components[EnemyFallingComponent.self], fallingComp.isFalling {
                continue // Don't move falling enemies
            }
            
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
                handlePlayerCollision(enemy: entity, player: target)
            }
        }
        
        // Simple enemy-enemy collision prevention (just prevent phasing)
        for i in 0..<allEnemies.count {
            for j in (i+1)..<allEnemies.count {
                let enemy1 = allEnemies[i]
                let enemy2 = allEnemies[j]
                
                if checkCollision(between: enemy1, and: enemy2) {
                    preventPhasing(enemy1: enemy1, enemy2: enemy2)
                }
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
        
        // Use different collision radius based on entity types
        let collisionRadius: Float
        if (entity1.components[GameStateComponent.self] != nil || entity2.components[GameStateComponent.self] != nil) {
            // Player involved in collision
            collisionRadius = GameConfig.playerCollisionRadius
        } else {
            // Enemy-enemy collision
            collisionRadius = GameConfig.enemyCollisionRadius
        }
        
        return distance < collisionRadius
    }
    
    private func handlePlayerCollision(enemy: Entity, player: Entity) {
        // Calculate collision force direction (from enemy to player)
        let collisionDirection = normalize(player.position - enemy.position)
        
        // Get masses for realistic collision response
        let playerMass = player.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.playerMass
        let enemyMass = enemy.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.enemyMass
        
        // Get wave-scaled enemy push force
        let enemyComponent = enemy.components[EnemyCapsuleComponent.self]
        let enemyPushForce = enemyComponent?.pushForceMultiplier ?? GameConfig.enemyPushForceMultiplier
        
        // Get player progression for enhanced attributes
        let progression = player.components[PlayerProgressionComponent.self]
        let resilience = progression?.currentResistance ?? GameConfig.playerResistance
        let forceMultiplier = progression?.forceMultiplier ?? 1.0
        
        // Calculate forces based on mass difference and strength multipliers
        let baseForce = GameConfig.bounceForceMultiplier
        
        // Player force is calculated with wave-scaled enemy push force, reduced by resilience
        let playerForce = collisionDirection * baseForce * enemyPushForce * (enemyMass / playerMass) / resilience
        
        // Enemy force is enhanced by player's force multiplier
        let enemyForce = -collisionDirection * baseForce * GameConfig.playerPushForceMultiplier * (playerMass / enemyMass) * forceMultiplier
        
        // Apply force to player (reduced by resilience)
        if var playerPhysics = player.components[PhysicsMovementComponent.self] {
            playerPhysics.velocity += playerForce
            player.components[PhysicsMovementComponent.self] = playerPhysics
        }
        
        // Apply stronger opposite force to enemy
        if var enemyPhysics = enemy.components[PhysicsMovementComponent.self] {
            enemyPhysics.velocity += enemyForce
            enemy.components[PhysicsMovementComponent.self] = enemyPhysics
        }
        
        // Orient player to face the colliding enemy
        orientPlayerTowardEnemy(player: player, enemy: enemy)
        
        // Trigger attack animation on player collision
        PlayerAnimationSystem.triggerAttackAnimation(for: player, currentTime: Date().timeIntervalSince1970)
    }
    
    private func orientPlayerTowardEnemy(player: Entity, enemy: Entity) {
        // Calculate direction from player to enemy (player should face enemy)
        let directionToEnemy = enemy.position - player.position
        
        // Only rotate if there's a meaningful distance between them
        let distance = length(directionToEnemy)
        guard distance > 0.01 else { return }
        
        // Normalize the direction vector
        let normalizedDirection = directionToEnemy / distance
        
        // Calculate the target rotation angle based on direction to enemy
        let targetAngle = atan2(normalizedDirection.x, normalizedDirection.z)
        
        // Create rotation quaternion around Y-axis (up vector)
        let targetRotation = simd_quatf(angle: targetAngle, axis: SIMD3<Float>(0, 1, 0))
        
        if GameConfig.instantCollisionOrientation {
            // Apply immediate rotation for combat responsiveness
            player.orientation = targetRotation
        } else {
            // Apply smooth rotation interpolation
            let currentRotation = player.orientation
            let smoothingFactor = GameConfig.characterRotationSmoothness * 2.0 // Faster than movement rotation
            let interpolatedRotation = simd_slerp(currentRotation, targetRotation, smoothingFactor)
            player.orientation = interpolatedRotation
        }
        
        print("Player oriented to face enemy at angle: \(targetAngle * 180 / .pi) degrees")
    }
    
    private func preventPhasing(enemy1: Entity, enemy2: Entity) {
        // Simple position correction to prevent phasing - just separate them
        let currentDistance = distance(enemy1.position, enemy2.position)
        let minDistance = GameConfig.enemyCollisionRadius
        let overlap = minDistance - currentDistance
        
        if overlap > 0 {
            let separationDirection = normalize(enemy2.position - enemy1.position)
            let correction = separationDirection * (overlap * 0.5)
            
            // Simply move them apart without applying forces
            enemy1.position -= correction
            enemy2.position += correction
        }
    }
    }

