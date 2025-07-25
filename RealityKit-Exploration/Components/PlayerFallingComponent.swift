import RealityKit
import Foundation

struct PlayerFallingComponent: Component, Codable {
    var isFalling: Bool = false
    var fallStartTime: TimeInterval = 0
    var fallProgress: Float = 0 // 0.0 to 1.0
    var shouldTriggerGameOver: Bool = false
    var hasTriggeredGameOver: Bool = false
    
    mutating func startFalling() {
        isFalling = true
        fallStartTime = Date().timeIntervalSince1970
        fallProgress = 0
        shouldTriggerGameOver = false
        hasTriggeredGameOver = false
    }
    
    mutating func updateProgress(deltaTime: Float) {
        guard isFalling else { return }
        
        let currentTime = Date().timeIntervalSince1970
        let elapsed = Float(currentTime - fallStartTime)
        
        // Calculate progress based on fall duration
        fallProgress = min(elapsed / GameConfig.playerFallDuration, 1.0)
        
        // Check if fall animation should complete
        if fallProgress >= 1.0 {
            shouldTriggerGameOver = true
        }
    }
}
