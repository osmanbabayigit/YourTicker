import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @Query(animation: .default) private var tasks: [TaskItem]

    let showCompleted: Bool
    let title: String

    @State private var text = ""
    @State private var selectedDate = Date()
    @State private var selectedColor: TaskColor = .blue
    @State private var priority: Int = 0
    @FocusState private var fieldFocused: Bool

    var filtered: [TaskItem] {
        tasks
            .filter { task in
                task.isCompleted == showCompleted &&
                (appState.searchText.isEmpty || task.title.localizedCaseInsensitiveContains(appState.searchText))
            }
            .sorted { a, b in
                if a.priority != b.priority { return a.priority > b.priority }
                guard let da = a.dueDate, let db = b.dueDate else { return a.dueDate != nil }
                return da < db
            }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Quick add bar
            HStack(spacing: 10) {
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 10, height: 10)

                TextField("Görev ekle...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($fieldFocused)
                    .onSubmit { addTask() }

                Divider().frame(height: 18).opacity(0.4)

                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .scaleEffect(0.85)
                    .fixedSize()

                Divider().frame(height: 18).opacity(0.4)

                Picker("", selection: $priority) {
                    Text("•").tag(0)
                    Text("!!").tag(1)
                    Text("!!!").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 90)

                Menu {
                    ForEach(TaskColor.allCases, id: \.self) { c in
                        Button {
                            selectedColor = c
                        } label: {
                            HStack {
                                Image(systemName: "circle.fill").foregroundStyle(c.color)
                                Text(c.label)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Circle().fill(selectedColor.color).frame(width: 10, height: 10)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: addTask) {
                    Text("Ekle")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedColor.color)
                .controlSize(.small)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider().opacity(0.4)

            // Stats bar
            HStack(spacing: 12) {
                statBadge("Toplam", value: tasks.filter { !$0.isCompleted }.count, color: .blue)
                statBadge("Yüksek", value: tasks.filter { !$0.isCompleted && $0.priority == 2 }.count, color: .red)
                statBadge("Bugün", value: tasks.filter {
                    !$0.isCompleted && ($0.dueDate.map { Calendar.current.isDateInToday($0) } ?? false)
                }.count, color: .orange)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider().opacity(0.3)

            // List
            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: showCompleted ? "checkmark.circle" : "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text(showCompleted ? "Henüz tamamlanan yok" : "Görev yok")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filtered) { task in
                            TaskRow(task: task)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(task)
                                        try? context.save()
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle(title)
    }

    private func addTask() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let newTask = TaskItem(
            title: trimmed,
            isCompleted: showCompleted,
            dueDate: selectedDate,
            hexColor: selectedColor.rawValue,
            priority: priority
        )

        context.insert(newTask)

        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }

        text = ""
        priority = 0
        fieldFocused = true
    }

    @ViewBuilder
    private func statBadge(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
