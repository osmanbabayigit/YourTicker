import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem = .calendar
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // App header
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Ticker")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

                Divider().opacity(0.4)

                List(SidebarItem.allCases, selection: $selection) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                        .font(.system(size: 13, weight: .medium))
                }
                .listStyle(.sidebar)

                Spacer()

                // Bottom bar
                VStack(spacing: 0) {
                    Divider().opacity(0.4)
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Hesap")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            // settings
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
            .frame(minWidth: 200)
            .background(GlassView(material: .sidebar))

        } detail: {
            VStack(spacing: 0) {
                if selection != .calendar {
                    GlobalSearchBar()
                    Divider().opacity(0.4)
                }

                Group {
                    switch selection {
                    case .pending:
                        TaskListView(showCompleted: false, title: "Görevler")
                    case .calendar:
                        CalendarView()
                    case .completed:
                        TaskListView(showCompleted: true, title: "Tamamlananlar")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 960, minHeight: 640)
    }
}
