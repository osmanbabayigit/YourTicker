import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem = .pending
    @EnvironmentObject var appState: AppState
    @Query(sort: \TagItem.name) private var tags: [TagItem]
    @Query private var tasks: [TaskItem]

    private var pendingCount: Int  { tasks.filter { !$0.isCompleted }.count }
    private var todayCount: Int {
        tasks.filter { !$0.isCompleted && ($0.dueDate.map { Calendar.current.isDateInToday($0) } ?? false) }.count
    }
    private var overdueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 < today } ?? false) }.count
    }
    private var completedCount: Int { tasks.filter { $0.isCompleted }.count }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 960, minHeight: 640)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // App header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Ticker")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().opacity(0.3)

            List(selection: $selection) {
                // Görevler
                Section {
                    sidebarRow(item: .pending, count: pendingCount > 0 ? pendingCount : nil,
                               badge: overdueCount > 0 ? "\(overdueCount)" : nil, badgeColor: .red)
                    sidebarRow(item: .calendar)
                    sidebarRow(item: .completed, count: completedCount > 0 ? completedCount : nil)
                }

                // Modüller
                Section("Modüller") {
                    sidebarRow(item: .budget)
                    sidebarRow(item: .books)
                }

                // Etiketler
                if !tags.isEmpty {
                    Section("Etiketler") {
                        ForEach(tags) { tag in
                            let count = tag.tasks.filter { !$0.isCompleted }.count
                            HStack(spacing: 9) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: tag.hexColor))
                                    .frame(width: 8, height: 8)
                                Text(tag.name)
                                    .font(.system(size: 13))
                                Spacer()
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(SidebarItem.tag(tag))
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Spacer()
            bottomBar
        }
        .frame(minWidth: 210)
        .background(GlassView(material: .sidebar))
    }

    @ViewBuilder
    private func sidebarRow(item: SidebarItem, count: Int? = nil, badge: String? = nil, badgeColor: Color = .blue) -> some View {
        HStack(spacing: 9) {
            Image(systemName: item.icon)
                .font(.system(size: 13))
                .frame(width: 18)
                .foregroundStyle(selection == item ? .blue : .secondary)
            Text(item.label)
                .font(.system(size: 13))
            Spacer()
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(badgeColor)
                    .clipShape(Capsule())
            } else if let count = count {
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .tag(item)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Hesabım")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("\(pendingCount) görev bekliyor")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    // Settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Detail view

    private var detailView: some View {
        VStack(spacing: 0) {
            if selection != .calendar && selection != .budget && selection != .books {
                GlobalSearchBar()
                Divider().opacity(0.3)
            }

            Group {
                switch selection {
                case .pending:
                    TaskListView(showCompleted: false, title: "Görevler", filterTag: nil)
                case .calendar:
                    CalendarView()
                case .completed:
                    TaskListView(showCompleted: true, title: "Tamamlananlar", filterTag: nil)
                case .budget:
                    BudgetView()
                case .books:
                    BookView()
                case .tag(let tag):
                    TaskListView(showCompleted: false, title: tag.name, filterTag: tag)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
