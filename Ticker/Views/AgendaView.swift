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

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(date, format: .dateTime.day())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(isToday ? .blue : .primary)

                    Text(date, format: .dateTime.month(.wide))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                }

                if !filtered.isEmpty {
                    Text("\(filtered.count) görev")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.3)

            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: isToday ? "sun.max" : "moon.stars")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary.opacity(0.35))
                    Text(isToday ? "Bugün boş" : "Bu gün boş")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filtered) { task in
                            TaskRow(task: task)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
            }
        }
    }
}
