import SwiftUI

struct GameOverView: View {
    let finalScore: Int
    let enemiesDefeated: Int
    let wavesCompleted: Int
    let onReplay: () -> Void
    let onMainMenu: () -> Void
    let backgroundImage: UIImage?


    var body: some View {
        ZStack {
            if let bgImage = backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 8)       // Add blur effect to simulate "background"
                    .overlay(Color.black.opacity(0.5)) // Dark overlay for contrast
                    .ignoresSafeArea()
            } else {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
            }

            
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .shadow(color: Color.black.opacity(0.8), radius: 6, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.8), radius: 12, x: 0, y: 0)
                
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
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Final Score:")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("\(finalScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    HStack {
                        Text("Enemies Defeated:")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("\(enemiesDefeated)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .padding(.horizontal, 20)
                //.padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.6))
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.6), lineWidth: 3)
                                )
                        )
                        .shadow(color: Color.purple.opacity(0.8), radius: 6, x: 0, y: 0)
                        .shadow(color: Color.purple.opacity(0.8), radius: 12, x: 0, y: 0)
                    
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.6), lineWidth: 3)
                                )
                        )
                        .shadow(color: Color.yellow.opacity(0.8), radius: 6, x: 0, y: 0)
                        .shadow(color: Color.yellow.opacity(0.8), radius: 12, x: 0, y: 0)
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
        onMainMenu: { print("Main Menu tapped")},
        backgroundImage: nil
    )
}
