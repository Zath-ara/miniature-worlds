import CoreGraphics
import CoreMotion
import Foundation
import os

/// Sample rates and thresholds shared by the motion provider, the scene, and the docs.
enum MotionBudget {
    #if os(watchOS)
    static let sampleHz: Double = 30
    static let framesPerSecond: Int = 30
    #else
    static let sampleHz: Double = 60
    static let framesPerSecond: Int = 60
    #endif

    /// Smoothing time constant. Lower is snappier; 120 ms hides sensor noise
    /// without making the pile feel stuck to the wrist.
    static let smoothingTau: Double = 0.12

    /// User acceleration (gravity removed), in g, that counts as a shake.
    static let shakeAcceleration: Double = 2.3
    static let shakeGap: TimeInterval = 0.9
}

/// Reads `CMMotionManager` device-motion gravity and turns it into a planar
/// vector for `physicsWorld.gravity`.
///
/// `CMDeviceMotion.gravity` points toward the ground in the device frame:
/// +x to the right of the screen, +y toward the top, in units of g. SpriteKit
/// uses those same directions. The z component is ignored on purpose: a flat
/// face (gravity straight out of the glass) leaves x and y near zero, so the
/// pile rests instead of being flung.
///
/// Simulators report `isDeviceMotionAvailable == false`. In that case, and
/// whenever `forceManualTilt` is on, crown and drag feed `setManual` /
/// `setCrown` instead. Hardware updates are stopped while manual tilt is
/// active so a real watch is not sampling the accelerometer for nothing.
final class TiltMotionProvider {
    var onGravity: ((CGVector) -> Void)?
    var onShake: (() -> Void)?
    var onModeChange: ((Bool) -> Void)?

    private(set) var usingManualInput = true
    var forceManualTilt = false

    private let manager = CMMotionManager()
    private let log = Logger(subsystem: "com.zathara.miniatureworlds", category: "motion")
    private var smoother = GravitySmoother()
    private var hardwareStarted = false
    private var lastShake = Date.distantPast
    private var didLogHardware = false

    /// Starts sampling, or emits the manual vector when hardware should stay off.
    /// Safe to call on every transition to the active scene phase.
    func refreshMode() {
        let hardwareAvailable = manager.isDeviceMotionAvailable
        if !didLogHardware {
            didLogHardware = true
            let availability = hardwareAvailable ? "yes" : "no"
            log.info("Device motion available: \(availability, privacy: .public)")
        }
        let manual = forceManualTilt || !hardwareAvailable
        if manual != usingManualInput {
            usingManualInput = manual
            let mode = manual ? "manual" : "wrist"
            log.info("Tilt input: \(mode, privacy: .public)")
        }
        onModeChange?(manual)

        if manual {
            stopHardware()
            if !smootherIsPrimed {
                smoother.reset(to: CGVector(dx: 0, dy: -0.85))
                smootherIsPrimed = true
            }
            onGravity?(smoother.current)
        } else {
            startHardware()
        }
    }

    /// Stops accelerometer delivery. Does not clear the last gravity vector,
    /// so a paused scene keeps its pile where it was.
    func stop() {
        stopHardware()
    }

    /// Absolute tilt in g, same axes as device gravity. Ignored while wrist
    /// motion is driving the scene.
    func setManual(x: Double, y: Double) {
        guard usingManualInput else { return }
        let sample = CGVector(dx: clamp(x), dy: clamp(y))
        let filtered = smoother.filter(sample, alpha: 0.5)
        smootherIsPrimed = true
        onGravity?(filtered)
    }

    /// Maps one crown revolution onto the downhill direction. 0 points downhill
    /// toward the bottom of the dial.
    func setCrown(_ turns: Double) {
        guard usingManualInput else { return }
        var wrapped = turns.truncatingRemainder(dividingBy: 1)
        if wrapped < 0 { wrapped += 1 }
        let angle = wrapped * Double.pi * 2
        let magnitude = 0.92
        setManual(x: sin(angle) * magnitude, y: -cos(angle) * magnitude)
    }

    private var smootherIsPrimed = false

    private func startHardware() {
        guard manager.isDeviceMotionAvailable, !hardwareStarted else { return }
        hardwareStarted = true
        manager.deviceMotionUpdateInterval = 1.0 / MotionBudget.sampleHz
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            self?.ingest(data, error: error)
        }
    }

    private func stopHardware() {
        guard hardwareStarted else { return }
        hardwareStarted = false
        manager.stopDeviceMotionUpdates()
    }

    private func ingest(_ data: CMDeviceMotion?, error: Error?) {
        if let error {
            let message = error.localizedDescription
            log.error("Device motion error: \(message, privacy: .public)")
            return
        }
        guard let data else { return }
        let sample = CGVector(dx: clamp(data.gravity.x), dy: clamp(data.gravity.y))
        let dt = 1.0 / MotionBudget.sampleHz
        let alpha = CGFloat(1 - exp(-dt / MotionBudget.smoothingTau))
        let filtered = smoother.filter(sample, alpha: alpha)
        smootherIsPrimed = true
        onGravity?(filtered)
        noteShake(data.userAcceleration)
    }

    private func noteShake(_ acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x
                + acceleration.y * acceleration.y
                + acceleration.z * acceleration.z
        )
        guard magnitude > MotionBudget.shakeAcceleration else { return }
        let now = Date()
        guard now.timeIntervalSince(lastShake) > MotionBudget.shakeGap else { return }
        lastShake = now
        onShake?()
    }

    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(1.25, max(-1.25, value)))
    }
}
