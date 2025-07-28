import RealityKit
import Foundation

// Different enemy types with progressive difficulty
// Each enemy asset should have a child entity with the same name containing animation library
// Animation structure: Index 0 = Walking animation
enum EnemyType: String, CaseIterable, Codable {
    case phase1 = "enemyPhase1" // Weakest - Basic enemy
    case phase2 = "enemyPhase2" // Light fighter
    case phase3 = "enemyPhase3" // Balanced warrior  
    case phase4 = "enemyPhase4" // Heavy bruiser
    case phase5 = "enemyPhase5" // Strongest - Elite enemy
    
    var name: String {
        switch self {
        case .phase1: return "Scout"
        case .phase2: return "Fighter" 
        case .phase3: return "Warrior"
        case .phase4: return "Bruiser"
        case .phase5: return "Elite"
        }
    }
    
    var assetName: String {
        return self.rawValue
    }
    
    // Base stats for each enemy type
    var baseStats: EnemyStats {
        switch self {
        case .phase1:
            return EnemyStats(
                speed: 0.25,
                mass: 0.8,
                pushForce: 0.3,
                scoreValue: 50,
                health: 1
            )
        case .phase2:
            return EnemyStats(
                speed: 0.3,
                mass: 1.0,
                pushForce: 0.4,
                scoreValue: 75,
                health: 1
            )
        case .phase3:
            return EnemyStats(
                speed: 0.35,
                mass: 1.2,
                pushForce: 0.5,
                scoreValue: 100,
                health: 1
            )
        case .phase4:
            return EnemyStats(
                speed: 0.3,
                mass: 1.4,
                pushForce: 0.6,
                scoreValue: 150,
                health: 1
            )
        case .phase5:
            return EnemyStats(
                speed: 0.4,
                mass: 1.6,
                pushForce: 0.7,
                scoreValue: 200,
                health: 1
            )
        }
    }
    
    // Determine enemy type based on wave number
    static func getEnemyTypeForWave(_ wave: Int) -> EnemyType {
        switch wave {
        case 1...2: return .phase1
        case 3...5: return .phase2
        case 6...8: return .phase3
        case 9...12: return .phase4
        default: return .phase5
        }
    }
    
    // Get random enemy type with wave-based weighting
    static func getRandomEnemyTypeForWave(_ wave: Int) -> EnemyType {
        let weights: [EnemyType: Float]
        
        switch wave {
        case 1...2:
            weights = [.phase1: 1.0]
        case 3...4:
            weights = [.phase1: 0.6, .phase2: 0.4]
        case 5...6:
            weights = [.phase1: 0.3, .phase2: 0.7]
        case 7...8:
            weights = [.phase2: 0.5, .phase3: 0.5]
        case 9...10:
            weights = [.phase2: 0.3, .phase3: 0.6, .phase4: 0.1]
        case 11...12:
            weights = [.phase3: 0.4, .phase4: 0.6]
        case 13...15:
            weights = [.phase3: 0.2, .phase4: 0.6, .phase5: 0.2]
        default:
            weights = [.phase4: 0.4, .phase5: 0.6]
        }
        
        return weightedRandomSelection(weights: weights)
    }
    
    private static func weightedRandomSelection(weights: [EnemyType: Float]) -> EnemyType {
        let totalWeight = weights.values.reduce(0, +)
        var random = Float.random(in: 0..<totalWeight)
        
        for (type, weight) in weights {
            random -= weight
            if random <= 0 {
                return type
            }
        }
        
        return weights.keys.first ?? .phase1
    }
}

// Enemy base stats structure
struct EnemyStats {
    let speed: Float
    let mass: Float
    let pushForce: Float
    let scoreValue: Int
    let health: Int
}

struct EnemyCapsuleComponent: Component {
    var isActive: Bool = true
    var spawnTime: Date = Date()
    var enemyType: EnemyType = .phase1
    var scoreValue: Int = 50
    var speed: Float = 0.25
    var mass: Float = 0.8
    var pushForceMultiplier: Float = 0.3
    var target: Entity? = nil
    var hasFallen: Bool = false
    
    // Initialize with enemy type
    init(enemyType: EnemyType = .phase1) {
        self.enemyType = enemyType
        let stats = enemyType.baseStats
        self.speed = stats.speed
        self.mass = stats.mass
        self.pushForceMultiplier = stats.pushForce
        self.scoreValue = stats.scoreValue
    }
    
    // Helper method to get animation component for this enemy type
    func createAnimationComponent() -> EnemyAnimationComponent {
        return EnemyAnimationComponent(enemyType: self.enemyType)
    }
}
