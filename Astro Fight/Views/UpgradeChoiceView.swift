import SwiftUI

struct UpgradeChoiceView: View {
    let upgradeChoices: [PlayerUpgradeType]
    let currentWave: Int
    let playerProgression: PlayerProgressionComponent
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
                            currentLevel: playerProgression.getUpgradeLevel(upgradeType),
                            onTap: { onChoiceMade(upgradeType) }
                        )
                    }
                }
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
    let currentLevel: Int
    let onTap: () -> Void
    
    private let maxLevel = 5
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with level indicator
                ZStack {
                    Image(systemName: upgradeType.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32) // Fixed icon area
                    
                    // Level indicator in corner
                    if currentLevel > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(currentLevel)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(levelColor)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(upgradeType.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Level \(currentLevel)/\(maxLevel)")
                            .font(.caption)
                            .foregroundColor(levelColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(levelColor.opacity(0.2))
                            )
                    }
                    
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
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(upgradeType.name), current level \(currentLevel) of \(maxLevel)")
        .accessibilityValue(upgradeType.description)
        .accessibilityHint("Tap to select this upgrade")
    }
    
    private var levelColor: Color {
        if currentLevel >= maxLevel {
            return .gold
        } else if currentLevel >= 3 {
            return .orange
        } else if currentLevel >= 1 {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var borderColor: Color {
        if currentLevel >= maxLevel - 1 {
            return .orange.opacity(0.7)
        } else {
            return .blue.opacity(0.5)
        }
    }
}

#Preview {
    UpgradeChoiceView(
        upgradeChoices: [.resilience, .force, .slowDuration],
        currentWave: 3,
        playerProgression: {
            var comp = PlayerProgressionComponent()
            comp.upgradesApplied[.resilience] = 2
            comp.upgradesApplied[.force] = 4
            comp.upgradesApplied[.slowDuration] = 1
            return comp
        }(),
        onChoiceMade: { upgradeType in
            print("Chosen: \(upgradeType.name)")
        }
    )
}
