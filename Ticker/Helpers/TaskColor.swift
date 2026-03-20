import SwiftUI

enum TaskColor: String, CaseIterable {
    case blue   = "#4C8EF7"
    case cyan   = "#00BCD4"
    case green  = "#4CAF50"
    case yellow = "#FFC107"
    case orange = "#FF7043"
    case red    = "#F44336"
    case purple = "#9C27B0"
    case pink   = "#E91E63"

    var color: Color { Color(hex: self.rawValue) }

    var label: String {
        switch self {
        case .blue:   return "Mavi"
        case .cyan:   return "Camgöbeği"
        case .green:  return "Yeşil"
        case .yellow: return "Sarı"
        case .orange: return "Turuncu"
        case .red:    return "Kırmızı"
        case .purple: return "Mor"
        case .pink:   return "Pembe"
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
