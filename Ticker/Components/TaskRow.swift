import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var context
    @Query private var allTasks: [TaskItem]
    @State private var isHovered = false
    @State private var showingEdit = false
    @State private var isExpanded = false

    private var accentColor: Color { Color(hex: task.hexColor) }

    private var priorityColor: Color {
        switch task.priority {
        case 2: return .red
        case 1: return .orange
        default: return .clear
        }
    }

    private var isOverdue: Bool {
        guard !task.isCompleted, let due = task.dueDate else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }

    private var isToday: Bool {
        guard let due = task.dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainRow
            if !task.tags.isEmpty { tagPills }
            if isExpanded && !task.subtasks.isEmpty { subtaskList }
        }
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(rowBorder)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }

    // MARK: - Ana satır

    private var mainRow: some View {
        HStack(spacing: 0) {
            // Sol renk çubuğu
            RoundedRectangle(cornerRadius: 2)
                .fill(task.isCompleted ? Color.secondary.opacity(0.3) : accentColor)
                .frame(width: 3)
                .padding(.vertical, 6)
                .padding(.leading, 8)
                .padding(.trailing, 10)

            // Tamamlama
            Button {
                withAnimation(.spring(response: 0.3)) { task.isCompleted.toggle() }
                if task.isCompleted && task.isRecurring {
                    let maxOrder = allTasks.map { $0.sortOrder }.max() ?? 0
                    task.makeNextRecurrence(context: context, maxSortOrder: maxOrder)
                }
                try? context.save()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? accentColor : Color.secondary.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)

            // İçerik
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 13, weight: task.priority == 2 ? .medium : .regular))
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                // Alt bilgi satırı
                if task.dueDate != nil || task.reminderDate != nil || task.isRecurring || !task.notes.isEmpty {
                    HStack(spacing: 8) {
                        if let due = task.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 9))
                                Text(due, format: .dateTime.day().month(.abbreviated))
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(isOverdue ? .red : isToday ? .orange : .secondary)
                        }
                        if task.reminderDate != nil {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        if task.isRecurring {
                            Image(systemName: "repeat")
                                .font(.system(size: 9))
                                .foregroundStyle(accentColor.opacity(0.8))
                        }
                        if !task.notes.isEmpty {
                            Image(systemName: "note.text")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Sağ taraf: subtask progress + öncelik + chevron
            HStack(spacing: 8) {
                if !task.subtasks.isEmpty {
                    subtaskProgress
                }

                if task.priority > 0 {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 7, height: 7)
                }

                if !task.subtasks.isEmpty {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                        }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .opacity(isHovered ? 1 : 0)
                }
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            if task.subtasks.isEmpty { showingEdit = true }
            else { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }
        }
    }

    // MARK: - Subtask progress pill

    private var subtaskProgress: some View {
        HStack(spacing: 5) {
            Text("\(task.completedSubtaskCount)/\(task.subtasks.count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15)).frame(width: 30, height: 4)
                Capsule()
                    .fill(accentColor)
                    .frame(
                        width: task.subtasks.isEmpty ? 0 :
                            30 * CGFloat(task.completedSubtaskCount) / CGFloat(task.subtasks.count),
                        height: 4
                    )
                    .animation(.spring(response: 0.4), value: task.completedSubtaskCount)
            }
        }
    }

    // MARK: - Etiket pills

    private var tagPills: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: 33)
            ForEach(task.tags.sorted(by: { $0.name < $1.name })) { tag in
                HStack(spacing: 3) {
                    Circle().fill(Color(hex: tag.hexColor)).frame(width: 4, height: 4)
                    Text(tag.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: tag.hexColor))
                }
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color(hex: tag.hexColor).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            Spacer()
        }
        .padding(.bottom, 7)
        .padding(.leading, 8)
    }

    // MARK: - Subtask listesi

    private var subtaskList: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.2).padding(.leading, 33)

            VStack(spacing: 0) {
                ForEach(task.sortedSubtasks) { subtask in
                    SubTaskRow(subtask: subtask, accentColor: accentColor) {
                        if task.allSubtasksCompleted {
                            withAnimation(.spring(response: 0.3)) { task.isCompleted = true }
                            if task.isRecurring {
                                let maxOrder = allTasks.map { $0.sortOrder }.max() ?? 0
                                task.makeNextRecurrence(context: context, maxSortOrder: maxOrder)
                            }
                        }
                        try? context.save()
                    }
                }
            }
            .padding(.leading, 33)
            .padding(.trailing, 12)
            .padding(.bottom, 4)

            HStack {
                Spacer().frame(width: 33)
                Button { showingEdit = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 9))
                        Text("Alt görev ekle").font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
                Spacer()
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Background & border

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isHovered
                  ? Color(nsColor: .controlBackgroundColor).opacity(0.9)
                  : Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                isOverdue && !task.isCompleted
                ? Color.red.opacity(0.2)
                : Color.primary.opacity(isHovered ? 0.08 : 0.04),
                lineWidth: 1
            )
    }
}

// MARK: - SubTask Row

struct SubTaskRow: View {
    @Bindable var subtask: SubTaskItem
    let accentColor: Color
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.25)) { subtask.isCompleted.toggle() }
                onToggle()
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(subtask.isCompleted ? accentColor : Color.secondary.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Text(subtask.title)
                .font(.system(size: 12))
                .strikethrough(subtask.isCompleted, color: .secondary)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 5)
    }
}
