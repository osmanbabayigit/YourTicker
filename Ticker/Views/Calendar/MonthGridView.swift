import SwiftUI
import SwiftData

struct MonthGridView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    var onFocusDay: () -> Void = {}
    var onTaskDropped: (UUID, Date) -> Void

    @State private var showingAddTask = false
    @State private var slideDirection: Edge = .trailing

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    private var days: [Date] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: selectedDate)
        comps.weekday = nil
        let start = cal.date(from: comps)!
        let firstWeekday = (cal.component(.weekday, from: start) + 5) % 7
        let totalDays = cal.range(of: .day, in: .month, for: selectedDate)!.count

        var dates: [Date] = []
        for i in (0..<firstWeekday).reversed() {
            if let d = cal.date(byAdding: .day, value: -(i+1), to: start) { dates.append(d) }
        }
        for i in 0..<totalDays {
            if let d = cal.date(byAdding: .day, value: i, to: start) { dates.append(d) }
        }
        let rem = dates.count % 7
        if rem != 0, let last = dates.last {
            for i in 1...(7 - rem) {
                if let d = cal.date(byAdding: .day, value: i, to: last) { dates.append(d) }
            }
        }
        return dates
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                topBar
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                weekdayHeader
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                calendarGrid
            }
            .frame(minWidth: 480)
            .background(TickerTheme.bgApp)

            AgendaView(date: selectedDate, tasks: tasks)
                .frame(minWidth: 200, maxWidth: 260)
        }
        .sheet(isPresented: $showingAddTask) { AddTaskView(selectedDate: selectedDate) }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(selectedDate, format: .dateTime.month(.wide))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Text(selectedDate, format: .dateTime.year())
                    .font(.system(size: 11))
                    .foregroundStyle(TickerTheme.textTertiary)
            }

            Spacer()

            // Bugün butonu
            Button {
                withAnimation(.spring(response: 0.35)) { selectedDate = Date() }
            } label: {
                Text("Bugün").font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TickerTheme.textSecondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(TickerTheme.borderMid, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Nav okları
            HStack(spacing: 0) {
                Button {
                    slideDirection = .trailing
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 11, weight: .medium))
                        .frame(width: 28, height: 28).foregroundStyle(TickerTheme.textSecondary)
                }
                .buttonStyle(.plain)

                Rectangle().fill(TickerTheme.borderSub).frame(width: 1, height: 16)

                Button {
                    slideDirection = .leading
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium))
                        .frame(width: 28, height: 28).foregroundStyle(TickerTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .background(TickerTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(TickerTheme.borderMid, lineWidth: 1))

            // Görev ekle
            Button { showingAddTask = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 10))
                    Text("Ekle").font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(TickerTheme.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .background(TickerTheme.bgPill.opacity(0.5))
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        GeometryReader { geo in
            let rowCount = days.count / 7
            let rowH = geo.size.height / CGFloat(rowCount)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(days, id: \.self) { day in
                    DayCell(
                        date: day,
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                        isToday:    Calendar.current.isDateInToday(day),
                        tasks:      tasksFor(day),
                        isCurrentMonth: Calendar.current.isDate(day, equalTo: selectedDate, toGranularity: .month),
                        onTaskDropped: onTaskDropped,
                        onFocusDay: onFocusDay
                    )
                    .frame(height: rowH)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2)) { selectedDate = day }
                    }
                }
            }
            .id(selectedDate.formatted(.dateTime.month().year()))
            .transition(.asymmetric(
                insertion: .move(edge: slideDirection).combined(with: .opacity),
                removal: .move(edge: slideDirection == .leading ? .trailing : .leading).combined(with: .opacity)
            ))
        }
    }

    private func tasksFor(_ date: Date) -> [TaskItem] {
        tasks.filter { $0.dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false }
    }
}
