import RealityKit

class MovementSystem: System {
    static let query = EntityQuery(where: .has(MovementComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var movement = entity.components[MovementComponent.self] else { continue }
            if movement.isMoving {
                let deltaTime = Float(context.deltaTime)
                let displacement = movement.velocity * movement.speed * deltaTime
                var newPosition = entity.position + displacement
                if let constrainedEntity = movement.constrainedTo {
                    newPosition = constrainToCubeSurface(newPosition, cube: constrainedEntity, offset: movement.surfaceOffset)
                }
                entity.position = newPosition
            }
            entity.components[MovementComponent.self] = movement
        }
    }
    
    private func constrainToCubeSurface(_ position: SIMD3<Float>, cube: Entity, offset: Float) -> SIMD3<Float> {
        let cubePosition = cube.position
        let cubeScale = cube.scale
        let cubeSize = cubeScale.x
        let halfSize = cubeSize / 2.0
        let minX = cubePosition.x - halfSize
        let maxX = cubePosition.x + halfSize
        let minZ = cubePosition.z - halfSize
        let maxZ = cubePosition.z + halfSize
        let constrainedX = max(minX, min(maxX, position.x))
        let constrainedZ = max(minZ, min(maxZ, position.z))
        let topSurfaceY = cubePosition.y + halfSize + offset
        return SIMD3<Float>(constrainedX, topSurfaceY, constrainedZ)
    }
}
