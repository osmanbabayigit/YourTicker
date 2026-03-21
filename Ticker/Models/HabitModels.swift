import Foundation
import SwiftData
import SwiftUI

// MARK: - Alışkanlık sıklığı

enum HabitFrequency: String, CaseIterable, Codable {
    case daily    = "daily"
    case weekdays = "weekdays"
    case custom   = "custom"

    var label: String {
        switch self {
        case .daily:    return "Her gün"
        case .weekdays: return "Haftaiçi"
        case .custom:   return "Özel günler"
        }
    }
}

// MARK: - Tamamlama kaydı

@Model
class HabitCompletion {
    var id: UUID = UUID()
    var date: Date = Date()
    var habit: Habit?

    init(date: Date = Date()) {
        self.date = date
    }
}

// MARK: - Alışkanlık

@Model
class Habit {
    var id: UUID = UUID()
    var title: String = ""
    var emoji: String = "⭐"
    var hexColor: String = "#34D399"
    var frequencyRaw: String = HabitFrequency.daily.rawValue
    var customWeekdays: [Int] = []   // 1=Paz, 2=Pzt... (Calendar)
    var reminderEnabled: Bool = false
    var reminderHour: Int = 9
    var reminderMinute: Int = 0
    var notes: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    // Bu gün için bekleniyor mu?
    var isExpectedToday: Bool {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        switch frequency {
        case .daily:    return true
        case .weekdays: return (2...6).contains(weekday) // Pzt-Cum
        case .custom:   return customWeekdays.contains(weekday)
        }
    }

    // Bugün tamamlandı mı?
    func isCompletedOn(_ date: Date) -> Bool {
        let cal = Calendar.current
        return completions.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    // Streak hesapla
    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())

        // Bugün tamamlanmadıysa dünden başla
        if !isCompletedOn(checkDate) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: checkDate),
                  isCompletedOn(yesterday) else { return 0 }
            checkDate = yesterday
        }

        while isCompletedOn(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            // Beklenmediği günleri atla
            let weekday = cal.component(.weekday, from: prev)
            var expected = true
            if frequency == .weekdays { expected = (2...6).contains(weekday) }
            if frequency == .custom   { expected = customWeekdays.contains(weekday) }
            if !expected { checkDate = prev; continue }
            checkDate = prev
        }
        return streak
    }

    // Son 7 günün durumu
    func last7Days() -> [(date: Date, status: DayStatus)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> (Date, DayStatus) in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let weekday = cal.component(.weekday, from: date)

            var expected = true
            switch frequency {
            case .daily:    expected = true
            case .weekdays: expected = (2...6).contains(weekday)
            case .custom:   expected = customWeekdays.contains(weekday)
            }

            if !expected { return (date, .notExpected) }
            let completed = isCompletedOn(date)
            let isToday = cal.isDateInToday(date)
            if isToday && !completed { return (date, .pending) }
            return (date, completed ? .completed : .missed)
        }
    }

    // Bu hafta tamamlanma oranı
    var weeklyRate: Double {
        let days = last7Days()
        let expected = days.filter { $0.status != .notExpected }.count
        let completed = days.filter { $0.status == .completed }.count
        guard expected > 0 else { return 0 }
        return Double(completed) / Double(expected)
    }

    init(title: String, emoji: String = "⭐",
         hexColor: String = "#34D399",
         frequency: HabitFrequency = .daily) {
        self.title = title
        self.emoji = emoji
        self.hexColor = hexColor
        self.frequencyRaw = frequency.rawValue
    }
}

// MARK: - Gün durumu

enum DayStatus {
    case completed
    case missed
    case pending      // Bugün, henüz tamamlanmadı
    case notExpected  // Bu gün beklenmiyordu (haftasonu vs)
}
