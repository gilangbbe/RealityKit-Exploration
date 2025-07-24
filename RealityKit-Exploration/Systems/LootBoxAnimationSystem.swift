import RealityKit
import Foundation

struct LootBoxAnimationSystem: System {
    static let query = EntityQuery(where: .has(LootBoxAnimationComponent.self) && .has(LootBoxComponent.self))
    static let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var animationComp = entity.components[LootBoxAnimationComponent.self] else { continue }
            
            // Handle enemy phasing interactions
            handleEnemyPhasing(lootBox: entity, animationComp: &animationComp, context: context, currentTime: currentTime)
            
            // Start default animation if not already animating and no enemies phasing
            if !animationComp.isAnimating && !animationComp.isEnemyPhasing {
                Self.startLootBoxAnimation(for: entity, animationComponent: &animationComp)
            }
            
            entity.components[LootBoxAnimationComponent.self] = animationComp
        }
    }
    
    private func handleEnemyPhasing(lootBox: Entity, animationComp: inout LootBoxAnimationComponent, context: SceneUpdateContext, currentTime: TimeInterval) {
        let enemies = context.entities(matching: Self.enemyQuery, updatingSystemWhen: .rendering)
        var currentlyPhasingEnemies: Set<String> = []
        
        // Check which enemies are currently phasing through the lootbox
        for enemy in enemies {
            // Use horizontal distance only (X and Z), ignore Y coordinate for phasing detection
            let lootBoxHorizontalPos = SIMD2<Float>(lootBox.position.x, lootBox.position.z)
            let enemyHorizontalPos = SIMD2<Float>(enemy.position.x, enemy.position.z)
            let horizontalDistance = simd_distance(lootBoxHorizontalPos, enemyHorizontalPos)
            let phasingRadius: Float = 0.15 // Distance threshold for phasing detection
            
            if horizontalDistance <= phasingRadius {
                let enemyId = enemy.id.description
                currentlyPhasingEnemies.insert(enemyId)
                print("🎯 Enemy \(enemyId) detected within phasing radius (horizontal distance: \(horizontalDistance))")
            }
        }
        
        // Check if phasing state changed
        let wasPhasing = animationComp.isEnemyPhasing
        let isNowPhasing = !currentlyPhasingEnemies.isEmpty
        
        // Handle phasing state transitions
        if !wasPhasing && isNowPhasing {
            // Started phasing - elevate lootbox
            onEnemyStartPhasing(lootBox: lootBox, animationComp: &animationComp, currentTime: currentTime)
        } else if wasPhasing && !isNowPhasing {
            // Stopped phasing - lower lootbox
            onEnemyStopPhasing(lootBox: lootBox, animationComp: &animationComp, currentTime: currentTime)
        }
        
        // Update the currently phasing enemies and state
        animationComp.enemiesCurrentlyPhasing = currentlyPhasingEnemies
        animationComp.isEnemyPhasing = isNowPhasing
        
        // If phasing just ended, transition back to default animation after lowering
        if wasPhasing && !isNowPhasing {
            // Delay a bit before returning to default animation to allow lowering animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(GameConfig.lootBoxPhasingAnimationDuration) + 0.1) {
                if var updatedAnimationComp = lootBox.components[LootBoxAnimationComponent.self],
                   !updatedAnimationComp.isEnemyPhasing && !updatedAnimationComp.isAnimatingPosition {
                    Self.startLootBoxAnimation(for: lootBox, animationComponent: &updatedAnimationComp)
                    lootBox.components[LootBoxAnimationComponent.self] = updatedAnimationComp
                }
            }
        }
    }
    
    private func onEnemyStartPhasing(lootBox: Entity, animationComp: inout LootBoxAnimationComponent, currentTime: TimeInterval) {
        print("🔺 Enemy started phasing through lootbox - elevating smoothly")
        animationComp.phasingStartTime = currentTime
        
        // Store original position if not already stored
        if animationComp.originalPosition == nil {
            animationComp.originalPosition = lootBox.position
        }
        
        // Elevate the lootbox (smooth position animation only)
        elevateLootBox(lootBox: lootBox, animationComp: animationComp)
    }
    
    private func onEnemyStopPhasing(lootBox: Entity, animationComp: inout LootBoxAnimationComponent, currentTime: TimeInterval) {
        print("🔻 All enemies stopped phasing through lootbox - lowering smoothly")
        print("   - isElevated: \(animationComp.isElevated)")
        print("   - isAnimatingPosition: \(animationComp.isAnimatingPosition)")
        print("   - originalPosition: \(animationComp.originalPosition)")
        
        // Lower the lootbox back to original position (smooth position animation only)
        lowerLootBox(lootBox: lootBox, animationComp: animationComp)
    }
    
    private func elevateLootBox(lootBox: Entity, animationComp: LootBoxAnimationComponent) {
        guard let originalPos = animationComp.originalPosition, 
              !animationComp.isElevated, 
              !animationComp.isAnimatingPosition else { return }
        
        let elevatedPosition = SIMD3<Float>(
            originalPos.x,
            originalPos.y + GameConfig.lootBoxPhasingHeightOffset,
            originalPos.z
        )
        
        // Update the component directly on the entity
        var updatedComp = animationComp
        updatedComp.isAnimatingPosition = true
        lootBox.components[LootBoxAnimationComponent.self] = updatedComp
        
        // Animate the position change smoothly
        animateLootBoxPosition(lootBox: lootBox, to: elevatedPosition) { [weak lootBox] in
            guard let lootBox = lootBox else { return }
            if var updatedAnimationComp = lootBox.components[LootBoxAnimationComponent.self] {
                updatedAnimationComp.isElevated = true
                updatedAnimationComp.isAnimatingPosition = false
                lootBox.components[LootBoxAnimationComponent.self] = updatedAnimationComp
            }
        }
        
        print("Elevating lootbox by \(GameConfig.lootBoxPhasingHeightOffset) units")
    }
    
    private func lowerLootBox(lootBox: Entity, animationComp: LootBoxAnimationComponent) {
        print("🔽 lowerLootBox called")
        print("   - originalPosition: \(animationComp.originalPosition)")
        print("   - isElevated: \(animationComp.isElevated)")
        print("   - isAnimatingPosition: \(animationComp.isAnimatingPosition)")
        
        guard let originalPos = animationComp.originalPosition else {
            print("❌ Cannot lower: originalPosition is nil")
            return
        }
        
        guard animationComp.isElevated else {
            print("❌ Cannot lower: not elevated")
            return
        }
        
        guard !animationComp.isAnimatingPosition else {
            print("❌ Cannot lower: already animating position")
            return
        }
        
        print("✅ Starting lower animation to position: \(originalPos)")
        
        // Update the component directly on the entity
        var updatedComp = animationComp
        updatedComp.isAnimatingPosition = true
        lootBox.components[LootBoxAnimationComponent.self] = updatedComp
        
        // Animate back to original position smoothly
        animateLootBoxPosition(lootBox: lootBox, to: originalPos) { [weak lootBox] in
            guard let lootBox = lootBox else { return }
            if var updatedAnimationComp = lootBox.components[LootBoxAnimationComponent.self] {
                updatedAnimationComp.isElevated = false
                updatedAnimationComp.isAnimatingPosition = false
                lootBox.components[LootBoxAnimationComponent.self] = updatedAnimationComp
            }
        }
        
        print("Lowering lootbox back to original position")
    }
    
    private func animateLootBoxPosition(lootBox: Entity, to targetPosition: SIMD3<Float>, completion: @escaping () -> Void) {
        let duration = TimeInterval(GameConfig.lootBoxPhasingAnimationDuration)
        let startPosition = lootBox.position
        let startTime = Date().timeIntervalSince1970
        
        // Create smooth interpolated animation using DispatchQueue
        let animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let currentTime = Date().timeIntervalSince1970
            let elapsed = currentTime - startTime
            let progress = min(elapsed / duration, 1.0)
            
            // Smooth easing function (ease-out)
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            
            // Interpolate position
            let currentPosition = SIMD3<Float>(
                startPosition.x + (targetPosition.x - startPosition.x) * Float(easedProgress),
                startPosition.y + (targetPosition.y - startPosition.y) * Float(easedProgress),
                startPosition.z + (targetPosition.z - startPosition.z) * Float(easedProgress)
            )
            
            lootBox.position = currentPosition
            
            // Check if animation is complete
            if progress >= 1.0 {
                timer.invalidate()
                lootBox.position = targetPosition // Ensure exact final position
                completion()
            }
        }
        
        // Store timer reference (simplified - in production you'd want better timer management)
        print("Started smooth position animation to y: \(targetPosition.y)")
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
        
        print("Started LootBox default animation on entity: \(animationComponent.animationChildEntityName)")
    }
    
    private static func startLootBoxUpAnimation(for lootBox: Entity, animationComponent: inout LootBoxAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = lootBox.findEntity(named: animationComponent.animationChildEntityName) else {
            print("Warning: Animation child entity '\(animationComponent.animationChildEntityName)' not found for LootBox UP animation")
            return
        }
        
        // Get available animations from the child entity
        let availableAnimations = animationEntity.availableAnimations
        
        // Check if UP animation exists at index 1
        guard GameConfig.lootBoxUpAnimationIndex < availableAnimations.count else {
            print("Warning: LootBox UP animation not found at index \(GameConfig.lootBoxUpAnimationIndex)")
            return
        }
        
        // Stop current animation
        animationComponent.animationController?.stop()
        
        // Play UP animation at index 1 (once, not looped)
        let upAnimation = availableAnimations[GameConfig.lootBoxUpAnimationIndex]
        let animationController = animationEntity.playAnimation(
            upAnimation,
            transitionDuration: 0.1,
            startsPaused: false
        )
        
        // Store the controller and mark as animating
        animationComponent.animationController = animationController
        animationComponent.isAnimating = true
        
        print("Started LootBox UP animation at index \(GameConfig.lootBoxUpAnimationIndex)")
    }
    
    private static func startLootBoxDownAnimation(for lootBox: Entity, animationComponent: inout LootBoxAnimationComponent) {
        // Find the child entity containing animations
        guard let animationEntity = lootBox.findEntity(named: animationComponent.animationChildEntityName) else {
            print("Warning: Animation child entity '\(animationComponent.animationChildEntityName)' not found for LootBox DOWN animation")
            return
        }
        
        // Get available animations from the child entity
        let availableAnimations = animationEntity.availableAnimations
        
        // Check if DOWN animation exists at index 2
        guard GameConfig.lootBoxDownAnimationIndex < availableAnimations.count else {
            print("Warning: LootBox DOWN animation not found at index \(GameConfig.lootBoxDownAnimationIndex)")
            return
        }
        
        // Stop current animation
        animationComponent.animationController?.stop()
        
        // Play DOWN animation at index 2 (once, not looped)
        let downAnimation = availableAnimations[GameConfig.lootBoxDownAnimationIndex]
        let animationController = animationEntity.playAnimation(
            downAnimation,
            transitionDuration: 0.1,
            startsPaused: false
        )
        
        // Store the controller and mark as animating
        animationComponent.animationController = animationController
        animationComponent.isAnimating = true
        
        print("Started LootBox DOWN animation at index \(GameConfig.lootBoxDownAnimationIndex)")
    }
    
    // Static method to start animation when LootBox is spawned
    static func startAnimation(for lootBox: Entity) {
        guard var animationComp = lootBox.components[LootBoxAnimationComponent.self] else {
            print("Warning: LootBoxAnimationComponent not found on LootBox entity")
            return
        }
        
        // Store the original position for height adjustments
        if animationComp.originalPosition == nil {
            animationComp.originalPosition = lootBox.position
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
