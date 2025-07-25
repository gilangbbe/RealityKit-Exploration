import SwiftUI

struct TimeSlowIndicator: View {
    let remainingTime: TimeInterval
    let totalDuration: TimeInterval
    
    private var progress: Double {
        return max(0, min(1, remainingTime / totalDuration))
    }
    
    private var progressColor: Color {
        if progress > 0.6 {
            return .blue
        } else if progress > 0.3 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Time slow icon with pulsing effect
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blue)
                .scaleEffect(progress > 0.3 ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: progress)
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: 60, height: 6)
                    .foregroundColor(.gray.opacity(0.3))
                    .cornerRadius(3)
                
                Rectangle()
                    .frame(width: 60 * progress, height: 6)
                    .foregroundColor(progressColor)
                    .cornerRadius(3)
                    .animation(.linear(duration: 0.1), value: progress)
            }
            
            // Remaining time text
            Text(String(format: "%.1fs", remainingTime))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(progressColor, lineWidth: 1)
                )
        )
        .opacity(remainingTime > 0 ? 1 : 0)
        .scaleEffect(remainingTime > 0 ? 1 : 0.8)
        .animation(.easeInOut(duration: 0.3), value: remainingTime > 0)
    }
}

#Preview {
    VStack(spacing: 20) {
        TimeSlowIndicator(remainingTime: 3.0, totalDuration: 3.0)
        TimeSlowIndicator(remainingTime: 1.5, totalDuration: 3.0)
        TimeSlowIndicator(remainingTime: 0.5, totalDuration: 3.0)
    }
    .background(Color.gray)
}
