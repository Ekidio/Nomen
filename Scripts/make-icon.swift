// Draws the Nomen app icon and writes Resources/AppIcon.icns.
// Usage: swift Scripts/make-icon.swift
import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
        let s = size / 1024
        let ctx = NSGraphicsContext.current!.cgContext

        // Squircle background (macOS grid: 824pt body inside 1024 canvas).
        let body = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
        let squircle = NSBezierPath(roundedRect: body, xRadius: 185 * s, yRadius: 185 * s)

        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowBlurRadius = 28 * s
        shadow.shadowOffset = NSSize(width: 0, height: -12 * s)
        shadow.set()
        NSColor.black.setFill()
        squircle.fill()
        ctx.restoreGState()

        NSGradient(colors: [
            NSColor(srgbRed: 0.98, green: 0.42, blue: 0.62, alpha: 1),
            NSColor(srgbRed: 0.55, green: 0.33, blue: 0.98, alpha: 1),
            NSColor(srgbRed: 0.27, green: 0.36, blue: 0.96, alpha: 1),
        ])!.draw(in: squircle, angle: -60)

        // Soft top highlight.
        ctx.saveGState()
        squircle.addClip()
        NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!
            .draw(in: NSRect(x: body.minX, y: body.midY, width: body.width, height: body.height / 2), angle: -90)
        ctx.restoreGState()

        // Tilted white name tag.
        ctx.saveGState()
        ctx.translateBy(x: 512 * s, y: 505 * s)
        ctx.rotate(by: 10 * .pi / 180)

        let tag = NSBezierPath()
        let w = 560 * s, h = 300 * s, point = 120 * s, r = 46 * s
        let left = -w / 2, right = w / 2, top = h / 2, bottom = -h / 2
        tag.move(to: NSPoint(x: left + point, y: top))
        tag.line(to: NSPoint(x: right - r, y: top))
        tag.curve(to: NSPoint(x: right, y: top - r), controlPoint1: NSPoint(x: right, y: top), controlPoint2: NSPoint(x: right, y: top))
        tag.line(to: NSPoint(x: right, y: bottom + r))
        tag.curve(to: NSPoint(x: right - r, y: bottom), controlPoint1: NSPoint(x: right, y: bottom), controlPoint2: NSPoint(x: right, y: bottom))
        tag.line(to: NSPoint(x: left + point, y: bottom))
        tag.line(to: NSPoint(x: left + 14 * s, y: -18 * s))
        tag.curve(to: NSPoint(x: left + 14 * s, y: 18 * s), controlPoint1: NSPoint(x: left, y: 0), controlPoint2: NSPoint(x: left, y: 0))
        tag.close()
        let hole = NSBezierPath(ovalIn: NSRect(x: left + 70 * s, y: -26 * s, width: 52 * s, height: 52 * s))
        tag.append(hole)
        tag.windingRule = .evenOdd

        ctx.saveGState()
        let tagShadow = NSShadow()
        tagShadow.shadowColor = NSColor(srgbRed: 0.15, green: 0.08, blue: 0.4, alpha: 0.45)
        tagShadow.shadowBlurRadius = 36 * s
        tagShadow.shadowOffset = NSSize(width: 0, height: -18 * s)
        tagShadow.set()
        NSColor.white.setFill()
        tag.fill()
        ctx.restoreGState()

        // "Aa" with a text cursor.
        let font = NSFont.systemFont(ofSize: 170 * s, weight: .heavy)
        let text = NSAttributedString(string: "Aa", attributes: [
            .font: font,
            .foregroundColor: NSColor(srgbRed: 0.36, green: 0.30, blue: 0.92, alpha: 1),
            .kern: -4 * s,
        ])
        let textSize = text.size()
        let textOrigin = NSPoint(x: left + 160 * s, y: -textSize.height / 2 + 6 * s)
        text.draw(at: textOrigin)

        let cursorX = textOrigin.x + textSize.width + 18 * s
        let cursor = NSBezierPath(roundedRect: NSRect(x: cursorX, y: -88 * s, width: 22 * s, height: 176 * s), xRadius: 11 * s, yRadius: 11 * s)
        NSColor(srgbRed: 0.98, green: 0.42, blue: 0.62, alpha: 1).setFill()
        cursor.fill()

        ctx.restoreGState()
        return true
    }
}

func png(_ image: NSImage, pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let master = drawIcon(size: 1024)
for base in [16, 32, 128, 256, 512] {
    try png(master, pixels: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try png(master, pixels: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try png(master, pixels: 1024).write(to: root.appendingPathComponent("Resources/AppIcon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print("Resources/AppIcon.icns kész")
