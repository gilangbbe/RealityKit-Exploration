import SwiftUI

struct ProgressionDebugView: View {
    let currentWave: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progression Stats")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Enemy Count: \(calculateEnemyCount())")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text("Upgrade Power: \(String(format: "%.1f%%", calculateUpgradePower() * 100))")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text("Score Bonus: \(calculateScoreBonus())")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.7))
        )
    }
    
    private func calculateEnemyCount() -> Int {
        let baseEnemies = GameConfig.baseEnemiesPerWave
        var totalIncrease = 0
        for wave in 1..<currentWave {
            let diminishingMultiplier = pow(GameConfig.enemyCountDiminishingFactor, Float(wave - 1))
            totalIncrease += Int(Float(GameConfig.enemyCountIncreasePerWave) * diminishingMultiplier)
        }
        return baseEnemies + totalIncrease
    }
    
    private func calculateUpgradePower() -> Float {
        let diminishingMultiplier = pow(GameConfig.playerUpgradeDiminishingFactor, Float(max(0, currentWave - 2)))
        return diminishingMultiplier
    }
    
    private func calculateScoreBonus() -> Int {
        var totalBonus = 0
        for completedWave in 1..<currentWave {
            let diminishingMultiplier = pow(GameConfig.waveScoreDiminishingFactor, Float(completedWave - 1))
            let waveBonus = Int(Float(GameConfig.waveScoreMultiplier) * diminishingMultiplier)
            totalBonus += waveBonus
        }
        return totalBonus
    }
}
