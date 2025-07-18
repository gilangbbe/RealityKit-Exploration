import SwiftUI

struct MainMenuView: View {
    let onStartGame: () -> Void
    
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
                }
                
                Spacer()
                
                // Start Game Button
                VStack(spacing: 20) {
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
                    
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    MainMenuView {
        print("Start game tapped")
    }
}
