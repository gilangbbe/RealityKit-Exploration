import Foundation

/// Monitors game performance and provides feedback for optimization
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var enemyCount: Int = 0
    @Published var averageFrameTime: Double = 0.0
    
    private var frameTimestamps: [Date] = []
    private let maxSamples = 60 // Track last 60 frames
    private var lastUpdateTime: Date = Date()
    
    private init() {}
    
    func recordFrame() {
        let now = Date()
        frameTimestamps.append(now)
        
        // Keep only recent frames
        if frameTimestamps.count > maxSamples {
            frameTimestamps.removeFirst()
        }
        
        // Calculate FPS
        if frameTimestamps.count >= 2 {
            let timeSpan = frameTimestamps.last!.timeIntervalSince(frameTimestamps.first!)
            currentFPS = Double(frameTimestamps.count - 1) / timeSpan
        }
        
        // Calculate average frame time
        if frameTimestamps.count >= 2 {
            let frameTime = now.timeIntervalSince(lastUpdateTime)
            averageFrameTime = frameTime * 1000 // Convert to milliseconds
        }
        
        lastUpdateTime = now
    }
    
    func updateEnemyCount(_ count: Int) {
        enemyCount = count
    }
    
    /// Returns true if performance is poor and optimizations should be more aggressive
    var shouldUseAggressiveOptimizations: Bool {
        return currentFPS < 30.0 || enemyCount > GameConfig.spawnRateReductionThreshold
    }
    
    /// Returns a performance score from 0 (poor) to 1 (excellent)
    var performanceScore: Double {
        let fpsScore = min(currentFPS / 60.0, 1.0)
        let enemyScore = 1.0 - (Double(enemyCount) / Double(GameConfig.maxSimultaneousEnemies))
        return (fpsScore + enemyScore) / 2.0
    }
}
