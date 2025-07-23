import SwiftUI

struct ScoreView: View {
    let score: Int
    let enemiesDefeated: Int
    let currentWave: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Wave info - most important
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Wave \(currentWave)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if currentWave > 4 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            // Score - secondary info
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                
                Text("\(score)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                
                // Divider
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundColor(.red)
                
                Text("\(enemiesDefeated)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ScoreView(score: 500, enemiesDefeated: 5, currentWave: 3)
        ScoreView(score: 1250, enemiesDefeated: 15, currentWave: 8)
    }
    .background(Color.black)
}
