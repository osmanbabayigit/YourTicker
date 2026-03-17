import Foundation

enum SidebarItem: String, CaseIterable, Identifiable {
    case pending   = "Görevler"
    case calendar  = "Takvim"
    case completed = "Tamamlananlar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pending:   return "checklist"
        case .calendar:  return "calendar"
        case .completed: return "checkmark.circle.fill"
        }
    }
}
