import SwiftUI
import SwiftData

// MARK: - OpenLibrary arama sonucu

struct OLBook: Identifiable, Decodable {
    let id: String
    let title: String
    let authorName: [String]?
    let coverI: Int?
    let firstPublishYear: Int?
    let numberOfPagesMedian: Int?
    let subject: [String]?
    let isbn: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title
        case authorName = "author_name"
        case coverI = "cover_i"
        case firstPublishYear = "first_publish_year"
        case numberOfPagesMedian = "number_of_pages_median"
        case subject, isbn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .key)) ?? UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        authorName = try? c.decode([String].self, forKey: .authorName)
        coverI = try? c.decode(Int.self, forKey: .coverI)
        firstPublishYear = try? c.decode(Int.self, forKey: .firstPublishYear)
        numberOfPagesMedian = try? c.decode(Int.self, forKey: .numberOfPagesMedian)
        subject = try? c.decode([String].self, forKey: .subject)
        isbn = try? c.decode([String].self, forKey: .isbn)
    }

    var author: String { authorName?.first ?? "Bilinmiyor" }
    var coverURL: URL? {
        guard let id = coverI else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(id)-M.jpg")
    }
    var genre: String { subject?.prefix(3).joined(separator: ", ") ?? "" }
}

struct OLResponse: Decodable {
    let docs: [OLBook]
}

// MARK: - Kitap Arama View

struct BookSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [OLBook] = []
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var selectedBook: OLBook? = nil
    @State private var addingBook: OLBook? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Kitap Ara")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 13))
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            // Arama çubuğu
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isLoading ? .blue : .secondary)
                    .font(.system(size: 13))
                    .symbolEffect(.pulse, isActive: isLoading)

                TextField("Kitap adı veya yazar...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { search() }

                if isLoading {
                    ProgressView().controlSize(.small)
                } else if !query.isEmpty {
                    Button { query = ""; results = [] } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button("Ara") { search() }
                    .buttonStyle(.borderedProminent).tint(.blue).controlSize(.small)
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider().opacity(0.3)

            if !errorMsg.isEmpty {
                Text(errorMsg).font(.system(size: 12)).foregroundStyle(.red)
                    .padding(12)
            }

            if results.isEmpty && !isLoading {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 32)).foregroundStyle(.secondary.opacity(0.3))
                    Text("OpenLibrary'de ara")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                    Text("Milyonlarca kitap arasından bul ve ekle")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(results) { book in
                            SearchResultRow(book: book) {
                                addingBook = book
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: 520, height: 560)
        .background(GlassView(material: .hudWindow))
        .sheet(item: $addingBook) { book in
            AddBookFromSearchView(olBook: book)
        }
    }

    private func search() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        isLoading = true; errorMsg = ""
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        let urlStr = "https://openlibrary.org/search.json?q=\(encoded)&limit=20&fields=key,title,author_name,cover_i,first_publish_year,number_of_pages_median,subject,isbn"
        guard let url = URL(string: urlStr) else { isLoading = false; return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error { errorMsg = error.localizedDescription; return }
                guard let data = data else { return }
                if let response = try? JSONDecoder().decode(OLResponse.self, from: data) {
                    results = response.docs
                } else {
                    errorMsg = "Sonuç alınamadı"
                }
            }
        }.resume()
    }
}

// MARK: - Arama sonuç satırı

struct SearchResultRow: View {
    let book: OLBook
    let onAdd: () -> Void
    @State private var coverImage: NSImage? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Kapak
            Group {
                if let img = coverImage {
                    Image(nsImage: img).resizable().scaledToFill()
                        .frame(width: 44, height: 60).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 60)
                        .overlay(Image(systemName: "book.closed")
                            .font(.system(size: 16)).foregroundStyle(.blue.opacity(0.4)))
                }
            }
            .task { await loadCover() }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold)).lineLimit(2)
                Text(book.author)
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 8) {
                    if let year = book.firstPublishYear {
                        Text("\(year)").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    if let pages = book.numberOfPagesMedian, pages > 0 {
                        Text("\(pages) sayfa").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button { onAdd() } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20)).foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func loadCover() async {
        guard let url = book.coverURL else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = NSImage(data: data) else { return }
        await MainActor.run { coverImage = img }
    }
}

// MARK: - Arama sonucundan kitap ekle

struct AddBookFromSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let olBook: OLBook

    @State private var status: ReadingStatus = .wantToRead
    @State private var selectedColor: TaskColor = .blue
    @State private var coverData: Data? = nil
    @State private var isLoadingCover = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kitaplığa Ekle")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                Button("Ekle") { save() }
                    .buttonStyle(.borderedProminent).tint(.blue)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            VStack(spacing: 20) {
                // Kitap önizleme
                HStack(spacing: 16) {
                    Group {
                        if let data = coverData, let img = NSImage(data: data) {
                            Image(nsImage: img).resizable().scaledToFill()
                                .frame(width: 80, height: 110).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if isLoadingCover {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 110)
                                .overlay(ProgressView().controlSize(.small))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor.color.opacity(0.2))
                                .frame(width: 80, height: 110)
                                .overlay(Image(systemName: "book.closed")
                                    .font(.system(size: 28)).foregroundStyle(selectedColor.color.opacity(0.5)))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(olBook.title).font(.system(size: 15, weight: .bold)).lineLimit(3)
                        Text(olBook.author).font(.system(size: 12)).foregroundStyle(.secondary)
                        if let year = olBook.firstPublishYear {
                            Text("\(year)").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        if let pages = olBook.numberOfPagesMedian, pages > 0 {
                            Text("\(pages) sayfa").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }

                // Durum seçici
                VStack(alignment: .leading, spacing: 6) {
                    Text("Okuma durumu")
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
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Renk
                VStack(alignment: .leading, spacing: 6) {
                    Text("Renk (kapak yüklenemezse)").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(TaskColor.allCases, id: \.self) { c in
                            Button { selectedColor = c } label: {
                                ZStack {
                                    Circle().fill(c.color).frame(width: 22, height: 22)
                                    if selectedColor == c {
                                        Circle().strokeBorder(.white, lineWidth: 2).frame(width: 22, height: 22)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 400)
        .background(GlassView(material: .hudWindow))
        .task { await loadCover() }
    }

    private func loadCover() async {
        guard let url = olBook.coverURL else { isLoadingCover = false; return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            await MainActor.run { isLoadingCover = false }; return
        }
        if let img = NSImage(data: data) {
            let resized = ImageHelper.resizedCoverData(img)
            await MainActor.run { coverData = resized; isLoadingCover = false }
        } else {
            await MainActor.run { isLoadingCover = false }
        }
    }

    private func save() {
        let book = BookItem(
            title: olBook.title, author: olBook.author,
            totalPages: olBook.numberOfPagesMedian ?? 0,
            status: status, hexColor: selectedColor.rawValue
        )
        book.coverImageData = coverData
        book.isbn = olBook.isbn?.first ?? ""
        book.genre = olBook.genre
        book.publishYear = olBook.firstPublishYear ?? 0
        if status == .reading  { book.startDate  = Date() }
        if status == .finished { book.finishDate = Date() }
        context.insert(book); try? context.save(); dismiss()
    }
}
