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


    var body: some View {
        ZStack {
            RealityView { content in
                guard let loadedScene = try? await Entity(named: "Scene", in: arenaBundle) else { return }
                guard let capsule = loadedScene.findEntity(named: "Capsule"),
                      let cube = loadedScene.findEntity(named: "Cube") else { return }

                capsuleEntity = capsule
                cubeEntity = cube
                
                // Set up the movement component for the capsule
                setupMovementComponent(for: capsule, constrainedTo: cube)
                
                // Set up isometric camera
                let camera = setupIsometricCamera(target: capsule)
                
                // Register both systems
                MovementSystem.registerSystem()
                IsometricCameraSystem.registerSystem()
                
                content.add(loadedScene)
                content.add(camera)
                
            } update: { content in
                // Update loop - the MovementSystem handles the actual movement
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
    
    // New analog control properties
    let applyAnalogForce: (SIMD2<Float>) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            // Analog joystick control
            AnalogJoystick { analogVector in
                applyAnalogForce(analogVector)
            } onRelease: {
                stopApplyingForce()
            }
            .frame(width: 200, height: 200)
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
    
    private let joystickRadius: CGFloat = 80
    private let knobRadius: CGFloat = 25
    
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
