import AppKit
import Foundation

// Procedural icon: no external assets or font dependencies.
let dimension: CGFloat = 1024
let rect = NSRect(x: 0, y: 0, width: dimension, height: dimension)
let image = NSImage(size: rect.size)
image.lockFocus()

let base = NSBezierPath(roundedRect: rect, xRadius: 220, yRadius: 220)
NSColor(calibratedRed: 0.057, green: 0.085, blue: 0.126, alpha: 1).setFill()
base.fill()

let halo = NSBezierPath(ovalIn: NSRect(x: 460, y: 540, width: 540, height: 540))
NSColor(calibratedRed: 0.22, green: 0.66, blue: 0.65, alpha: 0.07).setFill()
halo.fill()

// Offset tiles form a restrained, recognisable AIO monogram.
let rear = NSBezierPath(roundedRect: NSRect(x: 285, y: 255, width: 510, height: 505),
                        xRadius: 138, yRadius: 138)
NSColor(calibratedRed: 0.20, green: 0.29, blue: 0.38, alpha: 1).setFill()
rear.fill()

let main = NSBezierPath(roundedRect: NSRect(x: 220, y: 330, width: 475, height: 505),
                        xRadius: 130, yRadius: 130)
if let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.35, green: 0.83, blue: 0.80, alpha: 1),
    ending: NSColor(calibratedRed: 0.23, green: 0.55, blue: 0.69, alpha: 1)
) {
    gradient.draw(in: main, angle: -45)
}

let cutout = NSBezierPath(roundedRect: NSRect(x: 355, y: 470, width: 205, height: 220),
                          xRadius: 67, yRadius: 67)
NSColor(calibratedRed: 0.057, green: 0.085, blue: 0.126, alpha: 1).setFill()
cutout.fill()

let detail = NSBezierPath(ovalIn: NSRect(x: 645, y: 255, width: 116, height: 116))
NSColor(calibratedRed: 0.98, green: 0.59, blue: 0.45, alpha: 1).setFill()
detail.fill()

let bitmap = NSBitmapImageRep(focusedViewRect: rect)
image.unlockFocus()

guard let data = bitmap?.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}
let destination = URL(fileURLWithPath: "App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
try data.write(to: destination)
print("Generated app icon: \(destination.path)")
