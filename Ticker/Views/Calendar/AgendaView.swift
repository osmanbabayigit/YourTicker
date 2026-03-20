import SwiftUI

struct AgendaView: View {
    let date: Date
    let tasks: [TaskItem]

    private var filtered: [TaskItem] {
        tasks
            .filter {
                guard let d = $0.dueDate else { return false }
                return Calendar.current.isDate(d, inSameDayAs: date)
            }
            .sorted {
                if $0.priority != $1.priority { return $0.priority > $1.priority }
                return !$0.isCompleted && $1.isCompleted
            }
    }

    private var pending:   [TaskItem] { filtered.filter { !$0.isCompleted } }
    private var completed: [TaskItem] { filtered.filter {  $0.isCompleted } }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                if isToday {
                    Text("BUGÜN")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(date, format: .dateTime.day())
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(isToday ? .blue : .primary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(date, format: .dateTime.month(.wide))
                            .font(.system(size: 13, weight: .medium))
                        Text(date, format: .dateTime.weekday(.wide))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                // Mini progress
                if !filtered.isEmpty {
                    HStack(spacing: 6) {
                        Text("\(completed.count)/\(filtered.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isToday ? .blue : .secondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 4)
                                Capsule()
                                    .fill(isToday ? Color.blue : Color.green)
                                    .frame(
                                        width: filtered.isEmpty ? 0 :
                                            geo.size.width * CGFloat(completed.count) / CGFloat(filtered.count),
                                        height: 4
                                    )
                                    .animation(.spring(response: 0.5), value: completed.count)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.3)

            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Bekleyenler
                        if !pending.isEmpty {
                            sectionHeader("Bekleyen", count: pending.count, color: .blue)
                            ForEach(pending) { task in
                                agendaTaskRow(task)
                            }
                        }

                        // Tamamlananlar
                        if !completed.isEmpty {
                            sectionHeader("Tamamlandı", count: completed.count, color: .green)
                                .padding(.top, pending.isEmpty ? 0 : 8)
                            ForEach(completed) { task in
                                agendaTaskRow(task)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    // MARK: - Components

    @ViewBuilder
    private func sectionHeader(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(color).frame(width: 2, height: 12).clipShape(Capsule())
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func agendaTaskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 8) {
            // Renk çubuğu
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(hex: task.hexColor).opacity(task.isCompleted ? 0.3 : 1.0))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 12, weight: .medium))
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if !task.subtasks.isEmpty {
                    Text("\(task.completedSubtaskCount)/\(task.subtasks.count) alt görev")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if task.priority == 2 {
                Circle().fill(Color.red).frame(width: 6, height: 6)
            } else if task.priority == 1 {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 6)
        .background(Color(hex: task.hexColor).opacity(task.isCompleted ? 0.03 : 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .padding(.bottom, 3)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: isToday ? "sun.max" : "moon.stars")
                .font(.system(size: 22))
                .foregroundStyle(.secondary.opacity(0.3))
            Text("Boş gün")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("Çift tık ile odak modunu aç")
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
