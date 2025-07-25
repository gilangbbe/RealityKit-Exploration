import SwiftUI
import simd

struct AnalogJoystick: View {
    let onDrag: (SIMD2<Float>) -> Void
    let onRelease: () -> Void
    @State private var knobPosition: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var joystickCenter: CGPoint = .zero
    @State private var isVisible: Bool = false
    private let joystickRadius: CGFloat = 60 // UI config, can be moved to a UIConfig if needed
    private let knobRadius: CGFloat = 20
    var body: some View {
        ZStack {
            // Invisible tap area that covers the entire control area
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                // First touch - show joystick at tap location
                                isDragging = true
                                isVisible = true
                                joystickCenter = value.startLocation
                                knobPosition = .zero
                            }
                            
                            // Update knob position relative to joystick center
                            let translation = CGSize(
                                width: value.location.x - joystickCenter.x,
                                height: value.location.y - joystickCenter.y
                            )
                            updateKnobPosition(translation)
                        }
                        .onEnded { _ in
                            isDragging = false
                            returnKnobToCenter()
                            onRelease()
                            
                            // Hide joystick after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isVisible = false
                                }
                            }
                        }
                )
            
            // Joystick visual (only visible when active)
            if isVisible {
                ZStack {
                    // Joystick base
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: joystickRadius * 2, height: joystickRadius * 2)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .position(joystickCenter)
                    
                    // Joystick knob
                    Circle()
                        .fill(Color.blue.opacity(0.9))
                        .frame(width: knobRadius * 2, height: knobRadius * 2)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: Color.blue.opacity(0.4), radius: 3, x: 0, y: 1)
                        .position(
                            x: joystickCenter.x + knobPosition.x,
                            y: joystickCenter.y + knobPosition.y
                        )
                }
                .opacity(isDragging ? 1.0 : 0.8)
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isDragging)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
            }
        }
    }
    private func updateKnobPosition(_ translation: CGSize) {
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        let maxDistance = joystickRadius - knobRadius
        if distance <= maxDistance {
            knobPosition = CGPoint(x: translation.width, y: translation.height)
        } else {
            let angle = atan2(translation.height, translation.width)
            knobPosition = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
        }
        let normalizedX = Float(knobPosition.x / maxDistance)
        let normalizedY = Float(-knobPosition.y / maxDistance)
        onDrag(SIMD2<Float>(normalizedX, normalizedY))
    }
    private func returnKnobToCenter() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            knobPosition = .zero
        }
    }
}
