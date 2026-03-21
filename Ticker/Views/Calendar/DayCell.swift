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

    private var day: String { "\(Calendar.current.component(.day, from: date))" }
    private var pending:   [TaskItem] { tasks.filter { !$0.isCompleted } }
    private var completed: [TaskItem] { tasks.filter {  $0.isCompleted } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dayHeader
            taskList
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cellBg)
        .overlay(cellBorder)
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) { onFocusDay() }
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
            guard let p = providers.first else { return false }
            p.loadObject(ofClass: NSString.self) { s, _ in
                if let str = s as? String, let id = UUID(uuidString: str) {
                    DispatchQueue.main.async { onTaskDropped(id, date) }
                }
            }
            return true
        }
        .sheet(item: $editingTask) { EditTaskView(task: $0) }
    }

    // MARK: - Day header

    private var dayHeader: some View {
        HStack(alignment: .center) {
            ZStack {
                if isToday {
                    Circle().fill(TickerTheme.blue).frame(width: 24, height: 24)
                } else if isSelected {
                    Circle().fill(TickerTheme.blue.opacity(0.15)).frame(width: 24, height: 24)
                }
                Text(day)
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundStyle(
                        isToday    ? .white :
                        isSelected ? TickerTheme.blue :
                        isCurrentMonth ? TickerTheme.textPrimary :
                        TickerTheme.textTertiary
                    )
            }
            .frame(width: 24, height: 24)

            Spacer()

            if tasks.count > 0 {
                Text("\(tasks.count)")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isToday ? .white : TickerTheme.textTertiary)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(isToday ? TickerTheme.blue.opacity(0.5) : TickerTheme.bgPill)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 5).padding(.top, 5)
    }

    // MARK: - Task chips

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(pending.prefix(3)) { task in
                chip(task: task, faded: false).onTapGesture { editingTask = task }
            }
            if pending.count < 3 {
                let remaining = 3 - pending.count
                ForEach(completed.prefix(remaining)) { task in
                    chip(task: task, faded: true).onTapGesture { editingTask = task }
                }
            }
            if tasks.count > 3 {
                Text("+\(tasks.count - 3)")
                    .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                    .padding(.horizontal, 5).padding(.top, 1)
            }
        }
        .padding(.horizontal, 4).padding(.top, 2)
    }

    @ViewBuilder
    private func chip(task: TaskItem, faded: Bool) -> some View {
        HStack(spacing: 3) {
            Capsule()
                .fill(Color(hex: task.hexColor).opacity(faded ? 0.4 : 1.0))
                .frame(width: 2, height: 9)
            Text(task.title)
                .font(.system(size: 9.5, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(Color(hex: task.hexColor).opacity(faded ? 0.4 : 0.9))
        }
        .padding(.horizontal, 4).padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: task.hexColor).opacity(faded ? 0.04 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .onDrag { NSItemProvider(object: task.id.uuidString as NSString) }
    }

    // MARK: - Background & border

    private var cellBg: some View {
        Group {
            if isDropTargeted      { TickerTheme.blue.opacity(0.1) }
            else if isToday        { TickerTheme.blue.opacity(0.04) }
            else if isSelected     { TickerTheme.blue.opacity(0.03) }
            else if isHovered      { Color.white.opacity(0.02) }
            else                   { Color.clear }
        }
    }

    private var cellBorder: some View {
        Rectangle()
            .stroke(
                isDropTargeted ? TickerTheme.blue.opacity(0.4) : TickerTheme.borderSub,
                lineWidth: 0.5
            )
    }
}
