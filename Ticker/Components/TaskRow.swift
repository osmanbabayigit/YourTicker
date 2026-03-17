import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var task: TaskItem
    @State private var isHovered = false

    var priorityIcon: String {
        switch task.priority {
        case 2: return "exclamationmark.3"
        case 1: return "exclamationmark.2"
        default: return ""
        }
    }

    var priorityColor: Color {
        switch task.priority {
        case 2: return .red
        case 1: return .orange
        default: return .clear
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Completion toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    task.isCompleted.toggle()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(task.isCompleted ? Color(hex: task.hexColor) : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            // Color dot
            Circle()
                .fill(Color(hex: task.hexColor))
                .frame(width: 8, height: 8)

            // Title
            Text(task.title)
                .font(.system(size: 13, weight: .regular))
                .strikethrough(task.isCompleted, color: .secondary)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .lineLimit(1)

            Spacer()

            // Priority
            if !priorityIcon.isEmpty {
                Image(systemName: priorityIcon)
                    .font(.system(size: 10))
                    .foregroundStyle(priorityColor)
            }

            // Due date
            if let due = task.dueDate {
                Text(due, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered
                      ? Color(nsColor: .controlBackgroundColor).opacity(0.8)
                      : Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
