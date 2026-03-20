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
            sheetHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    titleSection
                    divider
                    metaSection
                    divider
                    reminderSection
                    divider
                    recurrenceSection
                    divider
                    subtaskSection
                    divider
                    tagSection
                    divider
                    colorSection
                    divider
                    statusSection
                    divider
                    deleteSection
                }
            }
        }
        .frame(width: 440)
        .background(Color(hex: "#161618"))
        .task { await checkNotifStatus() }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            // Renk dot
            Circle()
                .fill(selectedColor.color)
                .frame(width: 10, height: 10)

            Text("Görevi Düzenle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)

            Spacer()

            Button("İptal") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(TickerTheme.textTertiary)

            Button("Kaydet") { saveChanges() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TickerTheme.blue)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(TickerTheme.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Başlık", icon: "pencil")
            TextField("Ne yapılacak?", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(TickerTheme.textPrimary)
                .padding(10)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            sectionLabel("Not", icon: "note.text")
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Notlar, linkler...")
                        .font(.system(size: 13))
                        .foregroundStyle(TickerTheme.textTertiary)
                        .padding(10)
                }
                TextEditor(text: $notes)
                    .font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textSecondary)
                    .frame(height: 70)
                    .padding(6)
                    .scrollContentBackground(.hidden)
            }
            .background(TickerTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(18)
    }

    private var metaSection: some View {
        HStack(spacing: 20) {
            DateTimePickerField(label: "Tarih", icon: "calendar",
                                date: $selectedDate, showTime: false)

            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Öncelik", icon: "flag")
                HStack(spacing: 4) {
                    ForEach([(0, "Yok"), (1, "Orta"), (2, "Yüksek")], id: \.0) { p, label in
                        Button { priority = p } label: {
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(priority == p
                                            ? (p == 2 ? TickerTheme.red : p == 1 ? TickerTheme.orange : TickerTheme.bgPill).opacity(p == 0 ? 1 : 0.15)
                                            : TickerTheme.bgPill)
                                .foregroundStyle(priority == p
                                                 ? (p == 2 ? TickerTheme.red : p == 1 ? TickerTheme.orange : TickerTheme.textSecondary)
                                                 : TickerTheme.textTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.2), value: priority)
                    }
                }
            }
        }
        .padding(18)
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Hatırlatıcı", icon: "bell")
                Spacer()
                if !notifStatus.isEmpty {
                    Text(notifStatus).font(.system(size: 10)).foregroundStyle(TickerTheme.red)
                }
                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
            if reminderEnabled {
                DateTimePickerField(label: "Zaman", icon: "clock",
                                    date: $reminderDate, showTime: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .animation(.spring(response: 0.25), value: reminderEnabled)
    }

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Tekrarlama", icon: "repeat")
            HStack(spacing: 5) {
                ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                    Button { recurrenceRule = rule } label: {
                        Text(rule.label)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(recurrenceRule == rule
                                        ? selectedColor.color.opacity(0.15)
                                        : TickerTheme.bgPill)
                            .foregroundStyle(recurrenceRule == rule
                                             ? selectedColor.color
                                             : TickerTheme.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(recurrenceRule == rule
                                            ? selectedColor.color.opacity(0.2)
                                            : TickerTheme.borderSub, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain).animation(.spring(response: 0.2), value: recurrenceRule)
                }
            }
            if recurrenceRule == .custom {
                HStack(spacing: 5) {
                    ForEach(weekdayLabels, id: \.0) { day, lbl in
                        let isSel = recurrenceWeekdays.contains(day)
                        Button {
                            if isSel { recurrenceWeekdays.removeAll { $0 == day } }
                            else { recurrenceWeekdays.append(day) }
                        } label: {
                            Text(lbl).font(.system(size: 11, weight: .medium))
                                .frame(width: 32, height: 26)
                                .background(isSel ? selectedColor.color.opacity(0.15) : TickerTheme.bgPill)
                                .foregroundStyle(isSel ? selectedColor.color : TickerTheme.textTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .animation(.spring(response: 0.25), value: recurrenceRule)
    }

    private var subtaskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("Alt Görevler", icon: "list.bullet.indent")
                Spacer()
                if !task.subtasks.isEmpty {
                    Text("\(task.completedSubtaskCount)/\(task.subtasks.count)")
                        .font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
            }

            if !task.sortedSubtasks.isEmpty {
                VStack(spacing: 0) {
                    ForEach(task.sortedSubtasks) { subtask in
                        HStack(spacing: 9) {
                            Button {
                                withAnimation { subtask.isCompleted.toggle() }
                                if task.allSubtasksCompleted { task.isCompleted = true }
                                try? context.save()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(subtask.isCompleted ? selectedColor.color : Color.clear)
                                        .frame(width: 15, height: 15)
                                    Circle()
                                        .strokeBorder(subtask.isCompleted ? selectedColor.color : TickerTheme.borderMid, lineWidth: 1)
                                        .frame(width: 15, height: 15)
                                    if subtask.isCompleted {
                                        Image(systemName: "checkmark").font(.system(size: 7, weight: .heavy)).foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Text(subtask.title)
                                .font(.system(size: 12))
                                .foregroundStyle(subtask.isCompleted ? TickerTheme.textTertiary : TickerTheme.textSecondary)
                                .strikethrough(subtask.isCompleted, color: TickerTheme.textTertiary)
                                .lineLimit(1)
                            Spacer()

                            Button {
                                context.delete(subtask); try? context.save()
                            } label: {
                                Image(systemName: "xmark").font(.system(size: 9))
                                    .foregroundStyle(TickerTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6).padding(.horizontal, 10)

                        if subtask.id != task.sortedSubtasks.last?.id {
                            Rectangle().fill(TickerTheme.borderSub).frame(height: 1).padding(.horizontal, 10)
                        }
                    }
                }
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }

            // Yeni alt görev
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                TextField("Alt görev ekle...", text: $newSubtaskText)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textSecondary)
                    .focused($subtaskFieldFocused)
                    .onSubmit { addSubtask() }
                if !newSubtaskText.isEmpty {
                    Button("Ekle") { addSubtask() }
                        .buttonStyle(.plain).font(.system(size: 11, weight: .medium))
                        .foregroundStyle(TickerTheme.blue)
                }
            }
            .padding(8)
            .background(TickerTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(18)
    }

    private var tagSection: some View {
        TagPickerView(selectedTags: $selectedTags)
            .padding(18)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Renk", icon: "circle.hexagongrid")
            HStack(spacing: 8) {
                ForEach(TaskColor.allCases, id: \.self) { color in
                    Button { selectedColor = color } label: {
                        ZStack {
                            Circle().fill(color.color).frame(width: 24, height: 24)
                            if selectedColor == color {
                                Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2).frame(width: 24, height: 24)
                                Image(systemName: "checkmark").font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain).animation(.spring(response: 0.15), value: selectedColor)
                }
            }
        }
        .padding(18)
    }

    private var statusSection: some View {
        HStack {
            sectionLabel("Durum", icon: "checkmark.circle")
            Spacer()
            Toggle(task.isCompleted ? "Tamamlandı" : "Bekliyor", isOn: $task.isCompleted)
                .font(.system(size: 12))
                .foregroundStyle(TickerTheme.textSecondary)
                .toggleStyle(.switch).controlSize(.small)
        }
        .padding(18)
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            NotificationManager.shared.cancel(for: task)
            context.delete(task); try? context.save(); dismiss()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash").font(.system(size: 12))
                Text("Görevi Sil").font(.system(size: 13))
            }
            .foregroundStyle(TickerTheme.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18).padding(.vertical, 4)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary)
        .textCase(.uppercase)
    }

    // MARK: - Actions

    private func addSubtask() {
        let trimmed = newSubtaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = (task.subtasks.map { $0.sortOrder }.max() ?? -1) + 1
        let sub = SubTaskItem(title: trimmed, sortOrder: maxOrder)
        sub.task = task; context.insert(sub); try? context.save()
        newSubtaskText = ""; subtaskFieldFocused = true
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
