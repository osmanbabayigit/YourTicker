import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @Query(animation: .default) private var tasks: [TaskItem]

    let showCompleted: Bool
    let title: String
    var filterTag: TagItem?

    @State private var text = ""
    @State private var showingFullAdd = false
    @FocusState private var fieldFocused: Bool

    private var filtered: [TaskItem] {
        tasks
            .filter { task in
                guard task.isCompleted == showCompleted else { return false }
                if let tag = filterTag, !task.tags.contains(where: { $0.id == tag.id }) { return false }
                if !appState.searchText.isEmpty,
                   !task.title.localizedCaseInsensitiveContains(appState.searchText) { return false }
                return true
            }
            .sorted { a, b in
                if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
                if a.priority != b.priority { return a.priority > b.priority }
                guard let da = a.dueDate, let db = b.dueDate else { return a.dueDate != nil }
                return da < db
            }
    }

    private var pendingTasks: [TaskItem] { tasks.filter { !$0.isCompleted } }
    private var todayCount: Int {
        pendingTasks.filter { $0.dueDate.map { Calendar.current.isDateInToday($0) } ?? false }.count
    }
    private var overdueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return pendingTasks.filter { $0.dueDate.map { $0 < today } ?? false }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
            statsBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            quickAddBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if filtered.isEmpty { emptyState } else { taskList }
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingFullAdd) {
            AddTaskView(selectedDate: Date())
        }
    }

    // MARK: - Sayfa başlığı

    private var pageHeader: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)

            if !filtered.isEmpty {
                Text("\(filtered.count)")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(TickerTheme.bgPill).clipShape(Capsule())
            }

            if !appState.searchText.isEmpty {
                Text("· \"\(appState.searchText)\"")
                    .font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 16).padding(.bottom, 8)
    }

    // MARK: - Stats bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            if !showCompleted {
                statItem(value: pendingTasks.count, label: "Bekleyen",
                         color: TickerTheme.textSecondary)
                statSep
                statItem(value: todayCount, label: "Bugün",
                         color: todayCount > 0 ? TickerTheme.orange : TickerTheme.textTertiary)
                if overdueCount > 0 {
                    statSep
                    statItem(value: overdueCount, label: "Gecikmiş", color: TickerTheme.red)
                }
            } else {
                statItem(value: tasks.filter { $0.isCompleted }.count,
                         label: "Tamamlandı", color: TickerTheme.green)
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.vertical, 6)
    }

    @ViewBuilder
    private func statItem(value: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(value)").font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
            Text(label).font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
        }
        .padding(.horizontal, 4).padding(.vertical, 2)
    }

    private var statSep: some View {
        Rectangle().fill(TickerTheme.borderMid).frame(width: 1, height: 12).padding(.horizontal, 8)
    }

    // MARK: - Quick Add Bar
    // Sade: sadece text + enter. Detaylı eklemek için + butonu → AddTaskView sheet.

    private var quickAddBar: some View {
        HStack(spacing: 10) {
            // Tek tıkla hızlı renk seçeci (küçük dot)
            Circle()
                .fill(TickerTheme.textTertiary)
                .frame(width: 7, height: 7)
                .padding(.leading, 16)

            // Metin alanı
            TextField(showCompleted ? "Tamamlanan ekle..." : "Görev ekle...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(TickerTheme.textPrimary)
                .focused($fieldFocused)
                .onSubmit { quickAdd() }

            // Detaylı ekle butonu
            Button {
                showingFullAdd = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 10))
                }
                .foregroundStyle(TickerTheme.textTertiary)
                .frame(width: 28, height: 28)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Detaylı görev ekle (tarih, öncelik, etiket...)")

            // Enter butonu
            Button(action: quickAdd) {
                Text("↵")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(text.isEmpty ? TickerTheme.textTertiary : TickerTheme.blue)
                    .frame(width: 28, height: 28)
                    .background(text.isEmpty ? Color.clear : TickerTheme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
            .padding(.trailing, 12)
        }
        .padding(.vertical, 8)
        .background(TickerTheme.bgInput)
    }

    // MARK: - Görev listesi

    private var taskList: some View {
        List {
            ForEach(filtered) { task in
                TaskRow(task: task)
                    .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        Button {
                            withAnimation { task.isCompleted.toggle() }
                            try? context.save()
                        } label: {
                            Label(
                                task.isCompleted ? "Tamamlanmadı" : "Tamamlandı",
                                systemImage: task.isCompleted ? "circle" : "checkmark.circle"
                            )
                        }
                        Divider()
                        Button(role: .destructive) {
                            context.delete(task); try? context.save()
                        } label: { Label("Sil", systemImage: "trash") }
                    }
            }
            .onMove { from, to in moveTask(from: from, to: to) }

            Color.clear.frame(height: 80)
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(TickerTheme.bgApp)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: showCompleted ? "checkmark.seal" : "tray")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(TickerTheme.textTertiary)
            VStack(spacing: 4) {
                Text(showCompleted ? "Henüz tamamlanan yok" : "Görev yok")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(TickerTheme.textSecondary)
                Text(showCompleted ? "Tamamlanan görevler burada görünecek" : "Yukarıdan ekle veya ⌘+N")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity).background(TickerTheme.bgApp)
    }

    // MARK: - Actions

    private func quickAdd() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = (tasks.filter { $0.isCompleted == showCompleted }.map { $0.sortOrder }.max() ?? -1) + 1
        let newTask = TaskItem(
            title: trimmed, isCompleted: showCompleted,
            dueDate: Date(), hexColor: TaskColor.blue.rawValue,
            priority: 0, sortOrder: maxOrder
        )
        if let tag = filterTag { newTask.tags = [tag] }
        context.insert(newTask); try? context.save()
        text = ""; fieldFocused = true
    }

    private func moveTask(from source: IndexSet, to destination: Int) {
        var reordered = filtered
        reordered.move(fromOffsets: source, toOffset: destination)
        for (i, task) in reordered.enumerated() { task.sortOrder = i }
        try? context.save()
    }
}
