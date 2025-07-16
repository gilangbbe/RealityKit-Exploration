import RealityKit
import Foundation

struct PlayerProgressionSystem: System {
    static let playerQuery = EntityQuery(where: .has(PlayerProgressionComponent.self) && .has(PhysicsMovementComponent.self))
    
    init(scene: RealityKit.Scene) { }
    
    func update(context: SceneUpdateContext) {
        // This system mainly responds to wave completion events
        // The actual progression logic is triggered by notifications
    }
    
    static func applyPlayerUpgrade(to playerEntity: Entity) {
        guard var progression = playerEntity.components[PlayerProgressionComponent.self],
              var physics = playerEntity.components[PhysicsMovementComponent.self] else {
            return
        }
        
        // Apply random upgrade
        let upgradeType = progression.applyRandomUpgrade()
        
        // Update physics component with new values
        physics.mass = progression.currentMass
        
        // Save updated components
        playerEntity.components[PlayerProgressionComponent.self] = progression
        playerEntity.components[PhysicsMovementComponent.self] = physics
        
        // Notify UI about the upgrade
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .playerUpgraded, object: upgradeType)
        }
        
        print("Player upgraded: \(upgradeType.name)")
        print("Wave \(progression.wavesCompleted) - Diminishing multiplier: \(String(format: "%.3f", pow(GameConfig.playerUpgradeDiminishingFactor, Float(progression.wavesCompleted - 1))))")
        print("New stats - Speed: \(String(format: "%.2f", progression.currentSpeed)), Mass: \(String(format: "%.2f", progression.currentMass)), Force: \(String(format: "%.2f", progression.currentForce))")
    }
}

// Notification for player upgrades
extension Notification.Name {
    static let playerUpgraded = Notification.Name("PlayerUpgraded")
}
