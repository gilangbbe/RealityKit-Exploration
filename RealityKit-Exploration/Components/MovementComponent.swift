import RealityKit

struct MovementComponent: Component {
    var velocity: SIMD3<Float> = [0, 0, 0]
    var speed: Float = 1.0
    var isMoving: Bool = false
    var constrainedTo: Entity? = nil // The entity to constrain movement to (cube)
    var surfaceOffset: Float = 0.0 // How far above the surface to stay
}
