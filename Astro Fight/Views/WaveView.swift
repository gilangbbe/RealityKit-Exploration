import SwiftUI

struct WaveView: View {
    let currentWave: Int
    let enemiesRemaining: Int
    let isWaveActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Wave")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(currentWave)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            if isWaveActive {
                HStack {
                    Text("Enemies Left:")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("\(enemiesRemaining)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            } else {
                Text("WAVE CLEAR!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWaveActive)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isWaveActive ? Color.orange : Color.green, lineWidth: 2)
                )
        )
    }
}

#Preview {
    VStack {
        WaveView(currentWave: 3, enemiesRemaining: 2, isWaveActive: true)
        WaveView(currentWave: 3, enemiesRemaining: 0, isWaveActive: false)
    }
}
