import RealityKit
import Foundation

// Focused player progression types suitable for sumo-style gameplay
enum PlayerUpgradeType: String, CaseIterable, Codable {
    case resilience = "resilience"     // Resist enemy pushes better
    case force = "force"              // Push enemies with more power
    case slowDuration = "slowDuration" // Time slow effects last longer
    case shockwavePower = "shockwavePower" // Stronger shockwave effects
    
    var name: String {
        switch self {
        case .resilience: 
            return "Iron Will"
        case .force:
            return "Crushing Force"
        case .slowDuration:
            return "Extended Slow"
        case .shockwavePower:
            return "Devastating Shockwave"
        }
    }
    
    var description: String {
        switch self {
        case .resilience:
            return "Become harder to push around"
        case .force:
            return "Push enemies with devastating power"
        case .slowDuration:
            return "Time slow effects last much longer"
        case .shockwavePower:
            return "Shockwave pushes enemies harder and further"
        }
    }
    
    var icon: String {
        switch self {
        case .resilience:
            return "shield.fill"
        case .force:
            return "hand.raised.fill"
        case .slowDuration:
            return "clock.arrow.circlepath"
        case .shockwavePower:
            return "burst.fill"
        }
    }
}

// Component for tracking player progression
struct PlayerProgressionComponent: Component, Codable {
    var resilienceMultiplier: Float = 1.0   // Resist being pushed
    var forceMultiplier: Float = 1.0        // Push enemies harder
    var slowDurationMultiplier: Float = 1.0  // Time slow lasts longer
    var shockwavePowerMultiplier: Float = 1.0 // Shockwave is stronger
    var wavesCompleted: Int = 0
    
    // Tracking upgrade counts for better balance
    var upgradesApplied: [PlayerUpgradeType: Int] = [:]
    
    // Base values for calculating current stats
    var baseResistance: Float = GameConfig.playerResistance
    var baseForce: Float = GameConfig.playerPushForceMultiplier
    var baseSlowDuration: Float = Float(GameConfig.timeSlowDuration)
    var baseShockwaveForce: Float = GameConfig.shockwaveForce
    
    // Default initializer
    init() {
        // All properties already have default values, so this is sufficient
    }
    
    var currentResistance: Float {
        return baseResistance * resilienceMultiplier
    }
    
    var currentForce: Float {
        return baseForce * forceMultiplier
    }
    
    var currentSlowDuration: TimeInterval {
        return TimeInterval(baseSlowDuration * slowDurationMultiplier)
    }
    
    var currentShockwaveForce: Float {
        return baseShockwaveForce * shockwavePowerMultiplier
    }
    
    mutating func applyChosenUpgrade(_ upgradeType: PlayerUpgradeType) {
        wavesCompleted += 1
        
        // Track upgrade count for this type
        upgradesApplied[upgradeType, default: 0] += 1
        
        // Calculate diminishing upgrade values based on how many times this upgrade was chosen
        let upgradeCount = upgradesApplied[upgradeType, default: 0]
        let diminishingMultiplier = pow(GameConfig.playerUpgradeDiminishingFactor, Float(upgradeCount - 1))
        
        switch upgradeType {
        case .resilience:
            let upgradeAmount = 0.4 * diminishingMultiplier // Significant resistance boost
            resilienceMultiplier += upgradeAmount
        case .force:
            let upgradeAmount = GameConfig.playerForceIncrease * diminishingMultiplier
            forceMultiplier += upgradeAmount
        case .slowDuration:
            let upgradeAmount = 0.5 * diminishingMultiplier // +50% slow duration each upgrade
            slowDurationMultiplier += upgradeAmount
        case .shockwavePower:
            let upgradeAmount = 0.25 * diminishingMultiplier // +25% shockwave power each upgrade (more balanced for small arena)
            shockwavePowerMultiplier += upgradeAmount
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
        case resilienceMultiplier, forceMultiplier, slowDurationMultiplier, shockwavePowerMultiplier
        case wavesCompleted, upgradesApplied
        case baseResistance, baseForce, baseSlowDuration, baseShockwaveForce
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        resilienceMultiplier = try container.decodeIfPresent(Float.self, forKey: .resilienceMultiplier) ?? 1.0
        forceMultiplier = try container.decodeIfPresent(Float.self, forKey: .forceMultiplier) ?? 1.0
        slowDurationMultiplier = try container.decodeIfPresent(Float.self, forKey: .slowDurationMultiplier) ?? 1.0
        shockwavePowerMultiplier = try container.decodeIfPresent(Float.self, forKey: .shockwavePowerMultiplier) ?? 1.0
        wavesCompleted = try container.decodeIfPresent(Int.self, forKey: .wavesCompleted) ?? 0
        
        // Decode dictionary with string keys and convert back
        let upgradesDict = try container.decodeIfPresent([String: Int].self, forKey: .upgradesApplied) ?? [:]
        upgradesApplied = [:]
        for (key, value) in upgradesDict {
            if let upgradeType = PlayerUpgradeType(rawValue: key) {
                upgradesApplied[upgradeType] = value
            }
        }
        
        baseResistance = try container.decodeIfPresent(Float.self, forKey: .baseResistance) ?? GameConfig.playerResistance
        baseForce = try container.decodeIfPresent(Float.self, forKey: .baseForce) ?? GameConfig.playerPushForceMultiplier
        baseSlowDuration = try container.decodeIfPresent(Float.self, forKey: .baseSlowDuration) ?? Float(GameConfig.timeSlowDuration)
        baseShockwaveForce = try container.decodeIfPresent(Float.self, forKey: .baseShockwaveForce) ?? GameConfig.shockwaveForce
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(resilienceMultiplier, forKey: .resilienceMultiplier)
        try container.encode(forceMultiplier, forKey: .forceMultiplier)
        try container.encode(slowDurationMultiplier, forKey: .slowDurationMultiplier)
        try container.encode(shockwavePowerMultiplier, forKey: .shockwavePowerMultiplier)
        try container.encode(wavesCompleted, forKey: .wavesCompleted)
        
        // Convert dictionary to string keys for encoding
        let upgradesDict = Dictionary(uniqueKeysWithValues: upgradesApplied.map { ($0.key.rawValue, $0.value) })
        try container.encode(upgradesDict, forKey: .upgradesApplied)
        
        try container.encode(baseResistance, forKey: .baseResistance)
        try container.encode(baseForce, forKey: .baseForce)
        try container.encode(baseSlowDuration, forKey: .baseSlowDuration)
        try container.encode(baseShockwaveForce, forKey: .baseShockwaveForce)
    }
}
