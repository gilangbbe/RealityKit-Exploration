import SwiftUI
import simd

struct ControlsView: View {
    let startApplyingForce: (ForceDirection) -> Void
    let stopApplyingForce: () -> Void
    let applyAnalogForce: (SIMD2<Float>) -> Void
    
    var body: some View {
        // Full screen joystick area - tap anywhere to show controls
        AnalogJoystick { analogVector in
            applyAnalogForce(analogVector)
        } onRelease: {
            stopApplyingForce()
        }
    }
}
