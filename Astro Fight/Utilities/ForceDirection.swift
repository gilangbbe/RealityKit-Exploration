import simd

enum ForceDirection {
    case up, down, left, right
    var symbol: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .left: return "arrow.left.circle.fill"
        case .right: return "arrow.right.circle.fill"
        }
    }
    var velocity: SIMD3<Float> {
        switch self {
        case .up: return [0, 0, -1]
        case .down: return [0, 0, 1]
        case .left: return [-1, 0, 0]
        case .right: return [1, 0, 0]
        }
    }
}
