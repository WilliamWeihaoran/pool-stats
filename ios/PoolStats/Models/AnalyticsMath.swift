import Foundation

extension Analytics {
    static func clamp(_ v: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, v))
    }
}
