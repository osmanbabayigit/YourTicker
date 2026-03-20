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
            // Mod seçici
            HStack {
                Spacer()
                HStack(spacing: 2) {
                    ForEach(CalendarMode.allCases, id: \.self) { m in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                mode = m
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: m.icon).font(.system(size: 11))
                                Text(m.rawValue).font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(mode == m ? Color.blue : Color.clear)
                            .foregroundStyle(mode == m ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .padding(.trailing, 16)
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
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                } else {
                    WeekView(selectedDate: $selectedDate, tasks: tasks)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .sheet(isPresented: $showingFocusDay) {
            FocusDayView(date: selectedDate, tasks: tasks)
        }
    }
}
