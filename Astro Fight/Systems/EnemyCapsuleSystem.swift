import RealityKit
import Foundation

import RealityKit
import Foundation

public class EnemyCapsuleSystem: System {
    static let query = EntityQuery(where: .has(EnemyCapsuleComponent.self))
    
    private var cachedEnemies: [Entity] = []
    private var lastCacheUpdate: TimeInterval = 0
    private let cacheUpdateInterval: TimeInterval = 0.1 // 100ms
    private var frameCounter: Int = 0
    
    // Spatial partitioning for collision optimization
    private var spatialGrid: [SIMD2<Int>: [Entity]] = [:]
    private let gridSize: Float = 4.0
    
    public init() {
        // Listen for enemy defeat notifications to immediately clean cache
        NotificationCenter.default.addObserver(
            forName: Notification.Name("enemyDefeated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let defeatedEnemyId = notification.userInfo?["enemyId"] as? Entity.ID {
                self?.removeEnemyFromCache(id: defeatedEnemyId)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func removeEnemyFromCache(id: Entity.ID) {
        // Immediately remove defeated enemy from cache
        cachedEnemies.removeAll { $0.id == id }
        
        // Clean up spatial grid
        for (gridPos, enemies) in spatialGrid {
            let filteredEnemies = enemies.filter { $0.id != id }
            if filteredEnemies.isEmpty {
                spatialGrid.removeValue(forKey: gridPos)
            } else if filteredEnemies.count != enemies.count {
                spatialGrid[gridPos] = filteredEnemies
            }
        }
    }
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        // Record frame for performance monitoring
        PerformanceMonitor.shared.recordFrame()
        
        frameCounter += 1
        let currentTime = Date().timeIntervalSince1970
        
        // Update cached enemies less frequently for performance
        if currentTime - lastCacheUpdate > cacheUpdateInterval {
            updateEnemyCache(context: context)
            lastCacheUpdate = currentTime
            
            // Update performance monitor with current enemy count
            PerformanceMonitor.shared.updateEnemyCount(cachedEnemies.count)
            
            // Debug logging for cache monitoring
            print("Enemy Cache Status - Cached: \(cachedEnemies.count), Grid Cells: \(spatialGrid.count)")
        }
        
        // Adjust collision check frequency based on performance
        let collisionCheckInterval = PerformanceMonitor.shared.shouldUseAggressiveOptimizations ? 3 : 2
        let shouldCheckCollisions = frameCounter % collisionCheckInterval == 0
        
        let deltaTime = Float(context.deltaTime)
        
        // Find player once for all enemies to use
        let player = findPlayer(in: context)
        
        // Adjust batch size based on performance
        let baseBatchSize = GameConfig.enemyUpdateBatchSize
        let performanceMultiplier = PerformanceMonitor.shared.shouldUseAggressiveOptimizations ? 0.5 : 1.0
        let adjustedBatchSize = max(1, Int(Float(baseBatchSize) * Float(performanceMultiplier)))
        
        // Process enemies in batches for better performance
        let batchSize = min(cachedEnemies.count, adjustedBatchSize)
        let startIndex = (frameCounter * batchSize) % max(1, cachedEnemies.count)
        
        var enemiesToProcess: [Entity] = []
        for i in 0..<batchSize {
            let index = (startIndex + i) % cachedEnemies.count
            if index < cachedEnemies.count {
                enemiesToProcess.append(cachedEnemies[index])
            }
        }
        
        // Update spatial grid for collision optimization
        if shouldCheckCollisions {
            updateSpatialGrid(enemies: cachedEnemies)
        }
        
        // Process movement for all enemies every frame (critical for gameplay)
        for entity in cachedEnemies {
            guard var enemyComponent = entity.components[EnemyCapsuleComponent.self] else { continue }
            
            // Skip movement if enemy is falling
            if let fallingComp = entity.components[EnemyFallingComponent.self], fallingComp.isFalling {
                continue
            }
            
            // Use cached player reference
            if enemyComponent.target == nil {
                enemyComponent.target = player
                entity.components[EnemyCapsuleComponent.self] = enemyComponent
            }
            
            guard let target = enemyComponent.target else { continue }
            
            // Update LOD system if enabled
            if GameConfig.enableEnemyLOD {
                updateEnemyLOD(enemy: entity, player: target, currentTime: currentTime)
                
                // Check if this enemy should have reduced movement updates
                if let lodComponent = entity.components[EnemyLODComponent.self],
                   lodComponent.reducedMovementUpdates && frameCounter % 3 != 0 {
                    continue // Skip movement update for this frame
                }
            }
            
            // Move toward the player
            moveTowardTarget(enemy: entity, target: target, speed: enemyComponent.speed, deltaTime: deltaTime)
        }
        
        // Process collisions less frequently and only for batched enemies
        if shouldCheckCollisions {
            processCollisions(enemies: enemiesToProcess, player: player)
        }
    }
    
    private func updateEnemyCache(context: SceneUpdateContext) {
        // Get fresh list of active enemies from the scene
        let activeEnemies = Array(context.entities(matching: Self.query, updatingSystemWhen: .rendering))
        
        // Clean up cached enemies - remove any that no longer exist in the scene
        cachedEnemies = cachedEnemies.filter { cachedEnemy in
            // Check if the cached enemy still exists in the active enemies list
            return activeEnemies.contains { activeEnemy in
                activeEnemy.id == cachedEnemy.id
            }
        }
        
        // Add any new enemies that aren't in the cache yet
        for activeEnemy in activeEnemies {
            if !cachedEnemies.contains(where: { $0.id == activeEnemy.id }) {
                cachedEnemies.append(activeEnemy)
            }
        }
        
        // Limit maximum enemies for performance
        if cachedEnemies.count > GameConfig.maxEnemiesForPerformance {
            // Keep only the closest enemies to the player
            if let player = findPlayer(in: context) {
                cachedEnemies.sort { enemy1, enemy2 in
                    let dist1 = distance(enemy1.position, player.position)
                    let dist2 = distance(enemy2.position, player.position)
                    return dist1 < dist2
                }
                cachedEnemies = Array(cachedEnemies.prefix(GameConfig.maxEnemiesForPerformance))
            }
        }
        
        // Clean up spatial grid of any stale references
        cleanupSpatialGrid()
    }
    
    private func cleanupSpatialGrid() {
        // Remove any entities from spatial grid that are no longer in cachedEnemies
        let cachedEnemyIds = Set(cachedEnemies.map { $0.id })
        
        for (gridPos, enemies) in spatialGrid {
            let cleanedEnemies = enemies.filter { enemy in
                cachedEnemyIds.contains(enemy.id)
            }
            
            if cleanedEnemies.isEmpty {
                spatialGrid.removeValue(forKey: gridPos)
            } else if cleanedEnemies.count != enemies.count {
                spatialGrid[gridPos] = cleanedEnemies
            }
        }
    }
    
    private func updateSpatialGrid(enemies: [Entity]) {
        spatialGrid.removeAll()
        
        for enemy in enemies {
            let gridPos = getGridPosition(for: enemy.position)
            if spatialGrid[gridPos] == nil {
                spatialGrid[gridPos] = []
            }
            spatialGrid[gridPos]?.append(enemy)
        }
    }
    
    private func getGridPosition(for position: SIMD3<Float>) -> SIMD2<Int> {
        return SIMD2<Int>(
            Int(position.x / gridSize),
            Int(position.z / gridSize)
        )
    }
    
    private func getNearbyEnemies(for entity: Entity) -> [Entity] {
        let gridPos = getGridPosition(for: entity.position)
        var nearbyEnemies: [Entity] = []
        
        // Check current cell and 8 surrounding cells
        for x in -1...1 {
            for z in -1...1 {
                let checkPos = SIMD2<Int>(gridPos.x + x, gridPos.y + z)
                if let enemies = spatialGrid[checkPos] {
                    nearbyEnemies.append(contentsOf: enemies)
                }
            }
        }
        
        return nearbyEnemies
    }
    
    private func processCollisions(enemies: [Entity], player: Entity?) {
        guard let player = player else { return }
        
        // Check player collisions for batched enemies
        for enemy in enemies {
            // Skip collision check if LOD system says to
            if GameConfig.enableEnemyLOD,
               let lodComponent = enemy.components[EnemyLODComponent.self],
               lodComponent.skipCollisionChecks {
                continue
            }
            
            if checkCollision(between: enemy, and: player) {
                handlePlayerCollision(enemy: enemy, player: player)
            }
        }
        
        // Optimized enemy-enemy collision with spatial partitioning
        for enemy in enemies {
            // Skip if LOD system says to skip collision checks
            if GameConfig.enableEnemyLOD,
               let lodComponent = enemy.components[EnemyLODComponent.self],
               lodComponent.skipCollisionChecks {
                continue
            }
            
            let nearbyEnemies = getNearbyEnemies(for: enemy)
            
            for nearbyEnemy in nearbyEnemies {
                guard enemy !== nearbyEnemy else { continue }
                guard enemy.id.hashValue < nearbyEnemy.id.hashValue else { continue } // Prevent duplicate checks
                
                if checkCollision(between: enemy, and: nearbyEnemy) {
                    preventPhasing(enemy1: enemy, enemy2: nearbyEnemy)
                }
            }
        }
    }
    
    private func updateEnemyLOD(enemy: Entity, player: Entity, currentTime: TimeInterval) {
        // Add LOD component if it doesn't exist
        if enemy.components[EnemyLODComponent.self] == nil {
            enemy.components[EnemyLODComponent.self] = EnemyLODComponent()
        }
        
        guard var lodComponent = enemy.components[EnemyLODComponent.self] else { return }
        
        let distanceToPlayer = distance(enemy.position, player.position)
        lodComponent.updateLOD(distanceToPlayer: distanceToPlayer, currentTime: currentTime)
        
        enemy.components[EnemyLODComponent.self] = lodComponent
    }
    }
    
    private func findPlayer(in context: SceneUpdateContext) -> Entity? {
        let playerQuery = EntityQuery(where: .has(GameStateComponent.self))
        for entity in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            return entity
        }
        return nil
    }
    
    private func moveTowardTarget(enemy: Entity, target: Entity, speed: Float, deltaTime: Float) {
        let direction = normalize(target.position - enemy.position)
        
        // Apply movement force to physics component if available
        if var physics = enemy.components[PhysicsMovementComponent.self] {
            let force = direction * speed * deltaTime * GameConfig.collisionForceMultiplier
            physics.velocity += force
            enemy.components[PhysicsMovementComponent.self] = physics
        } else {
            // Fallback to direct position update
            let velocity = direction * speed * deltaTime
            enemy.position.x += velocity.x
            enemy.position.z += velocity.z
        }
    }
    
    private func checkCollision(between entity1: Entity, and entity2: Entity) -> Bool {
        let distance = distance(entity1.position, entity2.position)
        
        // Use different collision radius based on entity types
        let collisionRadius: Float
        if (entity1.components[GameStateComponent.self] != nil || entity2.components[GameStateComponent.self] != nil) {
            // Player involved in collision
            collisionRadius = GameConfig.playerCollisionRadius
        } else {
            // Enemy-enemy collision
            collisionRadius = GameConfig.enemyCollisionRadius
        }
        
        return distance < collisionRadius
    }
    
    private func handlePlayerCollision(enemy: Entity, player: Entity) {
        // Calculate collision force direction (from enemy to player)
        let collisionDirection = normalize(player.position - enemy.position)
        
        // Get masses for realistic collision response
        let playerMass = player.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.playerMass
        let enemyMass = enemy.components[PhysicsMovementComponent.self]?.mass ?? GameConfig.enemyMass
        
        // Get wave-scaled enemy push force
        let enemyComponent = enemy.components[EnemyCapsuleComponent.self]
        let enemyPushForce = enemyComponent?.pushForceMultiplier ?? GameConfig.enemyPushForceMultiplier
        
        // Get player progression for enhanced attributes
        let progression = player.components[PlayerProgressionComponent.self]
        let resilience = progression?.currentResistance ?? GameConfig.playerResistance
        let forceMultiplier = progression?.forceMultiplier ?? 1.0
        
        // Calculate forces based on mass difference and strength multipliers
        let baseForce = GameConfig.bounceForceMultiplier
        
        // Player force is calculated with wave-scaled enemy push force, reduced by resilience
        let playerForce = collisionDirection * baseForce * enemyPushForce * (enemyMass / playerMass) / resilience
        
        // Enemy force is enhanced by player's force multiplier
        let enemyForce = -collisionDirection * baseForce * GameConfig.playerPushForceMultiplier * (playerMass / enemyMass) * forceMultiplier
        
        // Apply force to player (reduced by resilience)
        if var playerPhysics = player.components[PhysicsMovementComponent.self] {
            playerPhysics.velocity += playerForce
            player.components[PhysicsMovementComponent.self] = playerPhysics
        }
        
        // Apply stronger opposite force to enemy
        if var enemyPhysics = enemy.components[PhysicsMovementComponent.self] {
            enemyPhysics.velocity += enemyForce
            enemy.components[PhysicsMovementComponent.self] = enemyPhysics
        }
        
        // Orient player to face the colliding enemy
        orientPlayerTowardEnemy(player: player, enemy: enemy)
        
        // Trigger attack animation on player collision
        PlayerAnimationSystem.triggerAttackAnimation(for: player, currentTime: Date().timeIntervalSince1970)
        
        // Post collision notification for sound effects
        NotificationCenter.default.post(name: .playerEnemyCollision, object: nil)
    }
    
    private func orientPlayerTowardEnemy(player: Entity, enemy: Entity) {
        // Calculate direction from player to enemy (player should face enemy)
        let directionToEnemy = enemy.position - player.position
        
        // Only rotate if there's a meaningful distance between them
        let distance = length(directionToEnemy)
        guard distance > 0.01 else { return }
        
        // Normalize the direction vector
        let normalizedDirection = directionToEnemy / distance
        
        // Calculate the target rotation angle based on direction to enemy
        let targetAngle = atan2(normalizedDirection.x, normalizedDirection.z)
        
        // Create rotation quaternion around Y-axis (up vector)
        let targetRotation = simd_quatf(angle: targetAngle, axis: SIMD3<Float>(0, 1, 0))
        
        if GameConfig.instantCollisionOrientation {
            // Apply immediate rotation for combat responsiveness
            player.orientation = targetRotation
        } else {
            // Apply smooth rotation interpolation
            let currentRotation = player.orientation
            let smoothingFactor = GameConfig.characterRotationSmoothness * 2.0 // Faster than movement rotation
            let interpolatedRotation = simd_slerp(currentRotation, targetRotation, smoothingFactor)
            player.orientation = interpolatedRotation
        }
    }
    
    private func preventPhasing(enemy1: Entity, enemy2: Entity) {
        // Simple position correction to prevent phasing - just separate them
        let currentDistance = distance(enemy1.position, enemy2.position)
        let minDistance = GameConfig.enemyCollisionRadius
        let overlap = minDistance - currentDistance
        
        if overlap > 0 {
            let separationDirection = normalize(enemy2.position - enemy1.position)
            let correction = separationDirection * (overlap * 0.5)
            
            // Simply move them apart without applying forces
            enemy1.position -= correction
            enemy2.position += correction
        }
    }


extension Notification.Name {
    static let playerEnemyCollision = Notification.Name("playerEnemyCollision")
}
