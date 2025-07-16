import RealityKit
import Foundation

struct EnemyCapsuleComponent: Component {
    var isActive: Bool = true
    var spawnTime: Date = Date()
    var scoreValue: Int = 10
    var speed: Float = 1.5
    var mass: Float = 1.0
    var target: Entity? = nil
    var hasFallen: Bool = false
}
