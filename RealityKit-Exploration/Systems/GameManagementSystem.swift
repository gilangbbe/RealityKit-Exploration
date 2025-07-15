import RealityKit
import Foundation

class GameManagementSystem: System {
    static let query = EntityQuery(where: .has(GameStateComponent.self))
    static let waveQuery = EntityQuery(where: .has(WaveManagerComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Handle wave management
        updateWaveSystem(in: context)
        
        // Handle fallen entities
        NotificationCenter.default.addObserver(
            forName: .entityFell,
            object: nil,
            queue: .main
        ) { notification in
            guard let fallenEntity = notification.object as? Entity else { return }
            self.handleFallenEntity(fallenEntity, in: context)
        }
    }
    
    private func updateWaveSystem(in context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.waveQuery, updatingSystemWhen: .rendering) {
            guard var waveManager = entity.components[WaveManagerComponent.self] else { continue }
            
            // If no wave is active and it's the first wave, start it immediately
            if !waveManager.isWaveActive && waveManager.totalWavesCompleted == 0 {
                print("🌊 Starting first wave...")
                waveManager.startNextWave()
                entity.components[WaveManagerComponent.self] = waveManager
                break
            }
            
            // Check if we need to start the next wave
            if waveManager.isReadyForNextWave {
                print("🌊 Starting wave \(waveManager.totalWavesCompleted + 1)...")
                waveManager.startNextWave()
                entity.components[WaveManagerComponent.self] = waveManager
                break
            }
        }
    }
    
    private func handleFallenEntity(_ entity: Entity, in context: SceneUpdateContext) {
        // Check if it's an enemy
        if var enemyComponent = entity.components[EnemyCapsuleComponent.self] {
            enemyComponent.hasFallen = true
            entity.components[EnemyCapsuleComponent.self] = enemyComponent
            
            // Get wave multiplier for score calculation
            let scoreMultiplier = getCurrentWaveScoreMultiplier(in: context)
            let adjustedScore = Int(Float(enemyComponent.scoreValue) * scoreMultiplier)
            
            // Award points to player
            updatePlayerScore(points: adjustedScore, in: context)
            
            // Update wave progress
            updateWaveProgress(in: context)
            
            // Remove the fallen enemy
            entity.removeFromParent()
            
            // Post notification for UI update
            NotificationCenter.default.post(name: .enemyDefeated, object: adjustedScore)
        }
        
        // Check if it's the player
        if entity.components[GameStateComponent.self] != nil {
            // Player fell - game over
            NotificationCenter.default.post(name: .playerFell, object: nil)
        }
    }
    
    private func getCurrentWaveScoreMultiplier(in context: SceneUpdateContext) -> Float {
        for entity in context.entities(matching: Self.waveQuery, updatingSystemWhen: .rendering) {
            guard let waveManager = entity.components[WaveManagerComponent.self] else { continue }
            return waveManager.currentWave.enemyScoreMultiplier
        }
        return 1.0
    }
    
    private func updateWaveProgress(in context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.waveQuery, updatingSystemWhen: .rendering) {
            guard var waveManager = entity.components[WaveManagerComponent.self] else { continue }
            print("🎯 Enemy defeated! Remaining: \(waveManager.currentWave.enemiesRemaining - 1)")
            waveManager.enemyDefeated()
            entity.components[WaveManagerComponent.self] = waveManager
        }
    }
    
    private func updatePlayerScore(points: Int, in context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var gameState = entity.components[GameStateComponent.self] else { continue }
            gameState.score += points
            gameState.enemiesDefeated += 1
            entity.components[GameStateComponent.self] = gameState
            
            // Notify UI about score change
            NotificationCenter.default.post(name: .scoreChanged, object: gameState.score)
            break
        }
    }
}

extension Notification.Name {
    static let enemyDefeated = Notification.Name("enemyDefeated")
    static let playerFell = Notification.Name("playerFell")
    static let scoreChanged = Notification.Name("scoreChanged")
}
