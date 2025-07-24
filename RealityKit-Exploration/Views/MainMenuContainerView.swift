import SwiftUI

struct MainMenuContainerView: View {
    let showLeaderboard: Bool
    let showTutorial: Bool
    let scoreManager: ScoreManager
    let onStartGame: () -> Void
    let onShowLeaderboard: () -> Void
    let onHideLeaderboard: () -> Void
    let onShowTutorial: () -> Void
    let onHideTutorial: () -> Void
    
    var body: some View {
        ZStack {
            // Main Menu
            if !showLeaderboard && !showTutorial {
                MainMenuView(
                    onStartGame: onStartGame,
                    onShowLeaderboard: onShowLeaderboard,
                    onShowTutorial: onShowTutorial,
                    scoreManager: scoreManager
                )
            }
            
            // Leaderboard View
            if showLeaderboard {
                LeaderboardView(scoreManager: scoreManager) {
                    onHideLeaderboard()
                }
            }
            
            // Tutorial View
            if showTutorial {
                TutorialView(showTutorial: .constant(true), onDismiss: onHideTutorial)
            }
        }
    }
}

#Preview {
    MainMenuContainerView(
        showLeaderboard: false,
        showTutorial: false,
        scoreManager: ScoreManager(),
        onStartGame: {},
        onShowLeaderboard: {},
        onHideLeaderboard: {},
        onShowTutorial: {},
        onHideTutorial: {}
    )
}
