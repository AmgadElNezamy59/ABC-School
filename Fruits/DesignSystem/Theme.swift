import SwiftUI
import UIKit

// MARK: - Color tokens
//
// "A sunny classroom": warm paper and plum ink by day, deep navy by night.
// Word stages keep their own bright colors in both modes, like illustrations in a book.

extension UIColor {
    fileprivate static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }

    private convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }

    static let ink = dynamic(light: 0x2B2340, dark: 0xF5F3FF)
}

extension Color {
    /// Screen background. Also the launch screen color (asset "AppBackground").
    static let appBackground = Color(.appBackground)
    /// Cards, tiles and other raised surfaces.
    static let surface = Color(uiColor: .dynamic(light: 0xFFFFFF, dark: 0x1E1E36))
    /// Tracks, wells and quiet fills.
    static let surfaceMuted = Color(uiColor: .dynamic(light: 0xF1EADF, dark: 0x2C2C4A))
    /// Primary text.
    static let ink = Color(uiColor: .ink)
    /// Secondary text.
    static let inkSecondary = Color(uiColor: .dynamic(light: 0x6E6787, dark: 0xA9A4C4))
    /// Brand violet: primary actions and selection. Matches the AccentColor asset.
    static let brand = Color(uiColor: .dynamic(light: 0x6C5CE7, dark: 0x8E80FF))
    /// Stars and rewards.
    static let star = Color(uiColor: .dynamic(light: 0xFFB400, dark: 0xFFC83D))
    /// Correct answers.
    static let success = Color(uiColor: .dynamic(light: 0x1E9E5A, dark: 0x3DD68C))
    /// Recording and "try again": a warm coral, never an alarming red.
    static let attention = Color(uiColor: .dynamic(light: 0xF2545B, dark: 0xFF7A80))
}

// MARK: - Spacing, radius, elevation

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

enum Radius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 20
    static let large: CGFloat = 28
}

extension View {
    /// The one shadow used for raised content.
    func softShadow() -> some View {
        shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    /// A raised surface card with continuous corners.
    func surfaceCard(radius: CGFloat = Radius.large) -> some View {
        background(Color.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .softShadow()
    }
}

// MARK: - Typography

enum Typography {
    /// Uses SF Pro Rounded for navigation bar titles, matching the rest of the app.
    @MainActor
    static func configureNavigationBar() {
        func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
            let size = UIFont.preferredFont(forTextStyle: style).pointSize
            let font = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = font.fontDescriptor.withDesign(.rounded) else { return font }
            return UIFont(descriptor: descriptor, size: size)
        }
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: rounded(.largeTitle, weight: .heavy), .foregroundColor: UIColor.ink]
        appearance.titleTextAttributes = [.font: rounded(.headline, weight: .bold), .foregroundColor: UIColor.ink]
    }
}
