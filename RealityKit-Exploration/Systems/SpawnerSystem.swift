import RealityKit
import Foundation

class SpawnerSystem: System {
    static let query = EntityQuery(where: .has(SpawnerComponent.self))
    required init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var spawner = entity.components[SpawnerComponent.self] else { continue }
            
            // Get current wave information
            let waveComponent = getWaveComponent(context: context)
            
            // Only spawn if wave is active and hasn't reached its enemy limit
            guard let wave = waveComponent, wave.isWaveActive else { continue }
            guard wave.enemiesSpawnedThisWave < wave.currentWaveEnemyCount else { continue }
            
            let currentTime = Date()
            let timeSinceLastSpawn = currentTime.timeIntervalSince(spawner.lastSpawnTime)
            
            if timeSinceLastSpawn >= spawner.spawnInterval {
                let currentEnemyCount = countActiveEnemies(in: context)
                
                // Calculate wave-based max enemies with diminishing returns
                var waveBasedMaxEnemies: Int
                if wave.currentWave == 1 {
                    waveBasedMaxEnemies = GameConfig.enemyMaxCount
                } else {
                    var maxEnemiesIncrease: Float = 0
                    for waveIncrement in 1..<wave.currentWave {
                        let diminishingFactor = pow(GameConfig.maxEnemiesDiminishingFactor, Float(waveIncrement - 1))
                        maxEnemiesIncrease += Float(GameConfig.enemyMaxCountIncreasePerWave) * diminishingFactor
                    }
                    waveBasedMaxEnemies = GameConfig.enemyMaxCount + Int(maxEnemiesIncrease)
                }
                
                // Debug: Uncomment to see max enemy progression
                print("Wave \(wave.currentWave): Max enemies = \(waveBasedMaxEnemies), Current = \(currentEnemyCount)")
                
                if currentEnemyCount < waveBasedMaxEnemies,
                   let surface = spawner.spawnSurface,
                   let prefab = spawner.enemyPrefab {
                    spawnEnemy(on: surface, using: prefab, waveStats: wave, in: context)
                    spawner.lastSpawnTime = currentTime
                    
                    // Update wave component
                    updateWaveSpawnCount(context: context)
                }
            }
            entity.components[SpawnerComponent.self] = spawner
        }
    }
    
    private func getWaveComponent(context: SceneUpdateContext) -> WaveComponent? {
        let waveQuery = EntityQuery(where: .has(WaveComponent.self))
        for entity in context.entities(matching: waveQuery, updatingSystemWhen: .rendering) {
            return entity.components[WaveComponent.self]
        }
        return nil
    }
    
    private func updateWaveSpawnCount(context: SceneUpdateContext) {
        let waveQuery = EntityQuery(where: .has(WaveComponent.self))
        for entity in context.entities(matching: waveQuery, updatingSystemWhen: .rendering) {
            guard var wave = entity.components[WaveComponent.self] else { continue }
            wave.enemiesSpawnedThisWave += 1
            entity.components[WaveComponent.self] = wave
            break
        }
    }
    private func countActiveEnemies(in context: SceneUpdateContext) -> Int {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        var count = 0
        for _ in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) { count += 1 }
        return count
    }
    private func spawnEnemy(on surface: Entity, using prefab: Entity, waveStats: WaveComponent, in context: SceneUpdateContext) {
        let enemy = prefab.clone(recursive: true)
        let randomPosition = generateRandomPositionOnCubeSurface(cube: surface)
        enemy.position = randomPosition
        
        // Apply wave-based enemy stats
        var enemyComponent = EnemyCapsuleComponent()
        enemyComponent.speed = waveStats.currentWaveEnemySpeed
        enemyComponent.mass = waveStats.currentWaveEnemyMass
        enemyComponent.scoreValue = GameConfig.enemyScoreValue + (waveStats.currentWave * 10) // More points for harder enemies
        enemy.components.set(enemyComponent)
        
        // Add physics movement component with wave-enhanced stats
        var physicsComponent = PhysicsMovementComponent()
        physicsComponent.mass = waveStats.currentWaveEnemyMass
        physicsComponent.friction = GameConfig.frictionCoefficient
        physicsComponent.constrainedTo = surface
        physicsComponent.groundLevel = GameConfig.enemySpawnYOffset
        enemy.components.set(physicsComponent)
        
        surface.parent?.addChild(enemy)
    }
    private func generateRandomPositionOnCubeSurface(cube: Entity) -> SIMD3<Float> {
        let cubePosition = cube.position
        let cubeScale = cube.scale
        let halfSize = cubeScale.x / 2.0
        let randomX = Float.random(in: -halfSize...halfSize) + cubePosition.x
        let randomZ = Float.random(in: -halfSize...halfSize) + cubePosition.z
        let surfaceY = cubePosition.y + halfSize + 0.1
        return SIMD3<Float>(randomX, surfaceY, randomZ)
    }
}
