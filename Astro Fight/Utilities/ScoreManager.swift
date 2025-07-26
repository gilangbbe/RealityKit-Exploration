import Foundation
import GameKit

struct GameScore: Codable, Identifiable {
    let id = UUID()
    let score: Int
    let enemiesDefeated: Int
    let wavesCompleted: Int
    let date: Date
    let duration: TimeInterval
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class ScoreManager: ObservableObject {
    @Published var bestScore: GameScore?
    @Published var totalGamesPlayed: Int = 0
    @Published var totalEnemiesDefeated: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let bestScoreKey = "BestScore"
    private let totalGamesKey = "TotalGames"
    private let totalEnemiesKey = "TotalEnemies"
    
    init() {
        loadData()
    }
    
    func addScore(score: Int, enemiesDefeated: Int, wavesCompleted: Int, gameDuration: TimeInterval) {
        // Increment total games played
        totalGamesPlayed += 1
        totalEnemiesDefeated += enemiesDefeated
        
        // Check if this is a new best score
        let newScore = GameScore(
            score: score,
            enemiesDefeated: enemiesDefeated,
            wavesCompleted: wavesCompleted,
            date: Date(),
            duration: gameDuration
        )
        
        if bestScore == nil || score > bestScore!.score {
            bestScore = newScore
            // Submit to GameKit only when we have a new best score
            GameKitManager.shared.submitScore(score)
        }
        
        saveData()
    }
    
    func clearBestScore() {
        bestScore = nil
        totalGamesPlayed = 0
        totalEnemiesDefeated = 0
        saveData()
    }
    
    var highScore: Int {
        return bestScore?.score ?? 0
    }
    
    var highestWaveReached: Int {
        return bestScore?.wavesCompleted ?? 0
    }
    
    private func saveData() {
        // Save best score
        if let bestScore = bestScore {
            do {
                let data = try JSONEncoder().encode(bestScore)
                userDefaults.set(data, forKey: bestScoreKey)
            } catch {
                print("Failed to save best score: \(error)")
            }
        } else {
            userDefaults.removeObject(forKey: bestScoreKey)
        }
        
        // Save statistics
        userDefaults.set(totalGamesPlayed, forKey: totalGamesKey)
        userDefaults.set(totalEnemiesDefeated, forKey: totalEnemiesKey)
    }
    
    private func loadData() {
        // Load best score
        if let data = userDefaults.data(forKey: bestScoreKey) {
            do {
                bestScore = try JSONDecoder().decode(GameScore.self, from: data)
            } catch {
                print("Failed to load best score: \(error)")
                bestScore = nil
            }
        }
        
        // Load statistics
        totalGamesPlayed = userDefaults.integer(forKey: totalGamesKey)
        totalEnemiesDefeated = userDefaults.integer(forKey: totalEnemiesKey)
    }
}
