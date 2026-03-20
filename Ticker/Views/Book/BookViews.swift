import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Kitap Ekleme

struct AddBookView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var status: ReadingStatus = .wantToRead
    @State private var selectedColorHex = "#3B82F6"
    @State private var coverImageData: Data? = nil
    @State private var isDragOver = false
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasFinishDate = false
    @State private var finishDate = Date()
    @FocusState private var titleFocused: Bool

    private let colorOptions = [
        "#3B82F6","#34D399","#FB923C","#F472B6",
        "#C084FC","#FBBF24","#2DD4BF","#FB7185"
    ]

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    coverSection
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                    infoSection
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                    statusSection
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                    dateSection
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                    colorSection
                }
            }
        }
        .frame(width: 420)
        .background(Color(hex: "#161618"))
        .onAppear { titleFocused = true }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: selectedColorHex)).frame(width: 10, height: 10)
            Text("Kitap Ekle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)
            Spacer()
            Button("İptal") { dismiss() }
                .buttonStyle(.plain).font(.system(size: 12))
                .foregroundStyle(TickerTheme.textTertiary)
            Button("Ekle") { save() }
                .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TickerTheme.blue)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(TickerTheme.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
    }

    private var coverSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Kapak Fotoğrafı", icon: "photo")
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(TickerTheme.bgPill)
                    .frame(height: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDragOver ? TickerTheme.blue : TickerTheme.borderMid,
                                    style: StrokeStyle(lineWidth: 1.2, dash: [5]))
                    )
                if let data = coverImageData, let img = NSImage(data: data) {
                    Image(nsImage: img).resizable().scaledToFit()
                        .frame(height: 126).clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 22)).foregroundStyle(TickerTheme.textTertiary)
                        Text("Sürükle veya tıkla")
                            .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    }
                }
            }
            .onTapGesture { pickImage() }
            .onDrop(of: ["public.image"], isTargeted: $isDragOver) { handleDrop(providers: $0) }

            if coverImageData != nil {
                Button("Kaldır") { coverImageData = nil }
                    .buttonStyle(.plain).font(.system(size: 11))
                    .foregroundStyle(TickerTheme.red)
            }
        }
        .padding(18)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Kitap Adı", icon: "book")
                TextField("Kitabın adı", text: $title)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textPrimary).focused($titleFocused)
                    .padding(9).background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Yazar", icon: "person")
                    TextField("Yazar", text: $author)
                        .textFieldStyle(.plain).font(.system(size: 13))
                        .foregroundStyle(TickerTheme.textPrimary)
                        .padding(9).background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Sayfa", icon: "doc.text")
                    TextField("0", text: $totalPages)
                        .textFieldStyle(.plain).font(.system(size: 13))
                        .foregroundStyle(TickerTheme.textPrimary)
                        .padding(9).background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .frame(width: 80)
                }
            }
        }
        .padding(18)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Durum", icon: "bookmark")
            HStack(spacing: 6) {
                ForEach(ReadingStatus.allCases, id: \.self) { s in
                    Button { status = s } label: {
                        HStack(spacing: 5) {
                            Image(systemName: s.icon).font(.system(size: 10))
                            Text(s.label).font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(status == s ? s.color.opacity(0.15) : TickerTheme.bgPill)
                        .foregroundStyle(status == s ? s.color : TickerTheme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(status == s ? s.color.opacity(0.2) : TickerTheme.borderSub, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain).animation(.spring(response: 0.2), value: status)
                }
            }
        }
        .padding(18)
    }

    private var dateSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Toggle("", isOn: $hasStartDate).labelsHidden().toggleStyle(.switch).controlSize(.small)
                sectionLabel("Başlangıç tarihi", icon: "play.circle")
                Spacer()
                if hasStartDate {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden().colorScheme(.dark)
                }
            }
            HStack(spacing: 8) {
                Toggle("", isOn: $hasFinishDate).labelsHidden().toggleStyle(.switch).controlSize(.small)
                sectionLabel("Bitiş tarihi", icon: "checkmark.circle")
                Spacer()
                if hasFinishDate {
                    DatePicker("", selection: $finishDate, displayedComponents: .date)
                        .labelsHidden().colorScheme(.dark)
                }
            }
        }
        .padding(18)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Renk (kapak yoksa)", icon: "circle.hexagongrid")
            HStack(spacing: 8) {
                ForEach(colorOptions, id: \.self) { hex in
                    Button { selectedColorHex = hex } label: {
                        ZStack {
                            Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                            if selectedColorHex == hex {
                                Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2).frame(width: 24, height: 24)
                                Image(systemName: "checkmark").font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain).animation(.spring(response: 0.15), value: selectedColorHex)
                }
            }
        }
        .padding(18)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let img = NSImage(contentsOf: url) {
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
                            status: status, hexColor: selectedColorHex)
        book.coverImageData = coverImageData
        book.startDate  = hasStartDate  ? startDate  : (status == .reading  ? Date() : nil)
        book.finishDate = hasFinishDate ? finishDate : (status == .finished ? Date() : nil)
        context.insert(book); try? context.save(); dismiss()
    }
}

// MARK: - Kitap Detay

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: BookItem

    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editAuthor = ""
    @State private var editPages = ""
    @State private var editColorHex = ""
    @State private var editCoverData: Data? = nil
    @State private var hasStartDate = false
    @State private var editStartDate = Date()
    @State private var hasFinishDate = false
    @State private var editFinishDate = Date()

    @State private var newNoteText = ""
    @State private var newNotePage = ""
    @State private var isQuote = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            detailHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if isEditing {
                editFields
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            }

            notesSection
        }
        .frame(width: 480, height: 580)
        .background(Color(hex: "#161618"))
    }

    // MARK: - Header

    private var detailHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            // Kapak
            coverThumbnail

            // Bilgiler
            VStack(alignment: .leading, spacing: 5) {
                if isEditing {
                    TextField("Kitap adı", text: $editTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TickerTheme.textPrimary)
                        .padding(6).background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    TextField("Yazar", text: $editAuthor)
                        .textFieldStyle(.plain).font(.system(size: 12))
                        .foregroundStyle(TickerTheme.textSecondary)
                        .padding(6).background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    HStack(spacing: 6) {
                        TextField("Sayfa", text: $editPages)
                            .textFieldStyle(.plain).font(.system(size: 11))
                            .foregroundStyle(TickerTheme.textSecondary)
                            .padding(5).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .frame(width: 70)
                        Text("sayfa").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    }
                } else {
                    Text(book.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TickerTheme.textPrimary).lineLimit(2)
                    if !book.author.isEmpty {
                        Text(book.author).font(.system(size: 12))
                            .foregroundStyle(TickerTheme.textSecondary)
                    }
                    if book.totalPages > 0 {
                        Text("\(book.totalPages) sayfa")
                            .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    }
                }

                // Yıldız
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            book.rating = book.rating == i ? 0 : i
                            try? context.save()
                        } label: {
                            Image(systemName: i <= book.rating ? "star.fill" : "star")
                                .font(.system(size: 13))
                                .foregroundStyle(i <= book.rating
                                                 ? Color(hex: "#FBBF24")
                                                 : TickerTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Durum seçici
                HStack(spacing: 5) {
                    ForEach(ReadingStatus.allCases, id: \.self) { s in
                        Button {
                            book.status = s
                            if s == .reading  && book.startDate  == nil { book.startDate  = Date() }
                            if s == .finished && book.finishDate == nil { book.finishDate = Date() }
                            try? context.save()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: s.icon).font(.system(size: 9))
                                Text(s.label).font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 7).padding(.vertical, 4)
                            .background(book.status == s ? s.color.opacity(0.12) : TickerTheme.bgPill)
                            .foregroundStyle(book.status == s ? s.color : TickerTheme.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            // Butonlar
            VStack(alignment: .trailing, spacing: 8) {
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)

                if isEditing {
                    Button("Kaydet") { saveEdits() }
                        .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TickerTheme.blue)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(TickerTheme.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Button("İptal") { isEditing = false }
                        .buttonStyle(.plain).font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                } else {
                    Button {
                        editTitle = book.title; editAuthor = book.author
                        editPages = book.totalPages > 0 ? "\(book.totalPages)" : ""
                        editColorHex = book.hexColor; editCoverData = nil
                        hasStartDate = book.startDate != nil
                        editStartDate = book.startDate ?? Date()
                        hasFinishDate = book.finishDate != nil
                        editFinishDate = book.finishDate ?? Date()
                        isEditing = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil").font(.system(size: 10))
                            Text("Düzenle").font(.system(size: 11))
                        }
                        .foregroundStyle(TickerTheme.textSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)

                    // Sil
                    Button {
                        context.delete(book); try? context.save(); dismiss()
                    } label: {
                        Image(systemName: "trash").font(.system(size: 11))
                            .foregroundStyle(TickerTheme.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
    }

    @ViewBuilder
    private var coverThumbnail: some View {
        let displayData = editCoverData ?? book.coverImageData
        Group {
            if let d = displayData, d.count > 0, let img = NSImage(data: d) {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 70, height: 96).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: book.hexColor).opacity(0.15))
                    Image(systemName: "book.closed.fill").font(.system(size: 20))
                        .foregroundStyle(Color(hex: book.hexColor).opacity(0.4))
                }
                .frame(width: 70, height: 96)
            }
        }
        .overlay(
            isEditing
            ? AnyView(
                Button { pickCover() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.5))
                        Image(systemName: "camera.fill").font(.system(size: 14)).foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
              )
            : AnyView(EmptyView())
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Edit fields

    private var editFields: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Toggle("", isOn: $hasStartDate).labelsHidden().toggleStyle(.switch).controlSize(.small)
                Text("Başlangıç").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                Spacer()
                if hasStartDate {
                    DatePicker("", selection: $editStartDate, displayedComponents: .date)
                        .labelsHidden().colorScheme(.dark)
                }
            }
            HStack(spacing: 8) {
                Toggle("", isOn: $hasFinishDate).labelsHidden().toggleStyle(.switch).controlSize(.small)
                Text("Bitiş").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                Spacer()
                if hasFinishDate {
                    DatePicker("", selection: $editFinishDate, displayedComponents: .date)
                        .labelsHidden().colorScheme(.dark)
                }
            }

            // Renk
            HStack(spacing: 8) {
                Text("Renk").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                ForEach(["#3B82F6","#34D399","#FB923C","#F472B6","#C084FC","#FBBF24"], id: \.self) { hex in
                    Button { editColorHex = hex } label: {
                        ZStack {
                            Circle().fill(Color(hex: hex)).frame(width: 18, height: 18)
                            if editColorHex == hex {
                                Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5).frame(width: 18, height: 18)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    // MARK: - Notlar

    private var notesSection: some View {
        VStack(spacing: 0) {
            // Not ekleme
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "quote.bubble").font(.system(size: 9))
                        Text("Notlar & Alıntılar").font(.system(size: 10, weight: .medium)).kerning(0.3)
                    }
                    .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Alıntı").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                        Toggle("", isOn: $isQuote).labelsHidden().toggleStyle(.switch).controlSize(.mini)
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    TextField("s.", text: $newNotePage)
                        .textFieldStyle(.plain).font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: 36)
                        .padding(6).background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    ZStack(alignment: .topLeading) {
                        if newNoteText.isEmpty {
                            Text("Not veya alıntı ekle...")
                                .font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                                .padding(7)
                        }
                        TextEditor(text: $newNoteText)
                            .font(.system(size: 12)).foregroundStyle(TickerTheme.textSecondary)
                            .frame(minHeight: 50, maxHeight: 80)
                            .padding(4).scrollContentBackground(.hidden)
                            .focused($noteFocused)
                    }
                    .background(TickerTheme.bgPill).clipShape(RoundedRectangle(cornerRadius: 5))

                    Button { addNote() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20)).foregroundStyle(TickerTheme.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newNoteText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(16)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if book.sortedNotes.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 22)).foregroundStyle(TickerTheme.textTertiary)
                    Text("Henüz not yok")
                        .font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(book.sortedNotes) { note in
                            BookNoteRow(note: note)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(note); try? context.save()
                                    } label: { Label("Sil", systemImage: "trash") }
                                }
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    // MARK: - Actions

    private func pickCover() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let img = NSImage(contentsOf: url) {
            editCoverData = ImageHelper.resizedCoverData(img)
        }
    }

    private func saveEdits() {
        book.title = editTitle.trimmingCharacters(in: .whitespaces)
        book.author = editAuthor
        book.totalPages = Int(editPages) ?? 0
        book.hexColor = editColorHex.isEmpty ? book.hexColor : editColorHex
        book.startDate  = hasStartDate  ? editStartDate  : nil
        book.finishDate = hasFinishDate ? editFinishDate : nil
        if let d = editCoverData { book.coverImageData = d.isEmpty ? nil : d }
        try? context.save(); isEditing = false
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
            // Sol çizgi
            RoundedRectangle(cornerRadius: 1)
                .fill(note.isQuote ? Color(hex: "#FBBF24") : TickerTheme.blue)
                .frame(width: 2)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.system(size: 12))
                    .italic(note.isQuote)
                    .foregroundStyle(TickerTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if note.page > 0 {
                        Text("s. \(note.page)")
                            .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    }
                    Text(note.createdAt, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    if note.isQuote {
                        Text("Alıntı").font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(hex: "#FBBF24"))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: "#FBBF24").opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
        .padding(10)
        .background(TickerTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(TickerTheme.borderSub, lineWidth: 1)
        )
    }
}
