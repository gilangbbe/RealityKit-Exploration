import SwiftUI
import RealityKit
import Arena

struct ContentView: View {
    @State private var capsuleEntity = Entity()
    @State private var cubeEntity = Entity()
    @State private var redCapsuleEntity = Entity()
    @State private var spawnerEntity = Entity()
    @State private var waveManagerEntity = Entity()
    @State private var isGameOver = false
    @State private var score = 0
    @State private var enemiesDefeated = 0
    @State private var gameKey = UUID() // For restarting the game
    
    // Wave system state
    @State private var currentWave = 1
    @State private var enemiesRemaining = 5
    @State private var totalEnemiesInWave = 5
    @State private var isWaveActive = false
    
    var body: some View {
        ZStack {
            RealityView { content in
                await setupGame(content: content)
            } update: { content in }
            .id(gameKey) // This will recreate the RealityView when gameKey changes
            
            VStack {
                HStack {
                    ScoreView(score: score, enemiesDefeated: enemiesDefeated)
                    Spacer()
                    WaveHUDView(
                        waveNumber: currentWave,
                        enemiesRemaining: enemiesRemaining,
                        totalEnemies: totalEnemiesInWave,
                        isWaveActive: isWaveActive
                    )
                }
                Spacer()
            }
            
            ControlsView { direction in
                startApplyingForce(direction: direction)
            } stopApplyingForce: {
                stopApplyingForce()
            } applyAnalogForce: { analogVector in
                applyAnalogForce(analogVector: analogVector)
            }
            
            if isGameOver {
                GameOverView(finalScore: score, enemiesDefeated: enemiesDefeated, waveReached: currentWave) {
                    restartGame()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerFell)) { _ in
            isGameOver = true
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
            print("📱 UI received waveStarted notification")
            if let waveInfo = notification.object as? WaveInfo {
                print("📱 Wave info: \(waveInfo.waveNumber), enemies: \(waveInfo.enemiesInWave)")
                currentWave = waveInfo.waveNumber
                enemiesRemaining = waveInfo.enemiesRemaining
                totalEnemiesInWave = waveInfo.enemiesInWave
                isWaveActive = true
            } else {
                print("❌ Failed to cast notification object to WaveInfo")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waveEnemyDefeated)) { notification in
            if let waveInfo = notification.object as? WaveInfo {
                enemiesRemaining = waveInfo.enemiesRemaining
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waveCompleted)) { notification in
            if let waveInfo = notification.object as? WaveInfo {
                isWaveActive = false
            }
        }
    }
    
    private func setupGame(content: RealityViewCameraContent) async {
        guard let loadedScene = try? await Entity(named: GameConfig.EntityNames.scene, in: arenaBundle) else { return }
        guard let capsule = loadedScene.findEntity(named: GameConfig.EntityNames.capsule),
              let cube = loadedScene.findEntity(named: GameConfig.EntityNames.cube) else { return }
        let redCapsule = loadedScene.findEntity(named: GameConfig.EntityNames.enemyCapsule)
        
        capsuleEntity = capsule
        cubeEntity = cube
        
        setupPlayerPhysics(for: capsule, constrainedTo: cube)
        setupPlayerGameState(for: capsule)
        setupWaveManager()
        
        if let redCapsule = redCapsule {
            redCapsuleEntity = redCapsule
            redCapsule.removeFromParent()
            setupSpawner(surface: cube, enemyPrefab: redCapsule)
        }
        
        let camera = setupIsometricCamera(target: capsule)
        
        // Register all systems
        PhysicsMovementSystem.registerSystem()
        IsometricCameraSystem.registerSystem()
        SpawnerSystem.registerSystem()
        SumoSystem.registerSystem() // Use enhanced wave-based AI instead of basic EnemyCapsuleSystem
        GameManagementSystem.registerSystem()
        
        content.add(loadedScene)
        content.add(camera)
        content.add(spawnerEntity)
        content.add(waveManagerEntity)
    }
    
    private func restartGame() {
        isGameOver = false
        score = 0
        enemiesDefeated = 0
        currentWave = 1
        enemiesRemaining = 5
        totalEnemiesInWave = 5
        isWaveActive = false
        gameKey = UUID() // This will trigger a complete recreation of the RealityView
    }
    
    private func setupWaveManager() {
        waveManagerEntity = Entity()
        let waveManagerComponent = WaveManagerComponent()
        waveManagerEntity.components.set(waveManagerComponent)
    }
    
    private func setupPlayerGameState(for entity: Entity) {
        let gameStateComponent = GameStateComponent()
        entity.components.set(gameStateComponent)
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
        spawnerComponent.maxEnemies = GameConfig.enemyMaxCount
        spawnerEntity.components.set(spawnerComponent)
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
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        physics.velocity += direction.velocity * GameConfig.playerSpeed * 0.15 // Increased force
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
    
    private func stopApplyingForce() {
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        physics.velocity *= 0.9 // Better control when stopping
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
    
    private func applyAnalogForce(analogVector: SIMD2<Float>) {
        guard var physics = capsuleEntity.components[PhysicsMovementComponent.self] else { return }
        let isoX = (analogVector.x - analogVector.y) * GameConfig.isometricDiagonal
        let isoZ = -(analogVector.x + analogVector.y) * GameConfig.isometricDiagonal
        let force = SIMD3<Float>(isoX, 0, isoZ) * GameConfig.playerSpeed * 0.15 // Increased force
        physics.velocity += force
        capsuleEntity.components[PhysicsMovementComponent.self] = physics
    }
}

#Preview {
    ContentView()
}
