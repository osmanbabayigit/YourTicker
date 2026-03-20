import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TagItem.name) private var tags: [TagItem]

    @State private var newName = ""
    @State private var newColor: TaskColor = .blue
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Etiketler")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider().opacity(0.4)

            // Yeni etiket ekleme
            HStack(spacing: 10) {
                Circle()
                    .fill(newColor.color)
                    .frame(width: 10, height: 10)

                TextField("Etiket adı...", text: $newName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($fieldFocused)
                    .onSubmit { addTag() }

                Menu {
                    ForEach(TaskColor.allCases, id: \.self) { c in
                        Button {
                            newColor = c
                        } label: {
                            HStack {
                                Image(systemName: "circle.fill").foregroundStyle(c.color)
                                Text(c.label)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Circle().fill(newColor.color).frame(width: 10, height: 10)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: addTag) {
                    Text("Ekle")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(newColor.color)
                .controlSize(.small)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider().opacity(0.4)

            // Etiket listesi
            if tags.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tag")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("Henüz etiket yok")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(tags) { tag in
                        TagRow(tag: tag)
                            .listRowInsets(EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            context.delete(tags[index])
                        }
                        try? context.save()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 360, height: 480)
        .background(GlassView(material: .hudWindow))
    }

    private func addTag() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let tag = TagItem(name: trimmed, hexColor: newColor.rawValue)
        context.insert(tag)
        try? context.save()
        newName = ""
        fieldFocused = true
    }
}

// MARK: - Tag Row

struct TagRow: View {
    @Bindable var tag: TagItem
    @Environment(\.modelContext) private var context
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editColor: TaskColor = .blue

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: tag.hexColor))
                .frame(width: 10, height: 10)

            if isEditing {
                TextField("", text: $editName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { saveEdit() }

                Menu {
                    ForEach(TaskColor.allCases, id: \.self) { c in
                        Button { editColor = c } label: {
                            HStack {
                                Image(systemName: "circle.fill").foregroundStyle(c.color)
                                Text(c.label)
                            }
                        }
                    }
                } label: {
                    Circle().fill(editColor.color).frame(width: 10, height: 10)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()

                Button("Kaydet") { saveEdit() }
                    .buttonStyle(.borderedProminent)
                    .tint(editColor.color)
                    .controlSize(.small)
                    .font(.system(size: 11))

                Button("İptal") { isEditing = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
            } else {
                Text(tag.name)
                    .font(.system(size: 13))

                Spacer()

                Text("\(tag.tasks.count) görev")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Button {
                    editName = tag.name
                    editColor = TaskColor(rawValue: tag.hexColor) ?? .blue
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
    }

    private func saveEdit() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tag.name = trimmed
        tag.hexColor = editColor.rawValue
        try? context.save()
        isEditing = false
    }
}
