import RealityKit
import Foundation

struct PlayerProgressionSystem: System {
    static let playerQuery = EntityQuery(where: .has(PlayerProgressionComponent.self) && .has(PhysicsMovementComponent.self))
    
    init(scene: RealityKit.Scene) { }
    
    func update(context: SceneUpdateContext) {
        // This system mainly responds to wave completion events
        // The actual progression logic is triggered by notifications
    }
    
    static func applyPlayerUpgrade(to playerEntity: Entity, upgradeType: PlayerUpgradeType) {
        guard var progression = playerEntity.components[PlayerProgressionComponent.self] else {
            return
        }
        
        // Apply chosen upgrade
        progression.applyChosenUpgrade(upgradeType)
        
        // Save updated components (no need to update physics mass anymore)
        playerEntity.components[PlayerProgressionComponent.self] = progression
        
        // Notify UI about the upgrade
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .playerUpgraded, object: upgradeType)
        }
        
        print("Player upgraded: \(upgradeType.name)")
        print("Wave \(progression.wavesCompleted) - Diminishing multiplier: \(String(format: "%.3f", pow(GameConfig.playerUpgradeDiminishingFactor, Float(progression.wavesCompleted - 1))))")
        print("New stats - Resilience: \(String(format: "%.2f", progression.currentResistance)), Force: \(String(format: "%.2f", progression.currentForce)), Speed: \(String(format: "%.2f", progression.currentSpeed)), Slow Duration: \(String(format: "%.2f", progression.currentSlowDuration))s, Shockwave Power: \(String(format: "%.2f", progression.currentShockwaveForce))")
    }
}

// Notification for player upgrades
extension Notification.Name {
    static let playerUpgraded = Notification.Name("PlayerUpgraded")
}
