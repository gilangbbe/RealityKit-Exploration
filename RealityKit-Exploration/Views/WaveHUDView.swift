import SwiftUI

struct WaveHUDView: View {
    let waveNumber: Int
    let enemiesRemaining: Int
    let totalEnemies: Int
    let isWaveActive: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Wave number
            HStack {
                Text("WAVE")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("\(waveNumber)")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.cyan)
            }
            
            if isWaveActive {
                // Enemies remaining progress
                VStack(spacing: 4) {
                    HStack {
                        Text("Enemies:")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(enemiesRemaining)/\(totalEnemies)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(
                                    width: geometry.size.width * progressPercentage,
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                        }
                    }
                    .frame(height: 6)
                }
            } else {
                Text("PREPARING...")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .opacity(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                )
        )
    }
    
    private var progressPercentage: Double {
        guard totalEnemies > 0 else { return 0 }
        return Double(totalEnemies - enemiesRemaining) / Double(totalEnemies)
    }
}

#Preview {
    VStack(spacing: 20) {
        WaveHUDView(
            waveNumber: 3,
            enemiesRemaining: 7,
            totalEnemies: 12,
            isWaveActive: true
        )
        
        WaveHUDView(
            waveNumber: 1,
            enemiesRemaining: 0,
            totalEnemies: 5,
            isWaveActive: false
        )
    }
    .padding()
    .background(Color.blue.ignoresSafeArea())
}
