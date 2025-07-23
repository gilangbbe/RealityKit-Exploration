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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with game context
                    VStack(spacing: 12) {
                        Text("Player Progression")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(.orange)
                                    .font(.headline)
                                Text("Wave \(currentWave)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                Text("\(totalUpgrades) Upgrades")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Upgrade grid - mobile optimized with fixed sizing
                    LazyVGrid(columns: [
                        GridItem(.fixed(160), spacing: 16),
                        GridItem(.fixed(160), spacing: 16)
                    ], spacing: 16) {
                        ForEach(PlayerUpgradeType.allCases, id: \.self) { upgradeType in
                            GameUpgradeCard(
                                upgradeType: upgradeType,
                                level: progression.upgradesApplied[upgradeType, default: 0]
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: onClose) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.headline)
                                Text("Resume Game")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56) // Minimum 44pt + padding for accessibility
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .accessibilityLabel("Resume game")
                        .accessibilityHint("Returns to the game")
                        
                        Text("Tap anywhere to close • Press Tab for quick access")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
            }
            .frame(maxWidth: 400) // Maximum width for better readability
            .frame(maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Player progression overlay")
    }
    
    private var totalUpgrades: Int {
        progression.upgradesApplied.values.reduce(0, +)
    }
}

struct GameUpgradeCard: View {
    let upgradeType: PlayerUpgradeType
    let level: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with level - Fixed sizing
            ZStack {
                Circle()
                    .fill(upgradeColor.opacity(0.15))
                    .frame(width: 56, height: 56) // Larger touch target
                
                Circle()
                    .stroke(upgradeColor, lineWidth: 2)
                    .frame(width: 56, height: 56)
                
                Image(systemName: upgradeType.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(upgradeColor)
                
                if level > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(level)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20) // Fixed size
                                .background(upgradeColor)
                                .clipShape(Circle())
                                .offset(x: 8, y: 8)
                        }
                    }
                }
            }
            .frame(width: 56, height: 56) // Ensure consistent sizing
            
            // Title with fixed height
            Text(upgradeType.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32) // Fixed height for alignment
            
            // Level indicator with consistent spacing
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { dotLevel in
                    Circle()
                        .fill(dotLevel <= level ? upgradeColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8) // Slightly larger for better visibility
                }
            }
            .frame(height: 16) // Fixed height
            
            // Status with fixed height
            Text(level > 0 ? "Level \(level)" : "Not Upgraded")
                .font(.caption2)
                .foregroundColor(level > 0 ? upgradeColor : .gray)
                .frame(height: 16) // Fixed height
        }
        .padding(16) // Consistent padding using 8pt grid
        .frame(width: 160, height: 180) // Fixed card dimensions
        .background(
            RoundedRectangle(cornerRadius: 16) // Rounded corners following 8pt grid
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(level > 0 ? upgradeColor.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(upgradeType.name), level \(level)")
        .accessibilityValue(upgradeType.description)
    }
    
    private var upgradeColor: Color {
        switch upgradeType {
        case .resilience:
            return .blue
        case .force:
            return .red
        case .speed:
            return .green
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
