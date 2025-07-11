import SwiftUI
import RealityKit
import Arena

struct ContentView: View {
    @State private var capsuleEntity = Entity()
    @State private var cubeEntity = Entity()
    @State private var redCapsuleEntity = Entity()
    @State private var spawnerEntity = Entity()

    var body: some View {
        ZStack {
            RealityView { content in
                guard let loadedScene = try? await Entity(named: GameConfig.EntityNames.scene, in: arenaBundle) else { return }
                guard let capsule = loadedScene.findEntity(named: GameConfig.EntityNames.capsule),
                      let cube = loadedScene.findEntity(named: GameConfig.EntityNames.cube) else { return }
                let redCapsule = loadedScene.findEntity(named: GameConfig.EntityNames.enemyCapsule)
                capsuleEntity = capsule
                cubeEntity = cube
                setupMovementComponent(for: capsule, constrainedTo: cube)
                setupAutoShooting(for: capsule)
                if let redCapsule = redCapsule {
                    redCapsuleEntity = redCapsule
                    redCapsule.removeFromParent()
                    setupSpawner(surface: cube, enemyPrefab: redCapsule)
                }
                let camera = setupIsometricCamera(target: capsule)
                MovementSystem.registerSystem()
                IsometricCameraSystem.registerSystem()
                SpawnerSystem.registerSystem()
                ProjectileSystem.registerSystem()
                DestroySystem.registerSystem()
                AutoShootSystem.registerSystem()
                content.add(loadedScene)
                content.add(camera)
                content.add(spawnerEntity)
            } update: { content in }
            ControlsView { direction in
                startApplyingForce(direction: direction)
            } stopApplyingForce: {
                stopApplyingForce()
            } applyAnalogForce: { analogVector in
                applyAnalogForce(analogVector: analogVector)
            }
        }
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
    private func setupAutoShooting(for entity: Entity) {
        var autoShootComponent = AutoShootComponent()
        autoShootComponent.shootInterval = GameConfig.autoShootInterval
        autoShootComponent.shootWhileMoving = GameConfig.autoShootWhileMoving
        autoShootComponent.isEnabled = true
        entity.components.set(autoShootComponent)
    }
    private func setupMovementComponent(for entity: Entity, constrainedTo cube: Entity) {
        let capsuleBounds = entity.visualBounds(relativeTo: nil)
        let cubeBounds = cube.visualBounds(relativeTo: nil)
        let capsuleHeight = capsuleBounds.max.y - capsuleBounds.min.y
        let surfaceOffset = capsuleHeight / 2.0 + GameConfig.playerSurfaceOffsetMargin
        var movementComponent = MovementComponent()
        movementComponent.speed = GameConfig.playerSpeed
        movementComponent.constrainedTo = cube
        movementComponent.surfaceOffset = surfaceOffset
        entity.components.set(movementComponent)
        let cubeTopY = cube.position.y + (cube.scale.y / 2.0)
        entity.position.y = cubeTopY + surfaceOffset
    }
    private func startApplyingForce(direction: ForceDirection) {
        guard var movement = capsuleEntity.components[MovementComponent.self] else { return }
        movement.velocity = direction.velocity
        movement.isMoving = true
        capsuleEntity.components[MovementComponent.self] = movement
    }
    private func stopApplyingForce() {
        guard var movement = capsuleEntity.components[MovementComponent.self] else { return }
        movement.velocity = [0, 0, 0]
        movement.isMoving = false
        capsuleEntity.components[MovementComponent.self] = movement
    }
    private func applyAnalogForce(analogVector: SIMD2<Float>) {
        guard var movement = capsuleEntity.components[MovementComponent.self] else { return }
        let isoX = (analogVector.x - analogVector.y) * GameConfig.isometricDiagonal
        let isoZ = -(analogVector.x + analogVector.y) * GameConfig.isometricDiagonal
        let velocity = SIMD3<Float>(isoX, 0, isoZ)
        movement.velocity = velocity
        movement.isMoving = length(velocity) > 0.1
        capsuleEntity.components[MovementComponent.self] = movement
    }
}

#Preview {
    ContentView()
}
