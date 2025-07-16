import RealityKit
import Foundation

// Player progression types
enum PlayerUpgradeType: CaseIterable {
    case speed
    case mass
    case force
    
    var name: String {
        switch self {
        case .speed:
            return "Speed Boost"
        case .mass:
            return "Mass Increase"
        case .force:
            return "Force Boost"
        }
    }
    
    var icon: String {
        switch self {
        case .speed:
            return "bolt.fill"
        case .mass:
            return "cube.fill"
        case .force:
            return "hand.raised.fill"
        }
    }
}

// Component for tracking player progression
struct PlayerProgressionComponent: Component, Codable {
    var speedMultiplier: Float = 1.0
    var massMultiplier: Float = 1.0
    var forceMultiplier: Float = 1.0
    var wavesCompleted: Int = 0
    
    // Base values for calculating current stats
    var baseSpeed: Float = GameConfig.playerSpeed
    var baseMass: Float = GameConfig.playerMass
    var baseForce: Float = 1.0
    
    var currentSpeed: Float {
        return baseSpeed * speedMultiplier
    }
    
    var currentMass: Float {
        return baseMass * massMultiplier
    }
    
    var currentForce: Float {
        return baseForce * forceMultiplier
    }
    
    mutating func applyRandomUpgrade() -> PlayerUpgradeType {
        let upgradeType = PlayerUpgradeType.allCases.randomElement()!
        wavesCompleted += 1
        
        // Calculate diminishing upgrade values based on waves completed
        let diminishingMultiplier = pow(GameConfig.playerUpgradeDiminishingFactor, Float(wavesCompleted - 1))
        
        switch upgradeType {
        case .speed:
            let upgradeAmount = GameConfig.playerSpeedIncrease * diminishingMultiplier
            speedMultiplier += upgradeAmount
        case .mass:
            let upgradeAmount = GameConfig.playerMassIncrease * diminishingMultiplier
            massMultiplier += upgradeAmount
        case .force:
            let upgradeAmount = GameConfig.playerForceIncrease * diminishingMultiplier
            forceMultiplier += upgradeAmount
        }
        
        return upgradeType
    }
}
