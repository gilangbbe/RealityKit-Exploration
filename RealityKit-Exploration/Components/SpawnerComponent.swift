import RealityKit
import Foundation

struct SpawnerComponent: Component {
    var spawnInterval: TimeInterval = 3.0 // Spawn every 3 seconds
    var lastSpawnTime: Date = Date()
    var maxEnemies: Int = 5
    var spawnSurface: Entity? = nil // The surface to spawn on (cube)
    var enemyPrefab: Entity? = nil // Reference to the enemy prefab
}
