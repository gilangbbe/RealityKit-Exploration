import RealityKit
import Foundation
import Arena
import QuartzCore

struct LootBoxSystem: System {
    static let query = EntityQuery(where: .has(LootBoxSpawnerComponent.self))
    static let lootBoxQuery = EntityQuery(where: .has(LootBoxComponent.self))
    static let playerQuery = EntityQuery(where: .has(PhysicsMovementComponent.self) && .has(GameStateComponent.self))
    static let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    
    private var scene: RealityKit.Scene?
    
    init(scene: RealityKit.Scene) {
        self.scene = scene
    }
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        let currentTime = CACurrentMediaTime()
        
        // Handle LootBox spawning
        handleLootBoxSpawning(context: context, currentTime: currentTime)
        
        // Handle LootBox collection and expiration
        handleLootBoxCollection(context: context, currentTime: currentTime)
        
        // Handle active power-up effects
        handlePowerUpEffects(context: context, currentTime: currentTime)
    }
    
    private func handleLootBoxSpawning(context: SceneUpdateContext, currentTime: TimeInterval) {
        for entity in context.scene.performQuery(Self.query) {
            guard var spawner = entity.components[LootBoxSpawnerComponent.self],
                  let surface = spawner.spawnSurface,
                  let prefab = spawner.lootBoxPrefab else { continue }
            
            if spawner.shouldSpawn(currentTime: currentTime) {
                spawnLootBox(surface: surface, prefab: prefab, container: spawner.lootBoxContainer)
                spawner.markSpawned(currentTime: currentTime)
                entity.components[LootBoxSpawnerComponent.self] = spawner
            }
        }
    }
    
    private func spawnLootBox(surface: Entity, prefab: Entity, container: Entity?) {
        let lootBox = prefab.clone(recursive: true)
        
        // Get random position on arena surface
        let cubeBounds = surface.visualBounds(relativeTo: nil)
        let cubeCenter = surface.position
        let cubeTopY = cubeCenter.y + (cubeBounds.max.y - cubeBounds.min.y) / 2.0
        
        // Calculate safe spawn area (slightly inside arena edges)
        let safeMargin: Float = 0.3
        let arenaMinX = cubeCenter.x + cubeBounds.min.x + safeMargin
        let arenaMaxX = cubeCenter.x + cubeBounds.max.x - safeMargin
        let arenaMinZ = cubeCenter.z + cubeBounds.min.z + safeMargin
        let arenaMaxZ = cubeCenter.z + cubeBounds.max.z - safeMargin
        
        let randomX = Float.random(in: arenaMinX...arenaMaxX)
        let randomZ = Float.random(in: arenaMinZ...arenaMaxZ)
        let spawnY = cubeTopY + 0.1 // Slightly above surface
        
        lootBox.position = SIMD3<Float>(randomX, spawnY, randomZ)
        
        // Add LootBox component with random power-up
        let lootBoxComponent = LootBoxComponent()
        lootBox.components.set(lootBoxComponent)
        
        // Add to container entity to prevent affecting arena bounds and camera
        if let container = container {
            container.addChild(lootBox)
        } else {
            // Fallback: add to scene root if container not found
            if let sceneRoot = surface.parent {
                sceneRoot.addChild(lootBox)
            } else {
                surface.addChild(lootBox)
            }
        }
        
        print("Spawned LootBox with power-up: \(lootBoxComponent.powerUpType.name)")
    }
    
    private func handleLootBoxCollection(context: SceneUpdateContext, currentTime: TimeInterval) {
        let players = context.scene.performQuery(Self.playerQuery)
        let lootBoxes = context.scene.performQuery(Self.lootBoxQuery)
        
        for player in players {
            for lootBox in lootBoxes {
                guard let lootBoxComp = lootBox.components[LootBoxComponent.self] else { continue }
                
                // Check if loot box is expired
                if lootBoxComp.isExpired(currentTime: currentTime) {
                    lootBox.removeFromParent()
                    continue
                }
                
                // Check collection distance
                let distance = simd_distance(player.position, lootBox.position)
                if distance <= GameConfig.lootBoxCollectionRadius {
                    collectLootBox(player: player, lootBox: lootBox, powerUpType: lootBoxComp.powerUpType, context: context, currentTime: currentTime)
                    lootBox.removeFromParent()
                }
            }
        }
    }
    
    private func collectLootBox(player: Entity, lootBox: Entity, powerUpType: PowerUpType, context: SceneUpdateContext, currentTime: TimeInterval) {
        print("Player collected LootBox: \(powerUpType.name)")
        
        // Play particle animation around player
        playKeyApparitionEffect(at: player)
        
        // Get or create PowerUpComponent
        var powerUpComp = player.components[PowerUpComponent.self] ?? PowerUpComponent()
        
        switch powerUpType {
        case .timeSlow:
            activateTimeSlow(player: player, powerUpComp: &powerUpComp, context: context, currentTime: currentTime)
        case .shockwave:
            activateShockwave(player: player, context: context)
        }
        
        player.components.set(powerUpComp)
        
        // Notify UI about power-up collection
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .powerUpCollected, object: powerUpType.name)
        }
    }
    
    private func activateTimeSlow(player: Entity, powerUpComp: inout PowerUpComponent, context: SceneUpdateContext, currentTime: TimeInterval) {
        powerUpComp.activateTimeSlow(currentTime: currentTime)
        
        // Apply time slow effect to all enemies immediately
        let enemies = context.scene.performQuery(Self.enemyQuery)
        for enemy in enemies {
            if var enemyComp = enemy.components[EnemyCapsuleComponent.self] {
                if powerUpComp.originalEnemySpeedMultiplier == 1.0 {
                    powerUpComp.originalEnemySpeedMultiplier = enemyComp.speed
                }
                enemyComp.speed *= GameConfig.timeSlowMultiplier
                enemy.components[EnemyCapsuleComponent.self] = enemyComp
            }
        }
        
        print("Time Slow activated for \(GameConfig.timeSlowDuration) seconds")
    }
    
    private func activateShockwave(player: Entity, context: SceneUpdateContext) {
        let enemies = context.scene.performQuery(Self.enemyQuery)
        
        // Trigger shockwave animation (index 4) on player
        PlayerAnimationSystem.triggerShockwaveAnimation(for: player, currentTime: Date().timeIntervalSince1970)
        
        for enemy in enemies {
            let distance = simd_distance(player.position, enemy.position)
            if distance <= GameConfig.shockwaveRadius {
                // Calculate push direction away from player
                let pushDirection = normalize(enemy.position - player.position)
                let pushForce = pushDirection * GameConfig.shockwaveForce
                
                // Apply force to enemy physics
                if var physics = enemy.components[PhysicsMovementComponent.self] {
                    physics.velocity += pushForce
                    enemy.components[PhysicsMovementComponent.self] = physics
                }
            }
        }
        
        print("Shockwave activated - pushed enemies within \(GameConfig.shockwaveRadius) radius")
    }
    
    private func handlePowerUpEffects(context: SceneUpdateContext, currentTime: TimeInterval) {
        let players = context.scene.performQuery(Self.playerQuery)
        
        for player in players {
            guard var powerUpComp = player.components[PowerUpComponent.self] else { continue }
            
            // Check if time slow effect has ended
            if !powerUpComp.isTimeSlowActive(currentTime: currentTime) && powerUpComp.originalEnemySpeedMultiplier != 1.0 {
                // Restore enemy speeds
                let enemies = context.scene.performQuery(Self.enemyQuery)
                for enemy in enemies {
                    if var enemyComp = enemy.components[EnemyCapsuleComponent.self] {
                        enemyComp.speed = powerUpComp.originalEnemySpeedMultiplier
                        enemy.components[EnemyCapsuleComponent.self] = enemyComp
                    }
                }
                
                // Reset the multiplier
                powerUpComp.originalEnemySpeedMultiplier = 1.0
                player.components[PowerUpComponent.self] = powerUpComp
                
                print("Time Slow effect ended - enemy speeds restored")
            }
        }
    }
    
    // MARK: - Particle Effects
    
    private func playKeyApparitionEffect(at player: Entity) {
        Task {
            do {
                // Load the key_apparition particle scene
                if let particleScene = try? await Entity(named: "key_apparition", in: arenaBundle) {
                    // Position the particle effect around the player's location
                    // Place it slightly above the player to be more visible
                    var effectPosition = player.position
                    effectPosition.y += 0.2 // Slightly above player
                    particleScene.position = effectPosition
                    
                    // Scale the effect if needed (adjust as needed for your particle system)
                    particleScene.scale = SIMD3<Float>(1.0, 1.0, 1.0)
                    
                    // Add the particle effect to the player's parent (scene)
                    if let playerParent = player.parent {
                        playerParent.addChild(particleScene)
                        
                        // Auto-remove the particle effect after a delay
                        // Adjust duration based on your particle animation length
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            particleScene.removeFromParent()
                        }
                    }
                    
                    print("Key apparition particle effect played around player")
                } else {
                    print("Warning: Could not load key_apparition particle scene from Arena bundle")
                }
            } catch {
                print("Error loading key_apparition particle scene: \(error)")
            }
        }
    }
}

// Notification for UI updates
extension Notification.Name {
    static let powerUpCollected = Notification.Name("PowerUpCollected")
}
