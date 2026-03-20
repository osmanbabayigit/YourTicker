import Foundation

enum SidebarItem: Hashable {
    case pending
    case calendar
    case completed
    case budget
    case books
    case tag(TagItem)

    var label: String {
        switch self {
        case .pending:    return "Görevler"
        case .calendar:   return "Takvim"
        case .completed:  return "Tamamlananlar"
        case .budget:     return "Bütçe"
        case .books:      return "Kitaplık"
        case .tag(let t): return t.name
        }
    }

    var icon: String {
        switch self {
        case .pending:   return "checklist"
        case .calendar:  return "calendar"
        case .completed: return "checkmark.circle.fill"
        case .budget:    return "turkishlirasign.circle"
        case .books:     return "books.vertical"
        case .tag:       return "tag.fill"
        }
    }
}
