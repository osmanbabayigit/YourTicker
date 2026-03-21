import SwiftUI

enum TickerTheme {
    // Backgrounds
    static let bgApp       = Color(hex: "#111113")
    static let bgSidebar   = Color(hex: "#0C0C0E")
    static let bgCard      = Color(hex: "#18181B")
    static let bgCardHover = Color(hex: "#1E1E22")
    static let bgInput     = Color(hex: "#16161A")
    static let bgPill      = Color(hex: "#1F1F23")

    // Borders
    static let borderSub   = Color.white.opacity(0.06)
    static let borderMid   = Color.white.opacity(0.09)
    static let borderFocus = Color(hex: "#3B82F6").opacity(0.5)

    // Text
    static let textPrimary   = Color(hex: "#E8E8EA")
    static let textSecondary = Color(hex: "#8B8B94")
    static let textTertiary  = Color(hex: "#4A4A54")
    static let textAccent    = Color(hex: "#3B82F6")

    // Status
    static let red    = Color(hex: "#F87171")
    static let orange = Color(hex: "#FB923C")
    static let green  = Color(hex: "#34D399")
    static let blue   = Color(hex: "#3B82F6")
    static let purple = Color(hex: "#C084FC")
}

extension Color {
    static var tickerApp:     Color { TickerTheme.bgApp }
    static var tickerSidebar: Color { TickerTheme.bgSidebar }
    static var tickerCard:    Color { TickerTheme.bgCard }
}
