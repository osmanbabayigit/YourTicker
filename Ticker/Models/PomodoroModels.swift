import Foundation
import SwiftData
import SwiftUI

// MARK: - Pomodoro modu

enum PomodoroMode: String, CaseIterable {
    case focus      = "focus"
    case shortBreak = "shortBreak"
    case longBreak  = "longBreak"

    var label: String {
        switch self {
        case .focus:      return "Odak"
        case .shortBreak: return "Kısa Mola"
        case .longBreak:  return "Uzun Mola"
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .focus:      return 25
        case .shortBreak: return 5
        case .longBreak:  return 15
        }
    }

    var color: Color {
        switch self {
        case .focus:      return Color(hex: "#F87171")
        case .shortBreak: return Color(hex: "#34D399")
        case .longBreak:  return Color(hex: "#3B82F6")
        }
    }

    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "moon.fill"
        }
    }
}

// MARK: - Pomodoro seansı (kayıt)

@Model
class PomodoroSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var mode: String = PomodoroMode.focus.rawValue
    var durationMinutes: Int = 25
    var completed: Bool = false
    var linkedTaskTitle: String = ""
    var linkedTaskID: UUID? = nil

    init(mode: PomodoroMode, durationMinutes: Int,
         completed: Bool = false,
         linkedTaskTitle: String = "",
         linkedTaskID: UUID? = nil) {
        self.mode = mode.rawValue
        self.durationMinutes = durationMinutes
        self.completed = completed
        self.linkedTaskTitle = linkedTaskTitle
        self.linkedTaskID = linkedTaskID
    }

    var pomodoroMode: PomodoroMode {
        PomodoroMode(rawValue: mode) ?? .focus
    }
}

// MARK: - Pomodoro ayarları (UserDefaults)

struct PomodoroSettings {
    static var focusMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "pomo_focus") == 0 ? 25 : UserDefaults.standard.integer(forKey: "pomo_focus") }
        set { UserDefaults.standard.set(newValue, forKey: "pomo_focus") }
    }
    static var shortBreakMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "pomo_short") == 0 ? 5 : UserDefaults.standard.integer(forKey: "pomo_short") }
        set { UserDefaults.standard.set(newValue, forKey: "pomo_short") }
    }
    static var longBreakMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "pomo_long") == 0 ? 15 : UserDefaults.standard.integer(forKey: "pomo_long") }
        set { UserDefaults.standard.set(newValue, forKey: "pomo_long") }
    }
    static var sessionsUntilLongBreak: Int {
        get { UserDefaults.standard.integer(forKey: "pomo_sets") == 0 ? 4 : UserDefaults.standard.integer(forKey: "pomo_sets") }
        set { UserDefaults.standard.set(newValue, forKey: "pomo_sets") }
    }
    static var autoStartBreaks: Bool {
        get { UserDefaults.standard.bool(forKey: "pomo_autobreak") }
        set { UserDefaults.standard.set(newValue, forKey: "pomo_autobreak") }
    }
    static var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "pomo_sound") == nil ? true : UserDefaults.standard.bool(forKey: "pomo_sound") }
        set { UserDefaults.standard.set(newValue, forKey: "pomo_sound") }
    }
}

// MARK: - Timer istatistikleri yardımcısı

struct PomodoroStatsHelper {
    static func todaySessions(_ sessions: [PomodoroSession]) -> [PomodoroSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) && $0.completed }
    }

    static func todayFocusMinutes(_ sessions: [PomodoroSession]) -> Int {
        todaySessions(sessions)
            .filter { $0.pomodoroMode == .focus }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    static func todayFocusCount(_ sessions: [PomodoroSession]) -> Int {
        todaySessions(sessions).filter { $0.pomodoroMode == .focus }.count
    }

    static func weekSessions(_ sessions: [PomodoroSession]) -> [(Date, Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> (Date, Int) in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let count = sessions.filter {
                $0.completed && $0.pomodoroMode == .focus &&
                cal.isDate(cal.startOfDay(for: $0.date), inSameDayAs: date)
            }.count
            return (date, count)
        }
    }
}
