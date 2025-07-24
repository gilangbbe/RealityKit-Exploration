import RealityKit
import Foundation

// Component for tracking LootBox animation state
struct LootBoxAnimationComponent: Component, Codable {
    var isAnimating: Bool = false
    var animationChildEntityName: String = "LootBox"
    var animationController: AnimationPlaybackController? = nil
    
    // Default initializer
    init() {
        // All properties already have default values
    }
    
    // Custom coding implementation to handle AnimationPlaybackController
    enum CodingKeys: String, CodingKey {
        case isAnimating, animationChildEntityName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isAnimating, forKey: .isAnimating)
        try container.encode(animationChildEntityName, forKey: .animationChildEntityName)
        // Note: animationController is not encoded as it's runtime state
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isAnimating = try container.decodeIfPresent(Bool.self, forKey: .isAnimating) ?? false
        animationChildEntityName = try container.decodeIfPresent(String.self, forKey: .animationChildEntityName) ?? "LootBox"
        animationController = nil // Will be set at runtime
    }
}
