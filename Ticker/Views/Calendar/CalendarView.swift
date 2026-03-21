import SwiftUI
import SwiftData

enum CalendarMode: String, CaseIterable {
    case month = "Ay"
    case week  = "Hafta"

    var icon: String {
        switch self {
        case .month: return "calendar"
        case .week:  return "calendar.day.timeline.left"
        }
    }
}

struct CalendarView: View {
    @Query private var tasks: [TaskItem]
    @State private var selectedDate = Date()
    @State private var mode: CalendarMode = .month
    @State private var showingFocusDay = false

    var body: some View {
        VStack(spacing: 0) {
            // Mod toggle — sağ üst
            HStack {
                Spacer()
                HStack(spacing: 1) {
                    ForEach(CalendarMode.allCases, id: \.self) { m in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                mode = m
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: m.icon).font(.system(size: 10))
                                Text(m.rawValue).font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(mode == m ? TickerTheme.blue : Color.clear)
                            .foregroundStyle(mode == m ? .white : TickerTheme.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .padding(.trailing, 14)
                .padding(.top, 10)
            }

            Group {
                if mode == .month {
                    MonthGridView(
                        selectedDate: $selectedDate,
                        tasks: tasks,
                        onFocusDay: { showingFocusDay = true }
                    ) { taskId, newDate in
                        if let task = tasks.first(where: { $0.id == taskId }) {
                            task.dueDate = newDate
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
                } else {
                    WeekView(selectedDate: $selectedDate, tasks: tasks)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingFocusDay) {
            FocusDayView(date: selectedDate, tasks: tasks)
        }
    }
}
