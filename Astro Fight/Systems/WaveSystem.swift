import RealityKit
import Foundation

class WaveSystem: System {
    static let query = EntityQuery(where: .has(WaveComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var waveComponent = entity.components[WaveComponent.self] else { continue }
            
            // Check if ready for next wave
            if waveComponent.isReadyForNextWave {
                waveComponent.startNextWave()
                entity.components[WaveComponent.self] = waveComponent
                
                // Update game state with new wave
                updateGameStateWave(waveComponent.currentWave, context: context)
                
                // Notify UI about new wave
                NotificationCenter.default.post(name: .waveStarted, object: waveComponent.currentWave)
                
                // Award wave completion bonus (except for first wave)
                if waveComponent.currentWave > 1 {
                    let bonusPoints = calculateDiminishingWaveBonus(wave: waveComponent.currentWave)
                    NotificationCenter.default.post(name: .waveBonus, object: bonusPoints)
                    
                    // Show upgrade choices to player after completing a wave
                    showUpgradeChoices(context: context)
                }
            }
            
            entity.components[WaveComponent.self] = waveComponent
        }
    }
    
    private func updateGameStateWave(_ wave: Int, context: SceneUpdateContext) {
        let gameStateQuery = EntityQuery(where: .has(GameStateComponent.self))
        for entity in context.entities(matching: gameStateQuery, updatingSystemWhen: .rendering) {
            guard var gameState = entity.components[GameStateComponent.self] else { continue }
            gameState.currentWave = wave
            entity.components[GameStateComponent.self] = gameState
            break
        }
    }
    
    private func calculateDiminishingWaveBonus(wave: Int) -> Int {
        // Calculate wave bonus with diminishing returns
        var totalBonus = 0
        for completedWave in 1..<wave {
            let diminishingMultiplier = pow(GameConfig.waveScoreDiminishingFactor, Float(completedWave - 1))
            let waveBonus = Int(Float(GameConfig.waveScoreMultiplier) * diminishingMultiplier)
            totalBonus += waveBonus
        }
        return totalBonus
    }
    
    private func showUpgradeChoices(context: SceneUpdateContext) {
        let playerQuery = EntityQuery(where: .has(PlayerProgressionComponent.self) && .has(PhysicsMovementComponent.self))
        for entity in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            if let progression = entity.components[PlayerProgressionComponent.self] {
                let choices = progression.generateUpgradeChoices()
                
                // Send upgrade choices to UI
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .showUpgradeChoice, object: choices)
                }
            }
            break // Only one player
        }
    }
}

extension Notification.Name {
    static let waveStarted = Notification.Name("waveStarted")
    static let waveBonus = Notification.Name("waveBonus")
    static let showUpgradeChoice = Notification.Name("showUpgradeChoice")
}
