import SpriteKit
import SwiftUI

/// Shared dial screen for the iOS and watchOS targets.
///
/// The clock is a SwiftUI overlay so the type stays sharp; the tray under it
/// is the SpriteKit world. Time and date sit in the upper bezel, outside the
/// physics tray. On watchOS the Digital Crown sets the downhill direction when
/// manual tilt is active (always, in the simulator).
struct ContentView: View {
    @StateObject private var session = WorldSession()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(WorldStorage.themeKey) private var themeID = WorldID.treasure
    @AppStorage(WorldStorage.manualKey) private var forceManualTilt = false

    #if os(watchOS)
    @State private var crown: Double = 0
    @FocusState private var crownFocused: Bool
    #endif

    var body: some View {
        NavigationStack {
            dial
                .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .persistentSystemOverlays(.hidden)
        #endif
        .onAppear {
            session.reloadPreferences()
            session.setRunning(scenePhase == .active)
            #if os(watchOS)
            crownFocused = true
            #endif
        }
        .onDisappear {
            session.setRunning(false)
        }
        .onChange(of: scenePhase) { _, phase in
            session.setRunning(phase == .active)
        }
        .onChange(of: themeID) { _, id in
            session.applyTheme(id: id)
        }
        .onChange(of: forceManualTilt) { _, enabled in
            session.setManualOverride(enabled)
        }
    }

    private var theme: any MiniatureWorld {
        WorldRegistry.world(id: themeID)
    }

    private var dial: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height) * dialScale
            ZStack {
                backdrop.ignoresSafeArea()
                face(side: side)
                    .frame(width: side, height: side)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
            }
        }
        .ignoresSafeArea()
    }

    private var dialScale: CGFloat {
        #if os(watchOS)
        1
        #else
        0.94
        #endif
    }

    private var backdrop: Color {
        #if os(watchOS)
        Color.black
        #else
        Color(red: 0.03, green: 0.035, blue: 0.045)
        #endif
    }

    @ViewBuilder
    private func face(side: CGFloat) -> some View {
        DialSprite(scene: session.scene, isPaused: scenePhase != .active)
        .equatable()
        .frame(width: side, height: side)
        .clipShape(Circle())
        .contentShape(Circle())
        .gesture(tiltGesture(side: side))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                session.scatter()
            }
        )
        .overlay {
            chrome(side: side)
        }
        .overlay {
            Circle()
                .stroke(theme.palette.bezel.swiftUIColor.opacity(0.9), lineWidth: max(1.5, side * 0.008))
                .allowsHitTesting(false)
        }
        #if os(iOS)
        .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        #endif
        #if os(watchOS)
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation(
            $crown,
            from: -1000,
            through: 1000,
            by: 0.01,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: false
        )
        .onChange(of: crown) { _, value in
            session.motion.setCrown(value)
        }
        #endif
        .accessibilityElement(children: .contain)
    }

    private func chrome(side: CGFloat) -> some View {
        VStack(spacing: 0) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 1) {
                    Text(FaceFormat.time(from: context.date))
                        .font(.system(size: side * DialLayout.timeFontRatio, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(theme.palette.time.swiftUIColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("\(FaceFormat.date.string(from: context.date)) · \(theme.title)")
                        .font(.system(size: side * DialLayout.dateFontRatio, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.palette.date.swiftUIColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            .allowsHitTesting(false)
            .padding(.top, side * DialLayout.clockTopRatio)
            .accessibilityAddTraits(.updatesFrequently)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text(session.inputDescription)
                    .font(.system(size: max(9, side * 0.04), weight: .medium, design: .rounded))
                    .foregroundStyle(theme.palette.date.swiftUIColor)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                Spacer(minLength: 0)
                NavigationLink {
                    SettingsView {
                        session.reloadPreferences()
                    }
                } label: {
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: max(11, side * 0.055), weight: .semibold))
                        .foregroundStyle(theme.palette.time.swiftUIColor)
                        .frame(width: max(26, side * 0.12), height: max(26, side * 0.12))
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose world")
            }
            .padding(.horizontal, side * 0.14)
            .padding(.bottom, side * DialLayout.footerBottomRatio)
        }
        .frame(width: side, height: side)
    }

    private func tiltGesture(side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard session.motion.usingManualInput else { return }
                let half = side * 0.5
                guard half > 1 else { return }
                let dx = (value.location.x - half) / half
                let dy = (half - value.location.y) / half
                session.motion.setManual(x: Double(dx), y: Double(dy))
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if distance < 12 {
                    session.toss()
                }
            }
    }
}

/// Isolated from the one-second clock. `Equatable` keeps SpriteKit from being
/// rebuilt on every clock tick; the view updates when pause state changes.
private struct DialSprite: View, Equatable {
    var scene: GameScene
    var isPaused: Bool

    static func == (lhs: DialSprite, rhs: DialSprite) -> Bool {
        lhs.isPaused == rhs.isPaused && lhs.scene === rhs.scene
    }

    var body: some View {
        SpriteView(
            scene: scene,
            isPaused: isPaused,
            preferredFramesPerSecond: MotionBudget.framesPerSecond
        )
    }
}

private enum FaceFormat {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return formatter
    }()

    static func time(from date: Date) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour24 = parts.hour ?? 0
        let minute = parts.minute ?? 0
        let hour = hour24 % 12 == 0 ? 12 : hour24 % 12
        return "\(hour):" + String(format: "%02d", minute)
    }
}

#Preview {
    ContentView()
}
