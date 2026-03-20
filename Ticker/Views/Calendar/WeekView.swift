import SwiftUI
import SwiftData

struct WeekView: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]

    @State private var slideDirection: Edge = .trailing

    private var weekDays: [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: selectedDate)
        // Haftayı Pazartesi'den başlat
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private let dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                weekHeader
                Divider().opacity(0.3)
                weekDayColumns
            }
            .frame(minWidth: 500)

            AgendaView(date: selectedDate, tasks: tasks)
                .frame(minWidth: 220, maxWidth: 280)
        }
    }

    // MARK: - Week header

    private var weekHeader: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekRangeLabel)
                    .font(.system(size: 18, weight: .bold))
                Text(selectedDate, format: .dateTime.year())
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    slideDirection = .trailing
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 12)).frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.3)) { selectedDate = Date() }
                } label: {
                    Text("Bu hafta").font(.system(size: 12, weight: .medium)).padding(.horizontal, 8).frame(height: 28)
                }
                .buttonStyle(.plain)

                Button {
                    slideDirection = .leading
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 12)).frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let f = first.formatted(.dateTime.day().month(.abbreviated))
        let l = last.formatted(.dateTime.day().month(.abbreviated))
        return "\(f) – \(l)"
    }

    // MARK: - Week day columns

    private var weekDayColumns: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.element) { index, day in
                VStack(spacing: 0) {
                    // Gün başlığı
                    VStack(spacing: 3) {
                        Text(dayLabels[index])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ZStack {
                            if Calendar.current.isDateInToday(day) {
                                Circle().fill(Color.blue).frame(width: 28, height: 28)
                            } else if Calendar.current.isDate(day, inSameDayAs: selectedDate) {
                                Circle().fill(Color.blue.opacity(0.15)).frame(width: 28, height: 28)
                            }
                            Text(day, format: .dateTime.day())
                                .font(.system(size: 14, weight: Calendar.current.isDateInToday(day) ? .bold : .regular))
                                .foregroundStyle(
                                    Calendar.current.isDateInToday(day) ? .white :
                                    Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .blue : .primary
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Calendar.current.isDateInToday(day) ? Color.blue.opacity(0.04) : Color.clear)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25)) { selectedDate = day }
                    }

                    Divider().opacity(0.3)

                    // Görevler
                    ScrollView {
                        VStack(spacing: 4) {
                            let dayTasks = tasksFor(day)
                            if dayTasks.isEmpty {
                                Spacer().frame(height: 20)
                            } else {
                                ForEach(dayTasks) { task in
                                    WeekTaskChip(task: task)
                                }
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: .infinity)
                    .background(
                        Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        ? Color.blue.opacity(0.03) : Color.clear
                    )
                }
                .frame(maxWidth: .infinity)

                if index < weekDays.count - 1 {
                    Divider()
                }
            }
        }
        .id(weekDays.first?.formatted(.dateTime.year().month().day()))
        .transition(.asymmetric(
            insertion: .move(edge: slideDirection).combined(with: .opacity),
            removal: .move(edge: slideDirection == .leading ? .trailing : .leading).combined(with: .opacity)
        ))
    }

    private func tasksFor(_ date: Date) -> [TaskItem] {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }
}

// MARK: - Haftalık görev chip'i

struct WeekTaskChip: View {
    @Bindable var task: TaskItem
    @State private var showingEdit = false

    var body: some View {
        HStack(spacing: 5) {
            Button {
                withAnimation(.spring(response: 0.25)) { task.isCompleted.toggle() }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(task.isCompleted ? Color(hex: task.hexColor) : Color.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .lineLimit(2)
        }
        .padding(.horizontal, 7).padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: task.hexColor).opacity(task.isCompleted ? 0.05 : 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: task.hexColor).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
}
