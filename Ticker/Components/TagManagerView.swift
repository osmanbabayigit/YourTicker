import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TagItem.name) private var tags: [TagItem]

    @State private var newName = ""
    @State private var newColor: TaskColor = .blue
    @State private var deleteConfirm: TagItem? = nil
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(newColor.color).frame(width: 10, height: 10)
                Text("Etiketler")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Yeni etiket
            HStack(spacing: 10) {
                // Renk seçici
                Menu {
                    ForEach(TaskColor.allCases, id: \.self) { c in
                        Button { newColor = c } label: {
                            HStack {
                                Image(systemName: "circle.fill").foregroundStyle(c.color)
                                Text(c.label)
                            }
                        }
                    }
                } label: {
                    Circle().fill(newColor.color).frame(width: 14, height: 14)
                        .padding(4).background(newColor.color.opacity(0.1)).clipShape(Circle())
                }
                .menuStyle(.borderlessButton).fixedSize()

                TextField("Yeni etiket adı...", text: $newName)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .focused($fieldFocused).onSubmit { addTag() }

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(newName.isEmpty ? TickerTheme.textTertiary : newColor.color)
                }
                .buttonStyle(.plain)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(TickerTheme.bgInput)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Etiket listesi
            if tags.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "tag")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(TickerTheme.textTertiary)
                    Text("Henüz etiket yok")
                        .font(.system(size: 13)).foregroundStyle(TickerTheme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(tags) { tag in
                            TagRowView(tag: tag) {
                                deleteConfirm = tag
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: 360, height: 460)
        .background(Color(hex: "#161618"))
        .alert("Etiketi sil?", isPresented: .constant(deleteConfirm != nil)) {
            Button("Sil", role: .destructive) {
                if let tag = deleteConfirm {
                    context.delete(tag)
                    try? context.save()
                }
                deleteConfirm = nil
            }
            Button("İptal", role: .cancel) { deleteConfirm = nil }
        } message: {
            if let tag = deleteConfirm {
                Text("\"\(tag.name)\" etiketi silinecek.")
            }
        }
    }

    private func addTag() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let tag = TagItem(name: trimmed, hexColor: newColor.rawValue)
        context.insert(tag); try? context.save()
        newName = ""; fieldFocused = true
    }
}

// MARK: - Tag Row

struct TagRowView: View {
    @Bindable var tag: TagItem
    @Environment(\.modelContext) private var context
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editColor: TaskColor = .blue
    @State private var isHovered = false

    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Renk
            Circle()
                .fill(Color(hex: tag.hexColor))
                .frame(width: 9, height: 9)

            if isEditing {
                // Düzenleme modu
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
                .menuStyle(.borderlessButton).fixedSize()

                TextField("", text: $editName)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .padding(.horizontal, 7).padding(.vertical, 5)
                    .background(TickerTheme.bgPill).clipShape(RoundedRectangle(cornerRadius: 5))
                    .onSubmit { saveEdit() }

                Spacer()

                Button("Kaydet") { saveEdit() }
                    .buttonStyle(.plain).font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(editColor.color)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(editColor.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Button("İptal") { isEditing = false }
                    .buttonStyle(.plain).font(.system(size: 11))
                    .foregroundStyle(TickerTheme.textTertiary)

            } else {
                // Normal görünüm
                Text(tag.name)
                    .font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textPrimary)

                Spacer()

                Text("\(tag.tasks.filter { !$0.isCompleted }.count) görev")
                    .font(.system(size: 10))
                    .foregroundStyle(TickerTheme.textTertiary)

                // Düzenle
                Button {
                    editName = tag.name
                    editColor = TaskColor(rawValue: tag.hexColor) ?? .blue
                    isEditing = true
                } label: {
                    Image(systemName: "pencil").font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0)

                // ✅ Sil butonu — her zaman görünür
                Button { onDelete() } label: {
                    Image(systemName: "trash").font(.system(size: 11))
                        .foregroundStyle(TickerTheme.red)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? TickerTheme.bgCardHover : TickerTheme.bgCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TickerTheme.borderSub, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
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
