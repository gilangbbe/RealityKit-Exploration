//
//  RealityKit_ExplorationApp.swift
//  RealityKit-Exploration
//
//  Created by Gilang Banyu Biru Erassunu on 10/07/25.
//

import SwiftUI
import GameKit

@main
struct RealityKit_ExplorationApp: App {
    init() {
        // Initialize GameKit when app starts
        _ = GameKitManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
