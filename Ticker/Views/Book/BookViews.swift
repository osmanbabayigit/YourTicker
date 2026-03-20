import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Custom tarih seçici

struct CompactDatePicker: View {
    let label: String
    let icon: String
    @Binding var date: Date
    @Binding var isEnabled: Bool

    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden().toggleStyle(.switch).controlSize(.small)

            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isEnabled ? .blue : .secondary)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(isEnabled ? .primary : .secondary)

            Spacer()

            if isEnabled {
                Button {
                    showPicker.toggle()
                } label: {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                    VStack(spacing: 0) {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical).labelsHidden().frame(width: 260)
                        Divider()
                        Button("Tamam") { showPicker = false }
                            .buttonStyle(.plain).font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.blue).padding(10)
                    }
                    .padding(4)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Kitap Ekleme

struct AddBookView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var status: ReadingStatus = .wantToRead
    @State private var selectedColor: TaskColor = .blue
    @State private var coverImageData: Data? = nil
    @State private var isDragOver = false
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasFinishDate = false
    @State private var finishDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kitap Ekle").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 13))
                Button("Ekle") { save() }
                    .buttonStyle(.borderedProminent).tint(selectedColor.color)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {
                    coverPickerSection
                    titleSection
                    authorPageSection
                    statusSection
                    dateSection
                    colorSection
                }
                .padding(20)
            }
        }
        .frame(width: 400)
        .background(GlassView(material: .hudWindow))
    }

    // MARK: Sections

    @ViewBuilder var coverPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Kapak Fotoğrafı", systemImage: "photo")
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDragOver ? Color.blue.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
                    .frame(height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isDragOver ? Color.blue : Color.gray.opacity(0.25),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    )
                if let data = coverImageData, let img = NSImage(data: data) {
                    Image(nsImage: img).resizable().scaledToFit()
                        .frame(height: 136).clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 24)).foregroundStyle(.secondary)
                        Text("Sürükle veya tıkla").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }
            .onTapGesture { pickImage() }
            .onDrop(of: ["public.image"], isTargeted: $isDragOver) { handleDrop(providers: $0) }
            if coverImageData != nil {
                Button("Fotoğrafı kaldır") { coverImageData = nil }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Kitap Adı", systemImage: "book")
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            TextField("Kitabın adı", text: $title)
                .textFieldStyle(.plain).font(.system(size: 14))
                .padding(10).background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder var authorPageSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Yazar", systemImage: "person")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                TextField("Yazar adı", text: $author)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .padding(10).background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 6) {
                Label("Sayfa", systemImage: "doc.text")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                TextField("0", text: $totalPages)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .padding(10).background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8)).frame(width: 80)
            }
        }
    }

    @ViewBuilder var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Durum", systemImage: "bookmark")
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(ReadingStatus.allCases, id: \.self) { s in
                    Button { status = s } label: {
                        HStack(spacing: 5) {
                            Image(systemName: s.icon).font(.system(size: 11))
                            Text(s.label).font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(status == s ? s.color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(status == s ? s.color : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(status == s ? s.color.opacity(0.4) : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain).animation(.spring(response: 0.2), value: status)
                }
            }
        }
    }

    @ViewBuilder var dateSection: some View {
        VStack(spacing: 8) {
            CompactDatePicker(label: "Başlangıç tarihi", icon: "play.circle",
                              date: $startDate, isEnabled: $hasStartDate)
            CompactDatePicker(label: "Bitiş tarihi", icon: "checkmark.circle",
                              date: $finishDate, isEnabled: $hasFinishDate)
        }
    }

    @ViewBuilder var colorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Renk (kapak yoksa)", systemImage: "paintpalette")
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(TaskColor.allCases, id: \.self) { color in
                    Button { selectedColor = color } label: {
                        ZStack {
                            Circle().fill(color.color).frame(width: 24, height: 24)
                            if selectedColor == color {
                                Circle().strokeBorder(.white, lineWidth: 2).frame(width: 24, height: 24)
                                Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            coverImageData = ImageHelper.resizedCoverData(img)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
            if let data, let img = NSImage(data: data) {
                DispatchQueue.main.async { coverImageData = ImageHelper.resizedCoverData(img) }
            }
        }
        return true
    }

    private func save() {
        let book = BookItem(title: title.trimmingCharacters(in: .whitespaces),
                            author: author, totalPages: Int(totalPages) ?? 0,
                            status: status, hexColor: selectedColor.rawValue)
        book.coverImageData = coverImageData
        book.startDate  = hasStartDate  ? startDate  : (status == .reading  ? Date() : nil)
        book.finishDate = hasFinishDate ? finishDate : (status == .finished ? Date() : nil)
        context.insert(book); try? context.save(); dismiss()
    }
}

// MARK: - Kitap Detay + Düzenleme

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: BookItem

    @State private var isEditing = false

    // Edit state
    @State private var editTitle = ""
    @State private var editAuthor = ""
    @State private var editPages = ""
    @State private var editColor: TaskColor = .blue
    @State private var editCoverData: Data? = nil
    @State private var editIsDragOver = false
    @State private var hasStartDate = false
    @State private var editStartDate = Date()
    @State private var hasFinishDate = false
    @State private var editFinishDate = Date()

    // Note state
    @State private var newNoteText = ""
    @State private var newNotePage = ""
    @State private var isQuote = false
    @FocusState private var noteFocused: Bool

    var sortedNotes: [BookNote] { book.notes.sorted { $0.createdAt > $1.createdAt } }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 16) {
                // Kapak
                coverImage
                    .frame(width: 72, height: 100)

                VStack(alignment: .leading, spacing: 6) {
                    if isEditing {
                        TextField("Kitap adı", text: $editTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .bold))
                            .padding(6).background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        TextField("Yazar", text: $editAuthor)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(6).background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text").font(.system(size: 11)).foregroundStyle(.secondary)
                            TextField("Sayfa", text: $editPages)
                                .textFieldStyle(.plain).font(.system(size: 12)).frame(width: 60)
                            Text("sayfa").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    } else {
                        Text(book.title).font(.system(size: 15, weight: .bold)).lineLimit(2)
                        if !book.author.isEmpty {
                            Text(book.author).font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        if book.totalPages > 0 {
                            Text("\(book.totalPages) sayfa").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }

                    // Yıldız
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                book.rating = book.rating == i ? 0 : i
                                try? context.save()
                            } label: {
                                Image(systemName: i <= book.rating ? "star.fill" : "star")
                                    .font(.system(size: 14))
                                    .foregroundStyle(i <= book.rating ? .yellow : .secondary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Durum
                    HStack(spacing: 6) {
                        ForEach(ReadingStatus.allCases, id: \.self) { s in
                            Button {
                                book.status = s
                                if s == .reading  && book.startDate  == nil { book.startDate  = Date() }
                                if s == .finished && book.finishDate == nil { book.finishDate = Date() }
                                try? context.save()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: s.icon).font(.system(size: 10))
                                    Text(s.label).font(.system(size: 10, weight: .medium))
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(book.status == s ? s.color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                                .foregroundStyle(book.status == s ? s.color : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Button("Kapat") { dismiss() }
                        .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 13))

                    if isEditing {
                        Button("Kaydet") { saveEdits() }
                            .buttonStyle(.borderedProminent).controlSize(.small)
                            .font(.system(size: 12, weight: .medium))
                        Button("İptal") { isEditing = false }
                            .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 12))
                    } else {
                        Button { startEditing() } label: {
                            Label("Düzenle", systemImage: "pencil")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }
            .padding(20)

            // Düzenleme ek alanları
            if isEditing {
                VStack(spacing: 10) {
                    Divider().opacity(0.4)
                    VStack(spacing: 8) {
                        // Kapak değiştir
                        HStack(spacing: 10) {
                            Button {
                                let panel = NSOpenPanel()
                                panel.allowedContentTypes = [.image]
                                panel.allowsMultipleSelection = false
                                if panel.runModal() == .OK, let url = panel.url,
                                   let img = NSImage(contentsOf: url) {
                                    editCoverData = ImageHelper.resizedCoverData(img)
                                }
                            } label: {
                                Label("Kapak değiştir", systemImage: "photo.badge.plus")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered).controlSize(.small)

                            if editCoverData != nil || book.coverImageData != nil {
                                Button("Kapağı kaldır") { editCoverData = Data() }
                                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.red)
                            }
                        }

                        // Renk
                        HStack(spacing: 10) {
                            Text("Renk:").font(.system(size: 11)).foregroundStyle(.secondary)
                            ForEach(TaskColor.allCases, id: \.self) { color in
                                Button { editColor = color } label: {
                                    ZStack {
                                        Circle().fill(color.color).frame(width: 20, height: 20)
                                        if editColor == color {
                                            Circle().strokeBorder(.white, lineWidth: 2).frame(width: 20, height: 20)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Tarihler
                        CompactDatePicker(label: "Başlangıç", icon: "play.circle",
                                          date: $editStartDate, isEnabled: $hasStartDate)
                        CompactDatePicker(label: "Bitiş", icon: "checkmark.circle",
                                          date: $editFinishDate, isEnabled: $hasFinishDate)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.25), value: isEditing)
            }

            Divider().opacity(0.4)

            // Notlar
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Not ekleme
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Notlar & Alıntılar", systemImage: "quote.bubble")
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Alıntı").font(.system(size: 11)).foregroundStyle(.secondary)
                                Toggle("", isOn: $isQuote).labelsHidden().toggleStyle(.switch).controlSize(.small)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            TextField("s.", text: $newNotePage)
                                .textFieldStyle(.plain).font(.system(size: 12))
                                .multilineTextAlignment(.center).frame(width: 40)
                                .padding(7).background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            TextEditor(text: $newNoteText)
                                .font(.system(size: 13)).frame(minHeight: 52, maxHeight: 80)
                                .padding(6).background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .scrollContentBackground(.hidden).focused($noteFocused)

                            Button { addNote() } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20)).foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            .disabled(newNoteText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    if sortedNotes.isEmpty {
                        Text("Henüz not yok").font(.system(size: 12)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(sortedNotes) { note in
                                BookNoteRow(note: note)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            context.delete(note); try? context.save()
                                        } label: { Label("Sil", systemImage: "trash") }
                                    }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 600)
        .background(GlassView(material: .hudWindow))
    }

    // MARK: - Kapak görünümü

    @ViewBuilder
    var coverImage: some View {
        let data = editCoverData ?? book.coverImageData
        Group {
            if let d = data, d.count > 0, let img = NSImage(data: d) {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 72, height: 100).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: book.hexColor).opacity(0.2))
                    .overlay(Image(systemName: "book.closed").font(.system(size: 22))
                        .foregroundStyle(Color(hex: book.hexColor).opacity(0.5)))
            }
        }
    }

    // MARK: - Actions

    private func startEditing() {
        editTitle  = book.title
        editAuthor = book.author
        editPages  = book.totalPages > 0 ? "\(book.totalPages)" : ""
        editColor  = TaskColor(rawValue: book.hexColor) ?? .blue
        editCoverData  = nil
        hasStartDate   = book.startDate != nil
        editStartDate  = book.startDate ?? Date()
        hasFinishDate  = book.finishDate != nil
        editFinishDate = book.finishDate ?? Date()
        isEditing = true
    }

    private func saveEdits() {
        book.title      = editTitle.trimmingCharacters(in: .whitespaces)
        book.author     = editAuthor
        book.totalPages = Int(editPages) ?? 0
        book.hexColor   = editColor.rawValue
        book.startDate  = hasStartDate  ? editStartDate  : nil
        book.finishDate = hasFinishDate ? editFinishDate : nil

        // Kapak: Data() = kaldır, nil = değiştirme, diğer = güncelle
        if let d = editCoverData {
            book.coverImageData = d.isEmpty ? nil : d
        }

        try? context.save()
        isEditing = false
    }

    private func addNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let note = BookNote(content: trimmed, page: Int(newNotePage) ?? 0, isQuote: isQuote)
        note.book = book; context.insert(note); try? context.save()
        newNoteText = ""; newNotePage = ""; noteFocused = true
    }
}

// MARK: - Not Satırı

struct BookNoteRow: View {
    let note: BookNote

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: note.isQuote ? "quote.opening" : "note.text")
                .font(.system(size: 13))
                .foregroundStyle(note.isQuote ? Color.yellow : Color.blue)
                .frame(width: 20).padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.content).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    if note.page > 0 {
                        Text("s. \(note.page)").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Text(note.createdAt, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(note.isQuote ? Color.yellow.opacity(0.07) : Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(note.isQuote ? Color.yellow.opacity(0.2) : Color.clear, lineWidth: 1))
    }
}
