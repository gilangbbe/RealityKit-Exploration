import RealityKit
import Foundation

struct PhysicsMovementComponent: Component {
    var velocity: SIMD3<Float> = [0, 0, 0]
    var mass: Float = 1.0
    var friction: Float = 0.95
    var isOnGround: Bool = true
    var groundLevel: Float = 0.0
    var constrainedTo: Entity? = nil
}
