import SwiftUI

struct GameModalOverlaysView: View {
    // Game state
    let gameState: GameState
    let showUpgradeChoice: Bool
    let showProgressionOverlay: Bool
    
    // Game data
    let score: Int
    let enemiesDefeated: Int
    let currentWave: Int
    let upgradeChoices: [PlayerUpgradeType]
    let playerProgression: PlayerProgressionComponent
    let lastSnapShot: UIImage?
    
    // Actions
    let onResume: () -> Void
    let onMainMenu: () -> Void
    let onReplay: () -> Void
    let onUpgradeChoice: (PlayerUpgradeType) -> Void
    let onCloseProgression: () -> Void
    
    var body: some View {
        ZStack {
            // Pause Menu Overlay
            if gameState == .paused {
                PauseMenuView(
                    onResume: onResume,
                    onMainMenu: onMainMenu,
                    currentScore: score,
                    currentWave: currentWave
                )
            }
            
            // Game Over Overlay
            if gameState == .gameOver {
                GameOverView(
                    finalScore: score,
                    enemiesDefeated: enemiesDefeated,
                    wavesCompleted: max(1, currentWave - 1),
                    onReplay: onReplay,
                    onMainMenu: onMainMenu,
                    backgroundImage: lastSnapShot
                )
            }
            
            // Upgrade Choice Overlay
            if showUpgradeChoice {
                UpgradeChoiceView(
                    upgradeChoices: upgradeChoices,
                    currentWave: currentWave,
                    playerProgression: playerProgression,
                    onChoiceMade: onUpgradeChoice
                )
            }
            
            // Progression Overlay
            if showProgressionOverlay {
                ProgressionOverlayView(
                    progression: playerProgression,
                    currentWave: currentWave,
                    onClose: onCloseProgression
                )
            }
        }
    }
}

#Preview {
    GameModalOverlaysView(
        gameState: .paused,
        showUpgradeChoice: false,
        showProgressionOverlay: false,
        score: 15420,
        enemiesDefeated: 47,
        currentWave: 8,
        upgradeChoices: [.resilience, .force, .speed],
        playerProgression: {
            var comp = PlayerProgressionComponent()
            comp.upgradesApplied[.resilience] = 3
            comp.upgradesApplied[.force] = 1
            comp.upgradesApplied[.speed] = 5 // Maxed out
            return comp
        }(),
        lastSnapShot: nil,
        onResume: {},
        onMainMenu: {},
        onReplay: {},
        onUpgradeChoice: { _ in },
        onCloseProgression: {}
    )
}
