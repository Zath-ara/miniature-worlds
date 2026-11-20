import CoreGraphics

/// Gold bars and diamonds in a walnut tray. Bars are heavy and dull; gems are
/// light and lively, so a tilt sorts them into a pile with the bars at the bottom.
struct TreasureChestWorld: MiniatureWorld {
    let id = WorldID.treasure
    let title = "Treasure Chest"
    let summary = "Gold bars and diamonds settle by weight."

    let palette = FacePalette(
        outer: RGB(0.09, 0.06, 0.04),
        inner: RGB(0.45, 0.30, 0.16),
        bezel: RGB(0.89, 0.69, 0.35),
        tick: RGB(0.94, 0.84, 0.62),
        trayFill: RGB(0.22, 0.14, 0.09),
        trayStroke: RGB(0.78, 0.57, 0.22),
        time: RGB(0.98, 0.93, 0.82),
        date: RGB(0.86, 0.72, 0.45),
        accent: RGB(0.98, 0.84, 0.45)
    )

    let wallFriction: CGFloat = 0.55
    let wallRestitution: CGFloat = 0.22

    var bodies: [BodySpec] {
        Array(repeating: bar, count: 8) + Array(repeating: gem, count: 6)
    }

    var obstacles: [ObstacleSpec] {
        [
            ObstacleSpec(
                kind: .bar(length: 96, thickness: 7, angle: 0.04),
                unitCenter: CGPoint(x: 0, y: 0.18),
                fill: RGB(0.40, 0.26, 0.13),
                stroke: RGB(0.72, 0.52, 0.22)
            ),
            ObstacleSpec(
                kind: .bar(length: 78, thickness: 7, angle: -0.10),
                unitCenter: CGPoint(x: 0, y: -0.42),
                fill: RGB(0.36, 0.22, 0.11),
                stroke: RGB(0.68, 0.48, 0.20)
            ),
            ObstacleSpec(
                kind: .post(radius: 5),
                unitCenter: CGPoint(x: 0, y: -0.08),
                fill: RGB(0.75, 0.60, 0.28),
                stroke: RGB(0.95, 0.84, 0.50)
            )
        ]
    }

    var decorations: [DecorationSpec] {
        let rivet = RGB(0.86, 0.68, 0.32, 0.9)
        return [
            DecorationSpec(kind: .dot(center: CGPoint(x: -0.88, y: 0.82), radius: 2.4), color: rivet),
            DecorationSpec(kind: .dot(center: CGPoint(x: 0.88, y: 0.82), radius: 2.4), color: rivet),
            DecorationSpec(kind: .dot(center: CGPoint(x: -0.88, y: -0.82), radius: 2.4), color: rivet),
            DecorationSpec(kind: .dot(center: CGPoint(x: 0.88, y: -0.82), radius: 2.4), color: rivet)
        ]
    }

    private var bar: BodySpec {
        BodySpec(
            shape: .roundedRect(size: CGSize(width: 28, height: 11), corner: 2),
            fill: RGB(0.95, 0.76, 0.28),
            accent: RGB(0.62, 0.42, 0.12),
            mass: 0.42,
            friction: 0.78,
            restitution: 0.10,
            linearDamping: 0.35,
            angularDamping: 0.55
        )
    }

    private var gem: BodySpec {
        BodySpec(
            shape: .diamond(radius: 7),
            fill: RGB(0.78, 0.93, 0.98),
            accent: RGB(0.45, 0.75, 0.88),
            mass: 0.07,
            friction: 0.18,
            restitution: 0.50,
            linearDamping: 0.12,
            angularDamping: 0.20
        )
    }
}
