import RealityKit
import Foundation

struct LootBoxAnimationSystem: System {
    static let query = EntityQuery(where: .has(LootBoxAnimationComponent.self) && .has(LootBoxComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var animationComp = entity.components[LootBoxAnimationComponent.self] else { continue }
            
            // Start animation if not already animating
            if !animationComp.isAnimating {
                Self.startLootBoxAnimation(for: entity, animationComponent: &animationComp)
                entity.components[LootBoxAnimationComponent.self] = animationComp
            }
        }
    }
    
    private static func startLootBoxAnimation(for lootBox: Entity, animationComponent: inout LootBoxAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = lootBox.findEntity(named: animationComponent.animationChildEntityName) else {
            print("Warning: Animation child entity '\(animationComponent.animationChildEntityName)' not found for LootBox")
            return
        }
        
        // Get available animations from the child entity
        let availableAnimations = animationEntity.availableAnimations
        
        // Check if animation exists at index 0
        guard GameConfig.lootBoxAnimationIndex < availableAnimations.count else {
            print("Warning: LootBox animation not found at index \(GameConfig.lootBoxAnimationIndex)")
            return
        }
        
        // Play animation at index 0
        let lootBoxAnimation = availableAnimations[GameConfig.lootBoxAnimationIndex]
        
        // Create looping animation controller
        let animationController = animationEntity.playAnimation(
            lootBoxAnimation.repeat(),
            transitionDuration: 0.1,
            startsPaused: false
        )
        
        // Store the controller and mark as animating
        animationComponent.animationController = animationController
        animationComponent.isAnimating = true
        
        print("Started LootBox animation on entity: \(animationComponent.animationChildEntityName)")
    }
    
    // Static method to start animation when LootBox is spawned
    static func startAnimation(for lootBox: Entity) {
        guard var animationComp = lootBox.components[LootBoxAnimationComponent.self] else {
            print("Warning: LootBoxAnimationComponent not found on LootBox entity")
            return
        }
        
        // Only start if not already animating
        if !animationComp.isAnimating {
            Self.startLootBoxAnimation(for: lootBox, animationComponent: &animationComp)
            lootBox.components[LootBoxAnimationComponent.self] = animationComp
        }
    }
    
    // Static method to stop animation when LootBox is collected/destroyed
    static func stopAnimation(for lootBox: Entity) {
        guard var animationComp = lootBox.components[LootBoxAnimationComponent.self] else { return }
        
        // Find the child entity and stop animations
        if let animationEntity = lootBox.findEntity(named: animationComp.animationChildEntityName) {
            animationEntity.stopAllAnimations()
        }
        
        // Update component state
        animationComp.isAnimating = false
        animationComp.animationController = nil
        lootBox.components[LootBoxAnimationComponent.self] = animationComp
        
        print("Stopped LootBox animation")
    }
}
