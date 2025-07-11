import RealityKit

class DestroySystem: System {
    static let query = EntityQuery(where: .has(DestroyableComponent.self))
    required init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let destroyable = entity.components[DestroyableComponent.self] else { continue }
            if destroyable.shouldDestroy {
                entity.removeFromParent()
            }
        }
    }
}
