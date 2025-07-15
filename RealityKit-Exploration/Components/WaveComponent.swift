import RealityKit
import Foundation

struct WaveComponent: Component {
    var currentWave: Int = 1
    var enemiesPerWave: Int = 2
    var enemiesSpawnedThisWave: Int = 0
    var enemiesDefeatedThisWave: Int = 0
    var isWaveActive: Bool = true
    var waveClearDelay: TimeInterval = 2.0
    var lastWaveClearTime: Date = Date.distantPast
    var baseEnemyHealth: Int = 1
    var baseEnemySpeed: Float = 1.0
    var baseEnemyMass: Float = 0.8
    
    // Wave progression settings
    var enemyHealthIncrease: Int = 1 // Health increase per wave
    var enemySpeedIncrease: Float = 0.2 // Speed increase per wave
    var enemyMassIncrease: Float = 0.1 // Mass increase per wave
    var enemyCountIncrease: Int = 1 // Additional enemies per wave
    
    // Current wave stats
    var currentWaveEnemyHealth: Int {
        return baseEnemyHealth + (currentWave - 1) * enemyHealthIncrease
    }
    
    var currentWaveEnemySpeed: Float {
        return baseEnemySpeed + Float(currentWave - 1) * enemySpeedIncrease
    }
    
    var currentWaveEnemyMass: Float {
        return baseEnemyMass + Float(currentWave - 1) * enemyMassIncrease
    }
    
    var currentWaveEnemyCount: Int {
        return enemiesPerWave + (currentWave - 1) * enemyCountIncrease
    }
    
    mutating func startNextWave() {
        currentWave += 1
        enemiesSpawnedThisWave = 0
        enemiesDefeatedThisWave = 0
        isWaveActive = true
        lastWaveClearTime = Date()
    }
    
    mutating func enemyDefeated() {
        enemiesDefeatedThisWave += 1
        if enemiesDefeatedThisWave >= currentWaveEnemyCount {
            isWaveActive = false
            lastWaveClearTime = Date()
        }
    }
    
    var isReadyForNextWave: Bool {
        return !isWaveActive && Date().timeIntervalSince(lastWaveClearTime) >= waveClearDelay
    }
}