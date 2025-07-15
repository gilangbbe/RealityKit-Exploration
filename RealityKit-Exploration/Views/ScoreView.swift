import SwiftUI

struct ScoreView: View {
    let score: Int
    let enemiesDefeated: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                Text("Enemies Defeated:")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("\(enemiesDefeated)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
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
    ScoreView(score: 500, enemiesDefeated: 5)
}
