import SwiftUI

struct GameOverlayView: View {
    // Game state
    let score: Int
    let enemiesDefeated: Int
    let currentWave: Int
    let gameState: GameState
    
    // Player state
    let playerProgression: PlayerProgressionComponent
    let activePowerUp: String?
    let playerUpgrade: String?
    
    // Time slow state
    let timeSlowEndTime: TimeInterval
    let timeSlowDuration: TimeInterval
    let currentTime: TimeInterval
    
    // Actions
    let onPauseGame: () -> Void
    let onShowProgression: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full-width background at the top
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.3), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            
            VStack {
                // Top HUD
                HStack(alignment: .center) {
                    ScoreView(score: score, enemiesDefeated: enemiesDefeated, currentWave: currentWave)
                        .frame(width: 150)
                    
                    Button(action: onShowProgression) {
                        PlayerProgressionView(progression: playerProgression, isCompact: true)
                    }
                    
                    Button(action: onPauseGame) {
                        Image(systemName: "pause.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .frame(alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                HStack {
                    if let upgrade = playerUpgrade {
                        let upgradeType = PlayerUpgradeType.allCases.first { $0.name == upgrade }
                        let level = upgradeType.map { playerProgression.upgradesApplied[$0, default: 0] }
                        PlayerUpgradeIndicator(upgradeName: upgrade, level: level)
                            .frame(maxWidth: .infinity)
                    } else if timeSlowEndTime > currentTime {
                        let remainingTime = max(0, timeSlowEndTime - currentTime)
                        TimeSlowIndicator(
                            remainingTime: remainingTime,
                            totalDuration: timeSlowDuration
                        )
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                if let powerUp = activePowerUp {
                    PowerUpIndicator(powerUpName: powerUp)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
        }

    }
}

#Preview {
    GameOverlayView(
        score: 15420,
        enemiesDefeated: 47,
        currentWave: 8,
        gameState: .playing,
        playerProgression: PlayerProgressionComponent(),
        activePowerUp: "Shield",
        playerUpgrade: "Devastating Shockwave",
        timeSlowEndTime: Date().timeIntervalSince1970 + 3.0,
        timeSlowDuration: 5.0,
        currentTime: Date().timeIntervalSince1970,
        onPauseGame: {},
        onShowProgression: {}
    )
}
