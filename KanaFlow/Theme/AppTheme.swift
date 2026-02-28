import SwiftUI

// MARK: - Colors

enum AppColors {
    // Navy palette
    static let navy100 = Color(hex: "#EBF0F5")
    static let navy200 = Color(hex: "#C8D6E3")
    static let navy300 = Color(hex: "#A5BCD0")
    static let navy400 = Color(hex: "#6B8FA8")
    static let navy500 = Color(hex: "#2D3E50")
    static let navy600 = Color(hex: "#243242")
    static let navy700 = Color(hex: "#1E2A38")
    static let navy800 = Color(hex: "#16202B")

    // Coral palette
    static let coral300 = Color(hex: "#F5A899")
    static let coral400 = Color(hex: "#EE8573")
    static let coral500 = Color(hex: "#E8634B")
    static let coral600 = Color(hex: "#D4523A")

    // Semantic — adaptive light/dark
    static var background: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#1E2A38")
                : UIColor.white
        })
    }

    static var backgroundSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#243242")
                : UIColor(hex: "#F7F9FC")
        })
    }

    static var text: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(hex: "#2D3E50")
        })
    }

    static var textSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#A5BCD0")
                : UIColor(hex: "#6B8FA8")
        })
    }

    static var textMuted: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#6B8FA8")
                : UIColor(hex: "#A5BCD0")
        })
    }

    static var tint: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#6B8FA8")
                : UIColor(hex: "#E8634B")
        })
    }

    static var border: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#6B8FA8")
                : UIColor(hex: "#C8D6E3")
        })
    }

    static var cardBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#243242")
                : UIColor.white
        })
    }

    static var cardBorder: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#A5BCD0")
                : UIColor(hex: "#A5BCD0")
        })
    }

    static var success: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#4ADE80")
                : UIColor(hex: "#22C55E")
        })
    }

    static var error: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#F87171")
                : UIColor(hex: "#EF4444")
        })
    }

    static var warning: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: "#FBBF24")
                : UIColor(hex: "#F59E0B")
        })
    }
}

// MARK: - Typography

enum AppFonts {
    static let kanaHuge = Font.system(size: 120, weight: .medium, design: .default)
    static let kanaLarge = Font.system(size: 80, weight: .medium, design: .default)
    static let kanaMedium = Font.system(size: 56, weight: .medium, design: .default)

    static let heading1 = Font.system(size: 28, weight: .bold, design: .default)
    static let heading2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let heading3 = Font.system(size: 18, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 13, weight: .semibold, design: .default)
    static let label = Font.system(size: 14, weight: .medium, design: .default)
    static let small = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Radius

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Color Hex Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
