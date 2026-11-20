import CoreGraphics
import SpriteKit
import SwiftUI

// MARK: - Colors

/// Plain RGB so a world can describe colors without importing both UI kits at every call site.
struct RGB {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    func withAlpha(_ alpha: Double) -> RGB {
        RGB(r, g, b, alpha)
    }

    var skColor: SKColor {
        SKColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }

    var swiftUIColor: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    var cgColor: CGColor {
        CGColor(srgbRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
}

struct FacePalette {
    var outer: RGB
    var inner: RGB
    var bezel: RGB
    var tick: RGB
    var trayFill: RGB
    var trayStroke: RGB
    var time: RGB
    var date: RGB
    var accent: RGB
}

// MARK: - Specs

enum SeamStyle {
    case none
    case tennis
    case basketball
    case soccer
}

enum BodyShape {
    case circle(radius: CGFloat)
    case roundedRect(size: CGSize, corner: CGFloat)
    case diamond(radius: CGFloat)

    /// Radius used to keep spawns inside the tray. Sizes are reference-dial points.
    var referenceRadius: CGFloat {
        switch self {
        case let .circle(radius):
            return radius
        case let .roundedRect(size, _):
            return hypot(size.width, size.height) * 0.5
        case let .diamond(radius):
            return radius
        }
    }
}

struct BodySpec {
    var shape: BodyShape
    var fill: RGB
    var accent: RGB
    var seam: SeamStyle = .none
    var mass: CGFloat
    var friction: CGFloat
    var restitution: CGFloat
    var linearDamping: CGFloat
    var angularDamping: CGFloat
}

enum ObstacleKind {
    /// `length` runs along local +x before `angle` (radians) is applied.
    case bar(length: CGFloat, thickness: CGFloat, angle: CGFloat)
    case post(radius: CGFloat)
    /// Open arc. Angles are radians in SpriteKit space (0 is +x, counterclockwise).
    case arc(radius: CGFloat, start: CGFloat, end: CGFloat, clockwise: Bool, lineWidth: CGFloat)
}

struct ObstacleSpec {
    var kind: ObstacleKind
    /// Center in tray units. (0, 0) is the tray center, (0, 1) is the top edge.
    var unitCenter: CGPoint
    var fill: RGB
    var stroke: RGB
}

enum DecorationKind {
    case line(from: CGPoint, to: CGPoint, width: CGFloat)
    case circle(center: CGPoint, radius: CGFloat, width: CGFloat)
    case dot(center: CGPoint, radius: CGFloat)
}

struct DecorationSpec {
    var kind: DecorationKind
    var color: RGB
}

enum PhysicsCategory {
    static let dynamic: UInt32 = 1 << 0
    static let boundary: UInt32 = 1 << 1
    static let obstacle: UInt32 = 1 << 2
}

// MARK: - World

/// A miniature dial: palette, a handful of bodies, and a few fixed obstacles.
///
/// Sizes are points on a 190-point dial. `GameScene` scales them to the real face.
///
/// To add a world:
/// 1. Add a type under `Shared/Worlds` that conforms to `MiniatureWorld`.
/// 2. Append an instance to `WorldRegistry.all`.
/// 3. Add the new Swift file to both app targets' Compile Sources (the file is
///    not picked up automatically).
protocol MiniatureWorld {
    var id: String { get }
    var title: String { get }
    var summary: String { get }
    var palette: FacePalette { get }
    var bodies: [BodySpec] { get }
    var obstacles: [ObstacleSpec] { get }
    var decorations: [DecorationSpec] { get }
    var wallFriction: CGFloat { get }
    var wallRestitution: CGFloat { get }
}

extension MiniatureWorld {
    var decorations: [DecorationSpec] { [] }
    var wallFriction: CGFloat { 0.4 }
    var wallRestitution: CGFloat { 0.34 }
}

enum WorldID {
    static let treasure = "treasure-chest"
    static let tennis = "tennis-court"
    static let basketball = "basketball-court"
}

enum WorldStorage {
    static let themeKey = "selectedWorldID"
    static let manualKey = "manualTiltEnabled"
}

enum WorldRegistry {
    static let all: [any MiniatureWorld] = [
        TreasureChestWorld(),
        TennisCourtWorld(),
        BasketballCourtWorld()
    ]

    static func world(id: String) -> any MiniatureWorld {
        all.first { $0.id == id } ?? TreasureChestWorld()
    }
}
