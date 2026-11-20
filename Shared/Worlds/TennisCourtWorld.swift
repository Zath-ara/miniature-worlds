import CoreGraphics

/// Optic-yellow balls on a hard court. The net spans most of the tray but
/// leaves a gap at each sideline so balls can roll around it and pile up.
struct TennisCourtWorld: MiniatureWorld {
    let id = WorldID.tennis
    let title = "Tennis Court"
    let summary = "Balls roll, bounce, and stack against the net."

    let palette = FacePalette(
        outer: RGB(0.05, 0.14, 0.12),
        inner: RGB(0.12, 0.42, 0.30),
        bezel: RGB(0.96, 0.94, 0.88),
        tick: RGB(0.82, 0.90, 0.84),
        trayFill: RGB(0.15, 0.48, 0.28),
        trayStroke: RGB(0.93, 0.91, 0.84),
        time: RGB(0.97, 0.96, 0.92),
        date: RGB(0.78, 0.88, 0.80),
        accent: RGB(0.85, 1.0, 0.35)
    )

    let wallFriction: CGFloat = 0.36
    let wallRestitution: CGFloat = 0.46

    var bodies: [BodySpec] {
        Array(repeating: ball, count: 12)
    }

    var obstacles: [ObstacleSpec] {
        let tape = RGB(0.94, 0.94, 0.90)
        return [
            ObstacleSpec(
                kind: .bar(length: 96, thickness: 3.2, angle: 0),
                unitCenter: CGPoint(x: 0, y: 0),
                fill: tape,
                stroke: RGB(0.75, 0.75, 0.70)
            ),
            ObstacleSpec(
                kind: .post(radius: 3.2),
                unitCenter: CGPoint(x: -0.70, y: 0),
                fill: tape,
                stroke: RGB(0.70, 0.70, 0.66)
            ),
            ObstacleSpec(
                kind: .post(radius: 3.2),
                unitCenter: CGPoint(x: 0.70, y: 0),
                fill: tape,
                stroke: RGB(0.70, 0.70, 0.66)
            )
        ]
    }

    var decorations: [DecorationSpec] {
        let line = RGB(0.95, 0.95, 0.90, 0.85)
        return [
            DecorationSpec(kind: .line(from: CGPoint(x: -0.72, y: -1), to: CGPoint(x: -0.72, y: 1), width: 1.3), color: line),
            DecorationSpec(kind: .line(from: CGPoint(x: 0.72, y: -1), to: CGPoint(x: 0.72, y: 1), width: 1.3), color: line),
            DecorationSpec(kind: .line(from: CGPoint(x: -0.72, y: 0.55), to: CGPoint(x: 0.72, y: 0.55), width: 1.1), color: line),
            DecorationSpec(kind: .line(from: CGPoint(x: -0.72, y: -0.55), to: CGPoint(x: 0.72, y: -0.55), width: 1.1), color: line)
        ]
    }

    private var ball: BodySpec {
        BodySpec(
            shape: .circle(radius: 8),
            fill: RGB(0.82, 1.0, 0.25),
            accent: RGB(0.96, 0.96, 0.92),
            seam: .tennis,
            mass: 0.12,
            friction: 0.42,
            restitution: 0.74,
            linearDamping: 0.18,
            angularDamping: 0.22
        )
    }
}
