import RealityKit
import Foundation

struct EnemyCapsuleComponent: Component {
    var isActive: Bool = true
    var spawnTime: Date = Date()
    var health: Int = 1
    var scoreValue: Int = 10
}
