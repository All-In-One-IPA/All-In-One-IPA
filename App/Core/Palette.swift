import SwiftUI
import UIKit

enum Palette {
    private static func uiColor(_ hex: UInt) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }

    private static func adaptive(dark: UInt, light: UInt) -> Color {
        Color(uiColor: UIColor { trait in
            uiColor(trait.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static let background = adaptive(dark: 0x0C1119, light: 0xF4F6F9)
    static let surface = adaptive(dark: 0x171F2B, light: 0xFFFFFF)
    static let elevated = adaptive(dark: 0x202B39, light: 0xEAF0F5)
    static let ink = adaptive(dark: 0xF3F5F8, light: 0x192333)
    static let secondary = adaptive(dark: 0x9FAEC1, light: 0x64748A)
    static let hairline = adaptive(dark: 0x304050, light: 0xDFE5EB)
    static let cyan = Color(red: 0.35, green: 0.82, blue: 0.80)
    static let coral = Color(red: 0.98, green: 0.59, blue: 0.45)
    static let lavender = Color(red: 0.70, green: 0.62, blue: 0.96)
    static let amber = Color(red: 0.94, green: 0.73, blue: 0.43)
    static let blue = Color(red: 0.48, green: 0.68, blue: 0.98)
    static let green = Color(red: 0.49, green: 0.85, blue: 0.64)
}

extension View {
    func surfaceCard(radius: CGFloat = 24) -> some View {
        self
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.hairline.opacity(0.50), lineWidth: 0.8)
            }
    }
}
