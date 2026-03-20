import Foundation
import SwiftData

@Model
class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    var reminderDate: Date? = nil
    var hexColor: String = "#4C8EF7"
    var priority: Int = 0
    var notes: String = ""
    var sortOrder: Int = 0

    // Tekrarlama
    var recurrenceRaw: String = RecurrenceRule.none.rawValue
    var recurrenceWeekdays: [Int] = []   // custom için: [2,4,6] = Pzt,Çar,Cum

    @Relationship(inverse: \TagItem.tasks) var tags: [TagItem] = []
    @Relationship(deleteRule: .cascade, inverse: \SubTaskItem.task) var subtasks: [SubTaskItem] = []

    var recurrenceRule: RecurrenceRule {
        get { RecurrenceRule(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    var isRecurring: Bool { recurrenceRule != .none }

    init(
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        hexColor: String = "#4C8EF7",
        priority: Int = 0,
        notes: String = "",
        sortOrder: Int = 0,
        recurrenceRule: RecurrenceRule = .none,
        recurrenceWeekdays: [Int] = []
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.hexColor = hexColor
        self.priority = priority
        self.notes = notes
        self.sortOrder = sortOrder
        self.recurrenceRaw = recurrenceRule.rawValue
        self.recurrenceWeekdays = recurrenceWeekdays
    }

    var allSubtasksCompleted: Bool {
        guard !subtasks.isEmpty else { return false }
        return subtasks.allSatisfy { $0.isCompleted }
    }

    var completedSubtaskCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }

    var sortedSubtasks: [SubTaskItem] {
        subtasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    // Bir sonraki tekrar görevini oluştur
    func makeNextRecurrence(context: ModelContext, maxSortOrder: Int) {
        guard isRecurring, let currentDate = dueDate else { return }
        guard let nextDate = recurrenceRule.nextDate(
            from: currentDate,
            customWeekdays: recurrenceWeekdays
        ) else { return }

        let next = TaskItem(
            title: title,
            dueDate: nextDate,
            hexColor: hexColor,
            priority: priority,
            notes: notes,
            sortOrder: maxSortOrder + 1,
            recurrenceRule: recurrenceRule,
            recurrenceWeekdays: recurrenceWeekdays
        )
        next.tags = tags
        context.insert(next)
    }
}
