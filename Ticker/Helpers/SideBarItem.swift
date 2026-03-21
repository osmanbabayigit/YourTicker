import Foundation

enum SidebarItem: Hashable {
    case pending
    case calendar
    case completed
    case pomodoro
    case goals
    case habits
    case stats
    case notes
    case budget
    case books
    case tag(TagItem)

    var label: String {
        switch self {
        case .pending:    return "Görevler"
        case .calendar:   return "Takvim"
        case .completed:  return "Tamamlananlar"
        case .pomodoro:   return "Pomodoro"
        case .goals:      return "Hedefler"
        case .habits:     return "Alışkanlıklar"
        case .stats:      return "İstatistikler"
        case .notes:      return "Notlar"
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
        case .pomodoro:  return "timer"
        case .goals:     return "target"
        case .habits:    return "repeat.circle.fill"
        case .stats:     return "chart.bar.xaxis"
        case .notes:     return "note.text"
        case .budget:    return "turkishlirasign.circle"
        case .books:     return "books.vertical"
        case .tag:       return "tag.fill"
        }
    }
}
