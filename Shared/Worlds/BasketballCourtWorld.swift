import CoreGraphics

/// Basketballs and soccer balls on a maple floor. A rim near the top of the
/// tray can catch a ball; the rest pile on the floor.
struct BasketballCourtWorld: MiniatureWorld {
    let id = WorldID.basketball
    let title = "Basketball Court"
    let summary = "Basketballs and soccer balls share the floor."

    let palette = FacePalette(
        outer: RGB(0.16, 0.07, 0.04),
        inner: RGB(0.55, 0.28, 0.12),
        bezel: RGB(0.95, 0.90, 0.82),
        tick: RGB(0.90, 0.82, 0.70),
        trayFill: RGB(0.76, 0.50, 0.24),
        trayStroke: RGB(0.96, 0.94, 0.90),
        time: RGB(0.99, 0.96, 0.92),
        date: RGB(0.99, 0.91, 0.78),
        accent: RGB(0.97, 0.97, 0.96)
    )

    let wallFriction: CGFloat = 0.45
    let wallRestitution: CGFloat = 0.40

    var bodies: [BodySpec] {
        Array(repeating: basketball, count: 7) + Array(repeating: soccer, count: 5)
    }

    var obstacles: [ObstacleSpec] {
        [
            ObstacleSpec(
                kind: .bar(length: 36, thickness: 3.5, angle: 0),
                unitCenter: CGPoint(x: 0, y: 0.86),
                fill: RGB(0.93, 0.94, 0.96),
                stroke: RGB(0.55, 0.58, 0.62)
            ),
            ObstacleSpec(
                kind: .arc(radius: 16, start: .pi, end: 0, clockwise: true, lineWidth: 2.4),
                unitCenter: CGPoint(x: 0, y: 0.55),
                fill: RGB(0.90, 0.90, 0.92),
                stroke: RGB(0.82, 0.84, 0.88)
            )
        ]
    }

    var decorations: [DecorationSpec] {
        let paint = RGB(0.97, 0.95, 0.92, 0.8)
        return [
            DecorationSpec(kind: .line(from: CGPoint(x: -0.34, y: -1), to: CGPoint(x: -0.34, y: 0.15), width: 1.3), color: paint),
            DecorationSpec(kind: .line(from: CGPoint(x: 0.34, y: -1), to: CGPoint(x: 0.34, y: 0.15), width: 1.3), color: paint),
            DecorationSpec(kind: .line(from: CGPoint(x: -0.34, y: 0.15), to: CGPoint(x: 0.34, y: 0.15), width: 1.3), color: paint),
            DecorationSpec(kind: .circle(center: CGPoint(x: 0, y: 0.15), radius: 16, width: 1.2), color: paint),
            DecorationSpec(kind: .line(from: CGPoint(x: -1, y: -0.72), to: CGPoint(x: 1, y: -0.72), width: 1.2), color: paint)
        ]
    }

    private var basketball: BodySpec {
        BodySpec(
            shape: .circle(radius: 9),
            fill: RGB(0.91, 0.36, 0.04),
            accent: RGB(0.12, 0.08, 0.06),
            seam: .basketball,
            mass: 0.22,
            friction: 0.55,
            restitution: 0.70,
            linearDamping: 0.16,
            angularDamping: 0.28
        )
    }

    private var soccer: BodySpec {
        BodySpec(
            shape: .circle(radius: 8),
            fill: RGB(0.96, 0.96, 0.94),
            accent: RGB(0.15, 0.15, 0.16),
            seam: .soccer,
            mass: 0.16,
            friction: 0.38,
            restitution: 0.58,
            linearDamping: 0.16,
            angularDamping: 0.24
        )
    }
}
