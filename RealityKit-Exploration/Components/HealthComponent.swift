import RealityKit
import Foundation

struct HealthComponent: Component {
    var currentHealth: Int
    var maxHealth: Int
    var isInvulnerable: Bool = false
    var invulnerabilityDuration: TimeInterval = 1.0
    var lastDamageTime: Date = Date.distantPast
    
    init(maxHealth: Int = 3) {
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
    }
    
    var isDead: Bool {
        return currentHealth <= 0
    }
    
    mutating func takeDamage(_ damage: Int) {
        let now = Date()
        if !isInvulnerable || now.timeIntervalSince(lastDamageTime) >= invulnerabilityDuration {
            currentHealth = max(0, currentHealth - damage)
            lastDamageTime = now
            isInvulnerable = true
        }
    }
    
    mutating func updateInvulnerability() {
        let now = Date()
        if isInvulnerable && now.timeIntervalSince(lastDamageTime) >= invulnerabilityDuration {
            isInvulnerable = false
        }
    }
}
