import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State var selectedDate: Date
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedColor: TaskColor = .blue
    @State private var priority: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Yeni Görev")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))

                Button("Ekle") { saveTask() }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedColor.color)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(title.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 20) {
                    // Title field
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

                    // Notes field
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Not", systemImage: "note.text")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .font(.system(size: 13))
                            .frame(height: 70)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .scrollContentBackground(.hidden)
                    }

                    // Date & Priority row
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Tarih", systemImage: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                        }
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

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Renk", systemImage: "paintpalette")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(TaskColor.allCases, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 26, height: 26)
                                        if selectedColor == color {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2)
                                                .frame(width: 26, height: 26)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.white)
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
        let newTask = TaskItem(
            title: title,
            dueDate: selectedDate,
            hexColor: selectedColor.rawValue,
            priority: priority,
            notes: notes
        )
        context.insert(newTask)
        dismiss()
    }
}
