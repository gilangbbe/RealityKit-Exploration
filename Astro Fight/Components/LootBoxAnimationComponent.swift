import RealityKit
import Foundation

// Component for tracking LootBox animation state
struct LootBoxAnimationComponent: Component, Codable {
    var isAnimating: Bool = false
    var animationChildEntityName: String = "LootBox"
    var animationController: AnimationPlaybackController? = nil
    
    // Enemy interaction states
    var isEnemyPhasing: Bool = false
    var enemiesCurrentlyPhasing: Set<String> = []  // Track which enemies are currently phasing through
    var phasingStartTime: TimeInterval = 0
    
    // Position tracking for height adjustments
    var originalPosition: SIMD3<Float>? = nil
    var isElevated: Bool = false
    var isAnimatingPosition: Bool = false
    
    // Default initializer
    init() {
        // All properties already have default values
    }
    
    // Custom coding implementation to handle AnimationPlaybackController
    enum CodingKeys: String, CodingKey {
        case isAnimating, animationChildEntityName, isEnemyPhasing, phasingStartTime, isElevated, isAnimatingPosition
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isAnimating, forKey: .isAnimating)
        try container.encode(animationChildEntityName, forKey: .animationChildEntityName)
        try container.encode(isEnemyPhasing, forKey: .isEnemyPhasing)
        try container.encode(phasingStartTime, forKey: .phasingStartTime)
        try container.encode(isElevated, forKey: .isElevated)
        try container.encode(isAnimatingPosition, forKey: .isAnimatingPosition)
        // Note: animationController, enemiesCurrentlyPhasing, and originalPosition are not encoded as they're runtime state
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isAnimating = try container.decodeIfPresent(Bool.self, forKey: .isAnimating) ?? false
        animationChildEntityName = try container.decodeIfPresent(String.self, forKey: .animationChildEntityName) ?? "LootBox"
        isEnemyPhasing = try container.decodeIfPresent(Bool.self, forKey: .isEnemyPhasing) ?? false
        phasingStartTime = try container.decodeIfPresent(TimeInterval.self, forKey: .phasingStartTime) ?? 0
        isElevated = try container.decodeIfPresent(Bool.self, forKey: .isElevated) ?? false
        isAnimatingPosition = try container.decodeIfPresent(Bool.self, forKey: .isAnimatingPosition) ?? false
        animationController = nil // Will be set at runtime
        enemiesCurrentlyPhasing = [] // Will be populated at runtime
        originalPosition = nil // Will be set when lootbox is spawned
    }
}
