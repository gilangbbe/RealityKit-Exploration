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
        
        // Get arena bounds
        let cubeBounds = surface.visualBounds(relativeTo: nil)
        let cubeCenter = surface.position
        let cubeTopY = cubeCenter.y + (cubeBounds.max.y - cubeBounds.min.y) / 2.0
        
        // Calculate safe spawn area (slightly inside arena edges)
        let safeMargin: Float = 0.3
        let arenaMinX = cubeCenter.x + cubeBounds.min.x + safeMargin
        let arenaMaxX = cubeCenter.x + cubeBounds.max.x - safeMargin
        let arenaMinZ = cubeCenter.z + cubeBounds.min.z + safeMargin
        let arenaMaxZ = cubeCenter.z + cubeBounds.max.z - safeMargin
        
        // Use efficient grid-based position finding
        let spawnPosition = findOptimalSpawnPosition(
            arenaMinX: arenaMinX,
            arenaMaxX: arenaMaxX,
            arenaMinZ: arenaMinZ,
            arenaMaxZ: arenaMaxZ,
            spawnY: cubeTopY + 0.1
        )
        
        lootBox.position = spawnPosition
        
        // Add LootBox component with random power-up
        let lootBoxComponent = LootBoxComponent()
        lootBox.components.set(lootBoxComponent)
        
        // Add LootBox animation component
        let animationComponent = LootBoxAnimationComponent()
        lootBox.components.set(animationComponent)
        
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
        
        // Start animation after adding to scene
        LootBoxAnimationSystem.startAnimation(for: lootBox)
    }
    
    // Efficient grid-based position finding to avoid performance drops
    private func findOptimalSpawnPosition(
        arenaMinX: Float,
        arenaMaxX: Float,
        arenaMinZ: Float,
        arenaMaxZ: Float,
        spawnY: Float
    ) -> SIMD3<Float> {
        guard let scene = scene else {
            // Fallback to random position if no scene available
            return SIMD3<Float>(
                Float.random(in: arenaMinX...arenaMaxX),
                spawnY,
                Float.random(in: arenaMinZ...arenaMaxZ)
            )
        }
        
        // Create a grid-based approach for efficient position finding
        let gridSize: Float = GameConfig.lootBoxMinSpawnDistance
        let gridCols = Int((arenaMaxX - arenaMinX) / gridSize) + 1
        let gridRows = Int((arenaMaxZ - arenaMinZ) / gridSize) + 1
        
        // Build a set of occupied grid positions for O(1) lookup
        var occupiedPositions = Set<String>()
        
        // Mark positions occupied by existing loot boxes
        let existingLootBoxes = Array(scene.performQuery(Self.lootBoxQuery))
        for lootBox in existingLootBoxes {
            let gridX = Int((lootBox.position.x - arenaMinX) / gridSize)
            let gridZ = Int((lootBox.position.z - arenaMinZ) / gridSize)
            // Mark the grid cell and adjacent cells as occupied
            for dx in -1...1 {
                for dz in -1...1 {
                    let adjX = gridX + dx
                    let adjZ = gridZ + dz
                    if adjX >= 0 && adjX < gridCols && adjZ >= 0 && adjZ < gridRows {
                        occupiedPositions.insert("\(adjX),\(adjZ)")
                    }
                }
            }
        }
        
        // Mark positions occupied by players (larger exclusion zone)
        let players = Array(scene.performQuery(Self.playerQuery))
        let playerExclusionRadius = GameConfig.lootBoxMinPlayerDistance
        for player in players {
            let gridX = Int((player.position.x - arenaMinX) / gridSize)
            let gridZ = Int((player.position.z - arenaMinZ) / gridSize)
            let exclusionCells = Int(playerExclusionRadius / gridSize) + 1
            // Mark larger area around player as occupied
            for dx in -exclusionCells...exclusionCells {
                for dz in -exclusionCells...exclusionCells {
                    let adjX = gridX + dx
                    let adjZ = gridZ + dz
                    if adjX >= 0 && adjX < gridCols && adjZ >= 0 && adjZ < gridRows {
                        occupiedPositions.insert("\(adjX),\(adjZ)")
                    }
                }
            }
        }
        
        // Find available positions
        var availablePositions: [SIMD3<Float>] = []
        for row in 0..<gridRows {
            for col in 0..<gridCols {
                let key = "\(col),\(row)"
                if !occupiedPositions.contains(key) {
                    let x = arenaMinX + Float(col) * gridSize + gridSize * 0.5
                    let z = arenaMinZ + Float(row) * gridSize + gridSize * 0.5
                    // Add some randomness within the grid cell
                    let randomOffsetX = Float.random(in: -gridSize*0.3...gridSize*0.3)
                    let randomOffsetZ = Float.random(in: -gridSize*0.3...gridSize*0.3)
                    let position = SIMD3<Float>(
                        min(max(x + randomOffsetX, arenaMinX), arenaMaxX),
                        spawnY,
                        min(max(z + randomOffsetZ, arenaMinZ), arenaMaxZ)
                    )
                    availablePositions.append(position)
                }
            }
        }
        
        // Return random position from available positions, or fallback
        if !availablePositions.isEmpty {
            return availablePositions.randomElement()!
        } else {
            // If no grid positions available, use fallback with minimal checks
            return findFallbackPosition(
                arenaMinX: arenaMinX,
                arenaMaxX: arenaMaxX,
                arenaMinZ: arenaMinZ,
                arenaMaxZ: arenaMaxZ,
                spawnY: spawnY
            )
        }
    }
    
    // Lightweight fallback position finder
    private func findFallbackPosition(
        arenaMinX: Float,
        arenaMaxX: Float,
        arenaMinZ: Float,
        arenaMaxZ: Float,
        spawnY: Float
    ) -> SIMD3<Float> {
        // Try only 3 quick attempts, then give up and place anywhere
        for _ in 0..<3 {
            let x = Float.random(in: arenaMinX...arenaMaxX)
            let z = Float.random(in: arenaMinZ...arenaMaxZ)
            let position = SIMD3<Float>(x, spawnY, z)
            
            // Quick check - only verify against nearest entities
            if isPositionQuickCheck(position) {
                return position
            }
        }
        
        // Final fallback - just place anywhere
        return SIMD3<Float>(
            Float.random(in: arenaMinX...arenaMaxX),
            spawnY,
            Float.random(in: arenaMinZ...arenaMaxZ)
        )
    }
    
    // Quick position check with minimal performance impact
    private func isPositionQuickCheck(_ position: SIMD3<Float>) -> Bool {
        guard let scene = scene else { return true }
        
        let minDistance = GameConfig.lootBoxMinSpawnDistance * 0.5 // Reduced requirement for fallback
        
        // Only check closest entities to avoid performance hit
        let existingLootBoxes = Array(scene.performQuery(Self.lootBoxQuery))
        let maxCheckCount = min(existingLootBoxes.count, 5) // Limit checks to 5 closest
        
        for (index, lootBox) in existingLootBoxes.enumerated() {
            if index >= maxCheckCount { break }
            let distance = simd_distance(position, lootBox.position)
            if distance < minDistance {
                return false
            }
        }
        
        return true
    }
    
    private func handleLootBoxCollection(context: SceneUpdateContext, currentTime: TimeInterval) {
        let players = context.scene.performQuery(Self.playerQuery)
        let lootBoxes = context.scene.performQuery(Self.lootBoxQuery)
        
        for player in players {
            for lootBox in lootBoxes {
                guard let lootBoxComp = lootBox.components[LootBoxComponent.self] else { continue }
                
                // Check if loot box is expired
                if lootBoxComp.isExpired(currentTime: currentTime) {
                    LootBoxAnimationSystem.stopAnimation(for: lootBox)
                    lootBox.removeFromParent()
                    continue
                }
                
                // Check collection distance
                let distance = simd_distance(player.position, lootBox.position)
                if distance <= GameConfig.lootBoxCollectionRadius {
                    collectLootBox(player: player, lootBox: lootBox, powerUpType: lootBoxComp.powerUpType, context: context, currentTime: currentTime)
                    LootBoxAnimationSystem.stopAnimation(for: lootBox)
                    lootBox.removeFromParent()
                }
            }
        }
    }
    
    private func collectLootBox(player: Entity, lootBox: Entity, powerUpType: PowerUpType, context: SceneUpdateContext, currentTime: TimeInterval) {
        
        // Play appropriate particle animation based on power-up type
        switch powerUpType {
        case .timeSlow:
            playTimeSlowParticleEffect(at: player)
        case .shockwave:
            playShockwaveParticleEffect(at: player)
        }
        
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
        // Get player's upgraded slow duration
        let progression = player.components[PlayerProgressionComponent.self]
        let slowDuration = progression?.currentSlowDuration ?? TimeInterval(GameConfig.timeSlowDuration)
        
        powerUpComp.activateTimeSlow(currentTime: currentTime, duration: slowDuration)
        
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
        
        // Notify UI about time slow activation
        DispatchQueue.main.async {
            let timeSlowInfo: [String: Any] = [
                "endTime": currentTime + slowDuration,
                "duration": slowDuration
            ]
            NotificationCenter.default.post(name: .timeSlowActivated, object: timeSlowInfo)
        }
        
    }
    
    private func activateShockwave(player: Entity, context: SceneUpdateContext) {
        // Get player's upgraded shockwave force
        let progression = player.components[PlayerProgressionComponent.self]
        let shockwaveForce = progression?.currentShockwaveForce ?? GameConfig.shockwaveForce
        
        let enemies = context.scene.performQuery(Self.enemyQuery)
        
        // Trigger shockwave animation (index 4) on player
        PlayerAnimationSystem.triggerShockwaveAnimation(for: player, currentTime: Date().timeIntervalSince1970)
        
        for enemy in enemies {
            let distance = simd_distance(player.position, enemy.position)
            if distance <= GameConfig.shockwaveRadius {
                // Calculate push direction away from player
                let pushDirection = normalize(enemy.position - player.position)
                let pushForce = pushDirection * shockwaveForce
                
                // Apply force to enemy physics
                if var physics = enemy.components[PhysicsMovementComponent.self] {
                    physics.velocity += pushForce
                    enemy.components[PhysicsMovementComponent.self] = physics
                }
            }
        }
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
                                
            }
        }
    }
    
    // MARK: - Particle Effects
    
    private func playTimeSlowParticleEffect(at player: Entity) {
        Task {
            do {
                // Load the timeslowParticle scene
                if let particleScene = try? await Entity(named: "timeslowParticle", in: arenaBundle) {
                    // Position the particle effect around the player's location
                    var effectPosition = player.position
                    effectPosition.y += 0.2 // Slightly above player
                    particleScene.position = effectPosition
                    
                    // Scale the effect if needed
                    particleScene.scale = SIMD3<Float>(1.0, 1.0, 1.0)
                    
                    // Add the particle effect to the player's parent (scene)
                    if let playerParent = player.parent {
                        playerParent.addChild(particleScene)
                        
                        // Auto-remove the particle effect after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            particleScene.removeFromParent()
                        }
                    }
                    
                } else {
                    print("Warning: Could not load timeslowParticle scene from Arena bundle")
                }
            } catch {
                print("Error loading timeslowParticle scene: \(error)")
            }
        }
    }
    
    private func playShockwaveParticleEffect(at player: Entity) {
        Task {
            do {
                // Load the shockwaveParticle scene
                if let particleScene = try? await Entity(named: "shockwaveParticle", in: arenaBundle) {
                    // Position the particle effect around the player's location
                    var effectPosition = player.position
                    effectPosition.y += 0.1 // Slightly above ground for shockwave effect
                    particleScene.position = effectPosition
                    
                    // Scale the effect if needed
                    particleScene.scale = SIMD3<Float>(1.0, 1.0, 1.0)
                    
                    // Add the particle effect to the player's parent (scene)
                    if let playerParent = player.parent {
                        playerParent.addChild(particleScene)
                        
                        // Auto-remove the particle effect after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            particleScene.removeFromParent()
                        }
                    }
                    
                } else {
                    print("Warning: Could not load shockwaveParticle scene from Arena bundle")
                }
            } catch {
                print("Error loading shockwaveParticle scene: \(error)")
            }
        }
    }
}

// Notification for UI updates
extension Notification.Name {
    static let powerUpCollected = Notification.Name("PowerUpCollected")
    static let timeSlowActivated = Notification.Name("TimeSlowActivated")
}
