import Foundation
import SwiftData
import SwiftUI

// MARK: - Hedef durumu

enum GoalStatus: String, CaseIterable, Codable {
    case active    = "active"
    case completed = "completed"
    case archived  = "archived"

    var label: String {
        switch self {
        case .active:    return "Aktif"
        case .completed: return "Tamamlandı"
        case .archived:  return "Arşiv"
        }
    }

    var color: Color {
        switch self {
        case .active:    return Color(hex: "#A78BFA")
        case .completed: return TickerTheme.green
        case .archived:  return TickerTheme.textTertiary
        }
    }
}

// MARK: - Milestone

@Model
class GoalMilestone {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var sortOrder: Int = 0
    var completedAt: Date? = nil
    var linkedTaskID: UUID? = nil
    var goal: Goal?

    init(title: String, sortOrder: Int = 0, linkedTaskID: UUID? = nil) {
        self.title = title
        self.sortOrder = sortOrder
        self.linkedTaskID = linkedTaskID
    }
}

// MARK: - Hedef

@Model
class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var emoji: String = "🎯"
    var hexColor: String = "#A78BFA"
    var statusRaw: String = GoalStatus.active.rawValue
    var notes: String = ""
    var targetDate: Date? = nil
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \GoalMilestone.goal)
    var milestones: [GoalMilestone] = []

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var completedMilestones: Int { milestones.filter { $0.isCompleted }.count }
    var totalMilestones: Int { milestones.count }

    var progressPercent: Double {
        guard totalMilestones > 0 else { return 0 }
        return Double(completedMilestones) / Double(totalMilestones)
    }

    var daysLeft: Int? {
        guard let target = targetDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
        return days
    }

    var sortedMilestones: [GoalMilestone] {
        milestones.sorted { $0.sortOrder < $1.sortOrder }
    }

    init(title: String, emoji: String = "🎯",
         hexColor: String = "#A78BFA", targetDate: Date? = nil,
         notes: String = "") {
        self.title = title
        self.emoji = emoji
        self.hexColor = hexColor
        self.targetDate = targetDate
        self.notes = notes
    }
}
