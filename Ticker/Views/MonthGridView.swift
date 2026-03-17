import SwiftUI

struct MonthGridView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    var onTaskDropped: (UUID, Date) -> Void

    @State private var showingAddTask = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    private var days: [Date] {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: selectedDate)
        comps.weekday = nil
        let startOfMonth = calendar.date(from: comps)!

        // Fill leading blank days (week starts Monday)
        let weekdayOfFirst = (calendar.component(.weekday, from: startOfMonth) + 5) % 7
        let totalDays = calendar.range(of: .day, in: .month, for: selectedDate)!.count

        var dates: [Date] = []

        // Leading padding
        for offset in (0..<weekdayOfFirst).reversed() {
            if let d = calendar.date(byAdding: .day, value: -offset - 1, to: startOfMonth) {
                dates.append(d)
            }
        }
        // Current month
        for i in 0..<totalDays {
            if let d = calendar.date(byAdding: .day, value: i, to: startOfMonth) {
                dates.append(d)
            }
        }
        // Trailing padding to complete grid
        let remainder = dates.count % 7
        if remainder != 0 {
            let trailing = 7 - remainder
            let lastDay = dates.last!
            for i in 1...trailing {
                if let d = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    dates.append(d)
                }
            }
        }
        return dates
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 0) {
                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Görev Ekle", systemImage: "plus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.blue)

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)

                    HStack(spacing: 0) {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedDate = Date()
                        } label: {
                            Text("Bugün")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .frame(height: 28)
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider().opacity(0.4)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            Divider().opacity(0.4)

            // Grid
            GeometryReader { geo in
                let rowCount = days.count / 7
                let rowHeight = geo.size.height / CGFloat(rowCount)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        DayCell(
                            date: day,
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(day),
                            tasks: tasksFor(day),
                            onTaskDropped: onTaskDropped
                        )
                        .opacity(isCurrentMonth(day) ? 1.0 : 0.35)
                        .onTapGesture { selectedDate = day }
                        .frame(height: rowHeight)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: selectedDate)
        }
    }

    private func tasksFor(_ date: Date) -> [TaskItem] {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }
}
