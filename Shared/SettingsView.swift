import SwiftUI

/// Theme picker. The choice is stored in `UserDefaults` (`@AppStorage`) so it
/// survives leaving the app. `onChange` lets the dial rebuild immediately.
struct SettingsView: View {
    var onChange: () -> Void

    @AppStorage(WorldStorage.themeKey) private var themeID = WorldID.treasure
    @AppStorage(WorldStorage.manualKey) private var forceManualTilt = false

    var body: some View {
        List {
            Section {
                ForEach(WorldRegistry.all, id: \.id) { world in
                    Button {
                        themeID = world.id
                        onChange()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(world.palette.trayFill.swiftUIColor)
                                .overlay(Circle().stroke(world.palette.bezel.swiftUIColor, lineWidth: 1.5))
                                .frame(width: 18, height: 18)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(world.title)
                                    .foregroundStyle(.primary)
                                Text(world.summary)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(world.bodies.count) objects")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer(minLength: 8)
                            if world.id == themeID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(world.palette.bezel.swiftUIColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("World")
            }

            Section {
                Toggle("Use crown and drag", isOn: $forceManualTilt)
                    .onChange(of: forceManualTilt) { _, _ in
                        onChange()
                    }
            } header: {
                Text("Tilt")
            } footer: {
                Text("Simulators have no accelerometer, so the crown and drag are used automatically. Turn this on to ignore wrist motion on a real iPhone or Watch. Shake the wrist to scatter the pile, or long-press the dial.")
            }
        }
        .navigationTitle("Worlds")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar(.visible, for: .navigationBar)
    }
}
