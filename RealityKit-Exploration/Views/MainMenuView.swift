import SwiftUI
import RealityKit
import Arena

struct MainMenuView: View {
    @State private var mainMenuKey = UUID()
    
    let onStartGame: () -> Void
    let onShowLeaderboard: () -> Void
    let scoreManager: ScoreManager

    var body: some View {
        ZStack {
            //RealityKitMenuBackground()
            RealityView { content in
                await setupMenuBackground(content: content)
            }
            .id(mainMenuKey)
            .ignoresSafeArea(.all)
            
            // Background gradient
//            LinearGradient(
//                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.3)]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 40)
                
                // Game Title
                VStack(spacing: 20) {
                    Text("ARENA")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue, radius: 10)
                    
                    Text("COMBAT")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .shadow(color: .white, radius: 5)
                    
                    Text("Push your enemies off the arena!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // High Score Display
                    if scoreManager.highScore > 0 {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("High Score: \(scoreManager.highScore)")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                    .frame(height: 180)
                
                // Menu Buttons
                VStack(spacing: 20) {
                    // Start Game Button
                    Button(action: onStartGame) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("START GAME")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.5), lineWidth: 3)
                                )
                        )
                        .shadow(color: .purple.opacity(0.8), radius: 6)
                        .shadow(color: Color.purple.opacity(0.8), radius: 12)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: false)

                    
                    // Leaderboard Button
                    Button(action: onShowLeaderboard) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                            Text("LEADERBOARD")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.5), lineWidth: 3)
                                )
                        )
                        .shadow(color: .yellow.opacity(0.8), radius: 6)
                        .shadow(color: Color.yellow.opacity(0.8), radius: 12)
                    }

                }
                
                Spacer()
            }
            .padding()
        }
    }
}

func setupMenuBackground(content: RealityViewCameraContent) async {
    print("Starting to load menuScene entity...")
    guard let loadedScene = try? await Entity(named: GameConfig.EntityNames.menuScene, in: arenaBundle) else {
        print("Failed to load menuScene entity")
        return
    }
    print("Loaded menuScene entity successfully")
    
    guard let capsule = await loadedScene.findEntity(named: GameConfig.EntityNames.capsule) else {
        print("Failed to find capsule entity in menuScene")
        return
    }
    guard let lootBox = await loadedScene.findEntity(named: GameConfig.EntityNames.lootBox) else {
        print("Failed to find lootBox entity in menuScene")
        return
    }

    // Play player idle animation repeatedly
    if let playerAnimationEntity = await capsule.findEntity(named: GameConfig.playerChildEntityName) {
        // Found player child entity with animations
        let availableAnimations = playerAnimationEntity.availableAnimations
        if GameConfig.idleAnimationIndex < availableAnimations.count {
            let idleAnimation = availableAnimations[GameConfig.idleAnimationIndex]
            playerAnimationEntity.playAnimation(idleAnimation.repeat(), transitionDuration: 0.25, startsPaused: false)
            print("Playing player idle animation on child entity at index \(GameConfig.idleAnimationIndex)")
        } else {
            print("Player idle animation not found at index \(GameConfig.idleAnimationIndex)")
        }
    } else if let animation = capsule.availableAnimations.first {
        // No child entity, but capsule itself has animation
        capsule.playAnimation(animation.repeat(), transitionDuration: 0.25, startsPaused: false)
        print("Playing player animation on capsule entity")
    } else {
        print("No animations found on player or its child entity")
    }

    // Play LootBox animation repeatedly
    if let animationEntity = await lootBox.findEntity(named: GameConfig.lootBoxChildEntityName) {
        // Found child entity with animations
        let availableAnimations = animationEntity.availableAnimations
        if GameConfig.lootBoxAnimationIndex < availableAnimations.count {
            let lootBoxAnimation = availableAnimations[GameConfig.lootBoxAnimationIndex]
            animationEntity.playAnimation(lootBoxAnimation.repeat(), transitionDuration: 0.25, startsPaused: false)
            print("Playing loot box animation on child entity at index \(GameConfig.lootBoxAnimationIndex)")
        } else if let firstAnimation = availableAnimations.first {
            animationEntity.playAnimation(firstAnimation.repeat(), transitionDuration: 0.25, startsPaused: false)
            print("Playing first available loot box animation on child entity")
        }
    } else if let animation = lootBox.availableAnimations.first {
        // No child entity, but lootBox itself has animation
        lootBox.playAnimation(animation.repeat(), transitionDuration: 0.25, startsPaused: false)
        print("Playing loot box animation on lootBox entity")
    } else {
        print("No animations found on lootBox or its child entity")
    }
    
    print("Found capsule entity: \(capsule)")
    
    let camera = setupStaticMenuCamera(target: capsule)
    print("Created camera entity: \(camera)")
    
    content.add(loadedScene)
    print("Added loadedScene to RealityView content")
    
    content.add(camera)
    print("Added camera entity to RealityView content")
}


    private func setupStaticMenuCamera(target: Entity) -> Entity  {
        let camera = Entity()
        var cameraComponent = PerspectiveCameraComponent()
        cameraComponent.fieldOfViewInDegrees = 10
        camera.components.set(cameraComponent)

        let offset = SIMD3<Float>(0, 1, 4)
        camera.position = offset
        
        let lookAtOffset = SIMD3<Float>(x: target.position.x, y: target.position.y + 0.1, z: target.position.z)  // shift X-axis
        camera.look(at: lookAtOffset, from: camera.position, relativeTo: nil)


        //camera.look(at: target.position, from: camera.position, relativeTo: nil)

        //content.add(cameraEntity)
        return camera
    }





#Preview {
    MainMenuView(
        onStartGame: { print("Start game tapped") },
        onShowLeaderboard: { print("Show leaderboard tapped") },
        scoreManager: ScoreManager()
    )
}
