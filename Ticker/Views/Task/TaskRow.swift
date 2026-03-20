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

    private var isOverdue: Bool {
        guard !task.isCompleted, let due = task.dueDate else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }
    private var isToday: Bool {
        task.dueDate.map { Calendar.current.isDateInToday($0) } ?? false
    }
    private var priorityColor: Color {
        task.priority == 2 ? TickerTheme.red : task.priority == 1 ? TickerTheme.orange : .clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainRow
            if !task.tags.isEmpty { tagPills }
            if isExpanded && !task.subtasks.isEmpty { subtaskSection }
        }
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isHovered ? TickerTheme.bgCardHover : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }

    // MARK: - Ana satır
    // NOT: contentShape kullanmıyoruz — checkbox ve row tıklamaları çakışıyor.
    // Her eleman kendi tıklama alanını yönetiyor.

    private var mainRow: some View {
        HStack(spacing: 0) {
            // Sol renk çizgisi — tıklanamaz
            Capsule()
                .fill(task.isCompleted ? TickerTheme.textTertiary : accentColor)
                .frame(width: 2, height: 22)
                .padding(.leading, 10)
                .padding(.trailing, 10)

            // ✅ CHECKBOX — kendi tıklama alanı, row'dan bağımsız
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    task.isCompleted.toggle()
                }
                if task.isCompleted && task.isRecurring {
                    let maxOrder = allTasks.map { $0.sortOrder }.max() ?? 0
                    task.makeNextRecurrence(context: context, maxSortOrder: maxOrder)
                }
                try? context.save()
            } label: {
                ZStack {
                    // Arka çember
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? accentColor : TickerTheme.borderMid,
                            lineWidth: 1.5
                        )
                        .frame(width: 18, height: 18)

                    // Dolu çember (tamamlandıysa)
                    if task.isCompleted {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                // Hit alanını büyüt — 44x44 minimum
                .frame(width: 32, height: 32)
                .contentShape(Circle().size(CGSize(width: 32, height: 32)))
            }
            .buttonStyle(.plain)

            // İçerik — tıklayınca edit açılır
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 13))
                        .foregroundStyle(task.isCompleted ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                        .strikethrough(task.isCompleted, color: TickerTheme.textTertiary)
                        .lineLimit(1)
                        .animation(.easeOut(duration: 0.15), value: task.isCompleted)

                    // Meta satırı
                    if task.dueDate != nil || task.reminderDate != nil || task.isRecurring {
                        HStack(spacing: 6) {
                            if let due = task.dueDate {
                                HStack(spacing: 3) {
                                    Image(systemName: "calendar").font(.system(size: 9))
                                    Text(due, format: .dateTime.day().month(.abbreviated))
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(isOverdue ? TickerTheme.red : isToday ? TickerTheme.orange : TickerTheme.textTertiary)
                            }
                            if task.reminderDate != nil {
                                Image(systemName: "bell.fill").font(.system(size: 9))
                                    .foregroundStyle(TickerTheme.textTertiary)
                            }
                            if task.isRecurring {
                                Image(systemName: "repeat").font(.system(size: 9))
                                    .foregroundStyle(accentColor.opacity(0.6))
                            }
                        }
                    }
                }

                Spacer()

                // Sağ: subtask + öncelik + chevron
                HStack(spacing: 7) {
                    if !task.subtasks.isEmpty {
                        HStack(spacing: 4) {
                            Text("\(task.completedSubtaskCount)/\(task.subtasks.count)")
                                .font(.system(size: 10))
                                .foregroundStyle(TickerTheme.textTertiary)
                            ZStack(alignment: .leading) {
                                Capsule().fill(TickerTheme.bgPill).frame(width: 24, height: 2)
                                Capsule().fill(accentColor)
                                    .frame(
                                        width: task.subtasks.isEmpty ? 0 :
                                            24 * CGFloat(task.completedSubtaskCount) / CGFloat(task.subtasks.count),
                                        height: 2
                                    )
                            }
                        }
                    }

                    if task.priority > 0 {
                        Circle().fill(priorityColor).frame(width: 5, height: 5)
                    }

                    // Chevron — subtask genişletme veya edit hint
                    if !task.subtasks.isEmpty {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(TickerTheme.textTertiary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(TickerTheme.textTertiary)
                            .opacity(isHovered ? 0.5 : 0)
                    }
                }
                .padding(.trailing, 12)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle()) // sadece içerik alanı tıklanabilir
            .onTapGesture {
                if !task.subtasks.isEmpty {
                    withAnimation(.spring(response: 0.25)) { isExpanded.toggle() }
                } else {
                    showingEdit = true
                }
            }
        }
    }

    // MARK: - Tag pills

    private var tagPills: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: 54) // checkbox + sol çizgi hizası
            ForEach(task.tags.sorted(by: { $0.name < $1.name })) { tag in
                HStack(spacing: 3) {
                    Circle().fill(Color(hex: tag.hexColor)).frame(width: 4, height: 4)
                    Text(tag.name).font(.system(size: 10))
                        .foregroundStyle(Color(hex: tag.hexColor).opacity(0.8))
                }
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Color(hex: tag.hexColor).opacity(0.1))
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.bottom, 5)
    }

    // MARK: - Subtask section

    private var subtaskSection: some View {
        VStack(spacing: 0) {
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1).padding(.leading, 54)

            VStack(spacing: 0) {
                ForEach(task.sortedSubtasks) { sub in
                    SubTaskRow(subtask: sub, accentColor: accentColor) {
                        if task.allSubtasksCompleted {
                            withAnimation { task.isCompleted = true }
                            if task.isRecurring {
                                let maxOrder = allTasks.map { $0.sortOrder }.max() ?? 0
                                task.makeNextRecurrence(context: context, maxSortOrder: maxOrder)
                            }
                        }
                        try? context.save()
                    }
                    .padding(.leading, 54).padding(.trailing, 12)
                }

                Button { showingEdit = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 8))
                        Text("Alt görev ekle").font(.system(size: 11))
                    }
                    .foregroundStyle(TickerTheme.textTertiary)
                    .padding(.leading, 54).frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
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
                withAnimation(.spring(response: 0.2)) { subtask.isCompleted.toggle() }
                onToggle()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(subtask.isCompleted ? accentColor : TickerTheme.borderMid, lineWidth: 1.2)
                        .frame(width: 14, height: 14)
                    if subtask.isCompleted {
                        Circle().fill(accentColor).frame(width: 14, height: 14)
                        Image(systemName: "checkmark").font(.system(size: 6, weight: .heavy)).foregroundStyle(.white)
                    }
                }
                .frame(width: 28, height: 28)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Text(subtask.title)
                .font(.system(size: 12))
                .foregroundStyle(subtask.isCompleted ? TickerTheme.textTertiary : TickerTheme.textSecondary)
                .strikethrough(subtask.isCompleted, color: TickerTheme.textTertiary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
