import CoreGraphics
import Foundation

/// Exponential smoothing for the gravity vector.
///
/// `alpha` is the blend toward the new sample (0 keeps the old value, 1 snaps).
/// Callers that know the sample interval should pass `1 - exp(-dt / tau)`.
struct GravitySmoother {
    private(set) var current = CGVector.zero
    private var primed = false

    mutating func reset(to value: CGVector) {
        current = value
        primed = true
    }

    mutating func filter(_ sample: CGVector, alpha: CGFloat) -> CGVector {
        if !primed {
            current = sample
            primed = true
            return current
        }
        let blend = min(max(alpha, 0), 1)
        current.dx += (sample.dx - current.dx) * blend
        current.dy += (sample.dy - current.dy) * blend
        return current
    }
}
