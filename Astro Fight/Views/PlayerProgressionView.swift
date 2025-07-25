import SwiftUI

struct PlayerProgressionView: View {
    let progression: PlayerProgressionComponent
    let isCompact: Bool
    
    init(progression: PlayerProgressionComponent, isCompact: Bool = false) {
        self.progression = progression
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: 8) { // Consistent 8pt spacing
            ForEach(PlayerUpgradeType.allCases, id: \.self) { upgradeType in
                UpgradeIconView(
                    upgradeType: upgradeType,
                    level: progression.upgradesApplied[upgradeType, default: 0],
                    isCompact: true
                )
            }
        }
        .frame(width: 150, height: 40) // Larger fixed size for better visibility
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7)) // Slightly more opaque for better contrast
        .cornerRadius(12) // Rounded corners following 8pt grid
        .clipped() // Ensure nothing overflows the fixed bounds
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Player upgrades")
    }
}

struct UpgradeIconView: View {
    let upgradeType: PlayerUpgradeType
    let level: Int
    let isCompact: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(upgradeColor.opacity(0.3))
                .frame(width: 24, height: 24) // Slightly larger for better visibility
            
            Circle()
                .stroke(upgradeColor, lineWidth: 1.5)
                .frame(width: 24, height: 24)
            
            Image(systemName: upgradeType.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(upgradeColor)
            
            if level > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(level)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 14, height: 14) // Fixed size for consistency
                            .background(upgradeColor)
                            .clipShape(Circle())
                            .offset(x: 4, y: 4)
                    }
                }
            }
        }
        .frame(width: 24, height: 24) // Fixed frame to prevent any expansion
        .accessibilityLabel("\(upgradeType.name), level \(level)")
    }
    
    private var upgradeColor: Color {
        switch upgradeType {
        case .resilience:
            return level > 0 ? .blue : .gray
        case .force:
            return level > 0 ? .red : .gray
        case .speed:
            return level > 0 ? .green : .gray
        case .slowDuration:
            return level > 0 ? .purple : .gray
        case .shockwavePower:
            return level > 0 ? .orange : .gray
        }
    }
}

#Preview {
    VStack {
        PlayerProgressionView(
            progression: {
                var comp = PlayerProgressionComponent()
                comp.upgradesApplied[.resilience] = 2
                comp.upgradesApplied[.force] = 1
                comp.upgradesApplied[.slowDuration] = 3
                return comp
            }(),
            isCompact: true
        )
    }
    .background(Color.black)
}
