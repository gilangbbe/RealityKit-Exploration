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
    
    // New upgrade choice system
    @State private var showUpgradeChoice = false
    @State private var upgradeChoices: [PlayerUpgradeType] = []
    
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
                    .ignoresSafeArea(.all)
                    
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
            
            // Upgrade Choice Overlay
            if showUpgradeChoice {
                UpgradeChoiceView(
                    upgradeChoices: upgradeChoices,
                    currentWave: currentWave,
                    onChoiceMade: handleUpgradeChoice
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
        .onReceive(NotificationCenter.default.publisher(for: .showUpgradeChoice)) { notification in
            if let choices = notification.object as? [PlayerUpgradeType] {
                upgradeChoices = choices
                showUpgradeChoice = true
                // Pause game while choosing upgrade
                GameConfig.isGamePaused = true
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
        showUpgradeChoice = false // Clear any upgrade choice overlay
        // Clear all game data
        score = 0
        enemiesDefeated = 0
        currentWave = 1
        activePowerUp = nil
        playerUpgrade = nil
        // Generate new key to ensure clean state
        gameKey = UUID()
    }
    
    private func handleUpgradeChoice(_ chosenUpgrade: PlayerUpgradeType) {
        showUpgradeChoice = false
        GameConfig.isGamePaused = false
        
        // Apply the chosen upgrade to the player
        guard var progression = capsuleEntity.components[PlayerProgressionComponent.self] else { return }
        progression.applyChosenUpgrade(chosenUpgrade)
        capsuleEntity.components[PlayerProgressionComponent.self] = progression
        
        // Show upgrade notification
        playerUpgrade = chosenUpgrade.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            playerUpgrade = nil
        }
        
        print("Player upgraded: \(chosenUpgrade.name)")
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
        PlayerAnimationSystem.registerSystem()
        
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
        
        // Initialize player animation component
        let animationComponent = PlayerAnimationComponent()
        entity.components.set(animationComponent)
        
        // Debug: List available animations in the entity hierarchy
        print("Player root entity name: \(entity.name ?? "unnamed")")
        let rootAnimations = entity.availableAnimations.map { $0.name ?? "unnamed" }
        print("Player root available animations: \(rootAnimations)")
        
        // Check child entities for animations
        for child in entity.children {
            let childAnimations = child.availableAnimations.map { $0.name ?? "unnamed" }
            print("Child entity '\(child.name ?? "unnamed")' available animations: \(childAnimations)")
        }
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
        
        // Check if player is immobilized (during shockwave)
        if let animationComp = capsuleEntity.components[PlayerAnimationComponent.self],
           animationComp.isImmobilized {
            return // Player cannot move during shockwave animation
        }
        
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        let progression = capsuleEntity.components[PlayerProgressionComponent.self]
        
        let forceMultiplier = progression?.forceMultiplier ?? 1.0
        
        physics.velocity += direction.velocity * GameConfig.playerSpeed * forceMultiplier * 0.15
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
        
        // Handle character orientation based on movement direction
        if length(direction.velocity) > GameConfig.minMovementForRotation { // Only rotate if there's significant movement
            rotateCharacterToDirection(direction: direction.velocity)
        }
    }
    
    private func stopApplyingForce() {
        // Don't apply force if game is paused
        if GameConfig.isGamePaused { return }
        
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        
        // Apply friction to stop player movement
        physics.velocity *= GameConfig.frictionCoefficient
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
    
    private func applyAnalogForce(analogVector: SIMD2<Float>) {
        // Don't apply force if game is paused
        if GameConfig.isGamePaused { return }
        
        // Check if player is immobilized (during shockwave)
        if let animationComp = capsuleEntity.components[PlayerAnimationComponent.self],
           animationComp.isImmobilized {
            return // Player cannot move during shockwave animation
        }
        
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        let progression = capsuleEntity.components[PlayerProgressionComponent.self]
        
        let forceMultiplier = progression?.forceMultiplier ?? 1.0
        
        let isoX = (analogVector.x - analogVector.y) * GameConfig.isometricDiagonal
        let isoZ = -(analogVector.x + analogVector.y) * GameConfig.isometricDiagonal
        let force = SIMD3<Float>(isoX, 0, isoZ) * GameConfig.playerSpeed * forceMultiplier * 0.15
        physics.velocity += force
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
        
        // Handle character orientation based on movement direction
        if length(analogVector) > GameConfig.minMovementForRotation { // Only rotate if there's significant movement
            let movementDirection = SIMD3<Float>(isoX, 0, isoZ)
            rotateCharacterToDirection(direction: normalize(movementDirection))
        }
    }
    
    // Helper function to rotate character based on movement direction
    private func rotateCharacterToDirection(direction: SIMD3<Float>) {
        // Calculate the target rotation angle based on movement direction
        let targetAngle = atan2(direction.x, direction.z)
        
        // Create rotation quaternion around Y-axis (up vector)
        let targetRotation = simd_quatf(angle: targetAngle, axis: SIMD3<Float>(0, 1, 0))
        
        // Apply smooth rotation interpolation for natural character turning
        let currentRotation = capsuleEntity.orientation
        let smoothingFactor = GameConfig.characterRotationSmoothness
        
        let interpolatedRotation = simd_slerp(currentRotation, targetRotation, smoothingFactor)
        capsuleEntity.orientation = interpolatedRotation
    }
}

#Preview {
    ContentView()
}
