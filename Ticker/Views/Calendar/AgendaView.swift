import SwiftUI

struct AgendaView: View {
    let date: Date
    let tasks: [TaskItem]

    @Environment(\.modelContext) private var context

    private var filtered: [TaskItem] {
        tasks.filter { $0.dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false }
            .sorted { $0.priority > $1.priority }
    }
    private var pending:   [TaskItem] { filtered.filter { !$0.isCompleted } }
    private var completed: [TaskItem] { filtered.filter {  $0.isCompleted } }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if !pending.isEmpty {
                            sectionHeader("Bekleyen", count: pending.count, color: TickerTheme.blue)
                            ForEach(pending) { task in agendaRow(task) }
                        }
                        if !completed.isEmpty {
                            sectionHeader("Tamamlandı", count: completed.count, color: TickerTheme.green)
                            ForEach(completed) { task in agendaRow(task) }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(TickerTheme.bgSidebar)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isToday {
                Text("BUGÜN")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(TickerTheme.blue).clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(date, format: .dateTime.day())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(isToday ? TickerTheme.blue : TickerTheme.textPrimary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(date, format: .dateTime.month(.wide))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TickerTheme.textSecondary)
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.system(size: 10))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
            }

            // Progress bar
            if !filtered.isEmpty {
                HStack(spacing: 6) {
                    Text("\(completed.count)/\(filtered.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isToday ? TickerTheme.blue : TickerTheme.textTertiary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(TickerTheme.bgPill).frame(height: 3)
                            Capsule()
                                .fill(isToday ? TickerTheme.blue : TickerTheme.green)
                                .frame(
                                    width: geo.size.width * (filtered.isEmpty ? 0 :
                                        Double(completed.count) / Double(filtered.count)),
                                    height: 3
                                )
                                .animation(.spring(response: 0.5), value: completed.count)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 10)
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(color).frame(width: 2, height: 10)
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(color)
            Text("\(count)").font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
    }

    // MARK: - Row

    @ViewBuilder
    private func agendaRow(_ task: TaskItem) -> some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(Color(hex: task.hexColor).opacity(task.isCompleted ? 0.3 : 0.9))
                .frame(width: 2).padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(task.isCompleted ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                    .strikethrough(task.isCompleted, color: TickerTheme.textTertiary)
                    .lineLimit(2)
                if !task.subtasks.isEmpty {
                    Text("\(task.completedSubtaskCount)/\(task.subtasks.count) alt görev")
                        .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                }
            }

            Spacer()

            if task.priority == 2 { Circle().fill(TickerTheme.red).frame(width: 5, height: 5) }
            else if task.priority == 1 { Circle().fill(TickerTheme.orange).frame(width: 5, height: 5) }
        }
        .padding(.horizontal, 8).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: task.hexColor).opacity(task.isCompleted ? 0.02 : 0.06))
        )
        .padding(.horizontal, 8).padding(.bottom, 4)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: isToday ? "sun.max" : "moon.stars")
                .font(.system(size: 22)).foregroundStyle(TickerTheme.textTertiary)
            Text("Boş gün").font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
            Text("Çift tıkla → odak modu")
                .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
