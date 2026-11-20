import CoreGraphics
import Foundation

#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif

/// Rate-limited haptics for hard wall and obstacle hits.
///
/// Watch uses `WKInterfaceDevice` (a click for a hard hit). iPhone uses a light
/// impact, or a medium one when the approach speed is high. Calls are expected
/// on the main queue.
final class ImpactFeedback {
    private var lastHit = Date.distantPast
    private var lastAccent = Date.distantPast
    private let hitGap: TimeInterval = 0.14
    private let accentGap: TimeInterval = 0.35

    #if os(iOS)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    #endif

    func prepare() {
        #if os(iOS)
        light.prepare()
        medium.prepare()
        #endif
    }

    /// `approachSpeed` is how fast the body was moving into the surface, in points per second.
    func playWallHit(approachSpeed: CGFloat) {
        guard approachSpeed >= 240 else { return }
        guard acquire(&lastHit, gap: hitGap) else { return }
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #elseif os(iOS)
        if approachSpeed >= 640 {
            medium.impactOccurred(intensity: 0.9)
            medium.prepare()
        } else {
            light.impactOccurred(intensity: 0.65)
            light.prepare()
        }
        #endif
    }

    func playToss() {
        guard acquire(&lastAccent, gap: accentGap) else { return }
        #if os(watchOS)
        WKInterfaceDevice.current().play(.directionUp)
        #elseif os(iOS)
        light.impactOccurred(intensity: 0.45)
        light.prepare()
        #endif
    }

    func playScatter() {
        guard acquire(&lastAccent, gap: 0.7) else { return }
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #elseif os(iOS)
        medium.impactOccurred(intensity: 1)
        medium.prepare()
        #endif
    }

    private func acquire(_ stamp: inout Date, gap: TimeInterval) -> Bool {
        let now = Date()
        guard now.timeIntervalSince(stamp) >= gap else { return false }
        stamp = now
        return true
    }
}
