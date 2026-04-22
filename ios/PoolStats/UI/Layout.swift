import SwiftUI

// Shared layout constants and a small session display helper.
enum Layout {
    static let pagePadding: CGFloat = 14
    static let cardSpacing: CGFloat = 14
    static let gridSpacing: CGFloat = 10

    static func twoColumn() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 2)
    }

    static func columns(hSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = hSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: count)
    }

    static func fourColumn() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 4)
    }

    static let chartSm: CGFloat = 180
    static let chartMd: CGFloat = 200
    static let chartLg: CGFloat = 220
    static let chartRadar: CGFloat = 240

    static func chartHeight(_ base: CGFloat, hSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        hSizeClass == .regular ? base * 1.4 : base
    }
}

extension Session {
    var resultAccentColor: Color {
        if isPractice { return Theme.muted }
        if wins > losses { return Theme.green }
        if losses > wins { return Theme.red }
        if isDraw { return Theme.amber }
        return Theme.border
    }
}
