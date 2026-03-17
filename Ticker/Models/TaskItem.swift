import Foundation
import SwiftData

@Model
class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    var hexColor: String = "#4C8EF7"
    var priority: Int = 0
    var notes: String = ""

    init(
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        hexColor: String = "#4C8EF7",
        priority: Int = 0,
        notes: String = ""
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.hexColor = hexColor
        self.priority = priority
        self.notes = notes
    }
}
