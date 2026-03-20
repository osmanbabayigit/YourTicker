import SwiftUI
import SwiftData

struct MonthGridView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    var onFocusDay: () -> Void = {}
    var onTaskDropped: (UUID, Date) -> Void

    @State private var showingAddTask = false
    @State private var monthOffset: Int = 0
    @State private var slideDirection: Edge = .trailing

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    private var days: [Date] {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: selectedDate)
        comps.weekday = nil
        let startOfMonth = calendar.date(from: comps)!
        let weekdayOfFirst = (calendar.component(.weekday, from: startOfMonth) + 5) % 7
        let totalDays = calendar.range(of: .day, in: .month, for: selectedDate)!.count

        var dates: [Date] = []
        for offset in (0..<weekdayOfFirst).reversed() {
            if let d = calendar.date(byAdding: .day, value: -offset - 1, to: startOfMonth) {
                dates.append(d)
            }
        }
        for i in 0..<totalDays {
            if let d = calendar.date(byAdding: .day, value: i, to: startOfMonth) {
                dates.append(d)
            }
        }
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
        HSplitView {
            // Sol: Takvim grid
            VStack(spacing: 0) {
                topBar
                Divider().opacity(0.3)
                weekdayHeader
                Divider().opacity(0.3)
                calendarGrid
            }
            .frame(minWidth: 500)

            // Sağ: Agenda paneli
            AgendaView(date: selectedDate, tasks: tasks)
                .frame(minWidth: 220, maxWidth: 280)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: selectedDate)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate, format: .dateTime.month(.wide))
                    .font(.system(size: 22, weight: .bold))
                Text(selectedDate, format: .dateTime.year())
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

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

                Divider().frame(height: 20).padding(.horizontal, 4)

                HStack(spacing: 0) {
                    Button {
                        slideDirection = .trailing
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedDate = Date()
                        }
                    } label: {
                        Text("Bugün")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8).frame(height: 28)
                    }
                    .buttonStyle(.plain)

                    Button {
                        slideDirection = .leading
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                        }
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    // MARK: - Calendar grid (animasyonlu)

    private var calendarGrid: some View {
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
                        isCurrentMonth: isCurrentMonth(day),
                        onTaskDropped: onTaskDropped,
                        onFocusDay: onFocusDay
                    )
                    .frame(height: rowHeight)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25)) {
                            selectedDate = day
                        }
                    }
                }
            }
            .id(selectedDate.formatted(.dateTime.month().year())) // ay değişince grid yenilenir
            .transition(.asymmetric(
                insertion: .move(edge: slideDirection).combined(with: .opacity),
                removal: .move(edge: slideDirection == .leading ? .trailing : .leading).combined(with: .opacity)
            ))
        }
    }

    private func tasksFor(_ date: Date) -> [TaskItem] {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }
}
