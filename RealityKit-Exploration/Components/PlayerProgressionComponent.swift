import RealityKit
import Foundation

// Enhanced player progression types with more variety
enum PlayerUpgradeType: String, CaseIterable, Codable {
    case speed = "speed"
    case mass = "mass"
    case force = "force"
    case agility = "agility"         // New: Better turning and control
    case resilience = "resilience"   // New: Resist enemy pushes better
    case momentum = "momentum"       // New: Keep moving through enemies
    
    var name: String {
        switch self {
        case .speed:
            return "Speed Boost"
        case .mass:
            return "Mass Increase" 
        case .force:
            return "Force Boost"
        case .agility:
            return "Agility"
        case .resilience: 
            return "Resilience"
        case .momentum:
            return "Momentum"
        }
    }
    
    var description: String {
        switch self {
        case .speed:
            return "Move faster across the arena"
        case .mass:
            return "Become heavier and harder to push"
        case .force:
            return "Push enemies with more power"
        case .agility:
            return "Better control and maneuverability"
        case .resilience:
            return "Resist enemy attacks better"
        case .momentum:
            return "Keep moving when colliding with enemies"
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
        case .agility:
            return "arrow.triangle.2.circlepath"
        case .resilience:
            return "shield.fill"
        case .momentum:
            return "arrow.forward.circle.fill"
        }
    }
}

// Component for tracking player progression
struct PlayerProgressionComponent: Component, Codable {
    var speedMultiplier: Float = 1.0
    var massMultiplier: Float = 1.0
    var forceMultiplier: Float = 1.0
    var agilityMultiplier: Float = 1.0      // New: affects friction and control
    var resilienceMultiplier: Float = 1.0   // New: affects resistance to pushes
    var momentumMultiplier: Float = 1.0     // New: affects collision preservation
    var wavesCompleted: Int = 0
    
    // Tracking upgrade counts for better balance
    var upgradesApplied: [PlayerUpgradeType: Int] = [:]
    
    // Base values for calculating current stats
    var baseSpeed: Float = GameConfig.playerSpeed
    var baseMass: Float = GameConfig.playerMass
    var baseForce: Float = 1.0
    
    // Default initializer
    init() {
        // All properties already have default values, so this is sufficient
    }
    
    var currentSpeed: Float {
        return baseSpeed * speedMultiplier
    }
    
    var currentMass: Float {
        return baseMass * massMultiplier
    }
    
    var currentForce: Float {
        return baseForce * forceMultiplier
    }
    
    var currentAgility: Float {
        return agilityMultiplier
    }
    
    var currentResilience: Float {
        return GameConfig.playerResistance * resilienceMultiplier
    }
    
    var currentMomentum: Float {
        return momentumMultiplier
    }
    
    mutating func applyChosenUpgrade(_ upgradeType: PlayerUpgradeType) {
        wavesCompleted += 1
        
        // Track upgrade count for this type
        upgradesApplied[upgradeType, default: 0] += 1
        
        // Calculate diminishing upgrade values based on how many times this upgrade was chosen
        let upgradeCount = upgradesApplied[upgradeType, default: 0]
        let diminishingMultiplier = pow(GameConfig.playerUpgradeDiminishingFactor, Float(upgradeCount - 1))
        
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
        case .agility:
            let upgradeAmount = 0.2 * diminishingMultiplier // Improves control
            agilityMultiplier += upgradeAmount
        case .resilience:
            let upgradeAmount = 0.3 * diminishingMultiplier // Better resistance
            resilienceMultiplier += upgradeAmount
        case .momentum:
            let upgradeAmount = 0.25 * diminishingMultiplier // Better collision handling
            momentumMultiplier += upgradeAmount
        }
    }
    
    // Generate 3 random upgrade choices, avoiding too much repetition
    func generateUpgradeChoices() -> [PlayerUpgradeType] {
        var choices: [PlayerUpgradeType] = []
        var availableUpgrades = PlayerUpgradeType.allCases
        
        // Reduce probability of already heavily upgraded options
        availableUpgrades = availableUpgrades.filter { upgradeType in
            let upgradeCount = upgradesApplied[upgradeType, default: 0]
            if upgradeCount >= 3 { // Avoid if already upgraded 3+ times
                return Float.random(in: 0...1) < 0.3 // Only 30% chance
            }
            return true
        }
        
        // Select 3 random choices
        for _ in 0..<min(3, availableUpgrades.count) {
            if let randomUpgrade = availableUpgrades.randomElement() {
                choices.append(randomUpgrade)
                availableUpgrades.removeAll { $0 == randomUpgrade }
            }
        }
        
        // Fill remaining slots if needed
        while choices.count < 3 {
            if let randomUpgrade = PlayerUpgradeType.allCases.randomElement() {
                choices.append(randomUpgrade)
            }
        }
        
        return choices
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case speedMultiplier, massMultiplier, forceMultiplier
        case agilityMultiplier, resilienceMultiplier, momentumMultiplier
        case wavesCompleted, upgradesApplied
        case baseSpeed, baseMass, baseForce
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        speedMultiplier = try container.decodeIfPresent(Float.self, forKey: .speedMultiplier) ?? 1.0
        massMultiplier = try container.decodeIfPresent(Float.self, forKey: .massMultiplier) ?? 1.0
        forceMultiplier = try container.decodeIfPresent(Float.self, forKey: .forceMultiplier) ?? 1.0
        agilityMultiplier = try container.decodeIfPresent(Float.self, forKey: .agilityMultiplier) ?? 1.0
        resilienceMultiplier = try container.decodeIfPresent(Float.self, forKey: .resilienceMultiplier) ?? 1.0
        momentumMultiplier = try container.decodeIfPresent(Float.self, forKey: .momentumMultiplier) ?? 1.0
        wavesCompleted = try container.decodeIfPresent(Int.self, forKey: .wavesCompleted) ?? 0
        
        // Decode dictionary with string keys and convert back
        let upgradesDict = try container.decodeIfPresent([String: Int].self, forKey: .upgradesApplied) ?? [:]
        upgradesApplied = [:]
        for (key, value) in upgradesDict {
            if let upgradeType = PlayerUpgradeType(rawValue: key) {
                upgradesApplied[upgradeType] = value
            }
        }
        
        baseSpeed = try container.decodeIfPresent(Float.self, forKey: .baseSpeed) ?? GameConfig.playerSpeed
        baseMass = try container.decodeIfPresent(Float.self, forKey: .baseMass) ?? GameConfig.playerMass
        baseForce = try container.decodeIfPresent(Float.self, forKey: .baseForce) ?? 1.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(speedMultiplier, forKey: .speedMultiplier)
        try container.encode(massMultiplier, forKey: .massMultiplier)
        try container.encode(forceMultiplier, forKey: .forceMultiplier)
        try container.encode(agilityMultiplier, forKey: .agilityMultiplier)
        try container.encode(resilienceMultiplier, forKey: .resilienceMultiplier)
        try container.encode(momentumMultiplier, forKey: .momentumMultiplier)
        try container.encode(wavesCompleted, forKey: .wavesCompleted)
        
        // Convert dictionary to string keys for encoding
        let upgradesDict = Dictionary(uniqueKeysWithValues: upgradesApplied.map { ($0.key.rawValue, $0.value) })
        try container.encode(upgradesDict, forKey: .upgradesApplied)
        
        try container.encode(baseSpeed, forKey: .baseSpeed)
        try container.encode(baseMass, forKey: .baseMass)
        try container.encode(baseForce, forKey: .baseForce)
    }
}
