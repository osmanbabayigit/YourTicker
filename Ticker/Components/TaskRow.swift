import SwiftUI
import SwiftData

struct TaskRow: View {

    @Bindable var task: TaskItem

    var body: some View {
        HStack {

            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    task.isCompleted.toggle()
                }

            Text(task.title)

            Spacer()
        }
        .padding()
        .background(GlassView())
        .cornerRadius(12)
    }
}
//
