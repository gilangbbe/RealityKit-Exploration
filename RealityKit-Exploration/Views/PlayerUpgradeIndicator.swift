import SwiftUI

struct PlayerUpgradeIndicator: View {
    let upgradeName: String
    let level: Int?
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    init(upgradeName: String, level: Int? = nil) {
        self.upgradeName = upgradeName
        self.level = level
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            
            Text(upgradeName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let level = level {
                Text("L\(level)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(upgradeColor.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Fade out after showing briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                    scale = 0.95
                }
            }
        }
    }
    
    private var upgradeColor: Color {
        switch upgradeName {
        case "Iron Will":
            return .blue
        case "Crushing Force":
            return .red
        case "Extended Slow":
            return .purple
        case "Devastating Shockwave":
            return .orange
        default:
            return .gray
        }
    }
    
    private var iconName: String {
        switch upgradeName {
        case "Iron Will":
            return "shield.fill"
        case "Crushing Force":
            return "hand.raised.fill"
        case "Extended Slow":
            return "clock.arrow.circlepath"
        case "Devastating Shockwave":
            return "burst.fill"
        // Legacy support
        case "Speed Boost":
            return "bolt.fill"
        case "Mass Increase":
            return "cube.fill"
        case "Force Boost":
            return "hand.raised.fill"
        default:
            return "arrow.up.circle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlayerUpgradeIndicator(upgradeName: "Iron Will", level: 2)
        PlayerUpgradeIndicator(upgradeName: "Crushing Force", level: 1)
        PlayerUpgradeIndicator(upgradeName: "Extended Slow", level: 3)
        PlayerUpgradeIndicator(upgradeName: "Devastating Shockwave", level: 1)
    }
    .background(Color.black)
}
