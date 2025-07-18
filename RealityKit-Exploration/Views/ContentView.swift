import SwiftUI
import RealityKit
import Arena

struct ContentView: View {
    @State private var gameState: GameState = .mainMenu
    @State private var capsuleEntity = Entity()
    @State private var cubeEntity = Entity()
    @State private var redCapsuleEntity = Entity()
    @State private var lootBoxEntity = Entity()
    @State private var lootBoxContainerEntity = Entity()
    @State private var spawnerEntity = Entity()
    @State private var lootBoxSpawnerEntity = Entity()
    @State private var score = 0
    @State private var enemiesDefeated = 0
    @State private var currentWave = 1
    @State private var activePowerUp: String? = nil
    @State private var playerUpgrade: String? = nil
    @State private var gameKey = UUID() // For restarting the game
    
    var body: some View {
        ZStack {
            // Main Menu
            if gameState == .mainMenu {
                MainMenuView {
                    startNewGame()
                }
            }
            
            // Game View (only rendered when playing or paused)
            if gameState == .playing || gameState == .paused {
                ZStack {
                    RealityView { content in
                        await setupGame(content: content)
                    } update: { content in }
                    .id(gameKey) // This will recreate the RealityView when gameKey changes
                    
                    // Game UI Overlay (only visible when playing)
                    if gameState == .playing {
                        VStack {
                            HStack {
                                ScoreView(score: score, enemiesDefeated: enemiesDefeated, currentWave: currentWave)
                                
                                Spacer()
                                
                                // Pause Button
                                Button(action: pauseGame) {
                                    Image(systemName: "pause.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(10)
                                }
                                
                                if let powerUp = activePowerUp {
                                    PowerUpIndicator(powerUpName: powerUp)
                                }
                                if let upgrade = playerUpgrade {
                                    PlayerUpgradeIndicator(upgradeName: upgrade)
                                }
                            }
                            
                            // Optional: Add progression debug view (remove for production)
                            if currentWave > 1 {
                                HStack {
                                    ProgressionDebugView(currentWave: currentWave)
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        // Controls (only visible when playing)
                        ControlsView { direction in
                            startApplyingForce(direction: direction)
                        } stopApplyingForce: {
                            stopApplyingForce()
                        } applyAnalogForce: { analogVector in
                            applyAnalogForce(analogVector: analogVector)
                        }
                    }
                }
            }
            
            // Pause Menu Overlay
            if gameState == .paused {
                PauseMenuView(
                    onResume: resumeGame,
                    onMainMenu: returnToMainMenu,
                    currentScore: score,
                    currentWave: currentWave
                )
            }
            
            // Game Over Overlay
            if gameState == .gameOver {
                GameOverView(
                    finalScore: score,
                    enemiesDefeated: enemiesDefeated,
                    wavesCompleted: max(1, currentWave - 1),
                    onReplay: startNewGame,
                    onMainMenu: returnToMainMenu
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerFell)) { _ in
            if gameState == .playing {
                gameOver()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .scoreChanged)) { notification in
            if let newScore = notification.object as? Int {
                score = newScore
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .enemyDefeated)) { notification in
            if let _ = notification.object as? Int {
                enemiesDefeated += 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waveStarted)) { notification in
            if let wave = notification.object as? Int {
                currentWave = wave
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waveBonus)) { notification in
            if let bonusPoints = notification.object as? Int {
                score += bonusPoints
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .powerUpCollected)) { notification in
            if let powerUpName = notification.object as? String {
                activePowerUp = powerUpName
                // Clear power-up indicator after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    activePowerUp = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerUpgraded)) { notification in
            if let upgradeType = notification.object as? PlayerUpgradeType {
                playerUpgrade = upgradeType.name
                // Clear upgrade indicator after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    playerUpgrade = nil
                }
            }
        }
    }
    
    // MARK: - Game State Management
    
    private func startNewGame() {
        score = 0
        enemiesDefeated = 0
        currentWave = 1
        activePowerUp = nil
        playerUpgrade = nil
        gameKey = UUID() // This will trigger a complete recreation of the RealityView
        GameConfig.isGamePaused = false
        gameState = .playing
    }
    
    private func pauseGame() {
        gameState = .paused
        GameConfig.isGamePaused = true
    }
    
    private func resumeGame() {
        gameState = .playing
        GameConfig.isGamePaused = false
    }
    
    private func gameOver() {
        gameState = .gameOver
        // Game is now stopped, no systems are running in background
    }
    
    private func returnToMainMenu() {
        gameState = .mainMenu
        GameConfig.isGamePaused = false
        // Clear all game data
        score = 0
        enemiesDefeated = 0
        currentWave = 1
        activePowerUp = nil
        playerUpgrade = nil
        // Generate new key to ensure clean state
        gameKey = UUID()
    }
    
    private func setupGame(content: RealityViewCameraContent) async {
        guard let loadedScene = try? await Entity(named: GameConfig.EntityNames.scene, in: arenaBundle) else { return }
        guard let capsule = loadedScene.findEntity(named: GameConfig.EntityNames.capsule),
              let cube = loadedScene.findEntity(named: GameConfig.EntityNames.cube) else { return }
        let redCapsule = loadedScene.findEntity(named: GameConfig.EntityNames.enemyCapsule)
        let lootBox = loadedScene.findEntity(named: GameConfig.EntityNames.lootBox)
        
        capsuleEntity = capsule
        cubeEntity = cube
        
        setupPlayerPhysics(for: capsule, constrainedTo: cube)
        setupPlayerGameState(for: capsule)
        setupWaveSystem(for: capsule)
        
        if let redCapsule = redCapsule {
            redCapsuleEntity = redCapsule
            redCapsule.removeFromParent()
            setupSpawner(surface: cube, enemyPrefab: redCapsule)
        }
        
        if let lootBox = lootBox {
            lootBoxEntity = lootBox
            lootBox.removeFromParent()
            
            // Create a dedicated container for LootBoxes to prevent camera issues
            lootBoxContainerEntity = Entity()
            lootBoxContainerEntity.name = "LootBoxContainer"
            
            // Position the container at the scene origin to avoid affecting camera bounds
            lootBoxContainerEntity.position = SIMD3<Float>(0, 0, 0)
            
            setupLootBoxSpawner(surface: cube, lootBoxPrefab: lootBox, container: lootBoxContainerEntity)
        }
        
        let camera = setupIsometricCamera(target: capsule)
        
        // Register all systems
        PhysicsMovementSystem.registerSystem()
        IsometricCameraSystem.registerSystem()
        SpawnerSystem.registerSystem()
        EnemyCapsuleSystem.registerSystem()
        GameManagementSystem.registerSystem()
        WaveSystem.registerSystem()
        LootBoxSystem.registerSystem()
        PlayerProgressionSystem.registerSystem()
        
        content.add(loadedScene)
        content.add(camera)
        content.add(spawnerEntity)
        content.add(lootBoxSpawnerEntity)
        content.add(lootBoxContainerEntity)
    }
    
    private func setupWaveSystem(for entity: Entity) {
        var waveComponent = WaveComponent()
        waveComponent.baseEnemySpeed = GameConfig.enemySpeed
        waveComponent.baseEnemyMass = GameConfig.enemyMass
        waveComponent.enemiesPerWave = GameConfig.baseEnemiesPerWave
        waveComponent.enemySpeedIncrease = GameConfig.enemySpeedIncreasePerWave
        waveComponent.enemyMassIncrease = GameConfig.enemyMassIncreasePerWave
        waveComponent.enemyCountIncrease = GameConfig.enemyCountIncreasePerWave
        waveComponent.waveClearDelay = GameConfig.waveClearDelay
        entity.components.set(waveComponent)
    }
    
    private func setupPlayerGameState(for entity: Entity) {
        let gameStateComponent = GameStateComponent()
        entity.components.set(gameStateComponent)
        
        // Initialize power-up component for the player
        let powerUpComponent = PowerUpComponent()
        entity.components.set(powerUpComponent)
        
        // Initialize player progression component
        let progressionComponent = PlayerProgressionComponent()
        entity.components.set(progressionComponent)
    }
    
    private func setupPlayerPhysics(for entity: Entity, constrainedTo cube: Entity) {
        let capsuleBounds = entity.visualBounds(relativeTo: nil)
        let capsuleHeight = capsuleBounds.max.y - capsuleBounds.min.y
        let surfaceOffset = capsuleHeight / 2.0 + GameConfig.playerSurfaceOffsetMargin
        
        var physicsComponent = PhysicsMovementComponent()
        physicsComponent.mass = GameConfig.playerMass
        physicsComponent.friction = GameConfig.frictionCoefficient
        physicsComponent.constrainedTo = cube
        physicsComponent.groundLevel = surfaceOffset
        entity.components.set(physicsComponent)
        
        let cubeTopY = cube.position.y + (cube.scale.y / 2.0)
        entity.position.y = cubeTopY + surfaceOffset
    }
    private func setupSpawner(surface: Entity, enemyPrefab: Entity) {
        spawnerEntity = Entity()
        var spawnerComponent = SpawnerComponent()
        spawnerComponent.spawnSurface = surface
        spawnerComponent.enemyPrefab = enemyPrefab
        spawnerComponent.spawnInterval = GameConfig.enemySpawnInterval
        spawnerComponent.maxEnemies = GameConfig.enemyMaxCount // This will be dynamically calculated per wave
        spawnerEntity.components.set(spawnerComponent)
    }
    private func setupLootBoxSpawner(surface: Entity, lootBoxPrefab: Entity, container: Entity) {
        lootBoxSpawnerEntity = Entity()
        var lootBoxSpawnerComponent = LootBoxSpawnerComponent()
        lootBoxSpawnerComponent.spawnSurface = surface
        lootBoxSpawnerComponent.lootBoxPrefab = lootBoxPrefab
        lootBoxSpawnerComponent.lootBoxContainer = container
        lootBoxSpawnerComponent.spawnInterval = GameConfig.lootBoxSpawnInterval
        lootBoxSpawnerEntity.components.set(lootBoxSpawnerComponent)
    }
    private func setupIsometricCamera(target: Entity) -> Entity {
        let camera = Entity()
        var cameraComponent = PerspectiveCameraComponent()
        cameraComponent.fieldOfViewInDegrees = GameConfig.cameraFOV
        camera.components.set(cameraComponent)
        var isometricComponent = IsometricCameraComponent()
        isometricComponent.target = target
        isometricComponent.offset = GameConfig.cameraIsometricOffset
        isometricComponent.smoothing = GameConfig.cameraSmoothing
        isometricComponent.lookAtTarget = true
        camera.components.set(isometricComponent)
        let initialPosition = target.position + isometricComponent.offset
        camera.position = initialPosition
        camera.look(at: target.position, from: initialPosition, relativeTo: nil)
        return camera
    }
    private func startApplyingForce(direction: ForceDirection) {
        // Don't apply force if game is paused
        if GameConfig.isGamePaused { return }
        
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        let progression = capsuleEntity.components[PlayerProgressionComponent.self]
        
        let speedMultiplier = progression?.speedMultiplier ?? 1.0
        let forceMultiplier = progression?.forceMultiplier ?? 1.0
        
        physics.velocity += direction.velocity * GameConfig.playerSpeed * speedMultiplier * forceMultiplier * 0.15
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
    
    private func stopApplyingForce() {
        // Don't apply force if game is paused
        if GameConfig.isGamePaused { return }
        
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        physics.velocity *= 0.9 // Better control when stopping
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
    
    private func applyAnalogForce(analogVector: SIMD2<Float>) {
        // Don't apply force if game is paused
        if GameConfig.isGamePaused { return }
        
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        let progression = capsuleEntity.components[PlayerProgressionComponent.self]
        
        let speedMultiplier = progression?.speedMultiplier ?? 1.0
        let forceMultiplier = progression?.forceMultiplier ?? 1.0
        
        let isoX = (analogVector.x - analogVector.y) * GameConfig.isometricDiagonal
        let isoZ = -(analogVector.x + analogVector.y) * GameConfig.isometricDiagonal
        let force = SIMD3<Float>(isoX, 0, isoZ) * GameConfig.playerSpeed * speedMultiplier * forceMultiplier * 0.15
        physics.velocity += force
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
}

#Preview {
    ContentView()
}
