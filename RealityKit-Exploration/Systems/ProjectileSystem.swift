import RealityKit
import Foundation

class ProjectileSystem: System {
    static let query = EntityQuery(where: .has(ProjectileComponent.self))
    required init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var projectile = entity.components[ProjectileComponent.self] else { continue }
            if entity.components.has(DestroyableComponent.self) { continue }
            let currentTime = Date()
            let age = currentTime.timeIntervalSince(projectile.spawnTime)
            if age > projectile.lifetime {
                entity.components.set(DestroyableComponent(shouldDestroy: true))
                continue
            }
            let oldPosition = entity.position
            let deltaTime = Float(context.deltaTime)
            let displacement = projectile.velocity * projectile.speed * deltaTime
            let newPosition = oldPosition + displacement
            entity.position = newPosition
            if checkProjectileCollisions(projectile: entity, oldPosition: oldPosition, newPosition: newPosition, in: context) {
                continue
            }
            entity.components[ProjectileComponent.self] = projectile
        }
    }
    private func checkProjectileCollisions(projectile: Entity, oldPosition: SIMD3<Float>, newPosition: SIMD3<Float>, in context: SceneUpdateContext) -> Bool {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        for enemy in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) {
            if enemy.components.has(DestroyableComponent.self) { continue }
            let enemyPosition = enemy.position
            let enemyBounds = enemy.visualBounds(relativeTo: enemy.parent)
            let extentX = (enemyBounds.max.x - enemyBounds.min.x) / 2.0
            let extentY = (enemyBounds.max.y - enemyBounds.min.y) / 2.0
            let extentZ = (enemyBounds.max.z - enemyBounds.min.z) / 2.0
            let enemyRadius = max(extentX, extentY, extentZ)
            if lineIntersectsSphere(lineStart: oldPosition, lineEnd: newPosition, sphereCenter: enemyPosition, sphereRadius: enemyRadius + 0.05) {
                projectile.components.set(DestroyableComponent(shouldDestroy: true))
                enemy.components.set(DestroyableComponent(shouldDestroy: true))
                print("Enemy hit! (radius: \(enemyRadius), pos: \(enemyPosition))")
                return true
            }
        }
        return false
    }
    private func lineIntersectsSphere(lineStart: SIMD3<Float>, lineEnd: SIMD3<Float>, sphereCenter: SIMD3<Float>, sphereRadius: Float) -> Bool {
        let lineDirection = lineEnd - lineStart
        let lineLength = length(lineDirection)
        if lineLength < 0.001 {
            return length(lineStart - sphereCenter) <= sphereRadius
        }
        let normalizedDirection = lineDirection / lineLength
        let toSphere = sphereCenter - lineStart
        let projectionLength = dot(toSphere, normalizedDirection)
        let clampedProjection = max(0, min(lineLength, projectionLength))
        let closestPoint = lineStart + normalizedDirection * clampedProjection
        let distanceSquared = length_squared(closestPoint - sphereCenter)
        return distanceSquared <= (sphereRadius * sphereRadius)
    }
}
