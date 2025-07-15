import RealityKit
import Foundation

struct WaveComponent: Component {
    var waveNumber: Int = 1
    var enemiesInWave: Int = 5
    var enemiesRemaining: Int = 5
    var waveCompleted: Bool = false
    var enemySpeedMultiplier: Float = 1.0
    var enemyHealthMultiplier: Float = 1.0
    var enemyScoreMultiplier: Float = 1.0
    var spawnIntervalMultiplier: Float = 1.0 // Lower = faster spawning
    var maxEnemiesMultiplier: Float = 1.0
    
    init(waveNumber: Int) {
        self.waveNumber = waveNumber
        // Scale difficulty based on wave number
        self.enemiesInWave = Int(Float(GameConfig.baseEnemiesPerWave) * pow(GameConfig.waveEnemyGrowthRate, Float(waveNumber - 1)))
        self.enemiesRemaining = enemiesInWave
        self.enemySpeedMultiplier = 1.0 + (Float(waveNumber - 1) * GameConfig.waveSpeedIncrease)
        self.enemyHealthMultiplier = 1.0 + (Float(waveNumber - 1) * GameConfig.waveHealthIncrease)
        self.enemyScoreMultiplier = 1.0 + (Float(waveNumber - 1) * GameConfig.waveScoreIncrease)
        self.spawnIntervalMultiplier = max(0.3, 1.0 - (Float(waveNumber - 1) * GameConfig.waveSpawnRateIncrease))
        self.maxEnemiesMultiplier = 1.0 + (Float(waveNumber - 1) * GameConfig.waveMaxEnemiesIncrease)
    }
}
