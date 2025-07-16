import SwiftUI

struct PlayerUpgradeIndicator: View {
    let upgradeName: String
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.cyan)
            
            Text(upgradeName)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan, lineWidth: 2)
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Fade out after showing briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0.0
                    scale = 0.8
                }
            }
        }
    }
    
    private var iconName: String {
        switch upgradeName {
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
