import RealityKit
import Foundation

class AutoShootSystem: System {
    static let query = EntityQuery(where: .has(AutoShootComponent.self))
    required init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var autoShoot = entity.components[AutoShootComponent.self] else { continue }
            guard autoShoot.isEnabled else { continue }
            guard let movement = entity.components[MovementComponent.self] else { continue }
            let shouldShoot = !autoShoot.shootWhileMoving || movement.isMoving
            guard shouldShoot else { continue }
            let currentTime = Date()
            let timeSinceLastShot = currentTime.timeIntervalSince(autoShoot.lastShootTime)
            if timeSinceLastShot >= autoShoot.shootInterval {
                let shootDirection = getShootDirection(from: movement)
                createProjectile(from: entity, direction: shootDirection, in: context)
                autoShoot.lastShootTime = currentTime
            }
            entity.components[AutoShootComponent.self] = autoShoot
        }
    }
    private func getShootDirection(from movement: MovementComponent) -> SIMD3<Float> {
        if movement.isMoving && length(movement.velocity) > 0.1 {
            return normalize(movement.velocity)
        }
        return [0, 0, -1]
    }
    private func createProjectile(from shooter: Entity, direction: SIMD3<Float>, in context: SceneUpdateContext) {
        let projectile = Entity()
        let sphereMesh = MeshResource.generateSphere(radius: 0.02)
        var material = SimpleMaterial()
        material.color = .init(tint: .yellow, texture: nil)
        material.roughness = 0.1
        material.metallic = 0.0
        projectile.components.set(ModelComponent(mesh: sphereMesh, materials: [material]))
        let shooterBounds = shooter.visualBounds(relativeTo: shooter.parent)
        let shooterPosition = shooter.position
        let capsuleRadius = (shooterBounds.max.x - shooterBounds.min.x) / 2.0
        let capsuleHeight = shooterBounds.max.y - shooterBounds.min.y
        let spawnOffset = direction * (capsuleRadius + 0.1)
        let heightOffset = SIMD3<Float>(0, capsuleHeight * 0.1, 0)
        let spawnPosition = shooterPosition + spawnOffset + heightOffset
        projectile.position = spawnPosition
        var projectileComponent = ProjectileComponent()
        projectileComponent.velocity = direction
        projectileComponent.speed = 2.0
        projectileComponent.lifetime = 3.0
        projectileComponent.damage = 1
        projectileComponent.spawnTime = Date()
        projectile.components.set(projectileComponent)
        shooter.parent?.addChild(projectile)
    }
}
