import SwiftUI
import RealityKit
import Arena
import AVFoundation

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
    
    // Game session tracking
    @State private var gameStartTime: Date = Date()
    @StateObject private var scoreManager = ScoreManager()
    
    // Time slow tracking
    @State private var timeSlowEndTime: TimeInterval = 0
    @State private var timeSlowDuration: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    
    // Timer for updating current time
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // New upgrade choice system
    @State private var showUpgradeChoice = false
    @State private var upgradeChoices: [PlayerUpgradeType] = []
    
    // Progression tracking
    @State private var showProgressionOverlay = false
    @State private var playerProgression = PlayerProgressionComponent()
    
    // Leaderboard
    @State private var showLeaderboard = false
    
    // GameOver
    @State private var lastGameSnapshot: UIImage? = nil
    
    // Audio players
    @State private var timeSlowAudioPlayer: AVAudioPlayer?
    @State private var shockwaveAudioPlayer: AVAudioPlayer?
    @State private var punchAudioPlayers: [AVAudioPlayer] = []
    @State private var timeSlowStopTask: DispatchWorkItem?
    
    // Collision sound management
    @State private var lastPunchSoundTime: TimeInterval = 0
    private let punchSoundCooldown: TimeInterval = GameConfig.punchSoundCooldown
    
    
    var body: some View {
        ZStack {
            // Main Menu and Leaderboard
            if gameState == .mainMenu {
                MainMenuContainerView(
                    showLeaderboard: showLeaderboard,
                    scoreManager: scoreManager,
                    onStartGame: startNewGame,
                    onShowLeaderboard: { showLeaderboard = true },
                    onHideLeaderboard: { showLeaderboard = false }
                )
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
                        ZStack {
                            // Full-screen controls - tap anywhere to show joystick
                            ControlsView { direction in
                                startApplyingForce(direction: direction)
                            } stopApplyingForce: {
                                stopApplyingForce()
                            } applyAnalogForce: { analogVector in
                                applyAnalogForce(analogVector: analogVector)
                            }
                            
                            // UI overlays on top of controls
                            GameOverlayView(
                                score: score,
                                enemiesDefeated: enemiesDefeated,
                                currentWave: currentWave,
                                gameState: gameState,
                                playerProgression: playerProgression,
                                activePowerUp: activePowerUp,
                                playerUpgrade: playerUpgrade,
                                timeSlowEndTime: timeSlowEndTime,
                                timeSlowDuration: timeSlowDuration,
                                currentTime: currentTime,
                                onPauseGame: pauseGame,
                                onShowProgression: {
                                    showProgressionOverlay = true
                                    if gameState == .playing {
                                        GameConfig.isGamePaused = true
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            // All Modal Overlays (pause, game over, upgrade choice, progression)
            GameModalOverlaysView(
                gameState: gameState,
                showUpgradeChoice: showUpgradeChoice,
                showProgressionOverlay: showProgressionOverlay,
                score: score,
                enemiesDefeated: enemiesDefeated,
                currentWave: currentWave,
                upgradeChoices: upgradeChoices,
                playerProgression: playerProgression,
                lastSnapShot: lastGameSnapshot,
                onResume: resumeGame,
                onMainMenu: returnToMainMenu,
                onReplay: startNewGame,
                onUpgradeChoice: handleUpgradeChoice,
                onCloseProgression: {
                    showProgressionOverlay = false
                    if gameState == .playing {
                        GameConfig.isGamePaused = false
                    }
                }
            )
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
                
                // Play appropriate sound for the power-up
                if powerUpName == "Shockwave" {
                    playShockwaveSound()
                }
                
                // If it's time slow, set up fallback indicator if notification system doesn't work
                if powerUpName == "Time Slow" {
                    // Use a delay to allow the proper notification to arrive first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Only set up manual indicator if the notification system didn't work
                        if timeSlowEndTime <= Date().timeIntervalSince1970 {
                            let progression = capsuleEntity.components[PlayerProgressionComponent.self]
                            let actualDuration = progression?.currentSlowDuration ?? TimeInterval(GameConfig.timeSlowDuration)
                            
                            timeSlowEndTime = Date().timeIntervalSince1970 + actualDuration
                            timeSlowDuration = actualDuration
                        }
                    }
                }
                
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
                
                // Sync current progression state
                if let progression = capsuleEntity.components[PlayerProgressionComponent.self] {
                    playerProgression = progression
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeSlowActivated)) { notification in
            if let timeSlowInfo = notification.object as? [String: Any],
               let endTime = timeSlowInfo["endTime"] as? TimeInterval,
               let duration = timeSlowInfo["duration"] as? TimeInterval {
                timeSlowEndTime = endTime
                timeSlowDuration = duration
                
                // Play time slow sound with appropriate duration
                playTimeSlowSound(duration: duration)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerEnemyCollision)) { _ in
            playRandomPunchSoundWithCooldown()
        }
        .onReceive(timer) { _ in
            // Update current time for time slow indicator
            if gameState == .playing {
                currentTime = Date().timeIntervalSince1970
            }
        }
        .onKeyPress(.tab) {
            if gameState == .playing && !showUpgradeChoice {
                showProgressionOverlay.toggle()
                if showProgressionOverlay {
                    GameConfig.isGamePaused = true
                } else {
                    GameConfig.isGamePaused = false
                }
                return .handled
            }
            return .ignored
        }
    }
    
    // MARK: - Game State Management
    
    private func startNewGame() {
        score = 0
        enemiesDefeated = 0
        currentWave = 1
        activePowerUp = nil
        playerUpgrade = nil
        playerProgression = PlayerProgressionComponent() // Reset progression
        
        // Reset time slow state
        timeSlowEndTime = 0
        timeSlowDuration = 0
        currentTime = Date().timeIntervalSince1970
        
        // Reset collision sound cooldown
        lastPunchSoundTime = 0
        
        // Setup audio
        setupAudio()
        
        // Track game start time
        gameStartTime = Date()
        
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
        captureGameSnapshot()
        
        // Stop any playing audio
        stopAllSounds()
        
        // Calculate game duration
        let gameDuration = Date().timeIntervalSince(gameStartTime)
        
        // Save the score
        scoreManager.addScore(
            score: self.score,
            enemiesDefeated: self.enemiesDefeated,
            wavesCompleted: max(1, self.currentWave - 1),
            duration: gameDuration
        )
            
        gameState = .gameOver
    }
    
    
    private func returnToMainMenu() {
        // Save current score only if game was in progress (not if coming from game over)
        if gameState == .playing {
            let gameDuration = Date().timeIntervalSince(gameStartTime)
            scoreManager.addScore(
                score: score,
                enemiesDefeated: enemiesDefeated,
                wavesCompleted: max(1, currentWave - 1),
                duration: gameDuration
            )
        }
        
        // Stop any playing audio
        stopAllSounds()
        
        gameState = .mainMenu
        GameConfig.isGamePaused = true // Keep game paused when returning to main menu to stop all systems
        showUpgradeChoice = false // Clear any upgrade choice overlay
        showProgressionOverlay = false // Clear progression overlay
        // Clear all game data
        score = 0
        enemiesDefeated = 0
        currentWave = 1
        activePowerUp = nil
        playerUpgrade = nil
        playerProgression = PlayerProgressionComponent() // Reset progression
        
        // Reset time slow state
        timeSlowEndTime = 0
        timeSlowDuration = 0
        currentTime = 0
        
        // Reset collision sound cooldown
        lastPunchSoundTime = 0
        
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
        
        // Update local progression state for UI
        playerProgression = progression
        
        // Show upgrade notification
        playerUpgrade = chosenUpgrade.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            playerUpgrade = nil
        }
    }
    
    private func setupGame(content: RealityViewCameraContent) async {
        guard let loadedScene = try? await Entity(named: GameConfig.EntityNames.scene, in: arenaBundle) else { return }
        guard let capsule = loadedScene.findEntity(named: GameConfig.EntityNames.capsule),
              let cube = loadedScene.findEntity(named: GameConfig.EntityNames.cube) else { return }
        
        // Load all enemy prefabs
        let enemyPrefabs: [EnemyType: Entity] = [
            .phase1: loadedScene.findEntity(named: GameConfig.EntityNames.enemyPhase1),
            .phase2: loadedScene.findEntity(named: GameConfig.EntityNames.enemyPhase2),
            .phase3: loadedScene.findEntity(named: GameConfig.EntityNames.enemyPhase3),
            .phase4: loadedScene.findEntity(named: GameConfig.EntityNames.enemyPhase4),
            .phase5: loadedScene.findEntity(named: GameConfig.EntityNames.enemyPhase5)
        ].compactMapValues { $0 }
        
        let redCapsule = enemyPrefabs[.phase1] // Legacy support
        let lootBox = loadedScene.findEntity(named: GameConfig.EntityNames.lootBox)
        
        capsuleEntity = capsule
        cubeEntity = cube
        
        setupPlayerPhysics(for: capsule, constrainedTo: cube)
        setupPlayerGameState(for: capsule)
        setupWaveSystem(for: capsule)
        
        if !enemyPrefabs.isEmpty {
            if let redCapsule = redCapsule {
                redCapsuleEntity = redCapsule
                redCapsule.removeFromParent()
            }
            
            // Remove all enemy prefabs from the scene
            for (_, prefab) in enemyPrefabs {
                prefab.removeFromParent()
            }
            
            setupSpawner(surface: cube, enemyPrefabs: enemyPrefabs)
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
        EnemyAnimationSystem.registerSystem()
        EnemyFallingSystem.registerSystem()
        PlayerFallingSystem.registerSystem()
        LootBoxAnimationSystem.registerSystem()
        
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
        
        // Sync local progression state
        playerProgression = progressionComponent
        
        // Initialize player animation component
        let animationComponent = PlayerAnimationComponent()
        entity.components.set(animationComponent)
        
        // Initialize player falling component
        let fallingComponent = PlayerFallingComponent()
        entity.components.set(fallingComponent)
    }
    
    private func setupPlayerPhysics(for entity: Entity, constrainedTo cube: Entity) {
        let capsuleBounds = entity.visualBounds(relativeTo: nil)
        let capsuleHeight = capsuleBounds.max.y - capsuleBounds.min.y
        let surfaceOffset = capsuleHeight / 2.0 + GameConfig.playerSurfaceOffsetMargin - 0.05
        
        var physicsComponent = PhysicsMovementComponent()
        physicsComponent.mass = GameConfig.playerMass
        physicsComponent.friction = GameConfig.frictionCoefficient
        physicsComponent.constrainedTo = cube
        physicsComponent.groundLevel = surfaceOffset
        entity.components.set(physicsComponent)
        
        let cubeTopY = cube.position.y + (cube.scale.y / 2.0)
        entity.position.y = cubeTopY + surfaceOffset
    }
    private func setupSpawner(surface: Entity, enemyPrefabs: [EnemyType: Entity]) {
        spawnerEntity = Entity()
        var spawnerComponent = SpawnerComponent()
        spawnerComponent.spawnSurface = surface
        spawnerComponent.enemyPrefabs = enemyPrefabs
        spawnerComponent.spawnInterval = GameConfig.enemySpawnInterval
        spawnerComponent.baseSpawnInterval = GameConfig.enemySpawnInterval // Set base interval
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
        let speedMultiplier = progression?.speedMultiplier ?? 1.0
        let currentSpeed = GameConfig.playerSpeed * speedMultiplier
        
        physics.velocity += direction.velocity * currentSpeed * forceMultiplier * 0.15
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
        let speedMultiplier = progression?.speedMultiplier ?? 1.0
        let currentSpeed = GameConfig.playerSpeed * speedMultiplier
        
        let isoX = (analogVector.x - analogVector.y) * GameConfig.isometricDiagonal
        let isoZ = -(analogVector.x + analogVector.y) * GameConfig.isometricDiagonal
        let force = SIMD3<Float>(isoX, 0, isoZ) * currentSpeed * forceMultiplier * 0.15
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
    
    private func captureGameSnapshot() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else {
            return
        }
        
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        let image = renderer.image { ctx in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        
        lastGameSnapshot = image
    }
    
    // MARK: - Audio Management
    
    private func setupTimeSlowAudio() {
        guard let path = Bundle.main.path(forResource: GameConfig.timeSlowSoundFileName, ofType: "mp3") else {
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            timeSlowAudioPlayer = try AVAudioPlayer(contentsOf: url)
            timeSlowAudioPlayer?.prepareToPlay()
        } catch {
            // Audio setup failed silently
        }
    }
    
    private func setupShockwaveAudio() {
        guard let path = Bundle.main.path(forResource: GameConfig.shockwaveSoundFileName, ofType: "mp3") else {
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            shockwaveAudioPlayer = try AVAudioPlayer(contentsOf: url)
            shockwaveAudioPlayer?.prepareToPlay()
        } catch {
            // Audio setup failed silently
        }
    }
    
    private func setupPunchAudio() {
        punchAudioPlayers.removeAll()
        
        for soundName in GameConfig.punchSoundFileNames {
            guard let path = Bundle.main.path(forResource: soundName, ofType: "mp3") else {
                continue
            }
            
            let url = URL(fileURLWithPath: path)
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                punchAudioPlayers.append(player)
            } catch {
                // Audio setup failed silently
            }
        }
    }
    
    private func setupAudio() {
        setupTimeSlowAudio()
        setupShockwaveAudio()
        setupPunchAudio()
    }
    
    private func playTimeSlowSound(duration: TimeInterval) {
        guard let player = timeSlowAudioPlayer else {
            return
        }
        
        // Cancel any existing stop task
        timeSlowStopTask?.cancel()
        
        // Calculate playback rate to stretch the sound to match the duration
        let baseDuration = GameConfig.baseTimeSlowSoundDuration
        let playbackRate = Float(baseDuration / duration)
        
        // Clamp playback rate to reasonable bounds (0.5 to 2.0)
        let clampedRate = max(0.5, min(2.0, playbackRate))
        
        player.enableRate = true
        player.rate = clampedRate
        player.currentTime = 0
        player.play()
        
        // Create new stop task for when time slow ends
        timeSlowStopTask = DispatchWorkItem {
            self.timeSlowAudioPlayer?.stop()
            self.timeSlowStopTask = nil
        }
        
        // Schedule the stop task
        if let stopTask = timeSlowStopTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: stopTask)
        }
    }
    
    private func playShockwaveSound() {
        guard let player = shockwaveAudioPlayer else {
            return
        }
        
        player.currentTime = 0
        player.play()
    }
    
    private func playRandomPunchSound() {
        guard !punchAudioPlayers.isEmpty else {
            return
        }
        
        // Find a player that's not currently playing, or use a random one if all are playing
        var availablePlayer: AVAudioPlayer?
        
        // First, try to find a non-playing player
        for player in punchAudioPlayers {
            if !player.isPlaying {
                availablePlayer = player
                break
            }
        }
        
        // If all players are busy, pick a random one (this will interrupt the current sound)
        if availablePlayer == nil {
            let randomIndex = Int.random(in: 0..<punchAudioPlayers.count)
            availablePlayer = punchAudioPlayers[randomIndex]
        }
        
        guard let player = availablePlayer else { return }
        
        player.currentTime = 0
        player.play()
    }
    
    private func playRandomPunchSoundWithCooldown() {
        let currentTime = Date().timeIntervalSince1970
        
        // Check if enough time has passed since the last punch sound
        if currentTime - lastPunchSoundTime < punchSoundCooldown {
            return
        }
        
        // Update the last punch sound time
        lastPunchSoundTime = currentTime
        
        // Play the sound
        playRandomPunchSound()
    }
    
    private func stopTimeSlowSound() {
        timeSlowStopTask?.cancel()
        timeSlowStopTask = nil
        timeSlowAudioPlayer?.stop()
    }
    
    private func stopAllSounds() {
        stopTimeSlowSound()
        shockwaveAudioPlayer?.stop()
        
        // Stop all punch sounds
        for player in punchAudioPlayers {
            player.stop()
        }
    }
    
    
}

#Preview {
    ContentView()
}
