import RealityKit
import Foundation

struct EnemyCapsuleComponent: Component {
    var isActive: Bool = true
    var spawnTime: Date = Date()
    var health: Int = 1
    var scoreValue: Int = 10
    var speed: Float = 0.0005
    var damage: Int = 1
    var target: Entity? = nil
}
