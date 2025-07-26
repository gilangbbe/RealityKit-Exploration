import SwiftUI
import GameKit

struct LeaderboardView: View {
    @ObservedObject var scoreManager: ScoreManager
    @State private var showingClearAlert = false
    @StateObject private var gameKitManager = GameKitManager.shared
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
                    HStack {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Leaderboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if gameKitManager.isAuthenticated {
                            Button(action: {
                                gameKitManager.loadLeaderboardScores()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Text("\(scoreManager.totalGamesPlayed) Games Played")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                .padding(.horizontal)
                
                // Personal Best Card
                if let bestScore = scoreManager.bestScore {
                    PersonalBestCard(score: bestScore)
                        .padding(.horizontal)
                }
                
                // Global Leaderboard Content
                if !gameKitManager.isAuthenticated {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Game Center Required")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Sign in to Game Center to view global leaderboards and compete with your friends.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            gameKitManager.authenticatePlayer()
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Sign In to Game Center")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.8))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Global Scores List
                    if gameKitManager.leaderboardScores.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "network")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Loading Global Scores...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Fetching the latest scores from Game Center")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            gameKitManager.loadLeaderboardScores()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(gameKitManager.leaderboardScores.enumerated()), id: \.element.player.gamePlayerID) { index, entry in
                                    GlobalScoreRowView(
                                        entry: entry, 
                                        rank: index + 1,
                                        isCurrentPlayer: entry.player.gamePlayerID == gameKitManager.localPlayer?.gamePlayerID
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .refreshable {
                            gameKitManager.loadLeaderboardScores()
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    // Clear Best Score Button
                    if scoreManager.bestScore != nil {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Best")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.6), lineWidth: 3)
                                    )
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
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.6), lineWidth: 3)
                                )
                        )
                        .shadow(color: Color.purple.opacity(0.8), radius: 6, x: 0, y: 0)
                        .shadow(color: Color.purple.opacity(0.8), radius: 12, x: 0, y: 0)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .alert("Clear Best Score", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                scoreManager.clearBestScore()
            }
        } message: {
            Text("This will permanently delete your best score. This action cannot be undone.")
        }
    }
}

// MARK: - Personal Best Card
struct PersonalBestCard: View {
    let score: GameScore
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Your Best Score")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(score.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(score.enemiesDefeated)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Enemies")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(score.wavesCompleted)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Waves")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text(score.formattedDuration)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text(score.formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

struct GlobalScoreRowView: View {
    let entry: GKLeaderboard.Entry
    let rank: Int
    let isCurrentPlayer: Bool
    
    private var rankColor: Color {
        if isCurrentPlayer {
            return .yellow
        }
        switch rank {
        case 1: return .gold
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
            
            // Player Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.playerDisplayName)
                        .font(.headline)
                        .foregroundColor(isCurrentPlayer ? .yellow : .white)
                        .lineLimit(1)
                    
                    if isCurrentPlayer {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    Text("\(entry.scoreValue)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentPlayer ? .yellow : .blue)
                }
                
                HStack {
                    Image(systemName: isCurrentPlayer ? "person.fill" : "globe")
                        .font(.caption)
                        .foregroundColor(isCurrentPlayer ? .yellow : .blue)
                    
                    Text(isCurrentPlayer ? "Your Score" : "Global Player")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if rank <= 3 {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(rankColor)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rankColor.opacity(0.3), lineWidth: isCurrentPlayer ? 3 : (rank <= 3 ? 2 : 1))
                )
        )
        .overlay(
            // Highlight border for current player
            isCurrentPlayer ? 
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow, lineWidth: 2) : nil
        )
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    LeaderboardView(scoreManager: ScoreManager(), onBack: {})
}
