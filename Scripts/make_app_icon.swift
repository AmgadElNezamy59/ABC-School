// Renders the 1024×1024 App Store icon: three toy letter blocks (A, B, C) on the brand violet.
// Usage: swift Scripts/make_app_icon.swift Fruits/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import AppKit

let size = 1024
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
// No alpha channel: App Store icons must be opaque.
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Background: brand violet gradient with two soft "bubbles", like the in-app stages.
let gradient = CGGradient(colorsSpace: space, colors: [color(0x7B6CF6), color(0x4B3BC4)] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
context.setFillColor(CGColor(gray: 1, alpha: 0.10))
context.fillEllipse(in: CGRect(x: -220, y: 560, width: 720, height: 720))
context.setFillColor(CGColor(gray: 1, alpha: 0.07))
context.fillEllipse(in: CGRect(x: 640, y: -200, width: 560, height: 560))

let graphics = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.current = graphics

func roundedFont(_ pointSize: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: pointSize, weight: .black)
    guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
    return NSFont(descriptor: descriptor, size: pointSize) ?? base
}

struct Block { let letter: String; let face: UInt32; let center: CGPoint; let angle: CGFloat }
let blocks = [
    Block(letter: "A", face: 0xF2545B, center: CGPoint(x: 300, y: 330), angle: 8),
    Block(letter: "B", face: 0xFFB400, center: CGPoint(x: 724, y: 330), angle: -7),
    Block(letter: "C", face: 0x22B573, center: CGPoint(x: 512, y: 690), angle: 4),
]
let side: CGFloat = 340
for block in blocks {
    context.saveGState()
    context.translateBy(x: block.center.x, y: block.center.y)
    context.rotate(by: block.angle * .pi / 180)
    let rect = CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
    // Soft drop shadow, then the darker "depth" edge, then the face: same chunky look as the app's buttons.
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 36, color: CGColor(gray: 0, alpha: 0.28))
    context.addPath(CGPath(roundedRect: rect.offsetBy(dx: 0, dy: -22), cornerWidth: 72, cornerHeight: 72, transform: nil))
    context.setFillColor(color(block.face))
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)
    context.addPath(CGPath(roundedRect: rect.offsetBy(dx: 0, dy: -22), cornerWidth: 72, cornerHeight: 72, transform: nil))
    context.setFillColor(CGColor(gray: 0, alpha: 0.22))
    context.fillPath()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: 72, cornerHeight: 72, transform: nil))
    context.setFillColor(color(block.face))
    context.fillPath()

    let text = NSAttributedString(string: block.letter, attributes: [
        .font: roundedFont(250),
        .foregroundColor: NSColor.white,
    ])
    let bounds = text.boundingRect(with: CGSize(width: 1000, height: 1000), options: [.usesLineFragmentOrigin])
    text.draw(at: CGPoint(x: -bounds.width / 2, y: -bounds.height / 2 + 6))
    context.restoreGState()
}

let image = context.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
