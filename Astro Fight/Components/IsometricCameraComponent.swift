import RealityKit

struct IsometricCameraComponent: Component {
    var target: Entity?
    var offset: SIMD3<Float> = [3, 8, 3] // Isometric offset from target
    var smoothing: Float = 0.1 // Camera follow smoothing factor
    var lookAtTarget: Bool = true
}
