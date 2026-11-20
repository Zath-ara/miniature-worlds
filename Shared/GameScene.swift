import Foundation
import SpriteKit

/// The dial: a round face, a bordered tray, fixed obstacles, and a pile of bodies.
///
/// Gravity is not simulated here. `TiltMotionProvider` (or the crown / a drag)
/// calls `applyGravity` with a vector in g. Sleeping bodies are woken only when
/// that vector actually changes, so a steady wrist does not keep the solver busy.
final class GameScene: SKScene, SKPhysicsContactDelegate {
    var onImpact: ((CGFloat) -> Void)?

    private var theme: any MiniatureWorld
    private var appliedThemeID: String
    private let bodyLayer = SKNode()
    private var downhillNode: SKShapeNode?
    private var lastUnit = CGVector(dx: 0, dy: -0.85)
    private var appliedUnit = CGVector(dx: 999, dy: 999)
    private var layoutSize: CGSize = .zero
    private var lastToss = Date.distantPast
    private var lastScatter = Date.distantPast

    init(theme: any MiniatureWorld) {
        self.theme = theme
        self.appliedThemeID = theme.id
        super.init(size: CGSize(width: 200, height: 200))
        configureScene()
    }

    required init?(coder decoder: NSCoder) {
        let theme = TreasureChestWorld()
        self.theme = theme
        self.appliedThemeID = theme.id
        super.init(coder: decoder)
        configureScene()
    }

    func apply(theme: any MiniatureWorld) {
        let themeChanged = theme.id != appliedThemeID
        self.theme = theme
        appliedThemeID = theme.id
        guard themeChanged || bodyLayer.parent == nil else { return }
        rebuild()
    }

    func applyGravity(_ unit: CGVector) {
        lastUnit = unit
        let diameter = dialDiameter()
        let scale = DialLayout.gravityScale(diameter: diameter > 20 ? diameter : DialLayout.referenceDiameter)
        physicsWorld.gravity = CGVector(dx: unit.dx * scale, dy: unit.dy * scale)

        let delta = hypot(unit.dx - appliedUnit.dx, unit.dy - appliedUnit.dy)
        appliedUnit = unit
        if delta > 0.012 {
            for node in bodyLayer.children {
                node.physicsBody?.isResting = false
            }
        }
        updateDownhill(unit)
    }

    /// Pops the pile upward. Returns false when a second tap arrives too quickly.
    @discardableResult
    func toss() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastToss) > 0.35 else { return false }
        lastToss = now
        impulseAll(horizontal: 90, vertical: 260...420)
        return true
    }

    func scatter() {
        let now = Date()
        guard now.timeIntervalSince(lastScatter) > 0.45 else { return }
        lastScatter = now
        impulseAll(horizontal: 280, vertical: -80...260)
    }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = MotionBudget.framesPerSecond
        if bodyLayer.parent == nil {
            rebuild()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 20, size.height > 20 else { return }
        let delta = hypot(size.width - layoutSize.width, size.height - layoutSize.height)
        if delta > 1 || bodyLayer.parent == nil {
            rebuild()
        }
    }

    @objc func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let hitsSurface = mask & (PhysicsCategory.boundary | PhysicsCategory.obstacle) != 0
        guard hitsSurface else { return }
        let relativeX = contact.bodyA.velocity.dx - contact.bodyB.velocity.dx
        let relativeY = contact.bodyA.velocity.dy - contact.bodyB.velocity.dy
        let approach = abs(relativeX * contact.contactNormal.dx + relativeY * contact.contactNormal.dy)
        guard approach > 240 else { return }
        let speed = approach
        DispatchQueue.main.async { [weak self] in
            self?.onImpact?(speed)
        }
    }

    private func configureScene() {
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -900)
        bodyLayer.zPosition = 4
    }

    private func rebuild() {
        guard size.width > 20, size.height > 20 else { return }
        layoutSize = size
        removeAllChildren()
        bodyLayer.removeAllChildren()
        downhillNode = nil

        let diameter = dialDiameter()
        let scale = DialLayout.scale(diameter: diameter)
        let tray = trayRect(diameter: diameter)
        backgroundColor = theme.palette.outer.skColor

        addBackdrop(diameter: diameter)
        addTicks(diameter: diameter)
        addBezel(diameter: diameter)
        addTray(tray)
        addDecorations(tray: tray, scale: scale)
        let blocked = addObstacles(tray: tray, scale: scale)
        addChild(bodyLayer)
        spawnBodies(in: tray, scale: scale, blocked: blocked)
        addDownhillMarker(diameter: diameter)

        appliedUnit = CGVector(dx: 999, dy: 999)
        applyGravity(lastUnit)
    }

    private func dialDiameter() -> CGFloat {
        min(size.width, size.height)
    }

    private func trayRect(diameter: CGFloat) -> CGRect {
        let width = diameter * DialLayout.trayWidthRatio
        let height = diameter * DialLayout.trayHeightRatio
        let originY = -height * 0.5 - diameter * DialLayout.trayDropRatio
        return CGRect(x: -width * 0.5, y: originY, width: width, height: height)
    }

    private func addBackdrop(diameter: CGFloat) {
        let node: SKNode
        if let texture = ProceduralArt.radialDisc(
            diameter: diameter,
            inner: theme.palette.inner,
            outer: theme.palette.outer
        ) {
            let sprite = SKSpriteNode(texture: texture, size: CGSize(width: diameter, height: diameter))
            node = sprite
        } else {
            let circle = SKShapeNode(circleOfRadius: diameter * 0.5)
            circle.fillColor = theme.palette.inner.skColor
            circle.strokeColor = .clear
            node = circle
        }
        node.zPosition = -20
        addChild(node)
    }

    private func addTicks(diameter: CGFloat) {
        let outer = diameter * 0.47
        for index in 0..<12 {
            let angle = CGFloat(index) / 12 * .pi * 2 - .pi / 2
            let inner = index % 3 == 0 ? diameter * 0.43 : diameter * 0.45
            let path = CGMutablePath()
            path.move(to: CGPoint(x: cos(angle) * inner, y: sin(angle) * inner))
            path.addLine(to: CGPoint(x: cos(angle) * outer, y: sin(angle) * outer))
            let tick = SKShapeNode(path: path)
            tick.strokeColor = theme.palette.tick.skColor
            tick.lineWidth = index % 3 == 0 ? 2.5 : 1.2
            tick.lineCap = .round
            tick.zPosition = 8
            addChild(tick)
        }
    }

    private func addBezel(diameter: CGFloat) {
        let bezel = SKShapeNode(circleOfRadius: diameter * 0.485)
        bezel.fillColor = .clear
        bezel.strokeColor = theme.palette.bezel.skColor
        bezel.lineWidth = max(2, DialLayout.scale(diameter: diameter) * 3)
        bezel.zPosition = 9
        addChild(bezel)
    }

    private func addTray(_ tray: CGRect) {
        let corner = min(tray.width, tray.height) * 0.12
        let path = CGPath(roundedRect: tray, cornerWidth: corner, cornerHeight: corner, transform: nil)
        let node = SKShapeNode(path: path)
        node.fillColor = theme.palette.trayFill.skColor
        node.strokeColor = theme.palette.trayStroke.skColor
        node.lineWidth = max(2, DialLayout.scale(diameter: dialDiameter()) * 2.5)
        node.zPosition = 0
        let body = SKPhysicsBody(edgeLoopFrom: path)
        body.friction = theme.wallFriction
        body.restitution = theme.wallRestitution
        body.categoryBitMask = PhysicsCategory.boundary
        body.collisionBitMask = PhysicsCategory.dynamic
        body.contactTestBitMask = PhysicsCategory.dynamic
        node.physicsBody = body
        addChild(node)
    }

    private func addDecorations(tray: CGRect, scale: CGFloat) {
        for spec in theme.decorations {
            let node = SKShapeNode()
            node.strokeColor = spec.color.skColor
            node.lineCap = .round
            node.zPosition = 1
            switch spec.kind {
            case let .line(from, to, width):
                let path = CGMutablePath()
                path.move(to: unitPoint(from, tray: tray))
                path.addLine(to: unitPoint(to, tray: tray))
                node.path = path
                node.lineWidth = max(1, width * scale)
                node.fillColor = .clear
            case let .circle(center, radius, width):
                let point = unitPoint(center, tray: tray)
                let scaled = radius * scale
                node.path = CGPath(
                    ellipseIn: CGRect(x: point.x - scaled, y: point.y - scaled, width: scaled * 2, height: scaled * 2),
                    transform: nil
                )
                node.lineWidth = max(1, width * scale)
                node.fillColor = .clear
            case let .dot(center, radius):
                let point = unitPoint(center, tray: tray)
                let scaled = radius * scale
                node.path = CGPath(
                    ellipseIn: CGRect(x: point.x - scaled, y: point.y - scaled, width: scaled * 2, height: scaled * 2),
                    transform: nil
                )
                node.fillColor = spec.color.skColor
                node.lineWidth = 0
            }
            addChild(node)
        }
    }

    private func addObstacles(tray: CGRect, scale: CGFloat) -> [CGRect] {
        var blocked: [CGRect] = []
        for spec in theme.obstacles {
            let center = unitPoint(spec.unitCenter, tray: tray)
            let node = SKShapeNode()
            node.position = center
            node.fillColor = spec.fill.skColor
            node.strokeColor = spec.stroke.skColor
            node.lineWidth = 1.5
            node.zPosition = 2

            let body: SKPhysicsBody
            let reach: CGFloat
            switch spec.kind {
            case let .bar(length, thickness, angle):
                let scaledLength = length * scale
                let scaledThickness = thickness * scale
                let rect = CGRect(
                    x: -scaledLength * 0.5,
                    y: -scaledThickness * 0.5,
                    width: scaledLength,
                    height: scaledThickness
                )
                node.path = CGPath(roundedRect: rect, cornerWidth: scaledThickness * 0.4, cornerHeight: scaledThickness * 0.4, transform: nil)
                node.zRotation = angle
                body = SKPhysicsBody(rectangleOf: CGSize(width: scaledLength, height: scaledThickness))
                reach = hypot(scaledLength, scaledThickness) * 0.5
            case let .post(radius):
                let scaled = radius * scale
                node.path = CGPath(ellipseIn: CGRect(x: -scaled, y: -scaled, width: scaled * 2, height: scaled * 2), transform: nil)
                body = SKPhysicsBody(circleOfRadius: scaled)
                reach = scaled
            case let .arc(radius, start, end, clockwise, lineWidth):
                let scaled = radius * scale
                let path = CGMutablePath()
                path.addArc(center: .zero, radius: scaled, startAngle: start, endAngle: end, clockwise: clockwise)
                node.path = path
                node.fillColor = .clear
                node.lineWidth = max(2, lineWidth * scale)
                body = SKPhysicsBody(edgeChainFrom: path)
                reach = scaled
            }

            body.isDynamic = false
            body.friction = theme.wallFriction
            body.restitution = max(0.05, theme.wallRestitution * 0.85)
            body.categoryBitMask = PhysicsCategory.obstacle
            body.collisionBitMask = PhysicsCategory.dynamic
            body.contactTestBitMask = PhysicsCategory.dynamic
            node.physicsBody = body
            addChild(node)
            blocked.append(CGRect(x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2))
        }
        return blocked
    }

    private func spawnBodies(in tray: CGRect, scale: CGFloat, blocked: [CGRect]) {
        var rng = SplitMix64(state: stableHash(theme.id))
        var placed: [CGRect] = []
        for spec in theme.bodies {
            let radius = spec.shape.referenceRadius * scale
            guard let point = spawnPoint(radius: radius, tray: tray, blocked: blocked, placed: &placed, rng: &rng) else {
                continue
            }
            let node = makeBodyNode(spec: spec, scale: scale)
            node.position = point
            node.zRotation = CGFloat.random(in: (-.pi) ... (.pi), using: &rng)
            if let body = node.physicsBody {
                configure(body: body, spec: spec, scale: scale)
            }
            bodyLayer.addChild(node)
            placed.append(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        }
    }

    private func spawnPoint(
        radius: CGFloat,
        tray: CGRect,
        blocked: [CGRect],
        placed: inout [CGRect],
        rng: inout SplitMix64
    ) -> CGPoint? {
        let minX = tray.minX + radius + 2
        let maxX = tray.maxX - radius - 2
        let minY = tray.minY + radius + 2
        let maxY = tray.maxY - radius - 2
        guard maxX > minX, maxY > minY else { return nil }

        for _ in 0..<36 {
            let point = CGPoint(
                x: CGFloat.random(in: minX...maxX, using: &rng),
                y: CGFloat.random(in: minY...maxY, using: &rng)
            )
            let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            let hitsBody = placed.contains { $0.insetBy(dx: -1, dy: -1).intersects(rect) }
            let hitsObstacle = blocked.contains { $0.insetBy(dx: -radius, dy: -radius).intersects(rect) }
            if !hitsBody && !hitsObstacle {
                return point
            }
        }

        let index = placed.count
        let columns = 4
        let column = index % columns
        let row = index / columns
        let x = minX + (maxX - minX) * (CGFloat(column) + 0.5) / CGFloat(columns)
        let y = maxY - CGFloat(row) * radius * 2.3
        return CGPoint(x: min(max(x, minX), maxX), y: min(max(y, minY), maxY))
    }

    private func makeBodyNode(spec: BodySpec, scale: CGFloat) -> SKNode {
        switch spec.shape {
        case let .circle(radius):
            let scaled = radius * scale
            if let texture = ProceduralArt.ball(
                diameter: scaled * 2,
                fill: spec.fill,
                accent: spec.accent,
                seam: spec.seam
            ) {
                let sprite = SKSpriteNode(texture: texture, size: CGSize(width: scaled * 2, height: scaled * 2))
                sprite.physicsBody = SKPhysicsBody(circleOfRadius: scaled)
                return sprite
            }
            let circle = SKShapeNode(circleOfRadius: scaled)
            circle.fillColor = spec.fill.skColor
            circle.strokeColor = spec.accent.skColor
            circle.lineWidth = 1
            circle.physicsBody = SKPhysicsBody(circleOfRadius: scaled)
            return circle
        case let .roundedRect(size, corner):
            let scaled = CGSize(width: size.width * scale, height: size.height * scale)
            let rect = CGRect(x: -scaled.width * 0.5, y: -scaled.height * 0.5, width: scaled.width, height: scaled.height)
            let node = SKShapeNode(path: CGPath(
                roundedRect: rect,
                cornerWidth: corner * scale,
                cornerHeight: corner * scale,
                transform: nil
            ))
            node.fillColor = spec.fill.skColor
            node.strokeColor = spec.accent.skColor
            node.lineWidth = max(1, scale)
            node.physicsBody = SKPhysicsBody(rectangleOf: scaled)
            let shine = SKShapeNode(rect: rect.insetBy(dx: scaled.width * 0.12, dy: scaled.height * 0.28), cornerRadius: 1)
            shine.fillColor = SKColor(white: 1, alpha: 0.22)
            shine.strokeColor = .clear
            node.addChild(shine)
            return node
        case let .diamond(radius):
            let scaled = radius * scale
            let path = diamondPath(radius: scaled)
            let node = SKShapeNode(path: path)
            node.fillColor = spec.fill.skColor
            node.strokeColor = spec.accent.skColor
            node.lineWidth = max(1, scale)
            node.physicsBody = SKPhysicsBody(polygonFrom: path) ?? SKPhysicsBody(circleOfRadius: scaled * 0.8)
            let glint = SKShapeNode(circleOfRadius: scaled * 0.16)
            glint.position = CGPoint(x: -scaled * 0.18, y: scaled * 0.22)
            glint.fillColor = SKColor(white: 1, alpha: 0.75)
            glint.strokeColor = .clear
            node.addChild(glint)
            return node
        }
    }

    private func configure(body: SKPhysicsBody, spec: BodySpec, scale: CGFloat) {
        body.mass = spec.mass
        body.friction = spec.friction
        body.restitution = spec.restitution
        body.linearDamping = spec.linearDamping
        body.angularDamping = spec.angularDamping
        body.allowsRotation = true
        body.categoryBitMask = PhysicsCategory.dynamic
        body.collisionBitMask = PhysicsCategory.dynamic | PhysicsCategory.boundary | PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.boundary | PhysicsCategory.obstacle
        body.usesPreciseCollisionDetection = spec.shape.referenceRadius * scale < 8
    }

    private func addDownhillMarker(diameter: CGFloat) {
        let scale = DialLayout.scale(diameter: diameter)
        let radius = diameter * 0.40
        let path = CGMutablePath()
        path.move(to: CGPoint(x: radius + 7 * scale, y: 0))
        path.addLine(to: CGPoint(x: radius - 3 * scale, y: 4.5 * scale))
        path.addLine(to: CGPoint(x: radius - 3 * scale, y: -4.5 * scale))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = theme.palette.accent.skColor
        node.strokeColor = .clear
        node.zPosition = 12
        node.alpha = 0.9
        addChild(node)
        downhillNode = node
    }

    private func updateDownhill(_ unit: CGVector) {
        guard let node = downhillNode else { return }
        let magnitude = hypot(unit.dx, unit.dy)
        node.alpha = magnitude < 0.06 ? 0.18 : 0.9
        if magnitude > 0.04 {
            node.zRotation = atan2(unit.dy, unit.dx)
        }
    }

    private func impulseAll(horizontal: CGFloat, vertical: ClosedRange<CGFloat>) {
        for node in bodyLayer.children {
            guard let body = node.physicsBody else { continue }
            let mass = max(body.mass, 0.01)
            let dx = CGFloat.random(in: -horizontal...horizontal) * mass
            let dy = CGFloat.random(in: vertical) * mass
            body.applyImpulse(CGVector(dx: dx, dy: dy))
            body.isResting = false
        }
    }

    private func unitPoint(_ unit: CGPoint, tray: CGRect) -> CGPoint {
        CGPoint(
            x: tray.midX + unit.x * tray.width * 0.5,
            y: tray.midY + unit.y * tray.height * 0.5
        )
    }

    private func diamondPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addLine(to: CGPoint(x: -radius * 0.72, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -radius))
        path.addLine(to: CGPoint(x: radius * 0.72, y: 0))
        path.closeSubpath()
        return path
    }
}

/// FNV-1a. `String.hashValue` is not stable across launches, and the pile
/// should come up in the same places for a given world.
private func stableHash(_ text: String) -> UInt64 {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return hash == 0 ? 1 : hash
}

private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58476D1CE4E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D049BB133111EB
        return mixed ^ (mixed >> 31)
    }
}
