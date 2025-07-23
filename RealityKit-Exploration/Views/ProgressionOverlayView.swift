import SwiftUI

struct ProgressionOverlayView: View {
    let progression: PlayerProgressionComponent
    let currentWave: Int
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Darker background for better focus
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            VStack(spacing: 20) {
                // Header with game context
                VStack(spacing: 8) {
                    Text("Player Progression")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                        Text("Wave \(currentWave)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Text("\(totalUpgrades) Upgrades")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                
                // Upgrade grid - mobile optimized
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(PlayerUpgradeType.allCases, id: \.self) { upgradeType in
                        GameUpgradeCard(
                            upgradeType: upgradeType,
                            level: progression.upgradesApplied[upgradeType, default: 0]
                        )
                    }
                }
                .padding(.horizontal, 16)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onClose) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume Game")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.6), lineWidth: 3)
                                )
                        )
                        .shadow(color: Color.purple.opacity(0.8), radius: 6, x: 0, y: 0)
                        .shadow(color: Color.purple.opacity(0.8), radius: 12, x: 0, y: 0)
                    }
                    
                    Text("Tap anywhere to close • Press Tab for quick access")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: 400)
        }
    }
    
    private var totalUpgrades: Int {
        progression.upgradesApplied.values.reduce(0, +)
    }
}

struct GameUpgradeCard: View {
    let upgradeType: PlayerUpgradeType
    let level: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with level
            ZStack {
                Circle()
                    .fill(upgradeColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .stroke(upgradeColor, lineWidth: 2)
                    .frame(width: 50, height: 50)
                
                Image(systemName: upgradeType.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(upgradeColor)
                
                if level > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(level)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(upgradeColor)
                                .clipShape(Circle())
                                .offset(x: 6, y: 6)
                        }
                    }
                }
            }
            
            // Title
            Text(upgradeType.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Level indicator
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { dotLevel in
                    Circle()
                        .fill(dotLevel <= level ? upgradeColor : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            // Status
            Text(level > 0 ? "Level \(level)" : "Not Upgraded")
                .font(.caption2)
                .foregroundColor(level > 0 ? upgradeColor : .gray)
        }
        .padding(12)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(level > 0 ? upgradeColor.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var upgradeColor: Color {
        switch upgradeType {
        case .resilience:
            return .blue
        case .force:
            return .red
        case .slowDuration:
            return .purple
        case .shockwavePower:
            return .orange
        }
    }
}

#Preview {
    ProgressionOverlayView(
        progression: {
            var comp = PlayerProgressionComponent()
            comp.upgradesApplied[.resilience] = 2
            comp.upgradesApplied[.force] = 3
            comp.upgradesApplied[.slowDuration] = 1
            comp.upgradesApplied[.shockwavePower] = 2
            return comp
        }(),
        currentWave: 5,
        onClose: {}
    )
}
