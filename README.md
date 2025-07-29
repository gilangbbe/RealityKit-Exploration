# Astro Fights: A 3D Physics-Based Arena Brawler 🤖💥

## ✨ Overview
Welcome to **Astro Fights**, a dynamic and engaging hypercasual game for iOS where survival depends on your ability to dominate a high-tech arena. A spiritual successor to *Astro Flights*, this project evolves the concept into a fully 3D world built with **RealityKit** and **SwiftUI**. Players control a charming robot in a physics-based "sumo" battle, tasked with knocking waves of enemies off the platform to claim victory and climb the leaderboards.
The game is a showcase of modern iOS development, using RealityKit's powerful Entity Component System (ECS) for gameplay logic and SwiftUI for a clean, responsive user interface.

## 🔋 Key Features
  * 💥 **Physics-Based Brawler Gameplay** — Engage in thrilling, wave-based survival combat where the goal is to push enemies off the arena using strategic movement and powerful abilities.
  * ⚡️ **Dynamic Power-Up System** — Turn the tide of battle by collecting loot boxes that grant temporary abilities, including a powerful **Shockwave** to clear the area and **Time Slow** to deftly outmaneuver opponents.
  * 📈 **Roguelike Upgrade Progression** — Survive a wave and be rewarded with a choice of powerful, permanent upgrades for that run. Enhance your robot's **Force**, **Resilience**, or **Speed** to build a unique fighting style with each game.
  * 🏆 **Full GameKit Integration** — Compete for the top spot\! The game features leaderboards to track high scores and achievements to reward strategic milestones.
  * 🎨 **Modern Hybrid Architecture** — A cutting-edge combination of Apple's latest frameworks:
      * **RealityKit**: Drives the entire 3D gameplay scene, including physics simulations, animations, rendering, and spatial audio.
      * **SwiftUI**: Powers all 2D UI elements, such as the main menu, in-game HUD, pause screen, and the dynamic upgrade selection interface.
  * 🕹️ **Intuitive Controls** — A smooth, virtual on-screen joystick provides precise control over the player's movement, making the gameplay accessible and engaging.
  * 🎧 **Immersive Audio & Visuals** — The experience is enhanced with custom 3D models, engaging animations, and satisfying sound effects for every action.

## 🌟 See Astro Fights in Action\! 📸
<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;">
    <img src="https://drive.google.com/uc?id=------" alt="Screenshot 1" style="width: 70%;"/>
    <img src="https://drive.google.com/uc?id=------" alt="Screenshot 2" style="width: 70%;"/>
    <img src="https://drive.google.com/uc?id=------" alt="Screenshot 3" style="width: 70%;"/>
    <img src="https://drive.google.com/uc?id=------" alt="Screenshot 4" style="width: 70%;"/>
    <img src="https://drive.google.com/uc?id=------" alt="Screenshot 5" style="width: 70%;"/>
</div>

## 🧑‍💻 How It Works
1.  **Entity Component System (ECS)**: The game is built on RealityKit's ECS architecture. Entities like the player and enemies have components (`PlayerProgressionComponent`, `HealthComponent`) that store their data.
2.  **Logic in Systems**: All gameplay logic is handled by Systems (`WaveSystem`, `EnemyCapsuleSystem`, `PhysicsMovementSystem`) that query entities and update them each frame.
3.  **SwiftUI for UI & State**: A main `ContentView` in SwiftUI manages the overall game state (e.g., `mainMenu`, `playing`, `gameOver`). It renders UI overlays like the HUD and menus on top of the game scene.
4.  **RealityView Integration**: A `RealityView` is used within SwiftUI to host the 3D game world. It is responsible for setting up the initial scene, including models, lighting, and physics.
5.  **Player Input**: The `AnalogJoystick` is a custom SwiftUI view that translates touch input into movement vectors, which are then passed to the `PhysicsMovementSystem` to apply forces to the player entity.

## ⚙️ Tech Stack
  * **UI Framework**: SwiftUI
  * **3D Engine / Framework**: RealityKit
  * **AR / World Tracking**: ARKit (for scene setup)
  * **Services**: GameKit (Game Center)
  * **Audio**: AVFoundation

## 🚀 Getting Started
Follow these steps to get Astro Fights up and running on your local machine using Xcode.

### Prerequisites
  * [macOS](https://www.google.com/search?q=https://www.apple.com/macos/) (latest version recommended)
  * [Xcode](https://developer.apple.com/xcode/) (version 15 or higher)
  * An ARKit-compatible iOS device (iPhone or iPad) is recommended for the best experience.
  * An active [Apple Developer Account](https://developer.apple.com/programs/enroll/) (required for Game Center features).

### Installation & Setup
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/streynaldo/realitykit-exploration.git
    cd realitykit-exploration
    ```

2.  **Open the project in Xcode:**
      * Double-click the `Astro Fight.xcodeproj` file to launch the project.

3.  **Configure Signing & Capabilities:**
      * In the Project Navigator, select the project file, then select the "Astro Fight" target.
      * Go to the **"Signing & Capabilities"** tab.
      * Select your developer account from the **"Team"** dropdown.
      * Ensure **Game Center** is added as a capability.

4.  **Run the application:**
      * Select an iOS Simulator or a connected physical device from the scheme menu.
      * Press the **Run** button (▶︎) or use the shortcut `Cmd + R`.

## 🤝 Contributors
  * 🧑‍💻 **Gilang Banyu Biru** : [@gilangbbe](https://github.com/gilangbbe)
  * 👩‍💻 **Gabriella Davis** : [@gabriellanatasya](https://github.com/gabriellanatasya)
