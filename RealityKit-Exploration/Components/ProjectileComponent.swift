import RealityKit
import Foundation

struct ProjectileComponent: Component {
    var velocity: SIMD3<Float> = [0, 0, 0]
    var speed: Float = 2.0
    var damage: Int = 1
    var lifetime: TimeInterval = 5.0
    var spawnTime: Date = Date()
}
