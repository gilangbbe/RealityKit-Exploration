import SwiftUI

struct PowerUpIndicator: View {
    let powerUpName: String
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text(powerUpName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(powerUpColor.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Fade out after showing briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0.0
                    scale = 0.95
                }
            }
        }
    }
    
    private var powerUpColor: Color {
        switch powerUpName {
        case "Time Slow":
            return .purple
        case "Shockwave":
            return .orange
        default:
            return .green
        }
    }
    
    private var iconName: String {
        switch powerUpName {
        case "Time Slow":
            return "clock.arrow.circlepath"
        case "Shockwave":
            return "burst.fill"
        default:
            return "star.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PowerUpIndicator(powerUpName: "Time Slow")
        PowerUpIndicator(powerUpName: "Shockwave")
    }
    .background(Color.black)
}
