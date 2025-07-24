import RealityKit
import Foundation

struct EnemyFallingComponent: Component, Codable {
    var isFalling: Bool = false
    var fallStartTime: TimeInterval = 0
    var fallDuration: Float = 2.0 // How long the falling animation lasts
    var hasTriggeredCleanup: Bool = false // Prevent multiple cleanup calls
    
    mutating func startFalling() {
        if !isFalling {
            isFalling = true
            fallStartTime = Date().timeIntervalSince1970
            hasTriggeredCleanup = false
        }
    }
    
    var fallProgress: Float {
        guard isFalling else { return 0.0 }
        let elapsed = Float(Date().timeIntervalSince1970 - fallStartTime)
        return min(elapsed / fallDuration, 1.0)
    }
    
    var shouldRemove: Bool {
        return isFalling && fallProgress >= 1.0
    }
}
