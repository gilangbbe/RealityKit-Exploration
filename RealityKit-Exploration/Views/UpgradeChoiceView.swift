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
            
            VStack(spacing: 32) {
                // Wave complete title with consistent spacing
                VStack(spacing: 16) {
                    Text("WAVE \(currentWave - 1) COMPLETE!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Choose your upgrade:")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                
                // Upgrade choices with fixed sizing
                VStack(spacing: 16) { // Consistent 16pt spacing
                    ForEach(Array(upgradeChoices.enumerated()), id: \.offset) { index, upgradeType in
                        UpgradeOptionButton(
                            upgradeType: upgradeType,
                            onTap: { onChoiceMade(upgradeType) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Instruction with proper spacing
                Text("Choose wisely - each upgrade gets weaker with repetition")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: 500) // Maximum width for better readability
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Upgrade selection")
    }
}

struct UpgradeOptionButton: View {
    let upgradeType: PlayerUpgradeType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with fixed sizing
                Image(systemName: upgradeType.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32) // Fixed icon area
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(upgradeType.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(upgradeType.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow indicator with fixed sizing
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24) // Fixed arrow area
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20) // Minimum 44pt touch target
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64) // Ensure minimum touch target size
            .background(
                RoundedRectangle(cornerRadius: 16) // Consistent with 8pt grid
                    .fill(Color.black.opacity(0.4))
                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(upgradeType.name)
        .accessibilityValue(upgradeType.description)
        .accessibilityHint("Tap to select this upgrade")
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
