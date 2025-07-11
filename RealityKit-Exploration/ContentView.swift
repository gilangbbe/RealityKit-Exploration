//
//  ContentView.swift
//  RealityKit-Exploration
//
//  Created by Gilang Banyu Biru Erassunu on 10/07/25.
//

import RealityKit
import SwiftUI
import Arena

// MARK: - ECS Components

// Component to store movement properties
struct MovementComponent: Component {
    var velocity: SIMD3<Float> = [0, 0, 0]
    var speed: Float = 1.0
    var isMoving: Bool = false
    var constrainedTo: Entity? = nil // The entity to constrain movement to (cube)
    var surfaceOffset: Float = 0.0 // How far above the surface to stay
}

// Component to identify enemy capsules
struct EnemyCapsuleComponent: Component {
    var isActive: Bool = true
    var spawnTime: Date = Date()
    var health: Int = 1
    var scoreValue: Int = 10
}

// Component to handle spawning logic
struct SpawnerComponent: Component {
    var spawnInterval: TimeInterval = 3.0 // Spawn every 3 seconds
    var lastSpawnTime: Date = Date()
    var maxEnemies: Int = 5
    var spawnSurface: Entity? = nil // The surface to spawn on (cube)
    var enemyPrefab: Entity? = nil // Reference to the enemy prefab
}

// Component for projectiles
struct ProjectileComponent: Component {
    var velocity: SIMD3<Float> = [0, 0, 0]
    var speed: Float = 2.0
    var damage: Int = 1
    var lifetime: TimeInterval = 5.0
    var spawnTime: Date = Date()
}

// Component to handle automatic shooting
struct AutoShootComponent: Component {
    var shootInterval: TimeInterval = 0.5 // Shoot every 0.5 seconds
    var lastShootTime: Date = Date()
    var shootWhileMoving: Bool = true
    var isEnabled: Bool = true
}

struct DestroyableComponent: Component {
    var shouldDestroy: Bool = false
}

// MARK: - Camera Component and System

struct IsometricCameraComponent: Component {
    var target: Entity?
    var offset: SIMD3<Float> = [3, 8, 3] // Isometric offset from target
    var smoothing: Float = 0.1 // Camera follow smoothing factor
    var lookAtTarget: Bool = true
}

class IsometricCameraSystem: System {
    static let query = EntityQuery(where: .has(IsometricCameraComponent.self))
    
    required init(scene: RealityKit.Scene) {
        // System initialization
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let cameraComponent = entity.components[IsometricCameraComponent.self],
                  let target = cameraComponent.target else { continue }
            
            // Calculate desired camera position
            let targetPosition = target.position
            let desiredPosition = targetPosition + cameraComponent.offset
            
            // Smooth camera movement
            let currentPosition = entity.position
            let newPosition = mix(currentPosition, desiredPosition, t: cameraComponent.smoothing)
            entity.position = newPosition
            
            // Look at target if enabled
            if cameraComponent.lookAtTarget {
                entity.look(at: targetPosition, from: newPosition, relativeTo: nil)
            }
        }
    }
}

// MARK: - ECS Systems

// System to handle movement updates
class MovementSystem: System {
    static let query = EntityQuery(where: .has(MovementComponent.self))
    
    required init(scene: RealityKit.Scene) {
        // System initialization
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var movement = entity.components[MovementComponent.self] else { continue }
            
            if movement.isMoving {
                // Apply movement
                let deltaTime = Float(context.deltaTime)
                let displacement = movement.velocity * movement.speed * deltaTime
                
                // Calculate new position
                var newPosition = entity.position + displacement
                
                // Constrain to cube surface if specified
                if let constrainedEntity = movement.constrainedTo {
                    newPosition = constrainToCubeSurface(newPosition, cube: constrainedEntity, offset: movement.surfaceOffset)
                }
                
                entity.position = newPosition
            }
            
            // Update the component (in case we modified it)
            entity.components[MovementComponent.self] = movement
        }
    }
    
    private func constrainToCubeSurface(_ position: SIMD3<Float>, cube: Entity, offset: Float) -> SIMD3<Float> {
        // Get cube's actual bounds
        let cubePosition = cube.position
        
        // Get the cube's scale and model bounds to determine actual size
        let cubeScale = cube.scale
        let cubeSize = cubeScale.x // Assuming uniform scale for cube
        let halfSize = cubeSize / 2.0
        
        // Calculate cube boundaries
        let minX = cubePosition.x - halfSize
        let maxX = cubePosition.x + halfSize
        let minZ = cubePosition.z - halfSize
        let maxZ = cubePosition.z + halfSize
        
        // Constrain X and Z to stay within cube bounds
        let constrainedX = max(minX, min(maxX, position.x))
        let constrainedZ = max(minZ, min(maxZ, position.z))
        
        // Calculate the top surface Y position
        let topSurfaceY = cubePosition.y + halfSize + offset
        
        return SIMD3<Float>(constrainedX, topSurfaceY, constrainedZ)
    }
}

// System to handle enemy spawning
class SpawnerSystem: System {
    static let query = EntityQuery(where: .has(SpawnerComponent.self))
    
    required init(scene: RealityKit.Scene) {
        // System initialization
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var spawner = entity.components[SpawnerComponent.self] else { continue }
            
            let currentTime = Date()
            let timeSinceLastSpawn = currentTime.timeIntervalSince(spawner.lastSpawnTime)
            
            // Check if it's time to spawn and we haven't reached max enemies
            if timeSinceLastSpawn >= spawner.spawnInterval {
                let currentEnemyCount = countActiveEnemies(in: context)
                
                if currentEnemyCount < spawner.maxEnemies,
                   let surface = spawner.spawnSurface,
                   let prefab = spawner.enemyPrefab {
                    
                    spawnEnemy(on: surface, using: prefab, in: context)
                    spawner.lastSpawnTime = currentTime
                }
            }
            
            // Update the component
            entity.components[SpawnerComponent.self] = spawner
        }
    }
    
    private func countActiveEnemies(in context: SceneUpdateContext) -> Int {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        var count = 0
        for _ in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) {
            count += 1
        }
        return count
    }
    
    private func spawnEnemy(on surface: Entity, using prefab: Entity, in context: SceneUpdateContext) {
        // Clone the prefab
        let enemy = prefab.clone(recursive: true)
        
        // Generate random position on cube surface
        let randomPosition = generateRandomPositionOnCubeSurface(cube: surface)
        enemy.position = randomPosition
        
        // Add enemy component
        enemy.components.set(EnemyCapsuleComponent())
        
        // Add to scene
        surface.parent?.addChild(enemy)
    }
    
    private func generateRandomPositionOnCubeSurface(cube: Entity) -> SIMD3<Float> {
        let cubePosition = cube.position
        let cubeScale = cube.scale
        let halfSize = cubeScale.x / 2.0
        
        // Generate random X and Z within cube bounds
        let randomX = Float.random(in: -halfSize...halfSize) + cubePosition.x
        let randomZ = Float.random(in: -halfSize...halfSize) + cubePosition.z
        
        // Place on top surface with small offset
        let surfaceY = cubePosition.y + halfSize + 0.1
        
        return SIMD3<Float>(randomX, surfaceY, randomZ)
    }
}

// System to handle projectile movement and collision
class ProjectileSystem: System {
    static let query = EntityQuery(where: .has(ProjectileComponent.self))
    
    required init(scene: RealityKit.Scene) {
        // System initialization
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var projectile = entity.components[ProjectileComponent.self] else { continue }
            
            // Skip if already marked for destruction
            if entity.components.has(DestroyableComponent.self) {
                continue
            }
            
            let currentTime = Date()
            let age = currentTime.timeIntervalSince(projectile.spawnTime)
            
            // Remove old projectiles
            if age > projectile.lifetime {
                entity.components.set(DestroyableComponent(shouldDestroy: true))
                continue
            }
            
            // Store old position for collision detection
            let oldPosition = entity.position
            
            // Move projectile
            let deltaTime = Float(context.deltaTime)
            let displacement = projectile.velocity * projectile.speed * deltaTime
            let newPosition = oldPosition + displacement
            entity.position = newPosition
            
            // Check for collision with enemies using both old and new positions
            if checkProjectileCollisions(projectile: entity, oldPosition: oldPosition, newPosition: newPosition, in: context) {
                // Collision detected, projectile is already marked for destruction
                continue
            }
            
            // Update component
            entity.components[ProjectileComponent.self] = projectile
        }
    }
    
    private func checkProjectileCollisions(projectile: Entity, oldPosition: SIMD3<Float>, newPosition: SIMD3<Float>, in context: SceneUpdateContext) -> Bool {
        let enemyQuery = EntityQuery(where: .has(EnemyCapsuleComponent.self))
        
        for enemy in context.entities(matching: enemyQuery, updatingSystemWhen: .rendering) {
            // Skip if enemy is already marked for destruction
            if enemy.components.has(DestroyableComponent.self) {
                continue
            }
            
            let enemyPosition = enemy.position
            
            // Get enemy bounds for more accurate collision
            let enemyBounds = enemy.visualBounds(relativeTo: enemy.parent)
            // Use the largest extent as the collision radius (covers capsule height and width)
            let extentX = (enemyBounds.max.x - enemyBounds.min.x) / 2.0
            let extentY = (enemyBounds.max.y - enemyBounds.min.y) / 2.0
            let extentZ = (enemyBounds.max.z - enemyBounds.min.z) / 2.0
            let enemyRadius = max(extentX, extentY, extentZ)
            
            // Use line-sphere intersection for better collision detection
            if lineIntersectsSphere(lineStart: oldPosition, lineEnd: newPosition,
                                  sphereCenter: enemyPosition, sphereRadius: enemyRadius + 0.05) {
                
                // Mark both for destruction immediately
                projectile.components.set(DestroyableComponent(shouldDestroy: true))
                enemy.components.set(DestroyableComponent(shouldDestroy: true))
                
                // Optional: Add hit effect or sound here
                print("Enemy hit! (radius: \(enemyRadius), pos: \(enemyPosition))")
                
                return true // Collision detected
            }
        }
        
        return false // No collision
    }
    
    // Line-sphere intersection test for more accurate collision detection
    private func lineIntersectsSphere(lineStart: SIMD3<Float>, lineEnd: SIMD3<Float>,
                                    sphereCenter: SIMD3<Float>, sphereRadius: Float) -> Bool {
        let lineDirection = lineEnd - lineStart
        let lineLength = length(lineDirection)
        
        // Handle zero-length line
        if lineLength < 0.001 {
            return length(lineStart - sphereCenter) <= sphereRadius
        }
        
        let normalizedDirection = lineDirection / lineLength
        let toSphere = sphereCenter - lineStart
        
        // Project sphere center onto line
        let projectionLength = dot(toSphere, normalizedDirection)
        
        // Clamp projection to line segment
        let clampedProjection = max(0, min(lineLength, projectionLength))
        
        // Find closest point on line segment to sphere center
        let closestPoint = lineStart + normalizedDirection * clampedProjection
        
        // Check if distance is within sphere radius
        let distanceSquared = length_squared(closestPoint - sphereCenter)
        return distanceSquared <= (sphereRadius * sphereRadius)
    }
}

// System to clean up destroyed entities
class DestroySystem: System {
    static let query = EntityQuery(where: .has(DestroyableComponent.self))
    
    required init(scene: RealityKit.Scene) {
        // System initialization
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let destroyable = entity.components[DestroyableComponent.self] else { continue }
            
            if destroyable.shouldDestroy {
                entity.removeFromParent()
            }
        }
    }
}

// System to handle automatic shooting
// System to handle automatic shooting
class AutoShootSystem: System {
    static let query = EntityQuery(where: .has(AutoShootComponent.self))
    
    required init(scene: RealityKit.Scene) {
        // System initialization
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var autoShoot = entity.components[AutoShootComponent.self] else { continue }
            
            // Skip if auto-shooting is disabled
            guard autoShoot.isEnabled else { continue }
            
            // Check if entity has movement component
            guard let movement = entity.components[MovementComponent.self] else { continue }
            
            // Only shoot if moving (if shootWhileMoving is true) or always shoot
            let shouldShoot = !autoShoot.shootWhileMoving || movement.isMoving
            
            guard shouldShoot else { continue }
            
            let currentTime = Date()
            let timeSinceLastShot = currentTime.timeIntervalSince(autoShoot.lastShootTime)
            
            // Check if enough time has passed since last shot
            if timeSinceLastShot >= autoShoot.shootInterval {
                // Get shoot direction based on movement
                let shootDirection = getShootDirection(from: movement)
                
                // Create and shoot projectile
                createProjectile(from: entity, direction: shootDirection, in: context)
                
                // Update last shot time
                autoShoot.lastShootTime = currentTime
            }
            
            // Update the component
            entity.components[AutoShootComponent.self] = autoShoot
        }
    }
    
    private func getShootDirection(from movement: MovementComponent) -> SIMD3<Float> {
        if movement.isMoving && length(movement.velocity) > 0.1 {
            // Normalize the movement velocity to get direction
            return normalize(movement.velocity)
        }
        
        // If not moving, shoot forward (default direction)
        return [0, 0, -1]
    }
    
    private func createProjectile(from shooter: Entity, direction: SIMD3<Float>, in context: SceneUpdateContext) {
        // Create a simple projectile (small sphere)
        let projectile = Entity()
        
        // Create a small sphere mesh
        let sphereMesh = MeshResource.generateSphere(radius: 0.02)
        var material = SimpleMaterial()
        material.color = .init(tint: .yellow, texture: nil)
        material.roughness = 0.1
        material.metallic = 0.0
        
        projectile.components.set(ModelComponent(mesh: sphereMesh, materials: [material]))
        
        // Get shooter's actual bounds for precise positioning
        let shooterBounds = shooter.visualBounds(relativeTo: shooter.parent)
        let shooterPosition = shooter.position
        
        // Calculate spawn position at the edge of the capsule in the shoot direction
        let capsuleRadius = (shooterBounds.max.x - shooterBounds.min.x) / 2.0
        let capsuleHeight = shooterBounds.max.y - shooterBounds.min.y
        
        // Spawn projectile at capsule's center height, offset by capsule radius in shoot direction
        let spawnOffset = direction * (capsuleRadius + 0.1) // Small additional offset to prevent overlap
        let heightOffset = SIMD3<Float>(0, capsuleHeight * 0.1, 0) // Slightly above center
        let spawnPosition = shooterPosition + spawnOffset + heightOffset
        
        projectile.position = spawnPosition
        
        // Set projectile component
        var projectileComponent = ProjectileComponent()
        projectileComponent.velocity = direction
        projectileComponent.speed = 2.0
        projectileComponent.lifetime = 3.0
        projectileComponent.damage = 1
        projectileComponent.spawnTime = Date()
        projectile.components.set(projectileComponent)
        
        // Add to scene (same parent as shooter)
        shooter.parent?.addChild(projectile)
    }
}

// MARK: - Force Direction Enum

enum ForceDirection {
    case up, down, left, right
    
    var symbol: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .left: return "arrow.left.circle.fill"
        case .right: return "arrow.right.circle.fill"
        }
    }
    
    var velocity: SIMD3<Float> {
        switch self {
        case .up: return [0, 0, -1]    // Forward in RealityKit
        case .down: return [0, 0, 1]   // Backward in RealityKit
        case .left: return [-1, 0, 0]  // Left
        case .right: return [1, 0, 0]  // Right
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var capsuleEntity = Entity()
    @State private var cubeEntity = Entity()
    @State private var redCapsuleEntity = Entity()
    @State private var spawnerEntity = Entity()

    var body: some View {
        ZStack {
            RealityView { content in
                guard let loadedScene = try? await Entity(named: "Scene", in: arenaBundle) else { return }
                guard let capsule = loadedScene.findEntity(named: "Capsule"),
                      let cube = loadedScene.findEntity(named: "Cube") else { return }
                
                // Try to find the red capsule (you'll need to create this in Reality Composer Pro)
                let redCapsule = loadedScene.findEntity(named: "EnemyCapsule")

                capsuleEntity = capsule
                cubeEntity = cube
                
                // Set up the movement component for the capsule
                setupMovementComponent(for: capsule, constrainedTo: cube)
                
                // Set up auto-shooting for the player
                setupAutoShooting(for: capsule)
                
                // Set up spawner if red capsule exists
                if let redCapsule = redCapsule {
                    redCapsuleEntity = redCapsule
                    // Remove the red capsule from the scene initially (we'll use it as a prefab)
                    redCapsule.removeFromParent()
                    setupSpawner(surface: cube, enemyPrefab: redCapsule)
                }
                
                // Set up isometric camera
                let camera = setupIsometricCamera(target: capsule)
                
                // Register all systems
                MovementSystem.registerSystem()
                IsometricCameraSystem.registerSystem()
                SpawnerSystem.registerSystem()
                ProjectileSystem.registerSystem()
                DestroySystem.registerSystem()
                AutoShootSystem.registerSystem()
                
                content.add(loadedScene)
                content.add(camera)
                content.add(spawnerEntity)
                
            } update: { content in
                // Update loop - the systems handle everything
            }

            // Control Buttons
            controlsView { direction in
                startApplyingForce(direction: direction)
            } stopApplyingForce: {
                stopApplyingForce()
            } applyAnalogForce: { analogVector in
                applyAnalogForce(analogVector: analogVector)
            }
        }
    }
    
    private func setupSpawner(surface: Entity, enemyPrefab: Entity) {
        spawnerEntity = Entity()
        
        var spawnerComponent = SpawnerComponent()
        spawnerComponent.spawnSurface = surface
        spawnerComponent.enemyPrefab = enemyPrefab
        spawnerComponent.spawnInterval = 2.0 // Spawn every 2 seconds
        spawnerComponent.maxEnemies = 3 // Maximum 3 enemies at once
        
        spawnerEntity.components.set(spawnerComponent)
    }
    
    private func setupIsometricCamera(target: Entity) -> Entity {
        let camera = Entity()
        
        // Set up perspective camera with appropriate FOV for isometric feel
        var cameraComponent = PerspectiveCameraComponent()
        cameraComponent.fieldOfViewInDegrees = 35 // Narrower FOV for less perspective distortion
        camera.components.set(cameraComponent)
        
        // Set up isometric camera component
        var isometricComponent = IsometricCameraComponent()
        isometricComponent.target = target
        isometricComponent.offset = [1, 2, 1] // Isometric position: back, up, right
        isometricComponent.smoothing = 0.05 // Smooth camera follow
        isometricComponent.lookAtTarget = true
        camera.components.set(isometricComponent)
        
        // Initial positioning
        let initialPosition = target.position + isometricComponent.offset
        camera.position = initialPosition
        camera.look(at: target.position, from: initialPosition, relativeTo: nil)
        
        return camera
    }
    
    private func setupAutoShooting(for entity: Entity) {
        var autoShootComponent = AutoShootComponent()
        autoShootComponent.shootInterval = 0.3 // Shoot every 0.3 seconds
        autoShootComponent.shootWhileMoving = true // Only shoot when moving
        autoShootComponent.isEnabled = true
        
        entity.components.set(autoShootComponent)
    }
    
    private func setupMovementComponent(for entity: Entity, constrainedTo cube: Entity) {
        // Get the actual bounds of both entities for better offset calculation
        let capsuleBounds = entity.visualBounds(relativeTo: nil)
        let cubeBounds = cube.visualBounds(relativeTo: nil)
        
        // Calculate surface offset based on actual capsule height
        let capsuleHeight = capsuleBounds.max.y - capsuleBounds.min.y
        let surfaceOffset = capsuleHeight / 2.0 + 0.05 // Half capsule height + small margin
        
        var movementComponent = MovementComponent()
        movementComponent.speed = 2.0 // Adjust speed as needed
        movementComponent.constrainedTo = cube
        movementComponent.surfaceOffset = surfaceOffset
        
        entity.components.set(movementComponent)
        
        // Position the capsule on the cube surface initially
        let cubeTopY = cube.position.y + (cube.scale.y / 2.0)
        entity.position.y = cubeTopY + surfaceOffset
    }
    
    private func startApplyingForce(direction: ForceDirection) {
        guard var movement = capsuleEntity.components[MovementComponent.self] else { return }
        
        movement.velocity = direction.velocity
        movement.isMoving = true
        
        capsuleEntity.components[MovementComponent.self] = movement
    }
    
    private func stopApplyingForce() {
        guard var movement = capsuleEntity.components[MovementComponent.self] else { return }
        
        movement.velocity = [0, 0, 0]
        movement.isMoving = false
        
        capsuleEntity.components[MovementComponent.self] = movement
    }
    
    private func applyAnalogForce(analogVector: SIMD2<Float>) {
        guard var movement = capsuleEntity.components[MovementComponent.self] else { return }
        
        // Convert 2D analog input to 3D velocity
        // For isometric view, we need to adjust the movement mapping
        // to align with the camera's perspective
        
        // Standard isometric movement mapping:
        // Joystick right -> move diagonally (positive X, negative Z)
        // Joystick left -> move diagonally (negative X, positive Z)
        // Joystick up -> move diagonally (positive X, positive Z)
        // Joystick down -> move diagonally (negative X, negative Z)
        
        // Convert to isometric-aligned movement
        let isoX = (analogVector.x - analogVector.y) * 0.707 // Diagonal component
        let isoZ = -(analogVector.x + analogVector.y) * 0.707 // Diagonal component
        
        let velocity = SIMD3<Float>(isoX, 0, isoZ)
        
        movement.velocity = velocity
        movement.isMoving = length(velocity) > 0.1 // Small threshold to avoid tiny movements
        
        capsuleEntity.components[MovementComponent.self] = movement
    }
}

// MARK: - Analog Controls View

struct controlsView: View {
    let startApplyingForce: (ForceDirection) -> Void
    let stopApplyingForce: () -> Void
    let applyAnalogForce: (SIMD2<Float>) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            // Analog joystick control (centered)
            AnalogJoystick { analogVector in
                applyAnalogForce(analogVector)
            } onRelease: {
                stopApplyingForce()
            }
            .frame(width: 150, height: 150)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Analog Joystick Component

struct AnalogJoystick: View {
    let onDrag: (SIMD2<Float>) -> Void
    let onRelease: () -> Void
    
    @State private var knobPosition: CGPoint = .zero
    @State private var isDragging: Bool = false
    
    private let joystickRadius: CGFloat = 60
    private let knobRadius: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Joystick base
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: joystickRadius * 2, height: joystickRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                )
            
            // Joystick knob
            Circle()
                .fill(Color.blue)
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .position(
                    x: joystickRadius + knobPosition.x,
                    y: joystickRadius + knobPosition.y
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            updateKnobPosition(value.translation)
                        }
                        .onEnded { _ in
                            isDragging = false
                            returnKnobToCenter()
                            onRelease()
                        }
                )
        }
        .frame(width: joystickRadius * 2, height: joystickRadius * 2)
    }
    
    private func updateKnobPosition(_ translation: CGSize) {
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        let maxDistance = joystickRadius - knobRadius
        
        if distance <= maxDistance {
            knobPosition = CGPoint(x: translation.width, y: translation.height)
        } else {
            // Constrain to circle boundary
            let angle = atan2(translation.height, translation.width)
            knobPosition = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
        }
        
        // Convert to normalized vector (-1 to 1)
        let normalizedX = Float(knobPosition.x / maxDistance)
        let normalizedY = Float(-knobPosition.y / maxDistance) // Invert Y for proper direction
        
        onDrag(SIMD2<Float>(normalizedX, normalizedY))
    }
    
    private func returnKnobToCenter() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            knobPosition = .zero
        }
    }
}

#Preview {
    ContentView()
}
