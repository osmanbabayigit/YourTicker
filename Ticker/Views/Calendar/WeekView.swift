import SwiftUI
import SwiftData

struct WeekView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]

    @State private var slideDirection: Edge = .trailing

    private let dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    private var weekDays: [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: selectedDate)
        let offset = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -offset, to: selectedDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                weekTopBar
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                weekColumns
            }
            .frame(minWidth: 480)
            .background(TickerTheme.bgApp)

            AgendaView(date: selectedDate, tasks: tasks)
                .frame(minWidth: 200, maxWidth: 260)
        }
    }

    // MARK: - Top bar

    private var weekTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(weekRangeLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Text(selectedDate, format: .dateTime.year())
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { selectedDate = Date() }
            } label: {
                Text("Bu hafta").font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TickerTheme.textSecondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(TickerTheme.borderMid, lineWidth: 1))
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                Button {
                    slideDirection = .trailing
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
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
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
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
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    private var weekRangeLabel: String {
        guard let f = weekDays.first, let l = weekDays.last else { return "" }
        return "\(f.formatted(.dateTime.day().month(.abbreviated))) – \(l.formatted(.dateTime.day().month(.abbreviated)))"
    }

    // MARK: - Week columns

    private var weekColumns: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.element) { idx, day in
                VStack(spacing: 0) {
                    // Gün başlığı
                    dayHeader(day: day, label: dayLabels[idx])
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Görevler
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(tasksFor(day)) { task in
                                WeekTaskChip(task: task)
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: .infinity)
                    .background(
                        Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        ? TickerTheme.blue.opacity(0.02) : Color.clear
                    )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.spring(response: 0.2)) { selectedDate = day } }

                if idx < weekDays.count - 1 {
                    Rectangle().fill(TickerTheme.borderSub).frame(width: 1)
                }
            }
        }
        .id(weekDays.first?.formatted(.dateTime.year().month().day()))
        .transition(.asymmetric(
            insertion: .move(edge: slideDirection).combined(with: .opacity),
            removal: .move(edge: slideDirection == .leading ? .trailing : .leading).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func dayHeader(day: Date, label: String) -> some View {
        let isToday    = Calendar.current.isDateInToday(day)
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)

        VStack(spacing: 3) {
            Text(label).font(.system(size: 9, weight: .semibold))
                .foregroundStyle(TickerTheme.textTertiary)
            ZStack {
                if isToday {
                    Circle().fill(TickerTheme.blue).frame(width: 26, height: 26)
                } else if isSelected {
                    Circle().fill(TickerTheme.blue.opacity(0.12)).frame(width: 26, height: 26)
                }
                Text(day, format: .dateTime.day())
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : isSelected ? TickerTheme.blue : TickerTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(isToday ? TickerTheme.blue.opacity(0.04) : Color.clear)
    }

    private func tasksFor(_ date: Date) -> [TaskItem] {
        tasks.filter { $0.dueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false }
    }
}

// MARK: - Haftalık görev chip

struct WeekTaskChip: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false

    var body: some View {
        HStack(spacing: 5) {
            Button {
                withAnimation(.spring(response: 0.25)) { task.isCompleted.toggle() }
                try? context.save()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                    .foregroundStyle(task.isCompleted ? Color(hex: task.hexColor) : TickerTheme.borderMid)
                    .contentTransition(.symbolEffect(.replace.downUp))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(task.isCompleted ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                .strikethrough(task.isCompleted, color: TickerTheme.textTertiary)
                .lineLimit(2)
        }
        .padding(.horizontal, 6).padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: task.hexColor).opacity(task.isCompleted ? 0.04 : 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5)
            .stroke(Color(hex: task.hexColor).opacity(0.2), lineWidth: 1))
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
}
