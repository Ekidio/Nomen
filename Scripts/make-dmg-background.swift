// Draws the DMG window background (1x and 2x PNGs).
// Usage: swift Scripts/make-dmg-background.swift <output-dir>
import AppKit

let width: CGFloat = 640, height: CGFloat = 400

func draw(scale: CGFloat) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let bounds = NSRect(x: 0, y: 0, width: width, height: height)
    NSGradient(colors: [NSColor(white: 0.97, alpha: 1), NSColor(white: 0.90, alpha: 1)])!
        .draw(in: bounds, angle: -90)
    NSGradient(colors: [NSColor(white: 1, alpha: 0.6), NSColor(white: 1, alpha: 0)])!
        .draw(fromCenter: NSPoint(x: width / 2, y: height), radius: 0,
              toCenter: NSPoint(x: width / 2, y: height), radius: 420, options: [])

    // Arrow between the app (x 160) and Applications (x 480); icons sit at y 200 from the top.
    let y = height - 190
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 262, y: y))
    arrow.line(to: NSPoint(x: 368, y: y))
    arrow.lineWidth = 5
    arrow.lineCapStyle = .round
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 352, y: y + 14))
    head.line(to: NSPoint(x: 372, y: y))
    head.line(to: NSPoint(x: 352, y: y - 14))
    head.lineWidth = 5
    head.lineCapStyle = .round
    head.lineJoinStyle = .round

    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.98, green: 0.42, blue: 0.62, alpha: 1),
        NSColor(srgbRed: 0.55, green: 0.33, blue: 0.98, alpha: 1),
        NSColor(srgbRed: 0.27, green: 0.36, blue: 0.96, alpha: 1),
    ])!
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    ctx.setLineWidth(5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.addPath(arrow.cgPath)
    ctx.addPath(head.cgPath)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    gradient.draw(in: NSRect(x: 255, y: y - 20, width: 125, height: 40), angle: 0)
    ctx.restoreGState()

    func centered(_ string: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        NSAttributedString(string: string, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor(white: 0, alpha: alpha),
            .paragraphStyle: style,
        ]).draw(in: NSRect(x: 0, y: y, width: width, height: size * 1.5))
    }
    centered("Drag Nomen to Applications", y: 70, size: 15, weight: .semibold, alpha: 0.7)
    centered("Húzd a Nomen-t az Applications mappába", y: 46, size: 12, weight: .regular, alpha: 0.45)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try draw(scale: 1).write(to: out.appendingPathComponent("background.png"))
try draw(scale: 2).write(to: out.appendingPathComponent("background@2x.png"))
