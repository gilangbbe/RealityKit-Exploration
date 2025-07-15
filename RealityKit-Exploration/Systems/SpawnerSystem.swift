import RealityKit
import Foundation
import UIKit

class SpawnerSystem: System {
    static let query = EntityQuery(where: .has(SpawnerComponent.self))
    static let waveQuery = EntityQuery(where: .has(WaveManagerComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        // Get current wave information
        guard let waveInfo = getCurrentWaveInfo(in: context) else { return }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var spawner = entity.components[SpawnerComponent.self] else { continue }
            
            // Only spawn if wave is active
            guard waveInfo.isActive else { continue }
            
            let currentTime = Date()
            let adjustedSpawnInterval = spawner.spawnInterval * Double(waveInfo.spawnIntervalMultiplier)
            let timeSinceLastSpawn = currentTime.timeIntervalSince(spawner.lastSpawnTime)
            
            if timeSinceLastSpawn >= adjustedSpawnInterval {
                let currentEnemyCount = countActiveEnemies(in: context)
                let adjustedMaxEnemies = Int(Float(spawner.maxEnemies) * waveInfo.maxEnemiesMultiplier)
                
                if currentEnemyCount < adjustedMaxEnemies,
                   let surface = spawner.spawnSurface,
                   let prefab = spawner.enemyPrefab {
                    spawnEnemy(on: surface, using: prefab, waveInfo: waveInfo, in: context)
                    spawner.lastSpawnTime = currentTime
                }
            }
            entity.components[SpawnerComponent.self] = spawner
        }
    }
    
    private func getCurrentWaveInfo(in context: SceneUpdateContext) -> WaveGameInfo? {
        for entity in context.entities(matching: Self.waveQuery, updatingSystemWhen: .rendering) {
            guard let waveManager = entity.components[WaveManagerComponent.self] else { continue }
            return WaveGameInfo(
                waveNumber: waveManager.currentWave.waveNumber,
                speedMultiplier: waveManager.currentWave.enemySpeedMultiplier,
                healthMultiplier: waveManager.currentWave.enemyHealthMultiplier,
                scoreMultiplier: waveManager.currentWave.enemyScoreMultiplier,
                spawnIntervalMultiplier: waveManager.currentWave.spawnIntervalMultiplier,
                maxEnemiesMultiplier: waveManager.currentWave.maxEnemiesMultiplier,
                isActive: waveManager.isWaveActive
            )
        }
        return nil
    }
    private func countActiveEnemies(in context: SceneUpdateContext) -> Int {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        var count = 0
        for _ in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) { count += 1 }
        return count
    }
    private func spawnEnemy(on surface: Entity, using prefab: Entity, waveInfo: WaveGameInfo, in context: SceneUpdateContext) {
        let enemy = prefab.clone(recursive: true)
        let randomPosition = generateRandomPositionOnCubeSurface(cube: surface)
        enemy.position = randomPosition
        
        var enemyComponent = EnemyCapsuleComponent()
        enemyComponent.speed = GameConfig.enemySpeed * waveInfo.speedMultiplier
        enemyComponent.mass = GameConfig.enemyMass
        enemyComponent.scoreValue = Int(Float(GameConfig.enemyScoreValue) * waveInfo.scoreMultiplier)
        enemy.components.set(enemyComponent)
        
        // Add physics movement component
        var physicsComponent = PhysicsMovementComponent()
        physicsComponent.mass = GameConfig.enemyMass
        physicsComponent.friction = GameConfig.frictionCoefficient
        physicsComponent.constrainedTo = surface
        physicsComponent.groundLevel = GameConfig.enemySpawnYOffset
        enemy.components.set(physicsComponent)
        
        // Apply wave-based visual modifications
        applyWaveBasedVisuals(to: enemy, speedMultiplier: waveInfo.speedMultiplier)
        
        surface.parent?.addChild(enemy)
    }
    
    private func applyWaveBasedVisuals(to enemy: Entity, speedMultiplier: Float) {
        // Change enemy color/material based on strength
        if let modelComponent = enemy.components[ModelComponent.self] {
            var materials = modelComponent.materials
            
            for i in 0..<materials.count {
                if var material = materials[i] as? SimpleMaterial {
                    // Color intensity based on speed multiplier (wave strength)
                    let intensity = min(speedMultiplier / 3.0, 1.0) // Cap at wave 3 equivalent
                    
                    // Interpolate from red (weak) to dark red/purple (strong)
                    let red = CGFloat(1.0 - intensity * 0.3)
                    let green = CGFloat(0.1 * (1.0 - intensity))
                    let blue = CGFloat(intensity * 0.6)
                    
                    material.color = .init(
                        tint: UIColor(red: red, green: green, blue: blue, alpha: 1.0),
                        texture: nil
                    )
                    
                    // Make stronger enemies more metallic/intimidating
                    material.metallic = .init(floatLiteral: intensity * 0.4)
                    material.roughness = .init(floatLiteral: 0.3 - (intensity * 0.2))
                    
                    materials[i] = material
                }
            }
            
            enemy.components.set(ModelComponent(mesh: modelComponent.mesh, materials: materials))
        }
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
