import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]

    @State var selectedDate: Date
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedColor: TaskColor = .blue
    @State private var priority: Int = 0
    @State private var reminderEnabled: Bool = false
    @State private var reminderDate: Date
    @State private var selectedTags: [TagItem] = []
    @State private var recurrenceRule: RecurrenceRule = .none
    @State private var recurrenceWeekdays: [Int] = []

    init(selectedDate: Date) {
        _selectedDate = State(initialValue: selectedDate)
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        comps.hour = 9; comps.minute = 0
        _reminderDate = State(initialValue: Calendar.current.date(from: comps) ?? selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Yeni Görev")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 13))
                Button("Ekle") { saveTask() }
                    .buttonStyle(.borderedProminent).tint(selectedColor.color)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {

                    // Başlık
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Görev Adı", systemImage: "pencil")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        TextField("Ne yapılacak?", text: $title)
                            .textFieldStyle(.plain).font(.system(size: 14))
                            .padding(10)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Not
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Not", systemImage: "note.text")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .font(.system(size: 13)).frame(height: 60)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .scrollContentBackground(.hidden)
                    }

                    // Tarih & Öncelik
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
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            Picker("", selection: $priority) {
                                Text("Düşük").tag(0)
                                Text("Orta").tag(1)
                                Text("Yüksek").tag(2)
                            }
                            .pickerStyle(.segmented).frame(width: 180)
                        }
                    }

                    // Hatırlatıcı
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Hatırlatıcı", systemImage: "bell")
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Toggle("", isOn: $reminderEnabled)
                                .labelsHidden().toggleStyle(.switch).controlSize(.small)
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
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
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

                    // Etiketler
                    TagPickerView(selectedTags: $selectedTags)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Renk
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Renk", systemImage: "paintpalette")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
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
                }
                .padding(20)
            }
        }
        .frame(width: 420)
        .background(GlassView(material: .hudWindow))
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = (tasks.map { $0.sortOrder }.max() ?? -1) + 1
        let newTask = TaskItem(
            title: trimmed,
            dueDate: selectedDate,
            reminderDate: reminderEnabled ? reminderDate : nil,
            hexColor: selectedColor.rawValue,
            priority: priority,
            notes: notes,
            sortOrder: maxOrder,
            recurrenceRule: recurrenceRule,
            recurrenceWeekdays: recurrenceWeekdays
        )
        newTask.tags = selectedTags
        context.insert(newTask)
        if reminderEnabled { NotificationManager.shared.schedule(for: newTask) }
        try? context.save()
        dismiss()
    }
}
