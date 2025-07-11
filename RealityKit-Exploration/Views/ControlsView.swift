import SwiftUI
import simd

struct ControlsView: View {
    let startApplyingForce: (ForceDirection) -> Void
    let stopApplyingForce: () -> Void
    let applyAnalogForce: (SIMD2<Float>) -> Void
    var body: some View {
        VStack {
            Spacer()
            AnalogJoystick { analogVector in
                applyAnalogForce(analogVector)
            } onRelease: {
                stopApplyingForce()
            }
            .frame(width: 150, height: 150)
            .padding(.bottom, 50)
        }
    }
}
