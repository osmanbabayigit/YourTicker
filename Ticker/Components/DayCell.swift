import SwiftUI
import UniformTypeIdentifiers

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let tasks: [TaskItem]
    var onTaskDropped: (UUID, Date) -> Void

    @State private var isDropTargeted = false
    @State private var editingTask: TaskItem? = nil

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Gün numarası
            HStack {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 22, height: 22)
                    }
                    Text(dayNumber)
                        .font(.system(size: 12, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundStyle(
                            isToday ? .white :
                            isSelected ? .blue : .primary
                        )
                }
                .frame(width: 24, height: 24)
                .padding(.leading, 6)
                .padding(.top, 6)
                Spacer()
            }

            // Görevler
            VStack(alignment: .leading, spacing: 2) {
                ForEach(tasks.prefix(3)) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: task.hexColor))
                            .frame(width: 5, height: 5)
                        Text(task.title)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: task.hexColor).opacity(0.18))
                    .foregroundStyle(Color(hex: task.hexColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onTapGesture { editingTask = task }         // ← tıklayınca edit aç
                    .onDrag {
                        NSItemProvider(object: task.id.uuidString as NSString)
                    }
                }
                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) daha")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if isDropTargeted {
                    Color.blue.opacity(0.15)
                } else if isSelected {
                    Color.blue.opacity(0.07)
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            Rectangle()
                .stroke(
                    isDropTargeted ? Color.blue.opacity(0.5) : Color.gray.opacity(0.12),
                    lineWidth: isDropTargeted ? 1.5 : 0.5
                )
        )
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
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task)
        }
    }
}
