import RealityKit
import Foundation

class SpawnerSystem: System {
    static let query = EntityQuery(where: .has(SpawnerComponent.self))
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Skip update if game is paused
        if GameConfig.isGamePaused { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var spawner = entity.components[SpawnerComponent.self] else { continue }
            
            // Get current wave information
            let waveComponent = getWaveComponent(context: context)
            
            // Only spawn if wave is active and hasn't reached its enemy limit
            guard let wave = waveComponent, wave.isWaveActive else { continue }
            guard wave.enemiesSpawnedThisWave < wave.currentWaveEnemyCount else { continue }
            
            // Update spawn interval for current wave
            spawner.updateSpawnIntervalForWave(wave.currentWave)
            
            let currentTime = Date()
            let timeSinceLastSpawn = currentTime.timeIntervalSince(spawner.lastSpawnTime)
            
            // Check for burst spawning opportunity
            let shouldBurst = spawner.shouldAttemptBurstSpawn(wave: wave.currentWave, currentTime: currentTime)
            
            if shouldBurst {
                // Execute burst spawn
                executeBurstSpawn(spawner: &spawner, wave: wave, context: context, currentTime: currentTime)
            } else if timeSinceLastSpawn >= spawner.spawnInterval {
                // Normal single enemy spawn
                executeSingleSpawn(spawner: &spawner, wave: wave, context: context, currentTime: currentTime)
            }
            
            entity.components[SpawnerComponent.self] = spawner
        }
    }
    
    private func executeBurstSpawn(spawner: inout SpawnerComponent, wave: WaveComponent, context: SceneUpdateContext, currentTime: Date) {
        guard let surface = spawner.spawnSurface else { return }
        
        let currentEnemyCount = countActiveEnemies(in: context)
        let waveBasedMaxEnemies = calculateMaxEnemiesForWave(wave.currentWave)
        let availableSlots = waveBasedMaxEnemies - currentEnemyCount
        let remainingWaveEnemies = wave.currentWaveEnemyCount - wave.enemiesSpawnedThisWave
        
        guard availableSlots > 0 && remainingWaveEnemies > 0 else { return }
        
        // Calculate burst size considering all constraints
        let burstSize = min(
            spawner.calculateBurstSize(wave: wave.currentWave),
            availableSlots,
            remainingWaveEnemies
        )
        
        print("🚀 Burst spawning \(burstSize) enemies for wave \(wave.currentWave)")
        
        // Spawn multiple enemies with slight delay between each
        for i in 0..<burstSize {
            let enemyType = EnemyType.getRandomEnemyTypeForWave(wave.currentWave)
            
            if let prefab = spawner.enemyPrefabs[enemyType] {
                // Add slight positional variation for burst spawns
                spawnEnemyWithVariation(
                    on: surface,
                    using: prefab,
                    enemyType: enemyType,
                    waveStats: wave,
                    variation: Float(i) * 0.1,
                    in: context
                )
                updateWaveSpawnCount(context: context)
            }
        }
        
        // Update spawner state
        spawner.lastBurstSpawnTime = currentTime
        spawner.lastSpawnTime = currentTime
    }
    
    private func executeSingleSpawn(spawner: inout SpawnerComponent, wave: WaveComponent, context: SceneUpdateContext, currentTime: Date) {
        guard let surface = spawner.spawnSurface else { return }
        
        let currentEnemyCount = countActiveEnemies(in: context)
        let waveBasedMaxEnemies = calculateMaxEnemiesForWave(wave.currentWave)
        
        guard currentEnemyCount < waveBasedMaxEnemies else { return }
        
        // Determine enemy type for this wave
        let enemyType = EnemyType.getRandomEnemyTypeForWave(wave.currentWave)
        
        // Get the appropriate prefab for this enemy type
        if let prefab = spawner.enemyPrefabs[enemyType] {
            spawnEnemy(on: surface, using: prefab, enemyType: enemyType, waveStats: wave, in: context)
            spawner.lastSpawnTime = currentTime
            updateWaveSpawnCount(context: context)
        } else {
            print("Warning: No prefab found for enemy type \(enemyType.name)")
        }
    }
    
    private func calculateMaxEnemiesForWave(_ wave: Int) -> Int {
        if wave == 1 {
            return GameConfig.enemyMaxCount
        }
        
        var maxEnemiesIncrease: Float = 0
        for waveIncrement in 1..<wave {
            let diminishingFactor = pow(GameConfig.maxEnemiesDiminishingFactor, Float(waveIncrement - 1))
            maxEnemiesIncrease += Float(GameConfig.enemyMaxCountIncreasePerWave) * diminishingFactor
        }
        return GameConfig.enemyMaxCount + Int(maxEnemiesIncrease)
    }
    
    private func getWaveComponent(context: SceneUpdateContext) -> WaveComponent? {
        let waveQuery = EntityQuery(where: .has(WaveComponent.self))
        for entity in context.entities(matching: waveQuery, updatingSystemWhen: .rendering) {
            return entity.components[WaveComponent.self]
        }
        return nil
    }
    
    private func updateWaveSpawnCount(context: SceneUpdateContext) {
        let waveQuery = EntityQuery(where: .has(WaveComponent.self))
        for entity in context.entities(matching: waveQuery, updatingSystemWhen: .rendering) {
            guard var wave = entity.components[WaveComponent.self] else { continue }
            wave.enemiesSpawnedThisWave += 1
            entity.components[WaveComponent.self] = wave
            break
        }
    }
    
    private func countActiveEnemies(in context: SceneUpdateContext) -> Int {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        var count = 0
        for _ in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) { count += 1 }
        return count
    }
    
    private func spawnEnemy(on surface: Entity, using prefab: Entity, enemyType: EnemyType, waveStats: WaveComponent, in context: SceneUpdateContext) {
        let enemy = prefab.clone(recursive: true)
        let randomPosition = generateRandomPositionOnCubeSurface(cube: surface)
        enemy.position = randomPosition
        
        // Create enemy component with type-specific stats
        var enemyComponent = EnemyCapsuleComponent(enemyType: enemyType)
        
        // Apply wave scaling to the base stats using WaveComponent scaling
        let speedScaling = waveStats.currentWaveEnemySpeed / waveStats.baseEnemySpeed
        let massScaling = waveStats.currentWaveEnemyMass / waveStats.baseEnemyMass
        let forceScaling = waveStats.currentWaveEnemyForceMultiplier / GameConfig.enemyPushForceMultiplier
        
        enemyComponent.speed = enemyComponent.speed * speedScaling
        enemyComponent.mass = enemyComponent.mass * massScaling
        enemyComponent.pushForceMultiplier = enemyComponent.pushForceMultiplier * forceScaling
        enemyComponent.scoreValue = Int(Float(enemyComponent.scoreValue) * speedScaling) // Scale score with difficulty
        
        // Check if time slow is currently active and apply it to new enemy
        let playerQuery = EntityQuery(where: .has(PowerUpComponent.self))
        let currentTime = Date().timeIntervalSince1970
        
        for player in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            if let powerUpComp = player.components[PowerUpComponent.self],
               powerUpComp.isTimeSlowActive(currentTime: currentTime) {
                // Apply time slow effect to newly spawned enemy
                enemyComponent.speed *= GameConfig.timeSlowMultiplier
                print("Applied time slow effect to newly spawned \(enemyType.name) enemy")
                break
            }
        }
        
        enemy.components.set(enemyComponent)
        
        // Add enemy animation component
        let animationComponent = enemyComponent.createAnimationComponent()
        enemy.components.set(animationComponent)
        
        // Add enemy falling component for out-of-bounds animations
        let fallingComponent = EnemyFallingComponent()
        enemy.components.set(fallingComponent)
        
        // Add physics movement component with wave-enhanced stats
        var physicsComponent = PhysicsMovementComponent()
        physicsComponent.mass = enemyComponent.mass
        physicsComponent.friction = GameConfig.frictionCoefficient
        physicsComponent.constrainedTo = surface
        physicsComponent.groundLevel = GameConfig.enemySpawnYOffset
        enemy.components.set(physicsComponent)
        
        surface.parent?.addChild(enemy)
        
        print("Spawned \(enemyType.name) enemy with speed: \(String(format: "%.2f", enemyComponent.speed)), mass: \(String(format: "%.2f", enemyComponent.mass)), score: \(enemyComponent.scoreValue)")
    }
    
    private func spawnEnemyWithVariation(on surface: Entity, using prefab: Entity, enemyType: EnemyType, waveStats: WaveComponent, variation: Float, in context: SceneUpdateContext) {
        let enemy = prefab.clone(recursive: true)
        var randomPosition = generateRandomPositionOnCubeSurface(cube: surface)
        
        // Add variation to position for burst spawns
        randomPosition.x += variation * (Float.random(in: -1...1))
        randomPosition.z += variation * (Float.random(in: -1...1))
        
        enemy.position = randomPosition
        
        // Create enemy component with type-specific stats (same as regular spawn)
        var enemyComponent = EnemyCapsuleComponent(enemyType: enemyType)
        
        // Apply wave scaling to the base stats using WaveComponent scaling
        let speedScaling = waveStats.currentWaveEnemySpeed / waveStats.baseEnemySpeed
        let massScaling = waveStats.currentWaveEnemyMass / waveStats.baseEnemyMass
        let forceScaling = waveStats.currentWaveEnemyForceMultiplier / GameConfig.enemyPushForceMultiplier
        
        enemyComponent.speed = enemyComponent.speed * speedScaling
        enemyComponent.mass = enemyComponent.mass * massScaling
        enemyComponent.pushForceMultiplier = enemyComponent.pushForceMultiplier * forceScaling
        enemyComponent.scoreValue = Int(Float(enemyComponent.scoreValue) * speedScaling)
        
        // Check if time slow is currently active and apply it to new enemy
        let playerQuery = EntityQuery(where: .has(PowerUpComponent.self))
        let currentTime = Date().timeIntervalSince1970
        
        for player in context.entities(matching: playerQuery, updatingSystemWhen: .rendering) {
            if let powerUpComp = player.components[PowerUpComponent.self],
               powerUpComp.isTimeSlowActive(currentTime: currentTime) {
                enemyComponent.speed *= GameConfig.timeSlowMultiplier
                break
            }
        }
        
        enemy.components.set(enemyComponent)
        
        // Add enemy animation component
        let animationComponent = enemyComponent.createAnimationComponent()
        enemy.components.set(animationComponent)
        
        // Add enemy falling component for out-of-bounds animations
        let fallingComponent = EnemyFallingComponent()
        enemy.components.set(fallingComponent)
        
        // Add physics movement component with wave-enhanced stats
        var physicsComponent = PhysicsMovementComponent()
        physicsComponent.mass = enemyComponent.mass
        physicsComponent.friction = GameConfig.frictionCoefficient
        physicsComponent.constrainedTo = surface
        physicsComponent.groundLevel = GameConfig.enemySpawnYOffset
        enemy.components.set(physicsComponent)
        
        surface.parent?.addChild(enemy)
    }
    
    private func generateRandomPositionOnCubeSurface(cube: Entity) -> SIMD3<Float> {
        let cubePosition = cube.position
        let cubeScale = cube.scale
        let halfSize = cubeScale.x / 2.0
        let randomX = Float.random(in: -halfSize...halfSize) + cubePosition.x
        let randomZ = Float.random(in: -halfSize...halfSize) + cubePosition.z
        let surfaceY = cubePosition.y + halfSize + 0.1
        return SIMD3<Float>(randomX, surfaceY, randomZ)
    }
}
