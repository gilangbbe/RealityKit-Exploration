import simd
import Foundation

struct GameConfig {
    // Player movement
    static let playerSpeed: Float = 2.0
    static let playerSurfaceOffsetMargin: Float = 0.05
    
    // Player health
    static let playerMaxHealth: Int = 3
    static let playerInvulnerabilityDuration: TimeInterval = 1.0
    
    // Enemy
    static let enemyHealth: Int = 1
    static let enemyScoreValue: Int = 10
    static let enemySpeed: Float = 1.0
    static let enemyDamage: Int = 1
    
    // Spawner
    static let enemySpawnInterval: TimeInterval = 2.0
    static let enemyMaxCount: Int = 3
    static let enemySpawnYOffset: Float = 0.1
    
    // Projectile
    static let projectileSpeed: Float = 2.0
    static let projectileDamage: Int = 1
    static let projectileLifetime: TimeInterval = 3.0
    static let projectileRadius: Float = 0.02
    static let projectileSpawnOffset: Float = 0.1
    static let projectileHeightOffsetFactor: Float = 0.1
    
    // Auto-shoot
    static let autoShootInterval: TimeInterval = 0.1
    static let autoShootWhileMoving: Bool = true
    
    // Camera
    static let cameraFOV: Float = 35.0
    static let cameraIsometricOffset: SIMD3<Float> = [1, 2, 1]
    static let cameraSmoothing: Float = 0.05
    
    // Isometric movement mapping
    static let isometricDiagonal: Float = 0.707

    // Entity names (for easy adjustment)
    struct EntityNames {
        static let scene = "Scene"
        static let capsule = "Capsule"
        static let cube = "Cube"
        static let enemyCapsule = "EnemyCapsule"
    }
}
