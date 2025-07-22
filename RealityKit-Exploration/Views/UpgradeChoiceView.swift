import SwiftUI

struct UpgradeChoiceView: View {
    let upgradeChoices: [PlayerUpgradeType]
    let currentWave: Int
    let onChoiceMade: (PlayerUpgradeType) -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Wave complete title
                VStack(spacing: 10) {
                    Text("WAVE \(currentWave - 1) COMPLETE!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("Choose your upgrade:")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Upgrade choices
                VStack(spacing: 15) {
                    ForEach(Array(upgradeChoices.enumerated()), id: \.offset) { index, upgradeType in
                        UpgradeOptionButton(
                            upgradeType: upgradeType,
                            onTap: { onChoiceMade(upgradeType) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Instruction
                Text("Choose wisely - each upgrade gets weaker with repetition")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
    }
}

struct UpgradeOptionButton: View {
    let upgradeType: PlayerUpgradeType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Icon
                Image(systemName: upgradeType.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(upgradeType.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(upgradeType.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.4))
                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

#Preview {
    UpgradeChoiceView(
        upgradeChoices: [.resilience, .force, .slowDuration],
        currentWave: 3,
        onChoiceMade: { upgradeType in
            print("Chosen: \(upgradeType.name)")
        }
    )
}
