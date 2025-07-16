import simd
import Foundation

struct GameConfig {
    // Player movement
  static let playerSpeed: Float = 0.3
    static let playerSurfaceOffsetMargin: Float = 0.05
    static let playerMass: Float = 3.0
  static let playerPushForceMultiplier: Float = 0.5 // Player pushes harder
  static let playerResistance: Float = 3 // Player resists being pushed
    
    // Enemy
  static let enemySpeed: Float = 0.3
    static let enemyMass: Float = 1
    static let enemyScoreValue: Int = 100
    static let enemyPushForceMultiplier: Float = 0.3 // Enemies push weaker
    
    // Physics & Collision
    static let collisionForceMultiplier: Float = 8.0 // Increased for more dramatic pushes
    static let frictionCoefficient: Float = 0.92 // Slightly less friction for better sliding
    static let bounceForceMultiplier: Float = 3.0 // Increased bounce force
    static let gravityStrength: Float = 9.8 // Gravity acceleration when off platform
    
    // Arena boundaries
    static let arenaFallThreshold: Float = -2.0 // Y position below which entities are considered "fallen"
    static let arenaEdgeBuffer: Float = 0.05 // Very tight threshold for edge detection
    static let arenaFallHeightThreshold: Float = 0.3 // Height below arena surface before considering fallen
    
    // Spawner
    static let enemySpawnInterval: TimeInterval = 1.5
    static let enemyMaxCount: Int = 10
    static let enemySpawnYOffset: Float = 0.1
    
    // Wave System
    static let baseEnemiesPerWave: Int = 2
    static let enemyHealthIncreasePerWave: Int = 1
    static let enemySpeedIncreasePerWave: Float = 0.15
    static let enemyMassIncreasePerWave: Float = 0.1
    static let enemyCountIncreasePerWave: Int = 1
    static let waveClearDelay: TimeInterval = 3.0
    static let waveScoreMultiplier: Int = 50 // Bonus points per wave completed
    
    // Camera
    static let cameraFOV: Float = 35.0
    static let cameraIsometricOffset: SIMD3<Float> = [1, 2, 1]
    static let cameraSmoothing: Float = 0.05
    
    // Isometric movement mapping
    static let isometricDiagonal: Float = 0.707
    
    // LootBox System
    static let lootBoxSpawnInterval: TimeInterval = 3.0 // Spawn loot box every 8 seconds
    static let lootBoxCollectionRadius: Float = 0.1 // Distance to collect loot box
    static let lootBoxLifetime: TimeInterval = 15.0 // How long loot box stays before disappearing
    
    // Power-ups
    static let timeSlowDuration: TimeInterval = 3.0 // Time slow effect duration
    static let timeSlowMultiplier: Float = 0.3 // Enemy speed multiplier during time slow
    static let shockwaveForce: Float = 15.0 // Force applied to enemies during shockwave
    static let shockwaveRadius: Float = 3.0 // Radius of shockwave effect

    // Entity names (for easy adjustment)
    struct EntityNames {
        static let scene = "Scene"
        static let capsule = "Capsule"
        static let cube = "Cube"
        static let enemyCapsule = "EnemyCapsule"
        static let lootBox = "LootBox"
    }
}
