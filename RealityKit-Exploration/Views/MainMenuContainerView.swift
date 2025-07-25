import SwiftUI

struct MainMenuContainerView: View {
    let showLeaderboard: Bool
    let scoreManager: ScoreManager
    let onStartGame: () -> Void
    let onShowLeaderboard: () -> Void
    let onHideLeaderboard: () -> Void
    
    var body: some View {
        ZStack {
            // Main Menu
            if !showLeaderboard {
                MainMenuView(
                    onStartGame: onStartGame,
                    onShowLeaderboard: onShowLeaderboard,
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
