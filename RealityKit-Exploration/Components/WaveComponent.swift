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
    var baseEnemySpeed: Float = 1.0 // Reduced from 1.2 for balanced hyper-casual gameplay
    var baseEnemyMass: Float = 1.0 // Reduced from 1.2 for more manageable enemy strength
    
    // Wave progression settings (tuned for hyper-casual)
    var enemyHealthIncrease: Int = 1 // Health increase per wave
    var enemySpeedIncrease: Float = 0.15 // Reduced from 0.2 for gentler progression
    var enemyMassIncrease: Float = 0.08 // Reduced from 0.1 for better balance
    var enemyCountIncrease: Int = 1 // Additional enemies per wave
    
    // Current wave stats
    var currentWaveEnemyHealth: Int {
        return baseEnemyHealth + (currentWave - 1) * enemyHealthIncrease
    }
    
    var currentWaveEnemySpeed: Float {
        // Balanced enemy scaling to match player progression
        let effectiveWave = min(currentWave, GameConfig.enemyMaxScalingWaves)
        let scalingFactor = 1.0 + (Float(effectiveWave - 1) * GameConfig.enemyScalingPerWave)
        return baseEnemySpeed * scalingFactor
    }
    
    var currentWaveEnemyMass: Float {
        // Balanced enemy mass scaling
        let effectiveWave = min(currentWave, GameConfig.enemyMaxScalingWaves)
        let scalingFactor = 1.0 + (Float(effectiveWave - 1) * GameConfig.enemyScalingPerWave)
        return baseEnemyMass * scalingFactor
    }
    
    var currentWaveEnemyForceMultiplier: Float {
        // Progressive enemy push force scaling
        let effectiveWave = min(currentWave, GameConfig.enemyMaxScalingWaves)
        let forceScaling = 1.0 + (Float(effectiveWave - 1) * GameConfig.enemyForceScalingPerWave)
        return GameConfig.enemyPushForceMultiplier * forceScaling
    }
    
    var currentWaveEnemyCount: Int {
        // Apply diminishing returns to enemy count increases
        if currentWave == 1 {
            return enemiesPerWave // Base amount for wave 1
        }
        
        var totalIncrease: Float = 0
        for waveIncrement in 1..<currentWave {
            let diminishingMultiplier = pow(GameConfig.enemyCountDiminishingFactor, Float(waveIncrement - 1))
            totalIncrease += Float(enemyCountIncrease) * diminishingMultiplier
        }
        return enemiesPerWave + Int(totalIncrease)
    }
    
    mutating func startNextWave() {
        currentWave += 1
        enemiesSpawnedThisWave = 0
        enemiesDefeatedThisWave = 0
        isWaveActive = true
        lastWaveClearTime = Date()
        
        // Debug: Show diminishing returns progression
        print("Wave \(currentWave) started:")
        print("- Enemies this wave: \(currentWaveEnemyCount)")
        print("- Enemy speed: \(String(format: "%.2f", currentWaveEnemySpeed))")
        print("- Enemy mass: \(String(format: "%.2f", currentWaveEnemyMass))")
        print("- Enemy push force: \(String(format: "%.2f", currentWaveEnemyForceMultiplier))")
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