import SwiftUI
import simd

struct AnalogJoystick: View {
    let onDrag: (SIMD2<Float>) -> Void
    let onRelease: () -> Void
    @State private var knobPosition: CGPoint = .zero
    @State private var isDragging: Bool = false
    private let joystickRadius: CGFloat = 60
    private let knobRadius: CGFloat = 20
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: joystickRadius * 2, height: joystickRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                )
            Circle()
                .fill(Color.blue)
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .position(
                    x: joystickRadius + knobPosition.x,
                    y: joystickRadius + knobPosition.y
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            updateKnobPosition(value.translation)
                        }
                        .onEnded { _ in
                            isDragging = false
                            returnKnobToCenter()
                            onRelease()
                        }
                )
        }
        .frame(width: joystickRadius * 2, height: joystickRadius * 2)
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
