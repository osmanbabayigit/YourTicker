import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem = .pending
    @EnvironmentObject var appState: AppState
    @Query(sort: \TagItem.name) private var tags: [TagItem]
    @Query private var tasks: [TaskItem]

    // Computed properties — performanslı, sadece tasks değişince yeniden hesaplanır
    private var pendingCount:   Int { tasks.filter { !$0.isCompleted }.count }
    private var completedCount: Int { tasks.filter {  $0.isCompleted }.count }
    private var overdueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { !$0.isCompleted && ($0.dueDate.map { $0 < today } ?? false) }.count
    }
    private var todayCount: Int {
        tasks.filter {
            !$0.isCompleted && ($0.dueDate.map { Calendar.current.isDateInToday($0) } ?? false)
        }.count
    }

    var body: some View {
        HStack(spacing: 0) {
            if appState.sidebarVisible {
                sidebar
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                collapsedStrip
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            Rectangle().fill(TickerTheme.borderSub).frame(width: 1)
            detailView
        }
        .frame(minWidth: 700, minHeight: 600)
        // FIX: ignoresSafeArea sadece renk bloğuna, HStack'e değil
        // FIX: hidden Button pattern kaldırıldı → AppState.init() içinde NSEvent ile yapılıyor
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: appState.sidebarVisible)
        .sheet(isPresented: $appState.showingQuickCapture) { QuickCaptureView() }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            appHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            ScrollView {
                VStack(spacing: 2) {
                    navRow(.pending,
                           count: pendingCount   > 0 ? "\(pendingCount)"   : nil,
                           badge: overdueCount   > 0 ? "\(overdueCount)"   : nil)
                    navRow(.calendar)
                    navRow(.completed, count: completedCount > 0 ? "\(completedCount)" : nil)

                    sectionHeader("MODÜLLER")
                        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 2)
                    navRow(.budget);  navRow(.books);   navRow(.pomodoro)
                    navRow(.goals);   navRow(.habits);  navRow(.stats); navRow(.notes)

                    if !tags.isEmpty {
                        sectionHeader("ETİKETLER")
                            .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 2)
                        ForEach(tags) { tag in tagRow(tag) }
                    }
                }
                .padding(.vertical, 8).padding(.horizontal, 6)
            }
            .scrollContentBackground(.hidden)
            .background(TickerTheme.bgSidebar)
            Spacer(minLength: 0)
            sidebarFooter
        }
        .frame(width: 200)
        // ignoresSafeArea sadece bu view'ın background'una — döngü yok
        .background(TickerTheme.bgSidebar.ignoresSafeArea(edges: .top))
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 76)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(TickerTheme.blue)
                    .frame(width: 18, height: 18)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Text("Ticker")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)
                .padding(.leading, 7)
                .lineLimit(1)
            Spacer()
            sidebarToggleButton(chevron: "chevron.left")
                .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(TickerTheme.bgSidebar)
    }

    // MARK: - Daraltılmış şerit

    private var collapsedStrip: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 36)
            sidebarToggleButton(chevron: "chevron.right")
            Image(systemName: selection.icon)
                .font(.system(size: 13))
                .foregroundStyle(TickerTheme.blue)
                .frame(width: 28, height: 28)
                .background(TickerTheme.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Spacer()
            VStack(spacing: 4) {
                miniNavButton(.pending, badge: overdueCount > 0 ? "\(overdueCount)" : nil)
                miniNavButton(.calendar)
                miniNavButton(.pomodoro)
                miniNavButton(.notes)
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 6)
        .frame(width: 44)
        .background(TickerTheme.bgSidebar.ignoresSafeArea(edges: .top))
    }

    // MARK: - Detail view

    private var detailView: some View {
        Group {
            switch selection {
            case .pending:      TaskListView(showCompleted: false, title: "Görevler",      filterTag: nil)
            case .calendar:     CalendarView()
            case .completed:    TaskListView(showCompleted: true,  title: "Tamamlananlar", filterTag: nil)
            case .budget:       BudgetView()
            case .books:        BookView()
            case .pomodoro:     PomodoroView()
            case .goals:        GoalView()
            case .habits:       HabitView()
            case .stats:        StatsView()
            case .notes:        NoteView()
            case .tag(let tag): TaskListView(showCompleted: false, title: tag.name, filterTag: tag)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TickerTheme.bgApp.ignoresSafeArea(edges: .top))
    }

    // MARK: - Yardımcılar

    @ViewBuilder
    private func miniNavButton(_ item: SidebarItem, badge: String? = nil) -> some View {
        Button { selection = item } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(selection == item ? TickerTheme.blue : TickerTheme.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(selection == item ? TickerTheme.blue.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                if let badge {
                    Text(badge)
                        .font(.system(size: 7, weight: .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 3).padding(.vertical, 1)
                        .background(TickerTheme.red).clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain).help(item.label)
    }

    @ViewBuilder
    private func sidebarToggleButton(chevron: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                appState.sidebarVisible.toggle()
            }
        } label: {
            Image(systemName: chevron)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(TickerTheme.textTertiary)
                .frame(width: 24, height: 24)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(TickerTheme.borderSub, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("Kenar çubuğunu gizle/göster (⌘⇧S)")
    }

    @ViewBuilder
    private func navRow(_ item: SidebarItem, count: String? = nil, badge: String? = nil) -> some View {
        Button { selection = item } label: {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 12)).frame(width: 16)
                    .foregroundStyle(selection == item ? TickerTheme.blue : TickerTheme.textTertiary)
                Text(item.label).font(.system(size: 13))
                    .foregroundStyle(selection == item ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                Spacer()
                if let badge {
                    Text(badge).font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1.5)
                        .background(TickerTheme.red).clipShape(Capsule())
                } else if let count {
                    Text(count).font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity).contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(selection == item ? Color.white.opacity(0.07) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tagRow(_ tag: TagItem) -> some View {
        Button { selection = .tag(tag) } label: {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: tag.hexColor)).frame(width: 7, height: 7).padding(.leading, 3)
                Text(tag.name).font(.system(size: 13))
                    .foregroundStyle(selection == SidebarItem.tag(tag)
                                     ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                Spacer()
                let c = tag.tasks.filter { !$0.isCompleted }.count
                if c > 0 { Text("\(c)").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary) }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity).contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(selection == SidebarItem.tag(tag) ? Color.white.opacity(0.07) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold)).foregroundStyle(TickerTheme.textTertiary)
            .kerning(0.5).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(TickerTheme.blue.opacity(0.15)).frame(width: 28, height: 28)
                    Text("OB").font(.system(size: 9, weight: .semibold)).foregroundStyle(TickerTheme.blue)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Osman Babayiğit")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(TickerTheme.textSecondary)
                    Text(todayCount > 0 ? "\(todayCount) görev bugün" : "Temiz gün 🎉")
                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                }
                Spacer()
                Button { } label: {
                    Image(systemName: "gearshape").font(.system(size: 12))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(TickerTheme.bgSidebar)
        }
    }
}
