import SwiftUI

struct ThemePalette {
    let bg: Color
    let panel: Color
    let panel2: Color
    let border: Color
    let text: Color
    let text2: Color
    let muted: Color
    let purple: Color
    let teal: Color
    let red: Color
    let amber: Color
    let blue: Color
    let green: Color
}

enum ThemeStyle: String, CaseIterable, Identifiable {
    case slate
    case midnight
    case paper
    case ivory
    case forest
    case ember
    case lagoon
    case parchment

    var id: String { rawValue }

    var label: String {
        switch self {
        case .slate: return "Slate"
        case .midnight: return "Midnight"
        case .paper: return "Paper"
        case .ivory: return "Ivory"
        case .forest: return "Forest"
        case .ember: return "Ember"
        case .lagoon: return "Lagoon"
        case .parchment: return "Parchment"
        }
    }

    var subtitle: String {
        switch self {
        case .slate: return "Balanced dark"
        case .midnight: return "Deep dark"
        case .paper: return "Cool light"
        case .ivory: return "Warm light"
        case .forest: return "Dark green"
        case .ember: return "Warm dark"
        case .lagoon: return "Soft aqua"
        case .parchment: return "Cream light"
        }
    }

    var scheme: ColorScheme {
        switch self {
        case .paper, .ivory:
            return .light
        case .slate, .midnight, .forest, .ember:
            return .dark
        case .lagoon, .parchment:
            return .light
        }
    }

    var palette: ThemePalette {
        switch self {
        case .slate:
            return ThemePalette(
                bg: Color(red: 0.06, green: 0.06, blue: 0.08),
                panel: Color(red: 0.09, green: 0.09, blue: 0.12),
                panel2: Color(red: 0.07, green: 0.07, blue: 0.1),
                border: Color(red: 0.16, green: 0.16, blue: 0.22),
                text: Color(red: 0.96, green: 0.96, blue: 0.98),
                text2: Color(red: 0.82, green: 0.82, blue: 0.87),
                muted: Color(red: 0.45, green: 0.45, blue: 0.5),
                purple: Color(red: 0.65, green: 0.54, blue: 0.98),
                teal: Color(red: 0.37, green: 0.92, blue: 0.83),
                red: Color(red: 0.97, green: 0.44, blue: 0.44),
                amber: Color(red: 0.98, green: 0.75, blue: 0.25),
                blue: Color(red: 0.38, green: 0.65, blue: 0.98),
                green: Color(red: 0.43, green: 0.91, blue: 0.72)
            )
        case .midnight:
            return ThemePalette(
                bg: Color(red: 0.03, green: 0.05, blue: 0.09),
                panel: Color(red: 0.07, green: 0.09, blue: 0.14),
                panel2: Color(red: 0.05, green: 0.07, blue: 0.11),
                border: Color(red: 0.14, green: 0.18, blue: 0.26),
                text: Color(red: 0.97, green: 0.98, blue: 1.0),
                text2: Color(red: 0.84, green: 0.86, blue: 0.92),
                muted: Color(red: 0.5, green: 0.53, blue: 0.6),
                purple: Color(red: 0.74, green: 0.63, blue: 0.99),
                teal: Color(red: 0.35, green: 0.9, blue: 0.94),
                red: Color(red: 0.98, green: 0.43, blue: 0.47),
                amber: Color(red: 0.98, green: 0.78, blue: 0.34),
                blue: Color(red: 0.38, green: 0.64, blue: 1.0),
                green: Color(red: 0.45, green: 0.94, blue: 0.68)
            )
        case .paper:
            return ThemePalette(
                bg: Color(red: 0.97, green: 0.97, blue: 0.95),
                panel: Color(red: 0.92, green: 0.92, blue: 0.89),
                panel2: Color(red: 0.95, green: 0.95, blue: 0.93),
                border: Color(red: 0.83, green: 0.83, blue: 0.79),
                text: Color(red: 0.12, green: 0.12, blue: 0.14),
                text2: Color(red: 0.28, green: 0.28, blue: 0.31),
                muted: Color(red: 0.47, green: 0.47, blue: 0.5),
                purple: Color(red: 0.48, green: 0.36, blue: 0.86),
                teal: Color(red: 0.08, green: 0.67, blue: 0.62),
                red: Color(red: 0.86, green: 0.29, blue: 0.34),
                amber: Color(red: 0.93, green: 0.63, blue: 0.18),
                blue: Color(red: 0.18, green: 0.44, blue: 0.92),
                green: Color(red: 0.15, green: 0.63, blue: 0.44)
            )
        case .ivory:
            return ThemePalette(
                bg: Color(red: 0.98, green: 0.96, blue: 0.92),
                panel: Color(red: 0.93, green: 0.91, blue: 0.86),
                panel2: Color(red: 0.96, green: 0.94, blue: 0.91),
                border: Color(red: 0.85, green: 0.82, blue: 0.76),
                text: Color(red: 0.14, green: 0.12, blue: 0.1),
                text2: Color(red: 0.31, green: 0.28, blue: 0.24),
                muted: Color(red: 0.49, green: 0.46, blue: 0.42),
                purple: Color(red: 0.58, green: 0.42, blue: 0.9),
                teal: Color(red: 0.11, green: 0.63, blue: 0.55),
                red: Color(red: 0.84, green: 0.32, blue: 0.31),
                amber: Color(red: 0.88, green: 0.6, blue: 0.2),
                blue: Color(red: 0.2, green: 0.5, blue: 0.9),
                green: Color(red: 0.2, green: 0.59, blue: 0.38)
            )
        case .forest:
            return ThemePalette(
                bg: Color(red: 0.04, green: 0.08, blue: 0.06),
                panel: Color(red: 0.07, green: 0.12, blue: 0.1),
                panel2: Color(red: 0.05, green: 0.09, blue: 0.08),
                border: Color(red: 0.14, green: 0.2, blue: 0.18),
                text: Color(red: 0.96, green: 0.98, blue: 0.95),
                text2: Color(red: 0.82, green: 0.88, blue: 0.84),
                muted: Color(red: 0.45, green: 0.52, blue: 0.47),
                purple: Color(red: 0.48, green: 0.8, blue: 0.56),
                teal: Color(red: 0.34, green: 0.88, blue: 0.71),
                red: Color(red: 0.93, green: 0.39, blue: 0.43),
                amber: Color(red: 0.85, green: 0.7, blue: 0.26),
                blue: Color(red: 0.37, green: 0.67, blue: 0.94),
                green: Color(red: 0.28, green: 0.78, blue: 0.46)
            )
        case .ember:
            return ThemePalette(
                bg: Color(red: 0.09, green: 0.05, blue: 0.04),
                panel: Color(red: 0.13, green: 0.08, blue: 0.07),
                panel2: Color(red: 0.1, green: 0.06, blue: 0.05),
                border: Color(red: 0.23, green: 0.15, blue: 0.13),
                text: Color(red: 0.99, green: 0.96, blue: 0.94),
                text2: Color(red: 0.88, green: 0.82, blue: 0.79),
                muted: Color(red: 0.56, green: 0.49, blue: 0.46),
                purple: Color(red: 0.98, green: 0.58, blue: 0.32),
                teal: Color(red: 0.98, green: 0.43, blue: 0.34),
                red: Color(red: 0.99, green: 0.29, blue: 0.31),
                amber: Color(red: 0.98, green: 0.74, blue: 0.26),
                blue: Color(red: 0.42, green: 0.64, blue: 0.98),
                green: Color(red: 0.42, green: 0.86, blue: 0.52)
            )
        case .lagoon:
            return ThemePalette(
                bg: Color(red: 0.95, green: 0.98, blue: 0.98),
                panel: Color(red: 0.9, green: 0.95, blue: 0.95),
                panel2: Color(red: 0.94, green: 0.98, blue: 0.98),
                border: Color(red: 0.8, green: 0.87, blue: 0.88),
                text: Color(red: 0.1, green: 0.13, blue: 0.15),
                text2: Color(red: 0.23, green: 0.28, blue: 0.31),
                muted: Color(red: 0.44, green: 0.5, blue: 0.52),
                purple: Color(red: 0.12, green: 0.58, blue: 0.74),
                teal: Color(red: 0.11, green: 0.7, blue: 0.68),
                red: Color(red: 0.85, green: 0.3, blue: 0.38),
                amber: Color(red: 0.94, green: 0.67, blue: 0.21),
                blue: Color(red: 0.18, green: 0.5, blue: 0.96),
                green: Color(red: 0.18, green: 0.68, blue: 0.46)
            )
        case .parchment:
            return ThemePalette(
                bg: Color(red: 0.99, green: 0.97, blue: 0.93),
                panel: Color(red: 0.95, green: 0.92, blue: 0.87),
                panel2: Color(red: 0.97, green: 0.95, blue: 0.91),
                border: Color(red: 0.87, green: 0.83, blue: 0.77),
                text: Color(red: 0.14, green: 0.11, blue: 0.08),
                text2: Color(red: 0.33, green: 0.29, blue: 0.25),
                muted: Color(red: 0.53, green: 0.48, blue: 0.43),
                purple: Color(red: 0.58, green: 0.35, blue: 0.82),
                teal: Color(red: 0.08, green: 0.62, blue: 0.58),
                red: Color(red: 0.86, green: 0.33, blue: 0.32),
                amber: Color(red: 0.91, green: 0.56, blue: 0.19),
                blue: Color(red: 0.23, green: 0.47, blue: 0.88),
                green: Color(red: 0.18, green: 0.56, blue: 0.36)
            )
        }
    }
}

@MainActor
final class ThemeStore: ObservableObject {
    private static let storageKey = "themeStyle"

    @Published private(set) var selectedTheme: ThemeStyle

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        let initial = ThemeStyle(rawValue: raw ?? ThemeStyle.slate.rawValue) ?? .slate
        selectedTheme = initial
        Theme.apply(initial.palette)
    }

    func setTheme(_ style: ThemeStyle) {
        guard style != selectedTheme else { return }
        Theme.apply(style.palette)
        selectedTheme = style
        UserDefaults.standard.set(style.rawValue, forKey: Self.storageKey)
    }
}

enum Theme {
    static var bg = Color(red: 0.06, green: 0.06, blue: 0.08)
    static var panel = Color(red: 0.09, green: 0.09, blue: 0.12)
    static var panel2 = Color(red: 0.07, green: 0.07, blue: 0.1)
    static var border = Color(red: 0.16, green: 0.16, blue: 0.22)
    static var text = Color(red: 0.96, green: 0.96, blue: 0.98)
    static var text2 = Color(red: 0.82, green: 0.82, blue: 0.87)
    static var muted = Color(red: 0.45, green: 0.45, blue: 0.5)
    static var purple = Color(red: 0.65, green: 0.54, blue: 0.98)
    static var teal = Color(red: 0.37, green: 0.92, blue: 0.83)
    static var red = Color(red: 0.97, green: 0.44, blue: 0.44)
    static var amber = Color(red: 0.98, green: 0.75, blue: 0.25)
    static var blue = Color(red: 0.38, green: 0.65, blue: 0.98)
    static var green = Color(red: 0.43, green: 0.91, blue: 0.72)

    static func apply(_ palette: ThemePalette) {
        bg = palette.bg
        panel = palette.panel
        panel2 = palette.panel2
        border = palette.border
        text = palette.text
        text2 = palette.text2
        muted = palette.muted
        purple = palette.purple
        teal = palette.teal
        red = palette.red
        amber = palette.amber
        blue = palette.blue
        green = palette.green
    }
}
