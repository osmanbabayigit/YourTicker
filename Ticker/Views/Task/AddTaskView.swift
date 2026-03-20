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
    @FocusState private var titleFocused: Bool

    init(selectedDate: Date) {
        _selectedDate = State(initialValue: selectedDate)
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        comps.hour = 9; comps.minute = 0
        _reminderDate = State(initialValue: Calendar.current.date(from: comps) ?? selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Circle().fill(selectedColor.color).frame(width: 10, height: 10)
                Text("Yeni Görev")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
                Button("Ekle") { saveTask() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerTheme.blue)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(TickerTheme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {

                    // Başlık + Not
                    VStack(alignment: .leading, spacing: 8) {
                        label("Başlık", icon: "pencil")
                        TextField("Ne yapılacak?", text: $title)
                            .textFieldStyle(.plain).font(.system(size: 14))
                            .foregroundStyle(TickerTheme.textPrimary)
                            .padding(10).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .focused($titleFocused)
                        label("Not", icon: "note.text")
                        TextEditor(text: $notes)
                            .font(.system(size: 13)).foregroundStyle(TickerTheme.textSecondary)
                            .frame(height: 60).padding(6).scrollContentBackground(.hidden)
                            .background(TickerTheme.bgPill).clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Tarih & Öncelik
                    HStack(spacing: 20) {
                        DateTimePickerField(label: "Tarih", icon: "calendar",
                                            date: $selectedDate, showTime: false)
                        VStack(alignment: .leading, spacing: 6) {
                            label("Öncelik", icon: "flag")
                            HStack(spacing: 4) {
                                ForEach([(0,"Yok"),(1,"Orta"),(2,"Yüksek")], id: \.0) { p, lbl in
                                    Button { priority = p } label: {
                                        Text(lbl).font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8).padding(.vertical, 5)
                                            .background(priority == p
                                                        ? (p == 2 ? TickerTheme.red : p == 1 ? TickerTheme.orange : TickerTheme.bgPill).opacity(p == 0 ? 1 : 0.15)
                                                        : TickerTheme.bgPill)
                                            .foregroundStyle(priority == p
                                                             ? (p == 2 ? TickerTheme.red : p == 1 ? TickerTheme.orange : TickerTheme.textSecondary)
                                                             : TickerTheme.textTertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                    .buttonStyle(.plain).animation(.spring(response: 0.2), value: priority)
                                }
                            }
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Hatırlatıcı
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            label("Hatırlatıcı", icon: "bell")
                            Spacer()
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

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Tekrarlama
                    VStack(alignment: .leading, spacing: 10) {
                        label("Tekrarlama", icon: "repeat")
                        HStack(spacing: 5) {
                            ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                                Button { recurrenceRule = rule } label: {
                                    Text(rule.label).font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 8).padding(.vertical, 5)
                                        .background(recurrenceRule == rule
                                                    ? selectedColor.color.opacity(0.15) : TickerTheme.bgPill)
                                        .foregroundStyle(recurrenceRule == rule
                                                         ? selectedColor.color : TickerTheme.textTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
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
                        }
                    }
                    .padding(18)
                    .animation(.spring(response: 0.25), value: recurrenceRule)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Etiketler
                    TagPickerView(selectedTags: $selectedTags).padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Renk
                    VStack(alignment: .leading, spacing: 8) {
                        label("Renk", icon: "circle.hexagongrid")
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
            }
        }
        .frame(width: 440)
        .background(Color(hex: "#161618"))
        .onAppear { titleFocused = true }
    }

    @ViewBuilder
    private func label(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = (tasks.map { $0.sortOrder }.max() ?? -1) + 1
        let newTask = TaskItem(
            title: trimmed, dueDate: selectedDate,
            reminderDate: reminderEnabled ? reminderDate : nil,
            hexColor: selectedColor.rawValue, priority: priority,
            notes: notes, sortOrder: maxOrder,
            recurrenceRule: recurrenceRule, recurrenceWeekdays: recurrenceWeekdays
        )
        newTask.tags = selectedTags
        context.insert(newTask)
        if reminderEnabled { NotificationManager.shared.schedule(for: newTask) }
        try? context.save()
        dismiss()
    }
}
