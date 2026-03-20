import Foundation
import SwiftData

@Model
class SubTaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var sortOrder: Int = 0
    var task: TaskItem?

    init(title: String, sortOrder: Int = 0) {
        self.title = title
        self.sortOrder = sortOrder
    }
}
