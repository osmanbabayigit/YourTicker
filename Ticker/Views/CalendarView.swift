import SwiftUI
import SwiftData

struct CalendarView: View {

    @Query private var tasks: [TaskItem]
    @EnvironmentObject var appState: AppState

    @State private var selectedDate = Date()

    var body: some View {
        HStack {

            // 🔥 SOL → AY GRID
            MonthGridView(selectedDate: $selectedDate, tasks: tasks)
                .frame(width: 420)

            Divider()

            // 🔥 SAĞ → AGENDA
            AgendaView(date: selectedDate, tasks: tasks)
        }
    }
}
//
