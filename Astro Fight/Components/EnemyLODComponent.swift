import RealityKit
import Foundation

/// Component for managing Level of Detail (LOD) for enemies
/// Reduces computation for distant enemies to improve performance
struct EnemyLODComponent: Component {
    /// Current LOD level (0 = full detail, 1 = reduced detail, 2 = minimal detail)
    var currentLOD: Int = 0
    
    /// Last time LOD was updated
    var lastLODUpdate: TimeInterval = 0
    
    /// How often to update LOD (in seconds)
    var lodUpdateInterval: TimeInterval = 0.5
    
    /// Distance to player for LOD calculation
    var distanceToPlayer: Float = 0
    
    /// Whether this enemy should use simplified behavior
    var useSimplifiedBehavior: Bool = false
    
    /// Whether this enemy should skip collision checks
    var skipCollisionChecks: Bool = false
    
    /// Whether this enemy should update movement less frequently
    var reducedMovementUpdates: Bool = false
    
    mutating func updateLOD(distanceToPlayer: Float, currentTime: TimeInterval) {
        guard currentTime - lastLODUpdate > lodUpdateInterval else { return }
        
        self.distanceToPlayer = distanceToPlayer
        lastLODUpdate = currentTime
        
        // Determine LOD level based on distance
        if distanceToPlayer > GameConfig.enemyLODDistance * 2 {
            // Very far - minimal detail
            currentLOD = 2
            useSimplifiedBehavior = true
            skipCollisionChecks = true
            reducedMovementUpdates = true
        } else if distanceToPlayer > GameConfig.enemyLODDistance {
            // Far - reduced detail
            currentLOD = 1
            useSimplifiedBehavior = true
            skipCollisionChecks = false
            reducedMovementUpdates = true
        } else {
            // Close - full detail
            currentLOD = 0
            useSimplifiedBehavior = false
            skipCollisionChecks = false
            reducedMovementUpdates = false
        }
    }
}
