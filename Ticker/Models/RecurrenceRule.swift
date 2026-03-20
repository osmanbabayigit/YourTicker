import Foundation

enum RecurrenceRule: String, CaseIterable, Codable {
    case none    = "none"
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    case custom  = "custom"  // Belirli günler

    var label: String {
        switch self {
        case .none:    return "Yok"
        case .daily:   return "Her gün"
        case .weekly:  return "Her hafta"
        case .monthly: return "Her ay"
        case .custom:  return "Belirli günler"
        }
    }

    var icon: String {
        switch self {
        case .none:    return "slash.circle"
        case .daily:   return "sun.max"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .custom:  return "checklist"
        }
    }

    // Bir sonraki tarihi hesapla
    func nextDate(from date: Date, customWeekdays: [Int] = []) -> Date? {
        let cal = Calendar.current
        switch self {
        case .none:
            return nil
        case .daily:
            return cal.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return cal.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return cal.date(byAdding: .month, value: 1, to: date)
        case .custom:
            guard !customWeekdays.isEmpty else { return nil }
            // Bugünden sonraki en yakın seçili günü bul
            let sortedDays = customWeekdays.sorted()
            let todayWeekday = cal.component(.weekday, from: date) // 1=Paz, 2=Pzt...
            // Haftanın geri kalanında uygun gün var mı?
            for day in sortedDays {
                if day > todayWeekday {
                    let diff = day - todayWeekday
                    return cal.date(byAdding: .day, value: diff, to: date)
                }
            }
            // Yoksa gelecek haftanın ilk uygun gününe git
            let firstDay = sortedDays[0]
            let diff = (7 - todayWeekday) + firstDay
            return cal.date(byAdding: .day, value: diff, to: date)
        }
    }
}

// Türkçe gün isimleri (weekday: 1=Paz, 2=Pzt, ..., 7=Cmt)
let weekdayLabels: [(Int, String)] = [
    (2, "Pzt"), (3, "Sal"), (4, "Çar"),
    (5, "Per"), (6, "Cum"), (7, "Cmt"), (1, "Paz")
]
