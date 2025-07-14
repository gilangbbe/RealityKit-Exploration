import SwiftUI

struct HealthBarView: View {
    let currentHealth: Int
    let maxHealth: Int
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<maxHealth, id: \.self) { index in
                Image(systemName: index < currentHealth ? "heart.fill" : "heart")
                    .foregroundColor(index < currentHealth ? .red : .gray)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
        )
    }
}

#Preview {
    HealthBarView(currentHealth: 2, maxHealth: 3)
}
