import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Reproducible original vector geometry. Coordinates match branding/mark.svg.
func drawMark(_ context: CGContext, menu: Bool) {
    let outline = CGPath(roundedRect: CGRect(x: 224, y: 248, width: 576, height: 528),
                         cornerWidth: 76, cornerHeight: 76, transform: nil)
    context.addPath(outline)
    context.setStrokeColor(menu ? CGColor(gray: 0, alpha: 1) : CGColor(red: 0.65, green: 0.88, blue: 1, alpha: 1))
    context.setLineWidth(menu ? 48 : 26)
    context.strokePath()
    if !menu {
        context.setFillColor(CGColor(red: 1, green: 0.66, blue: 0.32, alpha: 1))
        context.addPath(CGPath(roundedRect: CGRect(x: 252, y: 382, width: 14, height: 248), cornerWidth: 7, cornerHeight: 7, transform: nil))
        context.fillPath()
        context.setFillColor(CGColor(red: 0.2, green: 0.78, blue: 1, alpha: 1))
        context.addPath(CGPath(roundedRect: CGRect(x: 758, y: 382, width: 14, height: 248), cornerWidth: 7, cornerHeight: 7, transform: nil))
        context.fillPath()
    }
    context.setFillColor(menu ? CGColor(gray: 0, alpha: 1) : CGColor(red: 0.65, green: 0.88, blue: 1, alpha: 1))
    for x in [464, 512, 560] {
        context.fillEllipse(in: CGRect(x: x - 9, y: 300, width: 18, height: 18))
    }
    context.setStrokeColor(menu ? CGColor(gray: 0, alpha: 1) : CGColor(gray: 1, alpha: 1))
    context.setLineWidth(menu ? 58 : 46)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: 348, y: 418))
    context.addLine(to: CGPoint(x: 616, y: 418))
    context.addCurve(to: CGPoint(x: 616, y: 534), control1: CGPoint(x: 695, y: 418), control2: CGPoint(x: 695, y: 534))
    context.addLine(to: CGPoint(x: 426, y: 534))
    context.addCurve(to: CGPoint(x: 426, y: 650), control1: CGPoint(x: 347, y: 534), control2: CGPoint(x: 347, y: 650))
    context.addLine(to: CGPoint(x: 676, y: 650))
    context.strokePath()
}

func png(size: Int, destination: URL, menu: Bool = false) throws {
    let colors = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                            bytesPerRow: 0, space: colors, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.translateBy(x: 0, y: CGFloat(size))
    context.scaleBy(x: CGFloat(size) / 1024, y: -CGFloat(size) / 1024)
    if !menu {
        let tile = CGPath(roundedRect: CGRect(x: 80, y: 80, width: 864, height: 864),
                          cornerWidth: 194, cornerHeight: 194, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 16), blur: 26, color: CGColor(gray: 0, alpha: 0.2))
        context.addPath(tile)
        context.setFillColor(CGColor(red: 0.025, green: 0.10, blue: 0.2, alpha: 1))
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(tile)
        context.clip()
        let gradient = CGGradient(colorsSpace: colors, colors: [
            CGColor(red: 0.055, green: 0.38, blue: 0.68, alpha: 1),
            CGColor(red: 0.025, green: 0.09, blue: 0.18, alpha: 1)
        ] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 150, y: 80),
                                    end: CGPoint(x: 900, y: 980), options: [])
        context.restoreGState()
    } else {
        // Expand the mark to read clearly at menu-bar sizes.
        context.translateBy(x: -280, y: -225)
        context.scaleBy(x: 1.55, y: 1.55)
    }
    drawMark(context, menu: menu)
    let image = context.makeImage()!
    let target = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(target, image, nil)
    guard CGImageDestinationFinalize(target) else { throw NSError(domain: "Branding", code: 1) }
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let assets = root.appendingPathComponent("TrackFlow/Assets.xcassets")
let fm = FileManager.default
try fm.createDirectory(at: assets, withIntermediateDirectories: true)
func writeJSON(_ data: [String: Any], at url: URL) throws {
    try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]).write(to: url)
}
try writeJSON(["info": ["author": "xcode", "version": 1]], at: assets.appendingPathComponent("Contents.json"))
let icons = assets.appendingPathComponent("AppIcon.appiconset")
try fm.createDirectory(at: icons, withIntermediateDirectories: true)
var entries: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon-\(size)@\(scale)x.png"
        try png(size: size * scale, destination: icons.appendingPathComponent(name))
        entries.append(["filename": name, "idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x"])
    }
}
try writeJSON(["images": entries, "info": ["author": "xcode", "version": 1]], at: icons.appendingPathComponent("Contents.json"))
for (name, menu) in [("BrandMark", false), ("MenuBarIcon", true)] {
    let folder = assets.appendingPathComponent(name + ".imageset")
    try fm.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in [1, 2, 3] {
        let file = "mark@\(scale)x.png"
        try png(size: (menu ? 18 : 64) * scale, destination: folder.appendingPathComponent(file), menu: menu)
        images.append(["filename": file, "idiom": "universal", "scale": "\(scale)x"])
    }
    var json: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    if menu { json["properties"] = ["template-rendering-intent": "template"] }
    try writeJSON(json, at: folder.appendingPathComponent("Contents.json"))
}
try fm.createDirectory(at: root.appendingPathComponent("branding"), withIntermediateDirectories: true)
try png(size: 1024, destination: root.appendingPathComponent("branding/app-icon.png"))
print("Generated app icon and interface/menu assets.")
