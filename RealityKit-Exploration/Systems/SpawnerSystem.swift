import RealityKit
import Foundation

class SpawnerSystem: System {
    static let query = EntityQuery(where: .has(SpawnerComponent.self))
    required init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var spawner = entity.components[SpawnerComponent.self] else { continue }
            let currentTime = Date()
            let timeSinceLastSpawn = currentTime.timeIntervalSince(spawner.lastSpawnTime)
            if timeSinceLastSpawn >= spawner.spawnInterval {
                let currentEnemyCount = countActiveEnemies(in: context)
                if currentEnemyCount < spawner.maxEnemies,
                   let surface = spawner.spawnSurface,
                   let prefab = spawner.enemyPrefab {
                    spawnEnemy(on: surface, using: prefab, in: context)
                    spawner.lastSpawnTime = currentTime
                }
            }
            entity.components[SpawnerComponent.self] = spawner
        }
    }
    private func countActiveEnemies(in context: SceneUpdateContext) -> Int {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        var count = 0
        for _ in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) { count += 1 }
        return count
    }
    private func spawnEnemy(on surface: Entity, using prefab: Entity, in context: SceneUpdateContext) {
        let enemy = prefab.clone(recursive: true)
        let randomPosition = generateRandomPositionOnCubeSurface(cube: surface)
        enemy.position = randomPosition
        enemy.components.set(EnemyCapsuleComponent())
        surface.parent?.addChild(enemy)
    }
    private func generateRandomPositionOnCubeSurface(cube: Entity) -> SIMD3<Float> {
        let cubePosition = cube.position
        let cubeScale = cube.scale
        let halfSize = cubeScale.x / 2.0
        let randomX = Float.random(in: -halfSize...halfSize) + cubePosition.x
        let randomZ = Float.random(in: -halfSize...halfSize) + cubePosition.z
        let surfaceY = cubePosition.y + halfSize + 0.1
        return SIMD3<Float>(randomX, surfaceY, randomZ)
    }
}
