import SwiftUI
import SwiftData

struct NoteView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Query(sort: \NoteFolder.sortOrder) private var folders: [NoteFolder]

    @State private var selectedFolder: NoteFolder? = nil
    @State private var selectedNote: Note? = nil
    @State private var searchText = ""
    @State private var showingAddFolder = false
    @State private var deleteConfirm: Note? = nil

    private var filteredNotes: [Note] {
        var result = notes
        if let folder = selectedFolder {
            result = result.filter { $0.folder?.id == folder.id }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.updatedAt > b.updatedAt
        }
    }

    var body: some View {
        HSplitView {
            // Sol: Klasörler + liste
            leftPanel
                .frame(minWidth: 220, maxWidth: 280)

            // Sağ: Editör
            if let note = selectedNote {
                NoteEditorView(note: note, folders: folders)
            } else {
                emptyEditor
            }
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingAddFolder) { AddFolderView() }
        .alert("Notu sil?", isPresented: .constant(deleteConfirm != nil)) {
            Button("Sil", role: .destructive) {
                if let n = deleteConfirm { context.delete(n); try? context.save() }
                if selectedNote?.id == deleteConfirm?.id { selectedNote = nil }
                deleteConfirm = nil
            }
            Button("İptal", role: .cancel) { deleteConfirm = nil }
        }
    }

    // MARK: - Sol panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Arama + yeni not
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                TextField("Ara...", text: $searchText)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button { createNote() } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#FBBF24"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(TickerTheme.bgInput)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Klasörler
            VStack(spacing: 1) {
                // Tümü
                folderRow(name: "Tümü", icon: "tray.full",
                          color: TickerTheme.textTertiary, count: notes.count,
                          isSelected: selectedFolder == nil) {
                    selectedFolder = nil
                }

                ForEach(folders) { folder in
                    folderRow(name: folder.name, icon: "circle.fill",
                              color: Color(hex: folder.hexColor),
                              count: folder.notes.count,
                              isSelected: selectedFolder?.id == folder.id) {
                        selectedFolder = folder
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            if selectedFolder?.id == folder.id { selectedFolder = nil }
                            context.delete(folder); try? context.save()
                        } label: { Label("Sil", systemImage: "trash") }
                    }
                }

                Button { showingAddFolder = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 10))
                        Text("Klasör ekle").font(.system(size: 11))
                    }
                    .foregroundStyle(TickerTheme.textTertiary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6).padding(.horizontal, 6)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Not listesi
            if filteredNotes.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.system(size: 24)).foregroundStyle(TickerTheme.textTertiary)
                    Text("Not yok").font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(filteredNotes) { note in
                        NoteListRow(note: note, isSelected: selectedNote?.id == note.id)
                            .listRowInsets(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture { selectedNote = note }
                            .contextMenu {
                                Button {
                                    note.isPinned.toggle()
                                    try? context.save()
                                } label: {
                                    Label(note.isPinned ? "Sabitlemeyi kaldır" : "Sabitle",
                                          systemImage: note.isPinned ? "pin.slash" : "pin")
                                }
                                Divider()
                                Button(role: .destructive) { deleteConfirm = note } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // Alt: not sayısı
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            Text("\(filteredNotes.count) not")
                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                .padding(.vertical, 8)
        }
        .background(TickerTheme.bgSidebar)
    }

    @ViewBuilder
    private func folderRow(name: String, icon: String, color: Color,
                            count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? color : TickerTheme.textTertiary)
                Text(name).font(.system(size: 12))
                    .foregroundStyle(isSelected ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                Spacer()
                Text("\(count)").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Boş editör

    private var emptyEditor: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "square.and.pencil")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(TickerTheme.textTertiary)
            VStack(spacing: 4) {
                Text("Not seç veya yeni oluştur")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TickerTheme.textSecondary)
                Text("Soldaki listeden bir not seç")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            Button { createNote() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 11))
                    Text("Yeni Not").font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#FBBF24"))
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Color(hex: "#FBBF24").opacity(0.12)).clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "#FBBF24").opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity).background(TickerTheme.bgApp)
    }

    // MARK: - Yeni not oluştur

    private func createNote() {
        let note = Note(title: "", content: "", hexColor: selectedFolder?.hexColor ?? "#FBBF24")
        note.folder = selectedFolder
        context.insert(note)
        try? context.save()
        selectedNote = note
    }
}

// MARK: - Not liste satırı

struct NoteListRow: View {
    let note: Note
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8)).foregroundStyle(Color(hex: note.hexColor))
                }
                Text(note.title.isEmpty ? "Başlıksız" : note.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(note.title.isEmpty ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(note.relativeDate)
                    .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
            }
            Text(note.preview)
                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary).lineLimit(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? Color(hex: note.hexColor).opacity(0.1)
                      : isHovered ? TickerTheme.bgCardHover : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(hex: note.hexColor).opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Not Editörü

struct NoteEditorView: View {
    @Bindable var note: Note
    let folders: [NoteFolder]
    @Environment(\.modelContext) private var context

    @State private var showingFolderPicker = false

    private let noteColors = [
        "#FBBF24","#3B82F6","#34D399","#F472B6",
        "#A78BFA","#FB923C","#2DD4BF","#F87171"
    ]

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            editorContent
        }
        .background(TickerTheme.bgApp)
    }

    // MARK: - Toolbar

    private var editorToolbar: some View {
        HStack(spacing: 10) {
            // Breadcrumb
            HStack(spacing: 4) {
                Image(systemName: "tray.full")
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                Text(note.folder?.name ?? "Tümü")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                Text(note.title.isEmpty ? "Başlıksız" : note.title)
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textSecondary).lineLimit(1)
            }

            Spacer()

            // Klasör seçici
            Menu {
                Button("Klasör yok") {
                    note.folder = nil; save()
                }
                Divider()
                ForEach(folders) { folder in
                    Button(folder.name) {
                        note.folder = folder; save()
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: note.hexColor)).frame(width: 7, height: 7)
                    Text(note.folder?.name ?? "Klasörsüz")
                        .font(.system(size: 10))
                    Image(systemName: "chevron.down").font(.system(size: 8))
                }
                .foregroundStyle(TickerTheme.textSecondary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .menuStyle(.borderlessButton).fixedSize()

            // Renk seçici
            Menu {
                ForEach(noteColors, id: \.self) { hex in
                    Button {
                        note.hexColor = hex; save()
                    } label: {
                        Label(hex, systemImage: "circle.fill")
                    }
                }
            } label: {
                Circle().fill(Color(hex: note.hexColor)).frame(width: 14, height: 14)
                    .padding(4).background(TickerTheme.bgPill).clipShape(Circle())
            }
            .menuStyle(.borderlessButton).fixedSize()

            // Sabitle
            Button {
                note.isPinned.toggle(); save()
            } label: {
                Image(systemName: note.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12))
                    .foregroundStyle(note.isPinned ? Color(hex: note.hexColor) : TickerTheme.textTertiary)
            }
            .buttonStyle(.plain)

            Text(note.readingTime)
                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
    }

    // MARK: - Editör içeriği

    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Başlık
                TextField("Başlık...", text: $note.title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .onChange(of: note.title) { _, _ in save() }
                    .padding(.bottom, 4)

                // Meta
                Text(note.updatedAt.formatted(.dateTime.day().month(.wide).year()
                    .hour().minute()) + " · " + note.readingTime)
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    .padding(.bottom, 20)

                // İçerik
                TextEditor(text: $note.content)
                    .textEditorStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textSecondary)
                    .frame(minHeight: 400)
                    .scrollContentBackground(.hidden)
                    .onChange(of: note.content) { _, _ in save() }
            }
            .padding(.horizontal, 22).padding(.vertical, 18)
        }
    }

    private func save() {
        note.updatedAt = Date()
        try? context.save()
    }
}

// MARK: - Klasör ekleme

struct AddFolderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var folders: [NoteFolder]

    @State private var name = ""
    @State private var hexColor = "#FBBF24"
    @FocusState private var focused: Bool

    private let colors = [
        "#FBBF24","#3B82F6","#34D399","#F472B6",
        "#A78BFA","#FB923C","#2DD4BF","#F87171"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Circle().fill(Color(hex: hexColor)).frame(width: 10, height: 10)
                Text("Yeni Klasör")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
                Button("Ekle") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: hexColor))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: hexColor).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            VStack(spacing: 14) {
                TextField("Klasör adı...", text: $name)
                    .textFieldStyle(.plain).font(.system(size: 14))
                    .foregroundStyle(TickerTheme.textPrimary).focused($focused)
                    .padding(10).background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { hex in
                        Button { hexColor = hex } label: {
                            ZStack {
                                Circle().fill(Color(hex: hex)).frame(width: 26, height: 26)
                                if hexColor == hex {
                                    Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2)
                                        .frame(width: 26, height: 26)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
        }
        .frame(width: 360)
        .background(Color(hex: "#161618"))
        .onAppear { focused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (folders.map { $0.sortOrder }.max() ?? -1) + 1
        let folder = NoteFolder(name: trimmed, hexColor: hexColor, sortOrder: order)
        context.insert(folder); try? context.save(); dismiss()
    }
}
