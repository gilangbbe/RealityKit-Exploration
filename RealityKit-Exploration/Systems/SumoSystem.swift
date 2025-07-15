import RealityKit
import Foundation

class SumoSystem: System {
    static let query = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    static let waveQuery = EntityQuery(where: .has(WaveManagerComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Get current wave information for enhanced AI behavior
        guard let waveInfo = getCurrentWaveInfo(in: context) else { return }
        
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var enemyComponent = entity.components[EnemyCapsuleComponent.self] else { continue }
            
            // Find the player if not already assigned
            if enemyComponent.target == nil {
                enemyComponent.target = findPlayer(in: context)
                entity.components[EnemyCapsuleComponent.self] = enemyComponent
            }
            
            guard let target = enemyComponent.target else { continue }
            
            // Enhanced wave-based AI behavior
            performWaveBasedSumoAI(
                enemy: entity,
                target: target,
                enemyComponent: enemyComponent,
                waveInfo: waveInfo,
                deltaTime: deltaTime
            )
        }
    }
    
    private func getCurrentWaveInfo(in context: SceneUpdateContext) -> WaveGameInfo? {
        for entity in context.entities(matching: Self.waveQuery, updatingSystemWhen: .rendering) {
            guard let waveManager = entity.components[WaveManagerComponent.self] else { continue }
            return WaveGameInfo(
                waveNumber: waveManager.currentWave.waveNumber,
                speedMultiplier: waveManager.currentWave.enemySpeedMultiplier,
                healthMultiplier: waveManager.currentWave.enemyHealthMultiplier,
                scoreMultiplier: waveManager.currentWave.enemyScoreMultiplier,
                spawnIntervalMultiplier: waveManager.currentWave.spawnIntervalMultiplier,
                maxEnemiesMultiplier: waveManager.currentWave.maxEnemiesMultiplier,
                isActive: waveManager.isWaveActive
            )
        }
        return nil
    }
    
    private func performWaveBasedSumoAI(
        enemy: Entity,
        target: Entity,
        enemyComponent: EnemyCapsuleComponent,
        waveInfo: WaveGameInfo,
        deltaTime: Float
    ) {
        let distance = distance(enemy.position, target.position)
        
        // Wave-based AI strategy
        switch waveInfo.waveNumber {
        case 1...2:
            // Early waves: Simple direct approach
            performDirectApproach(enemy: enemy, target: target, speed: enemyComponent.speed, deltaTime: deltaTime)
            
        case 3...4:
            // Mid waves: More aggressive with flanking
            performAggressiveApproach(enemy: enemy, target: target, speed: enemyComponent.speed, waveInfo: waveInfo, deltaTime: deltaTime)
            
        case 5...7:
            // Later waves: Smart positioning and group tactics
            performSmartPositioning(enemy: enemy, target: target, speed: enemyComponent.speed, waveInfo: waveInfo, deltaTime: deltaTime)
            
        default:
            // Advanced waves: Coordinated attacks and evasion
            performCoordinatedAttack(enemy: enemy, target: target, speed: enemyComponent.speed, waveInfo: waveInfo, deltaTime: deltaTime)
        }
        
        // Check for collision with enhanced force based on wave
        if checkCollision(between: enemy, and: target) {
            handleWaveBasedCollision(enemy: enemy, player: target, waveInfo: waveInfo)
        }
    }
    
    private func performDirectApproach(enemy: Entity, target: Entity, speed: Float, deltaTime: Float) {
        let direction = normalize(target.position - enemy.position)
        applyMovementForce(to: enemy, direction: direction, speed: speed, deltaTime: deltaTime)
    }
    
    private func performAggressiveApproach(enemy: Entity, target: Entity, speed: Float, waveInfo: WaveGameInfo, deltaTime: Float) {
        let direction = normalize(target.position - enemy.position)
        let distance = distance(enemy.position, target.position)
        
        // Add some randomness for flanking
        let randomOffset = SIMD3<Float>(
            Float.random(in: -0.3...0.3),
            0,
            Float.random(in: -0.3...0.3)
        )
        
        let flankingDirection = normalize(direction + randomOffset)
        let enhancedSpeed = speed * (1.0 + Float(waveInfo.waveNumber - 1) * 0.1)
        
        applyMovementForce(to: enemy, direction: flankingDirection, speed: enhancedSpeed, deltaTime: deltaTime)
    }
    
    private func performSmartPositioning(enemy: Entity, target: Entity, speed: Float, waveInfo: WaveGameInfo, deltaTime: Float) {
        let distance = distance(enemy.position, target.position)
        let direction = normalize(target.position - enemy.position)
        
        // Try to approach from arena edges for better pushing angles
        let arenaCenter = SIMD3<Float>(0, target.position.y, 0)
        let enemyFromCenter = normalize(enemy.position - arenaCenter)
        let optimalDirection = normalize(direction + enemyFromCenter * 0.3)
        
        let enhancedSpeed = speed * waveInfo.speedMultiplier
        applyMovementForce(to: enemy, direction: optimalDirection, speed: enhancedSpeed, deltaTime: deltaTime)
    }
    
    private func performCoordinatedAttack(enemy: Entity, target: Entity, speed: Float, waveInfo: WaveGameInfo, deltaTime: Float) {
        // Advanced AI: Try to coordinate with other enemies for group attacks
        let direction = normalize(target.position - enemy.position)
        let distance = distance(enemy.position, target.position)
        
        // Enhanced speed and coordination
        let coordinatedSpeed = speed * waveInfo.speedMultiplier * 1.2
        
        // Add some strategic positioning based on enemy ID hash for variety
        let enemyHash = Float(enemy.id.hashValue % 100) / 100.0
        let strategicOffset = SIMD3<Float>(
            sin(enemyHash * 6.28) * 0.4,
            0,
            cos(enemyHash * 6.28) * 0.4
        )
        
        let strategicDirection = normalize(direction + strategicOffset)
        applyMovementForce(to: enemy, direction: strategicDirection, speed: coordinatedSpeed, deltaTime: deltaTime)
    }
    
    private func applyMovementForce(to enemy: Entity, direction: SIMD3<Float>, speed: Float, deltaTime: Float) {
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
    
    private func handleWaveBasedCollision(enemy: Entity, player: Entity, waveInfo: WaveGameInfo) {
        let collisionDirection = normalize(player.position - enemy.position)
        
        // Get masses for realistic collision response
        let playerMass = player.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.playerMass
        let enemyMass = enemy.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.enemyMass
        
        // Wave-based force multipliers - enemies get stronger each wave
        let waveForceMultiplier = 1.0 + Float(waveInfo.waveNumber - 1) * 0.2
        
        let baseForce = GameConfig.bounceForceMultiplier * waveForceMultiplier
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
    
    private func findPlayer(in context: SceneUpdateContext) -> Entity? {
        let playerQuery = EntityQuery(where: .has(GameStateComponent.self))
        for entity in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            return entity
        }
        return nil
    }
}
