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
    
    // Enemy falling animations
    static let enemyFallSpeed: Float = 2.0 // How fast enemies fall when out of bounds
    static let enemyFallRotationSpeed: Float = 3.0 // Rotation speed during fall (radians per second)
    static let enemyFallDuration: Float = 2.0 // How long the falling animation lasts
    
    // LootBox animations
    static let lootBoxAnimationIndex: Int = 0 // LootBox animation at index 0
    static let lootBoxChildEntityName: String = "powerupBlock" // Child entity containing LootBox animations
    
    // Game State
    static var isGamePaused: Bool = false
    
    // Wave System (rebalanced for hyper-casual 5-minute sessions)
    static let baseEnemiesPerWave: Int = 4 // Reduced from 5 to 4 for quicker waves
    static let enemyHealthIncreasePerWave: Int = 1
    static let enemySpeedIncreasePerWave: Float = 0.08 // Reduced from 0.1 for gentler progression
    static let enemyMassIncreasePerWave: Float = 0.08 // Reduced from 0.1 for balance
    static let enemyCountIncreasePerWave: Int = 1
    static let waveClearDelay: TimeInterval = 2.5 // Reduced from 3.0 for faster pacing
    static let waveScoreMultiplier: Int = 60 // Increased from 50 for better reward feedback
    
    // Wave progression limits
    static let maxWaveForSpeedIncrease: Int = 5 // After wave 4, no more speed/mass increases
    static let maxWaveForMassIncrease: Int = 5 // After wave 4, no more speed/mass increases
    
    // Balanced progression system (tuned for 5-minute hyper-casual gameplay)
    static let playerUpgradeChoicesPerWave: Int = 3 // Player chooses from 3 options
    static let playerUpgradeBaseValue: Float = 0.12 // Reduced from 0.15 for gentler progression
    static let playerUpgradeDiminishingFactor: Float = 0.85 // Stronger diminishing from 0.95 to 0.85
    
    // Enemy scaling to match player progression (tuned for hyper-casual)
    static let enemyScalingPerWave: Float = 0.12 // Reduced from 0.15 to 0.12 (12% per wave)
    static let enemyMaxScalingWaves: Int = 12 // Reduced from 15 to 12 for 5-minute sessions
    static let enemyForceScalingPerWave: Float = 0.15 // Reduced from 0.2 to 0.15 (15% per wave)
    
    // Diminishing returns for other systems (tuned for hyper-casual gameplay)
    static let enemyCountDiminishingFactor: Float = 0.75 // Stronger diminishing from 0.8 to 0.75
    static let waveScoreDiminishingFactor: Float = 0.88 // Slightly stronger from 0.9 to 0.88
    static let maxEnemiesDiminishingFactor: Float = 0.8 // Slightly stronger from 0.85 to 0.8
    
    // Player progression per wave (rebalanced for hyper-casual)
    static let playerSpeedIncrease: Float = 0.12 // Reduced from 0.15 for gentler scaling
    static let playerSpeedUpgradeValue: Float = 0.18 // Speed upgrade gives 18% per level (balanced with enemy progression)
    static let playerMassIncrease: Float = 0.20 // Reduced from 0.25 for balance
    static let playerForceIncrease: Float = 0.15 // Reduced from 0.2 for better balance
  
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
    
    // Spawner (dynamic wave-based spawning for hyper-casual gameplay)
    // Wave-based spawn intervals: Wave 1: 1.3s, Wave 2: 1.19s, Wave 3: 1.10s, Wave 4: 1.02s, Wave 5+: 0.6s min
    static let enemySpawnInterval: TimeInterval = 1.3 // Base spawn interval for wave 1
    static let enemySpawnIntervalReduction: Float = 0.08 // Reduce interval by 8% per wave (aggressive for hyper-casual)
    static let enemyMinSpawnInterval: TimeInterval = 0.6 // Minimum spawn interval (fastest spawning)
    static let enemyMaxCount: Int = 8 // Base max enemies for wave 1
    static let enemyMaxCountIncreasePerWave: Int = 1 // Reduced from 2 for gentler scaling
    static let enemySpawnYOffset: Float = 0.1
    
    // Burst spawning system (spawn multiple enemies at once in later waves)
    // Waves 1-3: Single spawns, Wave 4+: 40% chance for 2-3 enemy bursts
    static let burstSpawningStartWave: Int = 4 // Start burst spawning from wave 4
    static let maxEnemiesPerBurst: Int = 3 // Maximum enemies to spawn in one burst
    static let burstSpawningChance: Float = 0.4 // 40% chance for burst spawn in later waves
    
    // Camera
    static let cameraFOV: Float = 35.0
  static let cameraIsometricOffset: SIMD3<Float> = [1.5, 2.5, 1.5]
    static let cameraSmoothing: Float = 0.05
    
    // Isometric movement mapping
    static let isometricDiagonal: Float = 0.707
    
    // LootBox System (adjusted for faster hyper-casual pacing)
    static let lootBoxSpawnInterval: TimeInterval = 4.0 // Reduced from 5.0 for more frequent power-ups
    static let lootBoxCollectionRadius: Float = 0.1 // Distance to collect loot box
    static let lootBoxLifetime: TimeInterval = 12.0 // Reduced from 15.0 for faster turnover
    static let lootBoxMinSpawnDistance: Float = 0.8 // Reduced from 1.0 for 150cm arena
    static let lootBoxMinPlayerDistance: Float = 0.6 // Reduced from 0.8 for 150cm arena
    static let lootBoxSpawnAttempts: Int = 8 // Reduced from 10 for faster processing
    
    // Power-ups (optimized for 150cm arena and hyper-casual gameplay)
    static let timeSlowDuration: TimeInterval = 2.5 // Reduced from 3.0 for faster pacing
    static let timeSlowMultiplier: Float = 0.35 // Slightly less effective (was 0.3) for balance
    static let shockwaveForce: Float = 3.5 // Reduced from 4.0 for 150cm arena balance
    static let shockwaveRadius: Float = 0.7 // Reduced from 0.8 (70cm radius for 150cm arena)

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
