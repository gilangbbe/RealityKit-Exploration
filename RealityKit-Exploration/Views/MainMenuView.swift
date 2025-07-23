import SwiftUI

struct MainMenuView: View {
    let onStartGame: () -> Void
    let onShowLeaderboard: () -> Void
    let scoreManager: ScoreManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Game Title
                VStack(spacing: 20) {
                    Text("ARENA")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue, radius: 10)
                    
                    Text("COMBAT")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .shadow(color: .white, radius: 5)
                    
                    Text("Push your enemies off the arena!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // High Score Display
                    if scoreManager.highScore > 0 {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("High Score: \(scoreManager.highScore)")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // Menu Buttons
                VStack(spacing: 20) {
                    // Start Game Button
                    Button(action: onStartGame) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("START GAME")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: false)
                    
                    // Leaderboard Button
                    Button(action: onShowLeaderboard) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                            Text("LEADERBOARD")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    MainMenuView(
        onStartGame: { print("Start game tapped") },
        onShowLeaderboard: { print("Show leaderboard tapped") },
        scoreManager: ScoreManager()
    )
}
