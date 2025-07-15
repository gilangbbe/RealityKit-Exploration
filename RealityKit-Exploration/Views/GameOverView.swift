import SwiftUI

struct GameOverView: View {
    let finalScore: Int
    let enemiesDefeated: Int
    let waveReached: Int
    let onReplay: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("GAME OVER")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(performanceMessage)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Text("You fell out of the arena!")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Final Score:")
                            .font(.title2)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(finalScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    HStack {
                        Text("Wave Reached:")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(waveReached)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                    }
                    
                    HStack {
                        Text("Enemies Defeated:")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(enemiesDefeated)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(performanceColor, lineWidth: 2)
                        )
                )
                
                Button(action: onReplay) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                        Text("PLAY AGAIN")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }
    
    private var performanceMessage: String {
        switch waveReached {
        case 1:
            return "Just getting started!"
        case 2...3:
            return "Getting the hang of it!"
        case 4...5:
            return "Impressive survival skills!"
        case 6...8:
            return "Sumo warrior in training!"
        case 9...12:
            return "Arena champion!"
        default:
            return "Legendary sumo master!"
        }
    }
    
    private var performanceColor: Color {
        switch waveReached {
        case 1...2:
            return .gray
        case 3...4:
            return .green
        case 5...7:
            return .yellow
        case 8...10:
            return .orange
        default:
            return .purple
        }
    }
}

#Preview {
    GameOverView(finalScore: 750, enemiesDefeated: 7, waveReached: 3) {
        print("Replay tapped")
    }
}
