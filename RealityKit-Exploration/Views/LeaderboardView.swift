import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var scoreManager: ScoreManager
    @State private var showingClearAlert = false
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Solid Background
            Color.black
                .ignoresSafeArea()
            
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Leaderboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(scoreManager.totalGamesPlayed) Games Played")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                // Statistics Summary
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "High Score",
                            value: "\(scoreManager.highScore)",
                            icon: "crown.fill",
                            color: .yellow
                        )
                        
                        StatCard(
                            title: "Average Score",
                            value: String(format: "%.0f", scoreManager.averageScore),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Enemies",
                            value: "\(scoreManager.totalEnemiesDefeated)",
                            icon: "target",
                            color: .red
                        )
                        
                        StatCard(
                            title: "Highest Wave",
                            value: "\(scoreManager.highestWaveReached)",
                            icon: "flag.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Score List
                if scoreManager.scores.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Games Played Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Start playing to see your scores here!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(scoreManager.scores.enumerated()), id: \.element.id) { index, score in
                                ScoreRowView(score: score, rank: index + 1)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    // Clear Scores Button
                    if !scoreManager.scores.isEmpty {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear History")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                    }
                    
                    // Back Button
                    Button(action: {
                        onBack()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back to Menu")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .alert("Clear Score History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                scoreManager.clearAllScores()
            }
        } message: {
            Text("This will permanently delete all your score history. This action cannot be undone.")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 80)
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ScoreRowView: View {
    let score: GameScore
    let rank: Int
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "\(rank).circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Image(systemName: rankIcon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            // Score Details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(score.score)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(score.formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 16) {
                    Label("\(score.enemiesDefeated)", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Label("Wave \(score.wavesCompleted)", systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label(score.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rankColor.opacity(0.3), lineWidth: rank <= 3 ? 2 : 1)
                )
        )
    }
}

#Preview {
    LeaderboardView(scoreManager: ScoreManager(), onBack: {})
}
