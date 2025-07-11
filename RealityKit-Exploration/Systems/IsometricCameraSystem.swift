import RealityKit

class IsometricCameraSystem: System {
    static let query = EntityQuery(where: .has(IsometricCameraComponent.self))
    required init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let cameraComponent = entity.components[IsometricCameraComponent.self],
                  let target = cameraComponent.target else { continue }
            let targetPosition = target.position
            let desiredPosition = targetPosition + cameraComponent.offset
            let currentPosition = entity.position
            let newPosition = mix(currentPosition, desiredPosition, t: cameraComponent.smoothing)
            entity.position = newPosition
            if cameraComponent.lookAtTarget {
                entity.look(at: targetPosition, from: newPosition, relativeTo: nil)
            }
        }
    }
}
