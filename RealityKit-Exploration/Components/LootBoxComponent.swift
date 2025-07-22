import RealityKit
import Foundation
import QuartzCore

// Power-up types
enum PowerUpType: String, CaseIterable, Codable {
    case timeSlow = "timeSlow"
    case shockwave = "shockwave"
    
    var name: String {
        switch self {
        case .timeSlow:
            return "Time Slow"
        case .shockwave:
            return "Shockwave"
        }
    }
}

// Component for LootBox entities
struct LootBoxComponent: Component, Codable {
    var powerUpType: PowerUpType
    var spawnTime: TimeInterval
    var lifetime: TimeInterval = GameConfig.lootBoxLifetime
    
    init(powerUpType: PowerUpType = PowerUpType.allCases.randomElement()!) {
        self.powerUpType = powerUpType
        self.spawnTime = CACurrentMediaTime()
    }
    
    // Custom coding keys for proper Codable conformance
    enum CodingKeys: String, CodingKey {
        case powerUpType, spawnTime, lifetime
    }
    
    func isExpired(currentTime: TimeInterval) -> Bool {
        return currentTime - spawnTime > lifetime
    }
}

// Component for tracking active power-ups on the player
struct PowerUpComponent: Component, Codable {
    var timeSlowEndTime: TimeInterval = 0
    var originalEnemySpeedMultiplier: Float = 1.0
    
    func isTimeSlowActive(currentTime: TimeInterval) -> Bool {
        return currentTime < timeSlowEndTime
    }
    
    mutating func activateTimeSlow(currentTime: TimeInterval, duration: TimeInterval) {
        timeSlowEndTime = currentTime + duration
    }
}

// Component for LootBox spawning
struct LootBoxSpawnerComponent: Component, Codable {
    var spawnSurface: Entity?
    var lootBoxPrefab: Entity?
    var lootBoxContainer: Entity?
    var lastSpawnTime: TimeInterval = 0
    var spawnInterval: TimeInterval = GameConfig.lootBoxSpawnInterval
    
    // Custom coding implementation to handle Entity references
    enum CodingKeys: String, CodingKey {
        case lastSpawnTime, spawnInterval
    }
    
    func shouldSpawn(currentTime: TimeInterval) -> Bool {
        return currentTime - lastSpawnTime >= spawnInterval
    }
    
    mutating func markSpawned(currentTime: TimeInterval) {
        lastSpawnTime = currentTime
    }
}
