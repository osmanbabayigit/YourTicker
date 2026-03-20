import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem = .pending
    @EnvironmentObject var appState: AppState
    @Query(sort: \TagItem.name) private var tags: [TagItem]
    @Query private var tasks: [TaskItem]

    private var pendingCount:  Int { tasks.filter { !$0.isCompleted }.count }
    private var completedCount: Int { tasks.filter { $0.isCompleted }.count }
    private var overdueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 < today } ?? false) }.count
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 980, minHeight: 660)
        // Tüm arka planı koyu yap
        .background(TickerTheme.bgApp)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            Divider().background(TickerTheme.borderSub)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Ana navigasyon
                    sidebarGroup {
                        navRow(item: .pending,
                               count: pendingCount > 0 ? "\(pendingCount)" : nil,
                               badge: overdueCount > 0 ? "\(overdueCount)" : nil)
                        navRow(item: .calendar)
                        navRow(item: .completed,
                               count: completedCount > 0 ? "\(completedCount)" : nil)
                    }

                    sidebarDivider

                    // Modüller
                    sidebarGroup(label: "MODÜLLER") {
                        navRow(item: .budget)
                        navRow(item: .books)
                    }

                    // Etiketler
                    if !tags.isEmpty {
                        sidebarDivider
                        sidebarGroup(label: "ETİKETLER") {
                            ForEach(tags) { tag in
                                tagNavRow(tag)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Spacer(minLength: 0)
            sidebarFooter
        }
        .frame(minWidth: 210)
        .background(TickerTheme.bgSidebar)
    }

    // MARK: - Sidebar header

    private var sidebarHeader: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(TickerTheme.blue)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Text("Ticker")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Nav row

    @ViewBuilder
    private func navRow(item: SidebarItem,
                        count: String? = nil,
                        badge: String? = nil) -> some View {
        let isSelected = selection == item
        HStack(spacing: 9) {
            sidebarIcon(item.icon, selected: isSelected)

            Text(item.label)
                .font(.system(size: 12.5))
                .foregroundStyle(isSelected ? TickerTheme.textPrimary : TickerTheme.textSecondary)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1.5)
                    .background(Color(hex: "#E24B4A"))
                    .clipShape(Capsule())
            } else if let count {
                Text(count)
                    .font(.system(size: 11))
                    .foregroundStyle(TickerTheme.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected
                      ? Color.white.opacity(0.07)
                      : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { selection = item }
        .tag(item)
        .padding(.horizontal, 6)
    }

    // MARK: - Tag nav row

    @ViewBuilder
    private func tagNavRow(_ tag: TagItem) -> some View {
        let isSelected = selection == SidebarItem.tag(tag)
        let count = tag.tasks.filter { !$0.isCompleted }.count

        HStack(spacing: 9) {
            Circle()
                .fill(Color(hex: tag.hexColor))
                .frame(width: 7, height: 7)
                .padding(.leading, 4)

            Text(tag.name)
                .font(.system(size: 12.5))
                .foregroundStyle(isSelected ? TickerTheme.textPrimary : TickerTheme.textSecondary)

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundStyle(TickerTheme.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.white.opacity(0.07) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { selection = .tag(tag) }
        .padding(.horizontal, 6)
    }

    // MARK: - Sidebar icon

    @ViewBuilder
    private func sidebarIcon(_ name: String, selected: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(selected ? TickerTheme.textPrimary : TickerTheme.textTertiary)
            .frame(width: 16, height: 16)
    }

    // MARK: - Sidebar group

    @ViewBuilder
    private func sidebarGroup<Content: View>(label: String? = nil,
                                              @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .kerning(0.5)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
            }
            content()
        }
    }

    private var sidebarDivider: some View {
        Rectangle()
            .fill(TickerTheme.borderSub)
            .frame(height: 1)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
    }

    // MARK: - Footer

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(TickerTheme.borderSub)
                .frame(height: 1)

            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(TickerTheme.blue.opacity(0.2))
                        .frame(width: 26, height: 26)
                    Text("OB")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(TickerTheme.blue)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Osman Babayiğit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(TickerTheme.textSecondary)
                    Text("\(pendingCount) görev bekliyor")
                        .font(.system(size: 10))
                        .foregroundStyle(TickerTheme.textTertiary)
                }

                Spacer()

                Button { } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Detail

    private var detailView: some View {
        VStack(spacing: 0) {
            if selection != .calendar && selection != .budget && selection != .books {
                GlobalSearchBar()
                Rectangle()
                    .fill(TickerTheme.borderSub)
                    .frame(height: 1)
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
        .background(TickerTheme.bgApp)
    }
}
