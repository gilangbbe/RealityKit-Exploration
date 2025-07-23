import SwiftUI

struct PauseMenuView: View {
    let onResume: () -> Void
    let onMainMenu: () -> Void
    let currentScore: Int
    let currentWave: Int
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Pause Title
                Text("GAME PAUSED")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .blue, radius: 5)
                    .accessibilityAddTraits(.isHeader)
                
                // Current Stats with fixed sizing
                VStack(spacing: 16) {
                    HStack {
                        Text("Current Score:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(currentScore)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Current Wave:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(currentWave)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 320) // Fixed maximum width
                .background(Color.black.opacity(0.3))
                .cornerRadius(16)
                
                // Menu Buttons with consistent sizing
                VStack(spacing: 16) {
                    // Resume Button
                    Button(action: onResume) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text("RESUME")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56) // Minimum 44pt + padding for accessibility
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 8)
                    }
                    .accessibilityLabel("Resume game")
                    .accessibilityHint("Returns to the game")
                    
                    // Main Menu Button
                    Button(action: onMainMenu) {
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.title3)
                            Text("MAIN MENU")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56) // Minimum 44pt + padding for accessibility
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .red.opacity(0.3), radius: 8)
                    }
                    .accessibilityLabel("Main menu")
                    .accessibilityHint("Returns to the main menu")
                }
                .frame(maxWidth: 280) // Fixed button container width
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: 400) // Maximum overlay width
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.8))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game paused")
    }
}

#Preview {
    PauseMenuView(
        onResume: { print("Resume") },
        onMainMenu: { print("Main Menu") },
        currentScore: 1500,
        currentWave: 3
    )
}
