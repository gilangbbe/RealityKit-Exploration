import Foundation

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
    @Published var scores: [GameScore] = []
    private let userDefaults = UserDefaults.standard
    private let scoresKey = "GameScores"
    
    init() {
        loadScores()
    }
    
    func addScore(score: Int, enemiesDefeated: Int, wavesCompleted: Int, duration: TimeInterval) {
        let newScore = GameScore(
            score: score,
            enemiesDefeated: enemiesDefeated,
            wavesCompleted: wavesCompleted,
            date: Date(),
            duration: duration
        )
        
        scores.append(newScore)
        scores.sort { $0.score > $1.score } // Sort by score descending
        
        // Keep only top 50 scores to prevent unlimited growth
        if scores.count > 50 {
            scores = Array(scores.prefix(50))
        }
        
        saveScores()
    }
    
    func clearAllScores() {
        scores.removeAll()
        saveScores()
    }
    
    var highScore: Int {
        return scores.first?.score ?? 0
    }
    
    var totalGamesPlayed: Int {
        return scores.count
    }
    
    var averageScore: Double {
        guard !scores.isEmpty else { return 0 }
        let total = scores.reduce(0) { $0 + $1.score }
        return Double(total) / Double(scores.count)
    }
    
    var totalEnemiesDefeated: Int {
        return scores.reduce(0) { $0 + $1.enemiesDefeated }
    }
    
    var highestWaveReached: Int {
        return scores.max { $0.wavesCompleted < $1.wavesCompleted }?.wavesCompleted ?? 0
    }
    
    private func saveScores() {
        do {
            let data = try JSONEncoder().encode(scores)
            userDefaults.set(data, forKey: scoresKey)
        } catch {
            print("Failed to save scores: \(error)")
        }
    }
    
    private func loadScores() {
        guard let data = userDefaults.data(forKey: scoresKey) else { return }
        
        do {
            scores = try JSONDecoder().decode([GameScore].self, from: data)
            scores.sort { $0.score > $1.score }
        } catch {
            print("Failed to load scores: \(error)")
            scores = []
        }
    }
}
