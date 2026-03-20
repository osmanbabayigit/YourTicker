import SwiftUI
import UniformTypeIdentifiers

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let tasks: [TaskItem]
    let isCurrentMonth: Bool
    var onTaskDropped: (UUID, Date) -> Void
    var onFocusDay: () -> Void = {}

    @State private var isDropTargeted = false
    @State private var editingTask: TaskItem? = nil
    @State private var isHovered = false

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var pendingTasks: [TaskItem] { tasks.filter { !$0.isCompleted } }
    private var completedTasks: [TaskItem] { tasks.filter { $0.isCompleted } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gün numarası satırı
            HStack(alignment: .center) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 26, height: 26)
                    } else if isSelected {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 26, height: 26)
                    }
                    Text(dayNumber)
                        .font(.system(size: 12, weight: isToday ? .bold : isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isToday ? .white :
                            isSelected ? .blue :
                            isCurrentMonth ? .primary : .secondary.opacity(0.4)
                        )
                }
                .frame(width: 26, height: 26)

                Spacer()

                // Görev sayısı badge
                if tasks.count > 0 {
                    Text("\(tasks.count)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isToday ? .white : .secondary)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(isToday ? Color.blue.opacity(0.6) : Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 5)

            // Görev listesi
            VStack(alignment: .leading, spacing: 2) {
                ForEach(pendingTasks.prefix(3)) { task in
                    taskChip(task: task, completed: false)
                        .onTapGesture { editingTask = task }
                }

                // Tamamlananlar soluk göster
                if pendingTasks.count < 3 {
                    ForEach(completedTasks.prefix(max(0, 3 - pendingTasks.count))) { task in
                        taskChip(task: task, completed: true)
                            .onTapGesture { editingTask = task }
                    }
                }

                if tasks.count > 3 {
                    Text("+\(tasks.count - 3)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 3)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cellBackground)
        .overlay(cellBorder)
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) { onFocusDay() }   // çift tık = odak modu
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { string, _ in
                if let uuidString = string as? String,
                   let taskId = UUID(uuidString: uuidString) {
                    DispatchQueue.main.async { onTaskDropped(taskId, date) }
                }
            }
            return true
        }
        .sheet(item: $editingTask) { task in EditTaskView(task: task) }
    }

    @ViewBuilder
    private func taskChip(task: TaskItem, completed: Bool) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(hex: task.hexColor))
                .frame(width: 3, height: 10)

            Text(task.title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .strikethrough(completed)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: task.hexColor).opacity(completed ? 0.06 : 0.14))
        .foregroundStyle(Color(hex: task.hexColor).opacity(completed ? 0.45 : 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onDrag { NSItemProvider(object: task.id.uuidString as NSString) }
    }

    private var cellBackground: some View {
        Group {
            if isDropTargeted {
                Color.blue.opacity(0.12)
            } else if isToday {
                Color.blue.opacity(0.05)
            } else if isSelected {
                Color.blue.opacity(0.04)
            } else if isHovered {
                Color.primary.opacity(0.03)
            } else {
                Color.clear
            }
        }
    }

    private var cellBorder: some View {
        Rectangle()
            .stroke(
                isDropTargeted ? Color.blue.opacity(0.4) :
                isToday ? Color.blue.opacity(0.2) :
                Color.gray.opacity(0.1),
                lineWidth: isDropTargeted ? 1.5 : 0.5
            )
    }
}
