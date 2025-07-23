import RealityKit
import Foundation

// Component for tracking enemy animation state
struct EnemyAnimationComponent: Component, Codable {
    var isWalking: Bool = false
    var lastMovementTime: TimeInterval = 0
    var animationChildEntityName: String = ""
    
    // Initialize with enemy type name for finding animation child entity
    init(enemyType: EnemyType) {
        self.animationChildEntityName = enemyType.rawValue // "enemyPhase1", "enemyPhase2", etc.
    }
    
    // Default initializer for Codable
    init() {
        self.animationChildEntityName = EnemyType.phase1.rawValue
    }
}
