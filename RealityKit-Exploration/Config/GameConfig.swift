import simd
import Foundation

struct GameConfig {
    // Game State
    static var isGamePaused: Bool = false
    
    // Wave System
    static let baseEnemiesPerWave: Int = 6
    static let enemyHealthIncreasePerWave: Int = 1
    static let enemySpeedIncreasePerWave: Float = 0.15
    static let enemyMassIncreasePerWave: Float = 0.1
    static let enemyCountIncreasePerWave: Int = 1
    static let waveClearDelay: TimeInterval = 3.0
    static let waveScoreMultiplier: Int = 50 // Bonus points per wave completed
    
    // Wave progression limits
    static let maxWaveForSpeedIncrease: Int = 8 // After wave 4, no more speed/mass increases
    static let maxWaveForMassIncrease: Int = 8 // After wave 4, no more speed/mass increases
    
    // Diminishing returns progression
    static let enemyCountDiminishingFactor: Float = 0.8 // Each wave enemy count increase gets 20% smaller
    static let playerUpgradeDiminishingFactor: Float = 0.85 // Each wave player upgrade gets 15% smaller
    static let waveScoreDiminishingFactor: Float = 0.9 // Each wave score bonus gets 10% smaller
    static let maxEnemiesDiminishingFactor: Float = 0.85 // Each wave max enemies increase gets 15% smaller
    
    // Player progression per wave (base values that will diminish)
    static let playerSpeedIncrease: Float = 0.1 // Speed boost per wave (starts higher for diminishing)
    static let playerMassIncrease: Float = 0.3 // Mass boost per wave (starts higher for diminishing)
    static let playerForceIncrease: Float = 0.15 // Force multiplier boost per wave (starts higher for diminishing)
  
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
    
    // Collision detection
    static let playerCollisionRadius: Float = 0.05 // Player collision detection radius
    static let enemyCollisionRadius: Float = 0.05 // Enemy-enemy collision detection radius
    static let enemySeparationForce: Float = 0.5 // Force multiplier for enemy separation
    
    // Arena boundaries
    static let arenaFallThreshold: Float = -1.0 // Y position below which entities are considered "fallen"
    static let arenaEdgeBuffer: Float = 0.05 // Very tight threshold for edge detection
    static let arenaFallHeightThreshold: Float = 0.1 // Height below arena surface before considering fallen
    
    // Spawner
    static let enemySpawnInterval: TimeInterval = 1.5
    static let enemyMaxCount: Int = 10 // Base max enemies for wave 1
    static let enemyMaxCountIncreasePerWave: Int = 2 // How many more enemies can spawn each wave
    static let enemySpawnYOffset: Float = 0.1
    
    // Camera
    static let cameraFOV: Float = 35.0
    static let cameraIsometricOffset: SIMD3<Float> = [1, 2, 1]
    static let cameraSmoothing: Float = 0.05
    
    // Isometric movement mapping
    static let isometricDiagonal: Float = 0.707
    
    // LootBox System
    static let lootBoxSpawnInterval: TimeInterval = 5.0 // Spawn loot box every 8 seconds
    static let lootBoxCollectionRadius: Float = 0.1 // Distance to collect loot box
    static let lootBoxLifetime: TimeInterval = 15.0 // How long loot box stays before disappearing
    
    // Power-ups
    static let timeSlowDuration: TimeInterval = 3.0 // Time slow effect duration
    static let timeSlowMultiplier: Float = 0.3 // Enemy speed multiplier during time slow
    static let shockwaveForce: Float = 5.0 // Force applied to enemies during shockwave
    static let shockwaveRadius: Float = 1.0 // Radius of shockwave effect

    // Entity names (for easy adjustment)
    struct EntityNames {
        static let scene = "Scene"
        static let capsule = "Max"
        static let cube = "Cube"
        static let enemyCapsule = "enemy_chasing"
        static let lootBox = "LootBox"
    }
}
