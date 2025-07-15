import RealityKit
import Foundation

struct WaveManagerComponent: Component {
    var currentWave: WaveComponent
    var isWaveActive: Bool = false
    var waveStartTime: Date = Date()
    var timeBetweenWaves: TimeInterval = 3.0
    var lastWaveEndTime: Date = Date()
    var totalWavesCompleted: Int = 0
    
    init() {
        self.currentWave = WaveComponent(waveNumber: 1)
    }
    
    mutating func startNextWave() {
        let nextWaveNumber = totalWavesCompleted + 1
        currentWave = WaveComponent(waveNumber: nextWaveNumber)
        totalWavesCompleted = nextWaveNumber
        isWaveActive = true
        waveStartTime = Date()
        
        print("🌊 Wave \(nextWaveNumber) started! Enemies: \(currentWave.enemiesInWave)")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .waveStarted, 
            object: WaveInfo(
                waveNumber: currentWave.waveNumber,
                enemiesInWave: currentWave.enemiesInWave,
                enemiesRemaining: currentWave.enemiesRemaining
            )
        )
    }
    
    mutating func enemyDefeated() {
        if isWaveActive && currentWave.enemiesRemaining > 0 {
            currentWave.enemiesRemaining -= 1
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .waveEnemyDefeated,
                object: WaveInfo(
                    waveNumber: currentWave.waveNumber,
                    enemiesInWave: currentWave.enemiesInWave,
                    enemiesRemaining: currentWave.enemiesRemaining
                )
            )
            
            if currentWave.enemiesRemaining <= 0 {
                completeWave()
            }
        }
    }
    
    mutating func completeWave() {
        currentWave.waveCompleted = true
        isWaveActive = false
        lastWaveEndTime = Date()
        
        print("🎉 Wave \(currentWave.waveNumber) completed!")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .waveCompleted,
            object: WaveInfo(
                waveNumber: currentWave.waveNumber,
                enemiesInWave: currentWave.enemiesInWave,
                enemiesRemaining: currentWave.enemiesRemaining
            )
        )
    }
    
    var isReadyForNextWave: Bool {
        return !isWaveActive && 
               currentWave.waveCompleted && 
               Date().timeIntervalSince(lastWaveEndTime) >= timeBetweenWaves
    }
}

extension Notification.Name {
    static let waveStarted = Notification.Name("waveStarted")
    static let waveCompleted = Notification.Name("waveCompleted")
    static let waveEnemyDefeated = Notification.Name("waveEnemyDefeated")
}
