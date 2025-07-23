import simd
import Foundation

struct GameConfig {
     // Character animations
    static let walkAnimationName: String = "player_walk"
    static let walkAnimationIndex: Int = 5 // Row 6 in animation library (0-based index)
    static let attackAnimationIndices: [Int] = [0, 1, 2, 3] // Attack animations at indices 1-4
    static let shockwaveAnimationIndex: Int = 4 // Shockwave animation at index 4
  static let attackAnimationDuration: TimeInterval = 0.5 // How long attack animation plays
    static let shockwaveAnimationDuration: TimeInterval = 1 // How long shockwave animation plays
    static let minMovementForWalkAnimation: Float = 0.02 // Minimum movement threshold to trigger walk animation
    static let playerChildEntityName: String = "player" // Child entity containing animations
    
    // Enemy animations
    static let enemyWalkAnimationIndex: Int = 0 // Enemy walking animation at index 0
    static let minEnemyMovementForWalkAnimation: Float = 0.01 // Enemy movement threshold for walk animation
    
    // LootBox animations
    static let lootBoxAnimationIndex: Int = 0 // LootBox animation at index 0
    static let lootBoxChildEntityName: String = "powerupBlock" // Child entity containing LootBox animations
    
    // Game State
    static var isGamePaused: Bool = false
    
    // Wave System
    static let baseEnemiesPerWave: Int = 5
    static let enemyHealthIncreasePerWave: Int = 1
    static let enemySpeedIncreasePerWave: Float = 0.1
    static let enemyMassIncreasePerWave: Float = 0.1
    static let enemyCountIncreasePerWave: Int = 1
    static let waveClearDelay: TimeInterval = 3.0
    static let waveScoreMultiplier: Int = 50 // Bonus points per wave completed
    
    // Wave progression limits
    static let maxWaveForSpeedIncrease: Int = 5 // After wave 4, no more speed/mass increases
    static let maxWaveForMassIncrease: Int = 5 // After wave 4, no more speed/mass increases
    
    // Balanced progression system
    static let playerUpgradeChoicesPerWave: Int = 3 // Player chooses from 3 options
    static let playerUpgradeBaseValue: Float = 0.15 // Smaller, more balanced upgrades
    static let playerUpgradeDiminishingFactor: Float = 0.95 // Slower diminishing than before
    
    // Enemy scaling to match player progression
    static let enemyScalingPerWave: Float = 0.15 // Enemies get 15% stronger each wave (was 0.1)
    static let enemyMaxScalingWaves: Int = 15 // After wave 15, enemies cap out (was 10)
    static let enemyForceScalingPerWave: Float = 0.2 // Enemy push force scales 20% per wave
    
    // Diminishing returns for other systems
    static let enemyCountDiminishingFactor: Float = 0.8 // Each wave enemy count increase gets 20% smaller
    static let waveScoreDiminishingFactor: Float = 0.9 // Each wave score bonus gets 10% smaller
    static let maxEnemiesDiminishingFactor: Float = 0.85 // Each wave max enemies increase gets 15% smaller
    
    // Player progression per wave (balanced values)
    static let playerSpeedIncrease: Float = 0.15 // Moderate speed boost
    static let playerMassIncrease: Float = 0.25 // Reasonable mass boost (was 0.5)
    static let playerForceIncrease: Float = 0.2 // Balanced force boost
  
    // Player movement
    static let playerSpeed: Float = 0.3
    static let playerSurfaceOffsetMargin: Float = 0.05
    static let playerMass: Float = 3.0
    static let playerPushForceMultiplier: Float = 0.5 // Player pushes harder
    static let playerResistance: Float = 3 // Player resists being pushed
    
    // Character orientation
    static let characterRotationSmoothness: Float = 0.15 // How smoothly character rotates (0.1 = slow, 0.3 = fast)
    static let minMovementForRotation: Float = 0.01 // Minimum movement threshold to trigger rotation
    static let instantCollisionOrientation: Bool = true // Player immediately faces enemy on collision (true) or smooth rotation (false)
    
  static let enemySpeed: Float = 0.3
    static let enemyMass: Float = 1
    static let enemyScoreValue: Int = 100
    static let enemyPushForceMultiplier: Float = 0.5 // Enemies push harder (was 0.3)
    
    // Physics & Collision
    static let collisionForceMultiplier: Float = 8.0 // Increased for more dramatic pushes
    static let frictionCoefficient: Float = 0.92 // Slightly less friction for better sliding
    static let bounceForceMultiplier: Float = 3.0 // Increased bounce force
    static let gravityStrength: Float = 9.8 // Gravity acceleration when off platform
    
    // Collision detection
    static let playerCollisionRadius: Float = 0.1 // Player collision detection radius
    static let enemyCollisionRadius: Float = 0.1 // Enemy-enemy collision detection radius
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
  static let cameraIsometricOffset: SIMD3<Float> = [1, 2.5, 1]
    static let cameraSmoothing: Float = 0.05
    
    // Isometric movement mapping
    static let isometricDiagonal: Float = 0.707
    
    // LootBox System
    static let lootBoxSpawnInterval: TimeInterval = 5.0 // Spawn loot box every 8 seconds
    static let lootBoxCollectionRadius: Float = 0.1 // Distance to collect loot box
    static let lootBoxLifetime: TimeInterval = 15.0 // How long loot box stays before disappearing
    static let lootBoxMinSpawnDistance: Float = 1.0 // Minimum distance between LootBoxes to prevent overlap
    static let lootBoxMinPlayerDistance: Float = 0.8 // Minimum distance from player when spawning
    static let lootBoxSpawnAttempts: Int = 10 // Maximum attempts to find clear spawn position
    
    // Power-ups
    static let timeSlowDuration: TimeInterval = 3.0 // Time slow effect duration
    static let timeSlowMultiplier: Float = 0.3 // Enemy speed multiplier during time slow
    static let shockwaveForce: Float = 4.0 // Force applied to enemies during shockwave (balanced for 150cm arena)
    static let shockwaveRadius: Float = 0.8 // Radius of shockwave effect (80cm radius for 150cm arena)

    // Entity names (for easy adjustment)
    struct EntityNames {
        static let scene = "Scene"
        static let capsule = "player_root"
        static let cube = "Cube"
        static let enemyCapsule = "enemyPhase1" // Legacy - primary enemy
        static let lootBox = "LootBox"
        static let menuScene = "menuScene"
        
        // All enemy types
        static let enemyPhase1 = "enemyPhase1"
        static let enemyPhase2 = "enemyPhase2" 
        static let enemyPhase3 = "enemyPhase3"
        static let enemyPhase4 = "enemyPhase4"
        static let enemyPhase5 = "enemyPhase5"
    }
}
