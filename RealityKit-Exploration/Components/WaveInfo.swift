import Foundation

// Shared WaveInfo structure used for notifications between wave system and UI
struct WaveInfo {
    let waveNumber: Int
    let enemiesInWave: Int
    let enemiesRemaining: Int
}

// Shared WaveGameInfo structure used internally by systems for game logic
struct WaveGameInfo {
    let waveNumber: Int
    let speedMultiplier: Float
    let healthMultiplier: Float
    let scoreMultiplier: Float
    let spawnIntervalMultiplier: Float
    let maxEnemiesMultiplier: Float
    let isActive: Bool
}
