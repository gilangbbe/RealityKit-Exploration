import RealityKit
import Foundation

struct PlayerAnimationComponent: Component {
    var isWalking: Bool = false
    var isAttacking: Bool = false
    var isUsingShockwave: Bool = false
    var currentAnimationController: AnimationPlaybackController?
    var attackAnimationEndTime: TimeInterval = 0.0 // When current attack animation should end
    var shockwaveAnimationEndTime: TimeInterval = 0.0 // When shockwave animation should end
    
    // Track last movement to prevent unnecessary animation changes
    var lastMovementMagnitude: Float = 0.0
    
    // Check if player should be immobilized (during shockwave)
    var isImmobilized: Bool {
        return isUsingShockwave
    }
}
