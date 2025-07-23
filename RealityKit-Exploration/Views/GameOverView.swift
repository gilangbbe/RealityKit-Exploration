import SwiftUI

struct GameOverView: View {
    let finalScore: Int
    let enemiesDefeated: Int
    let wavesCompleted: Int
    let onReplay: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Title section
                    VStack(spacing: 16) {
                        Text("GAME OVER")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("You fell out of the arena!")
                            .font(.title2)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    
                    // Stats section with fixed sizing
                    VStack(spacing: 20) {
                        StatRow(
                            title: "Waves Completed:",
                            value: "\(wavesCompleted)",
                            valueColor: .orange,
                            titleFont: .title2,
                            valueFont: .title
                        )
                        
                        StatRow(
                            title: "Final Score:",
                            value: "\(finalScore)",
                            valueColor: .yellow,
                            titleFont: .title2,
                            valueFont: .title
                        )
                        
                        StatRow(
                            title: "Enemies Defeated:",
                            value: "\(enemiesDefeated)",
                            valueColor: .red,
                            titleFont: .headline,
                            valueFont: .title2
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 360) // Fixed maximum width
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                    )
                    
                    // Action Buttons with consistent sizing
                    VStack(spacing: 16) {
                        Button(action: onReplay) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                Text("PLAY AGAIN")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64) // Larger touch target for primary action
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8)
                        }
                        .accessibilityLabel("Play again")
                        .accessibilityHint("Starts a new game")
                        
                        Button(action: onMainMenu) {
                            HStack(spacing: 12) {
                                Image(systemName: "house.fill")
                                    .font(.title3)
                                Text("MAIN MENU")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56) // Standard button height
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .gray.opacity(0.3), radius: 8)
                        }
                        .accessibilityLabel("Main menu")
                        .accessibilityHint("Returns to the main menu")
                    }
                    .frame(maxWidth: 320) // Fixed button container width
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .frame(maxWidth: 480) // Maximum overlay width
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game over screen")
    }
}

// Helper view for consistent stat display
struct StatRow: View {
    let title: String
    let value: String
    let valueColor: Color
    let titleFont: Font
    let valueFont: Font
    
    var body: some View {
        HStack {
            Text(title)
                .font(titleFont)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(valueFont)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
        }
        .frame(height: 32) // Fixed height for alignment
    }
}

#Preview {
    GameOverView(
        finalScore: 750, 
        enemiesDefeated: 7, 
        wavesCompleted: 3,
        onReplay: { print("Replay tapped") },
        onMainMenu: { print("Main Menu tapped") }
    )
}
