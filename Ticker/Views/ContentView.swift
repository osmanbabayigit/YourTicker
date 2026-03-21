import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem = .pending

    private var selectionIsTag: Bool {
        if case .tag = selection { return true }
        return false
    }
    @EnvironmentObject var appState: AppState
    @Query(sort: \TagItem.name) private var tags: [TagItem]
    @Query private var tasks: [TaskItem]

    private var pendingCount:   Int { tasks.filter { !$0.isCompleted }.count }
    private var completedCount: Int { tasks.filter { $0.isCompleted }.count }
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
            sidebar
            Rectangle().fill(TickerTheme.borderSub).frame(width: 1)
            detailView
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $appState.showingQuickCapture) {
            QuickCaptureView()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            appHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 2) {
                    // Ana
                    navRow(.pending, count: pendingCount > 0 ? "\(pendingCount)" : nil,
                           badge: overdueCount > 0 ? "\(overdueCount)" : nil)
                    navRow(.calendar)
                    navRow(.completed, count: completedCount > 0 ? "\(completedCount)" : nil)

                    // Modüller
                    sectionHeader("MODÜLLER").padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 2)
                    navRow(.budget)
                    navRow(.books)
                    navRow(.pomodoro)
                    navRow(.goals)
                    navRow(.habits)
                    navRow(.stats)
                    navRow(.notes)

                    // Etiketler
                    if !tags.isEmpty {
                        sectionHeader("ETİKETLER").padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 2)
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
        .background(TickerTheme.bgSidebar)
    }

    // MARK: - App Header

    private var appHeader: some View {
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
        .padding(.bottom, 11)
        .background(TickerTheme.bgSidebar)
    }

    // MARK: - Nav row

    @ViewBuilder
    private func navRow(_ item: SidebarItem,
                        count: String? = nil,
                        badge: String? = nil) -> some View {
        Button { selection = item } label: {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundStyle(selection == item ? TickerTheme.blue : TickerTheme.textTertiary)

                Text(item.label)
                    .font(.system(size: 13))
                    .foregroundStyle(selection == item ? TickerTheme.textPrimary : TickerTheme.textSecondary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1.5)
                        .background(TickerTheme.red)
                        .clipShape(Capsule())
                } else if let count {
                    Text(count)
                        .font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(selection == item ? Color.white.opacity(0.07) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tag row

    @ViewBuilder
    private func tagRow(_ tag: TagItem) -> some View {
        Button { selection = .tag(tag) } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: tag.hexColor))
                    .frame(width: 7, height: 7)
                    .padding(.leading, 3)
                Text(tag.name)
                    .font(.system(size: 13))
                    .foregroundStyle(selection == SidebarItem.tag(tag)
                                     ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                Spacer()
                let count = tag.tasks.filter { !$0.isCompleted }.count
                if count > 0 {
                    Text("\(count)").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(selection == SidebarItem.tag(tag) ? Color.white.opacity(0.07) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(TickerTheme.textTertiary)
            .kerning(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(TickerTheme.borderSub)
                .frame(height: 1)

            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(TickerTheme.blue.opacity(0.15))
                        .frame(width: 24, height: 24)
                    Text("OB")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(TickerTheme.blue)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Osman Babayiğit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(TickerTheme.textSecondary)
                    Text(todayCount > 0 ? "\(todayCount) görev bugün" : "Temiz gün 🎉")
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
            .background(TickerTheme.bgSidebar)
        }
    }

    // MARK: - Detail

    private var detailView: some View {
        VStack(spacing: 0) {
            // Arama çubuğu sadece görev ekranlarında
            if selection == .pending || selection == .completed || selectionIsTag {
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
                case .pomodoro:
                    PomodoroView()
                case .goals:
                    GoalView()
                case .habits:
                    HabitView()
                case .stats:
                    StatsView()
                case .notes:
                    NoteView()
                case .tag(let tag):
                    TaskListView(showCompleted: false, title: tag.name, filterTag: tag)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(TickerTheme.bgApp)
    }
}
