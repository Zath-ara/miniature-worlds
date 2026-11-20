import Combine
import Foundation

/// Owns the scene, the motion source, and haptics for one SwiftUI screen.
///
/// Sampling starts only while the scene is active. `scenePhase` (wrist down,
/// app backgrounded, cover closed) calls `setRunning(false)`, which pauses the
/// SpriteKit scene and stops `CMMotionManager`.
final class WorldSession: ObservableObject {
    let scene: GameScene
    let motion = TiltMotionProvider()
    let haptics = ImpactFeedback()

    /// "Wrist" or "Crown or drag". Empty until the first `refreshMode`.
    @Published private(set) var inputDescription = ""

    private var sceneRunning = false

    init() {
        let storedID = UserDefaults.standard.string(forKey: WorldStorage.themeKey)
        let scene = GameScene(theme: WorldRegistry.world(id: storedID ?? WorldID.treasure))
        self.scene = scene

        scene.onImpact = { [weak self] speed in
            self?.haptics.playWallHit(approachSpeed: speed)
        }
        motion.onGravity = { [weak scene] vector in
            scene?.applyGravity(vector)
        }
        motion.onShake = { [weak self] in
            self?.scatter()
        }
        motion.onModeChange = { [weak self] manual in
            DispatchQueue.main.async {
                self?.setInputDescription(manual: manual)
            }
        }
        motion.forceManualTilt = UserDefaults.standard.bool(forKey: WorldStorage.manualKey)
    }

    func setRunning(_ running: Bool) {
        sceneRunning = running
        scene.isPaused = !running
        if running {
            haptics.prepare()
            motion.refreshMode()
        } else {
            motion.stop()
        }
    }

    func reloadPreferences() {
        let id = UserDefaults.standard.string(forKey: WorldStorage.themeKey) ?? WorldID.treasure
        applyTheme(id: id)
        setManualOverride(UserDefaults.standard.bool(forKey: WorldStorage.manualKey))
    }

    func applyTheme(id: String) {
        scene.apply(theme: WorldRegistry.world(id: id))
    }

    func setManualOverride(_ enabled: Bool) {
        motion.forceManualTilt = enabled
        if sceneRunning {
            motion.refreshMode()
        }
    }

    func toss() {
        guard scene.toss() else { return }
        haptics.playToss()
    }

    func scatter() {
        scene.scatter()
        haptics.playScatter()
    }

    private func setInputDescription(manual: Bool) {
        let text = manual ? "Crown or drag" : "Wrist"
        guard text != inputDescription else { return }
        inputDescription = text
    }
}
