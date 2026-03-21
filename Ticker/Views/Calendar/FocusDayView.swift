import SwiftUI
import SwiftData

struct FocusDayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let tasks: [TaskItem]

    @State private var showingAddTask = false

    private var dayTasks: [TaskItem] {
        tasks
            .filter { $0.dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false }
            .sorted { ($0.priority, $0.isCompleted ? 0 : 1) > ($1.priority, $1.isCompleted ? 0 : 1) }
    }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var completedCount: Int { dayTasks.filter { $0.isCompleted }.count }
    private var progressRatio: Double {
        dayTasks.isEmpty ? 0 : Double(completedCount) / Double(dayTasks.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if dayTasks.isEmpty {
                emptyState
            } else {
                taskGrid
            }
        }
        .frame(width: 660, height: 500)
        .background(Color(hex: "#161618"))
        .sheet(isPresented: $showingAddTask) { AddTaskView(selectedDate: date) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if isToday {
                        Text("BUGÜN")
                            .font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(TickerTheme.blue).clipShape(Capsule())
                    }
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
                }
                Text(date, format: .dateTime.day().month(.wide).year())
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(TickerTheme.textPrimary)

                if !dayTasks.isEmpty {
                    Text("\(completedCount)/\(dayTasks.count) görev tamamlandı")
                        .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)

                Button { showingAddTask = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 10))
                        Text("Görev Ekle").font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(TickerTheme.blue).clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(TickerTheme.bgPill).frame(height: 2)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [TickerTheme.blue, TickerTheme.green],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progressRatio, height: 2)
                    .animation(.spring(response: 0.5), value: progressRatio)
            }
        }
        .frame(height: 2)
        .padding(.horizontal, 22).padding(.bottom, 8)
    }

    // MARK: - Task grid

    private var taskGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(dayTasks) { task in
                    FocusTaskCard(task: task)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: isToday ? "sun.max" : "moon.stars")
                .font(.system(size: 30)).foregroundStyle(TickerTheme.textTertiary)
            Text(isToday ? "Bugün boş!" : "Bu gün boş")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(TickerTheme.textSecondary)
            Button { showingAddTask = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus").font(.system(size: 11))
                    Text("Görev Ekle").font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(TickerTheme.blue)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(TickerTheme.blue.opacity(0.12)).clipShape(Capsule())
                .overlay(Capsule().stroke(TickerTheme.blue.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Odak görev kartı

struct FocusTaskCard: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button {
                    withAnimation(.spring(response: 0.3)) { task.isCompleted.toggle() }
                    try? context.save()
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(task.isCompleted ? Color(hex: task.hexColor) : TickerTheme.borderMid)
                        .contentTransition(.symbolEffect(.replace.downUp))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                        .strikethrough(task.isCompleted, color: TickerTheme.textTertiary)
                        .lineLimit(2)
                    if !task.notes.isEmpty {
                        Text(task.notes).font(.system(size: 10))
                            .foregroundStyle(TickerTheme.textTertiary).lineLimit(2)
                    }
                }

                Spacer()

                if task.priority == 2 {
                    Circle().fill(TickerTheme.red).frame(width: 6, height: 6)
                } else if task.priority == 1 {
                    Circle().fill(TickerTheme.orange).frame(width: 6, height: 6)
                }
            }

            // Alt görevler
            if !task.subtasks.isEmpty {
                VStack(spacing: 3) {
                    ForEach(task.sortedSubtasks.prefix(3)) { sub in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(sub.isCompleted ? Color(hex: task.hexColor) : TickerTheme.borderMid)
                                .frame(width: 5, height: 5)
                            Text(sub.title).font(.system(size: 10))
                                .foregroundStyle(sub.isCompleted ? TickerTheme.textTertiary : TickerTheme.textSecondary)
                                .strikethrough(sub.isCompleted)
                                .lineLimit(1)
                        }
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(TickerTheme.bgPill).frame(height: 3)
                        Capsule().fill(Color(hex: task.hexColor))
                            .frame(
                                width: task.subtasks.isEmpty ? 0 :
                                    geo.size.width * Double(task.completedSubtaskCount) / Double(task.subtasks.count),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
            }

            // Etiketler
            if !task.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(task.tags.prefix(3)) { tag in
                        Text(tag.name).font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(hex: tag.hexColor))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: tag.hexColor).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(task.isCompleted
                      ? TickerTheme.bgCard.opacity(0.5)
                      : Color(hex: task.hexColor).opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    task.isCompleted ? TickerTheme.borderSub :
                    Color(hex: task.hexColor).opacity(isHovered ? 0.3 : 0.12),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.2), value: isHovered)
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
}
