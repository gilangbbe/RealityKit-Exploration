//
//  GameKitManager.swift
//  Astro Fight
//
//  Created by Copilot on 15/01/25.
//

import GameKit
import SwiftUI

class GameKitManager: NSObject, ObservableObject {
    static let shared = GameKitManager()
    
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var leaderboardScores: [GKLeaderboard.Entry] = []
    
    // Leaderboard ID - you'll need to create this in App Store Connect
    let leaderboardID = "astrofight.lb.astromaster"
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    func authenticatePlayer() {
        localPlayer = GKLocalPlayer.local
        
        localPlayer?.authenticateHandler = { [weak self] viewController, error in
            if let error = error {
                print("GameKit authentication error: \(error.localizedDescription)")
                return
            }
            
            if let viewController = viewController {
                // Present authentication view controller
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(viewController, animated: true)
                    }
                }
            } else if self?.localPlayer?.isAuthenticated == true {
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                    print("GameKit authentication successful: \(self?.localPlayer?.displayName ?? "Unknown")")
                }
            }
        }
    }
    
    func submitScore(_ score: Int) {
        guard isAuthenticated, let localPlayer = localPlayer else {
            print("Cannot submit score: Player not authenticated")
            return
        }
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: localPlayer,
                    leaderboardIDs: [leaderboardID]
                )
                print("Score submitted successfully: \(score)")
                await MainActor.run {
                    loadLeaderboardScores()
                }
            } catch {
                print("Error submitting score: \(error.localizedDescription)")
            }
        }
    }
    
    func loadLeaderboardScores() {
        guard isAuthenticated else { return }
        
        Task {
            do {
                let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
                guard let leaderboard = leaderboards.first else {
                    print("Leaderboard not found")
                    return
                }
                
                let entries = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 25))
                
                await MainActor.run {
                    self.leaderboardScores = entries.1 // entries.1 contains the array of entries
                }
            } catch {
                print("Error loading leaderboard scores: \(error.localizedDescription)")
            }
        }
    }
    
    func presentGameCenterLeaderboard() -> UIViewController? {
        guard isAuthenticated else { return nil }
        
        let leaderboardViewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        leaderboardViewController.gameCenterDelegate = self
        
        return leaderboardViewController
    }
    
    func presentGameCenterDashboard() -> UIViewController? {
        guard isAuthenticated else { return nil }
        
        let gameCenterViewController = GKGameCenterViewController(state: .leaderboards)
        gameCenterViewController.gameCenterDelegate = self
        
        return gameCenterViewController
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameKitManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Helper Extensions
extension GKLeaderboard.Entry {
    var playerDisplayName: String {
        return player.displayName
    }
    
    var scoreValue: Int {
        return score
    }
}
