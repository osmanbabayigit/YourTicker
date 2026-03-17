import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var tasks: [TaskItem]
    @State private var selectedDate = Date()

    var body: some View {
        MonthGridView(selectedDate: $selectedDate, tasks: tasks) { taskId, newDate in
            if let task = tasks.first(where: { $0.id == taskId }) {
                task.dueDate = newDate
            }
        }
    }
}
