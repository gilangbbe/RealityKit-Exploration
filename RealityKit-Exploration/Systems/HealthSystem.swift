import RealityKit
import Foundation

class HealthSystem: System {
    static let query = EntityQuery(where: .has(HealthComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var healthComponent = entity.components[HealthComponent.self] else { continue }
            
            let previousHealth = healthComponent.currentHealth
            healthComponent.updateInvulnerability()
            entity.components[HealthComponent.self] = healthComponent
            
            // Notify about health changes
            if healthComponent.currentHealth != previousHealth {
                NotificationCenter.default.post(name: .healthChanged, object: healthComponent.currentHealth)
            }
            
            // Post notification if player died
            if healthComponent.isDead {
                NotificationCenter.default.post(name: .gameOver, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let gameOver = Notification.Name("gameOver")
    static let healthChanged = Notification.Name("healthChanged")
}
