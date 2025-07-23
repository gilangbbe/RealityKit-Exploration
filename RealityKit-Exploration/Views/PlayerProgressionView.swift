import SwiftUI

struct PlayerProgressionView: View {
    let progression: PlayerProgressionComponent
    let isCompact: Bool
    
    init(progression: PlayerProgressionComponent, isCompact: Bool = false) {
        self.progression = progression
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(PlayerUpgradeType.allCases, id: \.self) { upgradeType in
                UpgradeIconView(
                    upgradeType: upgradeType,
                    level: progression.upgradesApplied[upgradeType, default: 0],
                    isCompact: true
                )
            }
        }
        .frame(width: 160, height: 32) // Fixed size to prevent expansion
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
        .clipped() // Ensure nothing overflows the fixed bounds
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
                .frame(width: 28, height: 28) // Slightly smaller for better fit
            
            Circle()
                .stroke(upgradeColor, lineWidth: 1.5)
                .frame(width: 28, height: 28)
            
            Image(systemName: upgradeType.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(upgradeColor)
            
            if level > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(level)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 12, height: 12)
                            .background(upgradeColor)
                            .clipShape(Circle())
                            .offset(x: 4, y: 4)
                    }
                }
            }
        }
        .frame(width: 32, height: 32) // Fixed frame to prevent any expansion
    }
    
    private var upgradeColor: Color {
        switch upgradeType {
        case .resilience:
            return level > 0 ? .blue : .gray
        case .force:
            return level > 0 ? .red : .gray
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
