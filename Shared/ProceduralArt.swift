import CoreGraphics
import Foundation
import SpriteKit

/// Gradients and ball textures built at runtime. Nothing in the app depends on
/// an asset catalog image for the scene itself.
enum ProceduralArt {
    private static var cache: [String: SKTexture] = [:]

    static func radialDisc(diameter: CGFloat, inner: RGB, outer: RGB) -> SKTexture? {
        let pixels = min(512, max(64, Int((diameter * 2).rounded())))
        let key = "disc-\(pixels)-\(inner.cacheKey)-\(outer.cacheKey)"
        if let cached = cache[key] { return cached }
        guard let image = image(pixels: pixels, draw: { context, side in
            paintRadial(context: context, side: side, inner: inner, outer: outer)
        }) else { return nil }
        return store(image, key: key)
    }

    static func ball(diameter: CGFloat, fill: RGB, accent: RGB, seam: SeamStyle) -> SKTexture? {
        let pixels = min(192, max(40, Int((diameter * 4).rounded())))
        let key = "ball-\(pixels)-\(seam.cacheKey)-\(fill.cacheKey)-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }
        guard let image = image(pixels: pixels, draw: { context, side in
            paintBall(context: context, side: side, fill: fill, accent: accent, seam: seam)
        }) else { return nil }
        return store(image, key: key)
    }

    private static func store(_ image: CGImage, key: String) -> SKTexture {
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        cache[key] = texture
        return texture
    }

    private static func image(pixels: Int, draw: (CGContext, CGFloat) -> Void) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        draw(context, CGFloat(pixels))
        return context.makeImage()
    }

    private static func paintRadial(context: CGContext, side: CGFloat, inner: RGB, outer: RGB) {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let gradient = CGGradient(
                colorsSpace: space,
                colors: [inner.cgColor, outer.cgColor] as CFArray,
                locations: [0, 1] as [CGFloat]
              ) else {
            context.setFillColor(outer.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            return
        }
        context.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: side * 0.5, y: side * 0.64),
            startRadius: 0,
            endCenter: CGPoint(x: side * 0.5, y: side * 0.48),
            endRadius: side * 0.72,
            options: [.drawsAfterEndLocation]
        )
    }

    private static func paintBall(
        context: CGContext,
        side: CGFloat,
        fill: RGB,
        accent: RGB,
        seam: SeamStyle
    ) {
        let ball = CGRect(x: side * 0.06, y: side * 0.06, width: side * 0.88, height: side * 0.88)
        context.setFillColor(fill.cgColor)
        context.fillEllipse(in: ball)

        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(max(1, side * 0.045))
        context.setLineCap(.round)
        context.beginPath()
        switch seam {
        case .none:
            break
        case .tennis:
            context.move(to: CGPoint(x: side * 0.20, y: side * 0.32))
            context.addQuadCurve(
                to: CGPoint(x: side * 0.80, y: side * 0.32),
                control: CGPoint(x: side * 0.50, y: side * 0.62)
            )
            context.move(to: CGPoint(x: side * 0.20, y: side * 0.68))
            context.addQuadCurve(
                to: CGPoint(x: side * 0.80, y: side * 0.68),
                control: CGPoint(x: side * 0.50, y: side * 0.38)
            )
        case .basketball:
            context.move(to: CGPoint(x: side * 0.50, y: side * 0.10))
            context.addLine(to: CGPoint(x: side * 0.50, y: side * 0.90))
            context.move(to: CGPoint(x: side * 0.14, y: side * 0.50))
            context.addLine(to: CGPoint(x: side * 0.86, y: side * 0.50))
            context.move(to: CGPoint(x: side * 0.22, y: side * 0.18))
            context.addQuadCurve(
                to: CGPoint(x: side * 0.22, y: side * 0.82),
                control: CGPoint(x: side * 0.42, y: side * 0.50)
            )
            context.move(to: CGPoint(x: side * 0.78, y: side * 0.18))
            context.addQuadCurve(
                to: CGPoint(x: side * 0.78, y: side * 0.82),
                control: CGPoint(x: side * 0.58, y: side * 0.50)
            )
        case .soccer:
            context.setFillColor(accent.cgColor)
            context.fillEllipse(in: CGRect(x: side * 0.38, y: side * 0.40, width: side * 0.24, height: side * 0.24))
            context.move(to: CGPoint(x: side * 0.50, y: side * 0.16))
            context.addLine(to: CGPoint(x: side * 0.50, y: side * 0.36))
            context.move(to: CGPoint(x: side * 0.24, y: side * 0.62))
            context.addLine(to: CGPoint(x: side * 0.40, y: side * 0.50))
            context.move(to: CGPoint(x: side * 0.76, y: side * 0.62))
            context.addLine(to: CGPoint(x: side * 0.60, y: side * 0.50))
        }
        context.strokePath()

        context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.40))
        context.fillEllipse(in: CGRect(x: side * 0.30, y: side * 0.58, width: side * 0.26, height: side * 0.18))

        context.setStrokeColor(accent.withAlpha(0.85).cgColor)
        context.setLineWidth(max(1, side * 0.05))
        context.strokeEllipse(in: ball)
    }
}

private extension RGB {
    var cacheKey: String {
        String(format: "%.3f-%.3f-%.3f-%.3f", r, g, b, a)
    }
}

private extension SeamStyle {
    var cacheKey: String {
        switch self {
        case .none: return "none"
        case .tennis: return "tennis"
        case .basketball: return "basketball"
        case .soccer: return "soccer"
        }
    }
}
