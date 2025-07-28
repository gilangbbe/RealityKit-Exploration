import RealityKit
import Foundation

// Focused player progression types suitable for sumo-style gameplay
enum PlayerUpgradeType: String, CaseIterable, Codable {
    case resilience = "resilience"     // Resist enemy pushes better
    case force = "force"              // Push enemies with more power
    case speed = "speed"              // Move faster to keep up with enemies
    case slowDuration = "slowDuration" // Time slow effects last longer
    case shockwavePower = "shockwavePower" // Stronger shockwave effects
    
    var name: String {
        switch self {
        case .resilience: 
            return "Iron Will"
        case .force:
            return "Crushing Force"
        case .speed:
            return "Swift Movement"
        case .slowDuration:
            return "Extended Slow"
        case .shockwavePower:
            return "Devastating Shockwave"
        }
    }
    
    var description: String {
        switch self {
        case .resilience:
            return "Become harder to push around (+25%)"
        case .force:
            return "Push enemies with greater power (+15%)"
        case .speed:
            return "Move faster to outmaneuver enemies (+18%)"
        case .slowDuration:
            return "Time slow effects last longer (+35%)"
        case .shockwavePower:
            return "Shockwave pushes enemies harder (+20%)"
        }
    }
    
    var icon: String {
        switch self {
        case .resilience:
            return "shield.fill"
        case .force:
            return "hand.raised.fill"
        case .speed:
            return "bolt.fill"
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
    var speedMultiplier: Float = 1.0        // Move faster
    var slowDurationMultiplier: Float = 1.0  // Time slow lasts longer
    var shockwavePowerMultiplier: Float = 1.0 // Shockwave is stronger
    var wavesCompleted: Int = 0
    
    // Tracking upgrade counts for better balance
    var upgradesApplied: [PlayerUpgradeType: Int] = [:]
    
    // Maximum level for each upgrade
    static let maxUpgradeLevel: Int = 5
    
    // Base values for calculating current stats
    var baseResistance: Float = GameConfig.playerResistance
    var baseForce: Float = GameConfig.playerPushForceMultiplier
    var baseSpeed: Float = GameConfig.playerSpeed
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
    
    var currentSpeed: Float {
        return baseSpeed * speedMultiplier
    }
    
    var currentSlowDuration: TimeInterval {
        return TimeInterval(baseSlowDuration * slowDurationMultiplier)
    }
    
    var currentShockwaveForce: Float {
        return baseShockwaveForce * shockwavePowerMultiplier
    }
    
    mutating func applyChosenUpgrade(_ upgradeType: PlayerUpgradeType) {
        wavesCompleted += 1
        
        // Check if upgrade is already at max level
        let currentLevel = upgradesApplied[upgradeType, default: 0]
        if currentLevel >= Self.maxUpgradeLevel {
            return // Cannot upgrade beyond max level
        }
        
        // Track upgrade count for this type
        upgradesApplied[upgradeType, default: 0] += 1
        
        // Calculate diminishing upgrade values based on how many times this upgrade was chosen
        let upgradeCount = upgradesApplied[upgradeType, default: 0]
        let diminishingMultiplier = pow(GameConfig.playerUpgradeDiminishingFactor, Float(upgradeCount - 1))
        
        switch upgradeType {
        case .resilience:
            let upgradeAmount = 0.25 * diminishingMultiplier // Reduced from 0.4 to 0.25 (25% instead of 40%)
            resilienceMultiplier += upgradeAmount
        case .force:
            let upgradeAmount = 0.15 * diminishingMultiplier // Reduced from GameConfig.playerForceIncrease (0.2) to 0.15
            forceMultiplier += upgradeAmount
        case .speed:
            let upgradeAmount = GameConfig.playerSpeedUpgradeValue * diminishingMultiplier // 18% speed increase per upgrade - balanced for enemy progression
            speedMultiplier += upgradeAmount
        case .slowDuration:
            let upgradeAmount = 0.35 * diminishingMultiplier // Reduced from 0.5 to 0.35 (+35% instead of +50%)
            slowDurationMultiplier += upgradeAmount
        case .shockwavePower:
            let upgradeAmount = 0.20 * diminishingMultiplier // Reduced from 0.25 to 0.20 for small arena balance
            shockwavePowerMultiplier += upgradeAmount
        }
    }
    
    // Generate 3 random upgrade choices, avoiding maxed out upgrades
    func generateUpgradeChoices() -> [PlayerUpgradeType] {
        var choices: [PlayerUpgradeType] = []
        
        // Filter out maxed upgrades first
        var availableUpgrades = PlayerUpgradeType.allCases.filter { upgradeType in
            let currentLevel = upgradesApplied[upgradeType, default: 0]
            return currentLevel < Self.maxUpgradeLevel
        }
        
        // If all upgrades are maxed, return empty array (should rarely happen)
        if availableUpgrades.isEmpty {
            return []
        }
        
        // Reduce probability of already heavily upgraded options (more aggressive for balance)
        let weightedUpgrades = availableUpgrades.compactMap { upgradeType -> (PlayerUpgradeType, Float)? in
            let upgradeCount = upgradesApplied[upgradeType, default: 0]
            var weight: Float = 1.0
            
            if upgradeCount >= 4 {
                weight = 0.3 // 30% chance for level 4 upgrades
            } else if upgradeCount >= 2 {
                weight = 0.7 // 70% chance for level 2-3 upgrades
            }
            
            return (upgradeType, weight)
        }
        
        // Select 3 random choices based on weights
        var remainingUpgrades = weightedUpgrades
        
        for _ in 0..<min(3, availableUpgrades.count) {
            guard !remainingUpgrades.isEmpty else { break }
            
            // Calculate total weight
            let totalWeight = remainingUpgrades.reduce(0) { $0 + $1.1 }
            let randomValue = Float.random(in: 0...totalWeight)
            
            var currentWeight: Float = 0
            var selectedIndex = 0
            
            for (index, (_, weight)) in remainingUpgrades.enumerated() {
                currentWeight += weight
                if randomValue <= currentWeight {
                    selectedIndex = index
                    break
                }
            }
            
            let selectedUpgrade = remainingUpgrades[selectedIndex].0
            choices.append(selectedUpgrade)
            remainingUpgrades.remove(at: selectedIndex)
        }
        
        // If we couldn't get 3 choices due to weighting, fill with remaining available upgrades
        while choices.count < 3 && choices.count < availableUpgrades.count {
            let remaining = availableUpgrades.filter { !choices.contains($0) }
            if let randomUpgrade = remaining.randomElement() {
                choices.append(randomUpgrade)
            } else {
                break
            }
        }
        
        return choices
    }
    
    // Helper method to check if an upgrade is at max level
    func isUpgradeMaxed(_ upgradeType: PlayerUpgradeType) -> Bool {
        let currentLevel = upgradesApplied[upgradeType, default: 0]
        return currentLevel >= Self.maxUpgradeLevel
    }
    
    // Get the current level of a specific upgrade
    func getUpgradeLevel(_ upgradeType: PlayerUpgradeType) -> Int {
        return upgradesApplied[upgradeType, default: 0]
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case resilienceMultiplier, forceMultiplier, speedMultiplier, slowDurationMultiplier, shockwavePowerMultiplier
        case wavesCompleted, upgradesApplied
        case baseResistance, baseForce, baseSpeed, baseSlowDuration, baseShockwaveForce
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        resilienceMultiplier = try container.decodeIfPresent(Float.self, forKey: .resilienceMultiplier) ?? 1.0
        forceMultiplier = try container.decodeIfPresent(Float.self, forKey: .forceMultiplier) ?? 1.0
        speedMultiplier = try container.decodeIfPresent(Float.self, forKey: .speedMultiplier) ?? 1.0
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
        baseSpeed = try container.decodeIfPresent(Float.self, forKey: .baseSpeed) ?? GameConfig.playerSpeed
        baseSlowDuration = try container.decodeIfPresent(Float.self, forKey: .baseSlowDuration) ?? Float(GameConfig.timeSlowDuration)
        baseShockwaveForce = try container.decodeIfPresent(Float.self, forKey: .baseShockwaveForce) ?? GameConfig.shockwaveForce
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(resilienceMultiplier, forKey: .resilienceMultiplier)
        try container.encode(forceMultiplier, forKey: .forceMultiplier)
        try container.encode(speedMultiplier, forKey: .speedMultiplier)
        try container.encode(slowDurationMultiplier, forKey: .slowDurationMultiplier)
        try container.encode(shockwavePowerMultiplier, forKey: .shockwavePowerMultiplier)
        try container.encode(wavesCompleted, forKey: .wavesCompleted)
        
        // Convert dictionary to string keys for encoding
        let upgradesDict = Dictionary(uniqueKeysWithValues: upgradesApplied.map { ($0.key.rawValue, $0.value) })
        try container.encode(upgradesDict, forKey: .upgradesApplied)
        
        try container.encode(baseResistance, forKey: .baseResistance)
        try container.encode(baseForce, forKey: .baseForce)
        try container.encode(baseSpeed, forKey: .baseSpeed)
        try container.encode(baseSlowDuration, forKey: .baseSlowDuration)
        try container.encode(baseShockwaveForce, forKey: .baseShockwaveForce)
    }
}
