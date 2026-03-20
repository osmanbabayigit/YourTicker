import SwiftUI
import SwiftData

// MARK: - OpenLibrary modeli

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
        id             = (try? c.decode(String.self, forKey: .key)) ?? UUID().uuidString
        title          = (try? c.decode(String.self, forKey: .title)) ?? ""
        authorName     = try? c.decode([String].self, forKey: .authorName)
        coverI         = try? c.decode(Int.self, forKey: .coverI)
        firstPublishYear      = try? c.decode(Int.self, forKey: .firstPublishYear)
        numberOfPagesMedian   = try? c.decode(Int.self, forKey: .numberOfPagesMedian)
        subject        = try? c.decode([String].self, forKey: .subject)
        isbn           = try? c.decode([String].self, forKey: .isbn)
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

// MARK: - Arama View

struct BookSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [OLBook] = []
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var addingBook: OLBook? = nil
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                TextField("Kitap adı veya yazar ara...", text: $query)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .focused($searchFocused).onSubmit { search() }
                if isLoading {
                    ProgressView().controlSize(.small).scaleEffect(0.7)
                } else if !query.isEmpty {
                    Button { query = ""; results = []; errorMsg = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                Button("Ara") { search() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerTheme.blue)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(TickerTheme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if !errorMsg.isEmpty {
                Text(errorMsg).font(.system(size: 11))
                    .foregroundStyle(TickerTheme.red).padding(12)
            }

            if results.isEmpty && !isLoading {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(TickerTheme.textTertiary)
                    Text("OpenLibrary'de kitap ara")
                        .font(.system(size: 13)).foregroundStyle(TickerTheme.textSecondary)
                    Text("Milyonlarca kitap arasından bul ve ekle")
                        .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(results) { book in
                            SearchResultRow(book: book) { addingBook = book }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: 540, height: 540)
        .background(Color(hex: "#161618"))
        .onAppear { searchFocused = true }
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
                if let error { errorMsg = error.localizedDescription; return }
                guard let data else { return }
                if let response = try? JSONDecoder().decode(OLResponse.self, from: data) {
                    results = response.docs
                } else { errorMsg = "Sonuç alınamadı" }
            }
        }.resume()
    }
}

// MARK: - Arama satırı

struct SearchResultRow: View {
    let book: OLBook
    let onAdd: () -> Void
    @State private var coverImage: NSImage? = nil
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Kapak
            Group {
                if let img = coverImage {
                    Image(nsImage: img).resizable().scaledToFill()
                        .frame(width: 42, height: 58).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5).fill(TickerTheme.bgPill)
                        Image(systemName: "book.closed")
                            .font(.system(size: 14)).foregroundStyle(TickerTheme.textTertiary)
                    }
                    .frame(width: 42, height: 58)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(TickerTheme.borderSub, lineWidth: 1))
            .task { await loadCover() }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary).lineLimit(2)
                Text(book.author)
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary).lineLimit(1)
                HStack(spacing: 8) {
                    if let year = book.firstPublishYear {
                        Text("\(year)").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    }
                    if let pages = book.numberOfPagesMedian, pages > 0 {
                        Text("\(pages) sayfa").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    }
                }
            }

            Spacer()

            Button { onAdd() } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20)).foregroundStyle(TickerTheme.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? TickerTheme.bgCardHover : TickerTheme.bgCard)
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(TickerTheme.borderSub, lineWidth: 1))
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }

    private func loadCover() async {
        guard let url = book.coverURL else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = NSImage(data: data) else { return }
        await MainActor.run { coverImage = img }
    }
}

// MARK: - Arama sonucundan ekleme

struct AddBookFromSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let olBook: OLBook

    @State private var status: ReadingStatus = .wantToRead
    @State private var selectedColorHex = "#3B82F6"
    @State private var coverData: Data? = nil
    @State private var isLoadingCover = true

    private let colorOptions = ["#3B82F6","#34D399","#FB923C","#F472B6","#C084FC","#FBBF24"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(Color(hex: selectedColorHex)).frame(width: 10, height: 10)
                Text("Kitaplığa Ekle")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                Button("Ekle") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerTheme.blue)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(TickerTheme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            VStack(spacing: 20) {
                // Kitap önizleme
                HStack(spacing: 16) {
                    Group {
                        if let data = coverData, let img = NSImage(data: data) {
                            Image(nsImage: img).resizable().scaledToFill()
                                .frame(width: 80, height: 110).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if isLoadingCover {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(TickerTheme.bgPill)
                                ProgressView().controlSize(.small)
                            }
                            .frame(width: 80, height: 110)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: selectedColorHex).opacity(0.15))
                                Image(systemName: "book.closed.fill").font(.system(size: 26))
                                    .foregroundStyle(Color(hex: selectedColorHex).opacity(0.4))
                            }
                            .frame(width: 80, height: 110)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(TickerTheme.borderSub, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(olBook.title).font(.system(size: 15, weight: .bold))
                            .foregroundStyle(TickerTheme.textPrimary).lineLimit(3)
                        Text(olBook.author).font(.system(size: 12))
                            .foregroundStyle(TickerTheme.textSecondary)
                        if let year = olBook.firstPublishYear {
                            Text("\(year)").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                        }
                        if let pages = olBook.numberOfPagesMedian, pages > 0 {
                            Text("\(pages) sayfa").font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                        }
                    }
                }

                // Durum
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Okuma durumu", icon: "bookmark")
                    HStack(spacing: 6) {
                        ForEach(ReadingStatus.allCases, id: \.self) { s in
                            Button { status = s } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: s.icon).font(.system(size: 10))
                                    Text(s.label).font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 9).padding(.vertical, 6)
                                .background(status == s ? s.color.opacity(0.12) : TickerTheme.bgPill)
                                .foregroundStyle(status == s ? s.color : TickerTheme.textTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(status == s ? s.color.opacity(0.2) : TickerTheme.borderSub, lineWidth: 1))
                            }
                            .buttonStyle(.plain).animation(.spring(response: 0.2), value: status)
                        }
                    }
                }

                // Renk
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Renk (kapak yüklenemezse)", icon: "circle.hexagongrid")
                    HStack(spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button { selectedColorHex = hex } label: {
                                ZStack {
                                    Circle().fill(Color(hex: hex)).frame(width: 22, height: 22)
                                    if selectedColorHex == hex {
                                        Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2).frame(width: 22, height: 22)
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
        .background(Color(hex: "#161618"))
        .task { await loadCover() }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
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
        let book = BookItem(title: olBook.title, author: olBook.author,
                            totalPages: olBook.numberOfPagesMedian ?? 0,
                            status: status, hexColor: selectedColorHex)
        book.coverImageData = coverData
        book.isbn = olBook.isbn?.first ?? ""
        book.genre = olBook.genre
        book.publishYear = olBook.firstPublishYear ?? 0
        if status == .reading  { book.startDate  = Date() }
        if status == .finished { book.finishDate = Date() }
        context.insert(book); try? context.save(); dismiss()
    }
}
