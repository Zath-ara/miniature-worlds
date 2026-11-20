import CoreGraphics

/// Fractions of the dial diameter. Both the SpriteKit tray and the SwiftUI
/// clock use these so the time stays in the bezel and the pile stays in the tray.
enum DialLayout {
    /// Body and obstacle sizes in the world files are authored against this dial.
    static let referenceDiameter: CGFloat = 190

    static let trayWidthRatio: CGFloat = 0.80
    static let trayHeightRatio: CGFloat = 0.50
    static let trayDropRatio: CGFloat = 0.08

    static let clockTopRatio: CGFloat = 0.075
    static let timeFontRatio: CGFloat = 0.145
    static let dateFontRatio: CGFloat = 0.050
    static let footerBottomRatio: CGFloat = 0.055

    /// Points per g, scaled up for larger dials so a tilt feels the same on
    /// a watch and on the phone's big circle.
    static func gravityScale(diameter: CGFloat) -> CGFloat {
        max(diameter, 1) / referenceDiameter * 1100
    }

    static func scale(diameter: CGFloat) -> CGFloat {
        max(diameter, 1) / referenceDiameter
    }
}
