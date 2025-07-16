import SwiftUI

struct ScoreView: View {
    let score: Int
    let enemiesDefeated: Int
    let currentWave: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Wave:")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(currentWave)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                // Difficulty indicator
                if currentWave > 4 {
                    Text("⚡")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("📈")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Text("Score:")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            
            HStack {
                Text("Enemies:")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("\(enemiesDefeated)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
        )
    }
}

#Preview {
    ScoreView(score: 500, enemiesDefeated: 5, currentWave: 3)
}
