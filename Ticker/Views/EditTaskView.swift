import SwiftUI
import SwiftData
import UserNotifications

struct EditTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var task: TaskItem

    @State private var title: String
    @State private var notes: String
    @State private var selectedDate: Date
    @State private var selectedColor: TaskColor
    @State private var priority: Int
    @State private var reminderEnabled: Bool
    @State private var reminderDate: Date
    @State private var selectedTags: [TagItem]
    @State private var recurrenceRule: RecurrenceRule
    @State private var recurrenceWeekdays: [Int]
    @State private var notifStatus: String = ""
    @State private var newSubtaskText: String = ""
    @FocusState private var subtaskFieldFocused: Bool

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _selectedDate = State(initialValue: task.dueDate ?? Date())
        _selectedColor = State(initialValue: TaskColor(rawValue: task.hexColor) ?? .blue)
        _priority = State(initialValue: task.priority)
        _reminderEnabled = State(initialValue: task.reminderDate != nil)
        _reminderDate = State(initialValue: task.reminderDate ?? {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: task.dueDate ?? Date())
            comps.hour = 9; comps.minute = 0
            return Calendar.current.date(from: comps) ?? Date()
        }())
        _selectedTags = State(initialValue: task.tags)
        _recurrenceRule = State(initialValue: task.recurrenceRule)
        _recurrenceWeekdays = State(initialValue: task.recurrenceWeekdays)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Görevi Düzenle")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                Button("Kaydet") { saveChanges() }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedColor.color)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {

                    // Başlık
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Görev Adı", systemImage: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextField("Ne yapılacak?", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(10)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Not
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Not", systemImage: "note.text")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .font(.system(size: 13))
                            .frame(height: 60)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .scrollContentBackground(.hidden)
                    }

                    // Tarih — yeni temiz picker
                    HStack(spacing: 16) {
                        DateTimePickerField(
                            label: "Tarih",
                            icon: "calendar",
                            date: $selectedDate,
                            showTime: false
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Öncelik", systemImage: "flag")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Picker("", selection: $priority) {
                                Text("Düşük").tag(0)
                                Text("Orta").tag(1)
                                Text("Yüksek").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }
                    }

                    // Hatırlatıcı — tarih + saat birlikte
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Hatırlatıcı", systemImage: "bell")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !notifStatus.isEmpty {
                                Text(notifStatus).font(.system(size: 10)).foregroundStyle(.red)
                            }
                            Toggle("", isOn: $reminderEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }

                        if reminderEnabled {
                            DateTimePickerField(
                                label: "Hatırlatma zamanı",
                                icon: "bell",
                                date: $reminderDate,
                                showTime: true
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.spring(response: 0.25), value: reminderEnabled)

                    // Tekrarlama
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Tekrarlama", systemImage: "repeat")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                                Button { recurrenceRule = rule } label: {
                                    Text(rule.label)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 8).padding(.vertical, 5)
                                        .background(recurrenceRule == rule
                                                    ? selectedColor.color.opacity(0.2)
                                                    : Color(nsColor: .controlBackgroundColor).opacity(0.6))
                                        .foregroundStyle(recurrenceRule == rule ? selectedColor.color : .secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.2), value: recurrenceRule)
                            }
                        }
                        if recurrenceRule == .custom {
                            HStack(spacing: 6) {
                                ForEach(weekdayLabels, id: \.0) { day, lbl in
                                    let isSel = recurrenceWeekdays.contains(day)
                                    Button {
                                        if isSel { recurrenceWeekdays.removeAll { $0 == day } }
                                        else { recurrenceWeekdays.append(day) }
                                    } label: {
                                        Text(lbl)
                                            .font(.system(size: 11, weight: .medium))
                                            .frame(width: 34, height: 28)
                                            .background(isSel ? selectedColor.color.opacity(0.2) : Color(nsColor: .controlBackgroundColor).opacity(0.6))
                                            .foregroundStyle(isSel ? selectedColor.color : .secondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.spring(response: 0.25), value: recurrenceRule)

                    // Alt Görevler
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Alt Görevler", systemImage: "list.bullet.indent")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !task.subtasks.isEmpty {
                                Text("\(task.completedSubtaskCount)/\(task.subtasks.count)")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                        }
                        if !task.sortedSubtasks.isEmpty {
                            List {
                                ForEach(task.sortedSubtasks) { subtask in
                                    HStack(spacing: 8) {
                                        Button {
                                            withAnimation { subtask.isCompleted.toggle() }
                                            if task.allSubtasksCompleted { task.isCompleted = true }
                                            try? context.save()
                                        } label: {
                                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 14))
                                                .foregroundStyle(subtask.isCompleted ? selectedColor.color : .secondary)
                                                .contentTransition(.symbolEffect(.replace))
                                        }
                                        .buttonStyle(.plain)
                                        Text(subtask.title).font(.system(size: 13))
                                            .strikethrough(subtask.isCompleted, color: .secondary)
                                            .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                                            .lineLimit(1)
                                        Spacer()
                                        Button { context.delete(subtask); try? context.save() } label: {
                                            Image(systemName: "minus.circle").font(.system(size: 13)).foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                                .onMove { from, to in moveSubtask(from: from, to: to) }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .frame(height: CGFloat(task.subtasks.count) * 36)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle").font(.system(size: 14)).foregroundStyle(selectedColor.color)
                            TextField("Alt görev ekle...", text: $newSubtaskText)
                                .textFieldStyle(.plain).font(.system(size: 13))
                                .focused($subtaskFieldFocused)
                                .onSubmit { addSubtask() }
                            if !newSubtaskText.isEmpty {
                                Button("Ekle") { addSubtask() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(selectedColor.color).controlSize(.mini)
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Etiketler
                    TagPickerView(selectedTags: $selectedTags)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Renk
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Renk", systemImage: "paintpalette")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(TaskColor.allCases, id: \.self) { color in
                                Button { selectedColor = color } label: {
                                    ZStack {
                                        Circle().fill(color.color).frame(width: 26, height: 26)
                                        if selectedColor == color {
                                            Circle().strokeBorder(.white, lineWidth: 2).frame(width: 26, height: 26)
                                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.2), value: selectedColor)
                            }
                        }
                    }

                    // Tamamlandı
                    HStack {
                        Label("Tamamlandı", systemImage: "checkmark.circle")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Toggle("", isOn: $task.isCompleted).labelsHidden()
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Sil
                    Button(role: .destructive) {
                        NotificationManager.shared.cancel(for: task)
                        context.delete(task); try? context.save(); dismiss()
                    } label: {
                        Label("Görevi Sil", systemImage: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered).tint(.red)
                }
                .padding(20)
            }
        }
        .frame(width: 420)
        .background(GlassView(material: .hudWindow))
        .task { await checkNotifStatus() }
    }

    private func addSubtask() {
        let trimmed = newSubtaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = (task.subtasks.map { $0.sortOrder }.max() ?? -1) + 1
        let sub = SubTaskItem(title: trimmed, sortOrder: maxOrder)
        sub.task = task; context.insert(sub); try? context.save()
        newSubtaskText = ""; subtaskFieldFocused = true
    }

    private func moveSubtask(from source: IndexSet, to destination: Int) {
        var reordered = task.sortedSubtasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (i, sub) in reordered.enumerated() { sub.sortOrder = i }
        try? context.save()
    }

    private func saveChanges() {
        task.title = title.trimmingCharacters(in: .whitespaces)
        task.notes = notes; task.dueDate = selectedDate
        task.hexColor = selectedColor.rawValue; task.priority = priority
        task.tags = selectedTags
        task.recurrenceRule = recurrenceRule; task.recurrenceWeekdays = recurrenceWeekdays
        NotificationManager.shared.cancel(for: task)
        if reminderEnabled {
            task.reminderDate = reminderDate
            NotificationManager.shared.schedule(for: task)
        } else { task.reminderDate = nil }
        try? context.save(); dismiss()
    }

    private func checkNotifStatus() async {
        let status = await NotificationManager.shared.authorizationStatus()
        if status == .denied { notifStatus = "Bildirim izni kapalı" }
    }
}
