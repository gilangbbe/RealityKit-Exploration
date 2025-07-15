import RealityKit
import Foundation

struct GameStateComponent: Component {
    var score: Int = 0
    var enemiesDefeated: Int = 0
    var isGameActive: Bool = true
    var currentWave: Int = 1
}
