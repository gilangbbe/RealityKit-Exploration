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
            
            VStack(spacing: 30) {
                // Pause Title
                Text("GAME PAUSED")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .blue, radius: 5)
                
                // Current Stats
                VStack(spacing: 15) {
                    HStack {
                        Text("Current Score:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(currentScore)")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Current Wave:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(currentWave)")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                
                // Menu Buttons
                VStack(spacing: 15) {
                    // Resume Button
                    Button(action: onResume) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text("RESUME")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .green.opacity(0.3), radius: 8)
                    }
                    
                    // Main Menu Button
                    Button(action: onMainMenu) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.title3)
                            Text("MAIN MENU")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .red.opacity(0.3), radius: 8)
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.8))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
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
