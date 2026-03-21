import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @Query(animation: .default) private var tasks: [TaskItem]

    let showCompleted: Bool
    let title: String
    var filterTag: TagItem?

    @State private var showingFullAdd = false
    @State private var quickText = ""
    @FocusState private var quickFieldFocused: Bool
    @FocusState private var searchFocused: Bool

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
            topBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            quickAddBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            if filtered.isEmpty { emptyState } else { taskList }
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingFullAdd) { AddTaskView(selectedDate: Date()) }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)

            if !filtered.isEmpty {
                Text("\(filtered.count)")
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(TickerTheme.bgPill).clipShape(Capsule())
            }

            if !showCompleted {
                if todayCount   > 0 { statChip("\(todayCount) bugün",      color: TickerTheme.orange) }
                if overdueCount > 0 { statChip("\(overdueCount) gecikmiş", color: TickerTheme.red)   }
            } else {
                statChip("\(tasks.filter { $0.isCompleted }.count) tamamlandı", color: TickerTheme.green)
            }

            Spacer()
            searchField

            Button { showingFullAdd = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
                    Text("Ekle").font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(TickerTheme.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func statChip(_ label: String, color: Color) -> some View {
        Text(label).font(.system(size: 10, weight: .medium)).foregroundStyle(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 10))
                .foregroundStyle(searchFocused ? TickerTheme.blue : TickerTheme.textTertiary)
            TextField("Ara...", text: $appState.searchText)
                .textFieldStyle(.plain).font(.system(size: 12))
                .foregroundStyle(TickerTheme.textPrimary).focused($searchFocused)
                .frame(width: searchFocused || !appState.searchText.isEmpty ? 120 : 60)
                .animation(.spring(response: 0.25), value: searchFocused)
            if !appState.searchText.isEmpty {
                Button { withAnimation { appState.searchText = "" } } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 10))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain).transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(TickerTheme.bgPill)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7)
            .stroke(searchFocused ? TickerTheme.borderFocus : TickerTheme.borderSub, lineWidth: 1))
        .animation(.spring(response: 0.2), value: appState.searchText.isEmpty)
    }

    private var quickAddBar: some View {
        HStack(spacing: 8) {
            Circle().fill(TickerTheme.textTertiary.opacity(0.4))
                .frame(width: 6, height: 6).padding(.leading, 16)
            TextField(showCompleted ? "Tamamlanan ekle..." : "Görev ekle...", text: $quickText)
                .textFieldStyle(.plain).font(.system(size: 13))
                .foregroundStyle(TickerTheme.textPrimary)
                .focused($quickFieldFocused).onSubmit { quickAdd() }
            Button { showingFullAdd = true } label: {
                Image(systemName: "slider.horizontal.3").font(.system(size: 10))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .frame(width: 26, height: 26).background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain).help("Detaylı görev ekle")
            Button(action: quickAdd) {
                Text("↵").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(quickText.isEmpty ? TickerTheme.textTertiary : TickerTheme.blue)
                    .frame(width: 26, height: 26)
                    .background(quickText.isEmpty ? Color.clear : TickerTheme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(quickText.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.trailing, 12)
        }
        .padding(.vertical, 7)
        .background(TickerTheme.bgInput)
    }

    private var taskList: some View {
        List {
            ForEach(filtered) { task in
                TaskRow(task: task)
                    .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    .contextMenu {
                        Button {
                            withAnimation { task.isCompleted.toggle() }
                            try? context.save()
                        } label: {
                            Label(task.isCompleted ? "Tamamlanmadı" : "Tamamlandı",
                                  systemImage: task.isCompleted ? "circle" : "checkmark.circle")
                        }
                        Divider()
                        Button(role: .destructive) {
                            context.delete(task); try? context.save()
                        } label: { Label("Sil", systemImage: "trash") }
                    }
            }
            .onMove { from, to in moveTask(from: from, to: to) }
            Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .listStyle(.plain).scrollContentBackground(.hidden).background(TickerTheme.bgApp)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: showCompleted ? "checkmark.seal" : "tray")
                .font(.system(size: 28, weight: .ultraLight)).foregroundStyle(TickerTheme.textTertiary)
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

    private func quickAdd() {
        let trimmed = quickText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = (tasks.filter { $0.isCompleted == showCompleted }.map { $0.sortOrder }.max() ?? -1) + 1
        let newTask = TaskItem(title: trimmed, isCompleted: showCompleted, dueDate: nil,
                               hexColor: TaskColor.blue.rawValue, priority: 0, sortOrder: maxOrder)
        if let tag = filterTag { newTask.tags = [tag] }
        context.insert(newTask); try? context.save()
        quickText = ""; quickFieldFocused = true
    }

    private func moveTask(from source: IndexSet, to destination: Int) {
        var reordered = filtered
        reordered.move(fromOffsets: source, toOffset: destination)
        for (i, task) in reordered.enumerated() { task.sortOrder = i }
        try? context.save()
    }
}
