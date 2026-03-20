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
    @State private var quickDate = Date()
    @State private var showDatePicker = false
    @State private var selectedColor: TaskColor = .blue
    @State private var priority: Int = 0
    @FocusState private var fieldFocused: Bool

    private var filtered: [TaskItem] {
        tasks
            .filter { task in
                guard task.isCompleted == showCompleted else { return false }
                if let tag = filterTag {
                    guard task.tags.contains(where: { $0.id == tag.id }) else { return false }
                }
                if !appState.searchText.isEmpty {
                    guard task.title.localizedCaseInsensitiveContains(appState.searchText) else { return false }
                }
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
    private var highPriorityCount: Int { pendingTasks.filter { $0.priority == 2 }.count }

    var body: some View {
        VStack(spacing: 0) {
            quickAddBar
            Divider().opacity(0.3)
            statsBar
            Divider().opacity(0.2)

            if filtered.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .navigationTitle(title)
    }

    // MARK: - Quick add bar

    private var quickAddBar: some View {
        HStack(spacing: 10) {
            // Renk dot
            Menu {
                ForEach(TaskColor.allCases, id: \.self) { c in
                    Button { selectedColor = c } label: {
                        HStack {
                            Image(systemName: "circle.fill").foregroundStyle(c.color)
                            Text(c.label)
                        }
                    }
                }
            } label: {
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Görev alanı
            TextField("Yeni görev ekle...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($fieldFocused)
                .onSubmit { addTask() }

            Divider().frame(height: 16).opacity(0.4)

            // Tarih butonu
            Button {
                showDatePicker.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(Calendar.current.isDateInToday(quickDate) ? "Bugün" :
                            quickDate.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Calendar.current.isDateInToday(quickDate)
                            ? Color.blue.opacity(0.1)
                            : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(Calendar.current.isDateInToday(quickDate) ? .blue : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                VStack(spacing: 0) {
                    DatePicker("", selection: $quickDate, displayedComponents: .date)
                        .datePickerStyle(.graphical).labelsHidden().frame(width: 260)
                    Divider()
                    HStack(spacing: 12) {
                        Button("Bugün") { quickDate = Date(); showDatePicker = false }
                            .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.blue)
                        Button("Yarın") {
                            quickDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            showDatePicker = false
                        }
                        .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.secondary)
                        Spacer()
                        Button("Tamam") { showDatePicker = false }
                            .buttonStyle(.plain).font(.system(size: 12, weight: .medium)).foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
            }

            Divider().frame(height: 16).opacity(0.4)

            // Öncelik
            HStack(spacing: 2) {
                ForEach([0, 1, 2], id: \.self) { p in
                    Button { priority = p } label: {
                        Image(systemName: p == 0 ? "minus" : p == 1 ? "exclamationmark" : "exclamationmark.2")
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 22, height: 22)
                            .background(priority == p
                                        ? (p == 2 ? Color.red : p == 1 ? Color.orange : Color.blue).opacity(0.15)
                                        : Color.clear)
                            .foregroundStyle(priority == p
                                             ? (p == 2 ? Color.red : p == 1 ? Color.orange : Color.blue)
                                             : Color.secondary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().frame(height: 16).opacity(0.4)

            Button(action: addTask) {
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(text.isEmpty ? Color.secondary : Color.blue)
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
    }

    // MARK: - Stats bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            if !showCompleted {
                statItem(value: pendingTasks.count, label: "Bekleyen", color: .blue)
                statDivider
                statItem(value: todayCount, label: "Bugün", color: .orange)
                if overdueCount > 0 {
                    statDivider
                    statItem(value: overdueCount, label: "Gecikmiş", color: .red)
                }
                if highPriorityCount > 0 {
                    statDivider
                    statItem(value: highPriorityCount, label: "Yüksek", color: .red)
                }
            } else {
                statItem(value: tasks.filter { $0.isCompleted }.count, label: "Tamamlandı", color: .green)
            }
            Spacer()

            if !appState.searchText.isEmpty {
                Text("\(filtered.count) sonuç")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private func statItem(value: Int, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(value > 0 ? color : .secondary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
    }

    private var statDivider: some View {
        Rectangle().fill(Color.secondary.opacity(0.15)).frame(width: 1, height: 14)
    }

    // MARK: - Task list

    private var taskList: some View {
        List {
            ForEach(filtered) { task in
                TaskRow(task: task)
                    .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        Button {
                            withAnimation { task.isCompleted.toggle() }
                            try? context.save()
                        } label: {
                            Label(task.isCompleted ? "Tamamlanmadı işaretle" : "Tamamlandı işaretle",
                                  systemImage: task.isCompleted ? "circle" : "checkmark.circle")
                        }
                        Divider()
                        Button(role: .destructive) {
                            context.delete(task); try? context.save()
                        } label: { Label("Sil", systemImage: "trash") }
                    }
            }
            .onMove { indexSet, destination in moveTask(from: indexSet, to: destination) }

            // Alt boşluk
            Color.clear.frame(height: 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.06))
                    .frame(width: 80, height: 80)
                Image(systemName: showCompleted ? "checkmark.circle" : appState.searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text(emptyTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                Text(emptySubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if !showCompleted && appState.searchText.isEmpty {
                Button("Görev Ekle") { fieldFocused = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                    .font(.system(size: 12, weight: .medium))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    private var emptyTitle: String {
        if !appState.searchText.isEmpty { return "Sonuç bulunamadı" }
        return showCompleted ? "Henüz tamamlanan yok" : "Görev yok"
    }

    private var emptySubtitle: String {
        if !appState.searchText.isEmpty { return "\"\(appState.searchText)\" için sonuç yok" }
        if let tag = filterTag { return "\(tag.name) etiketli görev yok" }
        return showCompleted ? "Tamamlanan görevler burada görünecek" : "Yukarıdan yeni bir görev ekle"
    }

    // MARK: - Actions

    private func addTask() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let maxOrder = (tasks.filter { $0.isCompleted == showCompleted }.map { $0.sortOrder }.max() ?? -1) + 1
        let newTask = TaskItem(
            title: trimmed,
            isCompleted: showCompleted,
            dueDate: quickDate,
            hexColor: selectedColor.rawValue,
            priority: priority,
            sortOrder: maxOrder
        )
        if let tag = filterTag { newTask.tags = [tag] }
        context.insert(newTask)
        try? context.save()
        text = ""; priority = 0; fieldFocused = true
    }

    private func moveTask(from source: IndexSet, to destination: Int) {
        var reordered = filtered
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() { task.sortOrder = index }
        try? context.save()
    }
}
