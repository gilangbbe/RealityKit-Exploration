import SwiftUI

struct MainMenuContainerView: View {
    let showLeaderboard: Bool
    let scoreManager: ScoreManager
    let onStartGame: () -> Void
    let onShowLeaderboard: () -> Void
    let onHideLeaderboard: () -> Void
    
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Main Menu (always visible behind modal)
            if !showLeaderboard {
                MainMenuView(
                    onStartGame: onStartGame,
                    onShowLeaderboard: onShowLeaderboard,
                    onShowSettings: { showSettings = true },
                    scoreManager: scoreManager
                )
            }
            
            // Leaderboard View (replaces main menu)
            if showLeaderboard {
                LeaderboardView(scoreManager: scoreManager) {
                    onHideLeaderboard()
                }
            }
        }
        // Settings Modal
        .sheet(isPresented: $showSettings) {
            SettingsView {
                showSettings = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    MainMenuContainerView(
        showLeaderboard: false,
        scoreManager: ScoreManager(),
        onStartGame: {},
        onShowLeaderboard: {},
        onHideLeaderboard: {}
    )
}
