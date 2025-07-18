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
            
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("You fell out of the arena!")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Waves Completed:")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("\(wavesCompleted)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Final Score:")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("\(finalScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    HStack {
                        Text("Enemies Defeated:")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(enemiesDefeated)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                )
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: onReplay) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            Text("PLAY AGAIN")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 8)
                    }
                    
                    Button(action: onMainMenu) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.title3)
                            Text("MAIN MENU")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .gray.opacity(0.3), radius: 8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
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
