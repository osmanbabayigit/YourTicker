import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case pending = "Görevler"
    case calendar = "Takvim"
    case completed = "Tamamlananlar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pending: return "checklist"
        case .calendar: return "calendar"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

struct ContentView: View {

    @State private var selection: SidebarItem = .pending

    var body: some View {
        NavigationSplitView {

            List(SidebarItem.allCases, selection: $selection) { item in
                HStack {
                    Image(systemName: item.icon)
                    Text(item.rawValue)
                }
                .tag(item) // 🔥 KRİTİK
            }
            .listStyle(.sidebar)
            .frame(minWidth: 220)

        } detail: {

            VStack(spacing: 0) {

                GlobalSearchBar()

                Divider()

                ZStack {
                    Color.black.opacity(0.03).ignoresSafeArea()

                    switch selection {
                    case .pending:
                        TaskListView(showCompleted: false, title: "Görevler")

                    case .calendar:
                        CalendarView()

                    case .completed:
                        TaskListView(showCompleted: true, title: "Tamamlananlar")
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
//
