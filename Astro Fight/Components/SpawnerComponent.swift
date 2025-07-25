import RealityKit
import Foundation

struct SpawnerComponent: Component {
    var spawnInterval: TimeInterval = 3.0 // Current spawn interval (dynamically adjusted per wave)
    var baseSpawnInterval: TimeInterval = GameConfig.enemySpawnInterval // Base interval for wave 1
    var lastSpawnTime: Date = Date()
    var maxEnemies: Int = 5
    var spawnSurface: Entity? = nil // The surface to spawn on (cube)
    var enemyPrefabs: [EnemyType: Entity] = [:] // Dictionary of enemy prefabs by type
    
    // Burst spawning properties
    var lastBurstSpawnTime: Date = Date.distantPast
    var enemiesSpawnedInCurrentBurst: Int = 0
    var isInBurstMode: Bool = false
    var burstCooldown: TimeInterval = 2.0 // Cooldown between potential bursts
    
    // Legacy property for backward compatibility
    var enemyPrefab: Entity? {
        return enemyPrefabs[.phase1]
    }
    
    // Calculate dynamic spawn interval based on current wave
    mutating func updateSpawnIntervalForWave(_ wave: Int) {
        let reductionFactor = 1.0 - (Float(wave - 1) * GameConfig.enemySpawnIntervalReduction)
        let dynamicInterval = baseSpawnInterval * TimeInterval(max(reductionFactor, Float(GameConfig.enemyMinSpawnInterval / baseSpawnInterval)))
        spawnInterval = max(dynamicInterval, GameConfig.enemyMinSpawnInterval)
    }
    
    // Determine if should attempt burst spawning
    func shouldAttemptBurstSpawn(wave: Int, currentTime: Date) -> Bool {
        guard wave >= GameConfig.burstSpawningStartWave else { return false }
        guard currentTime.timeIntervalSince(lastBurstSpawnTime) >= burstCooldown else { return false }
        return Float.random(in: 0...1) < GameConfig.burstSpawningChance
    }
    
    // Calculate number of enemies to spawn in burst
    func calculateBurstSize(wave: Int) -> Int {
        let baseSize = min(2, wave - GameConfig.burstSpawningStartWave + 2) // Start with 2, increase gradually
        return min(baseSize, GameConfig.maxEnemiesPerBurst)
    }
}
