import RealityKit
import Foundation

struct AutoShootComponent: Component {
    var shootInterval: TimeInterval = 0.5 // Shoot every 0.5 seconds
    var lastShootTime: Date = Date()
    var shootWhileMoving: Bool = true
    var isEnabled: Bool = true
}
