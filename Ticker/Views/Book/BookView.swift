import SwiftUI
import SwiftData

struct BookView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BookItem.createdAt, order: .reverse) private var books: [BookItem]
    @Query(sort: \BookCollection.sortOrder) private var collections: [BookCollection]
    @Query private var allSessions: [ReadingSession]

    @State private var selectedStatus: ReadingStatus? = nil
    @State private var selectedCollection: BookCollection? = nil
    @State private var showingAddBook = false
    @State private var showingSearch = false
    @State private var showingCollections = false
    @State private var selectedBook: BookItem? = nil
    @State private var yearlyGoal: Int = UserDefaults.standard.integer(forKey: "yearlyBookGoal") == 0
        ? 12 : UserDefaults.standard.integer(forKey: "yearlyBookGoal")
    @State private var showingGoalEdit = false
    @State private var goalText = ""
    @State private var viewMode: BookViewMode = .grid

    enum BookViewMode { case grid, list }

    var filteredBooks: [BookItem] {
        var result = books
        if let s = selectedStatus { result = result.filter { $0.status == s } }
        if let col = selectedCollection { result = result.filter { $0.collections.contains { $0.id == col.id } } }
        return result
    }

    var finishedThisYear: Int {
        let year = Calendar.current.component(.year, from: Date())
        return books.filter {
            $0.status == .finished &&
            ($0.finishDate.map { Calendar.current.component(.year, from: $0) == year } ?? false)
        }.count
    }

    var currentStreak: Int { ReadingStreakHelper.currentStreak(sessions: allSessions) }
    var last7Days: [(Date, Int)] { ReadingStreakHelper.last7DaysSessions(sessions: allSessions) }
    var totalPagesRead: Int { allSessions.reduce(0) { $0 + $1.pagesRead } }

    var currentlyReading: [BookItem] { books.filter { $0.status == .reading } }
    var queueBooks: [BookItem] { books.filter { $0.status == .queue }.sorted { $0.queueOrder < $1.queueOrder } }

    var body: some View {
        HSplitView {
            // Sol sidebar
            bookSidebar
                .frame(minWidth: 200, maxWidth: 240)

            // Ana içerik
            VStack(spacing: 0) {
                topBar
                Divider().opacity(0.3)

                if filteredBooks.isEmpty {
                    emptyState
                } else if viewMode == .grid {
                    bookGrid
                } else {
                    bookList
                }
            }
        }
        .sheet(isPresented: $showingAddBook) { AddBookView() }
        .sheet(isPresented: $showingSearch) { BookSearchView() }
        .sheet(isPresented: $showingCollections) { BookCollectionManagerView() }
        .sheet(item: $selectedBook) { book in BookDetailView(book: book) }
        .alert("Yıllık hedef", isPresented: $showingGoalEdit) {
            TextField("Kitap sayısı", text: $goalText)
            Button("Kaydet") {
                if let n = Int(goalText), n > 0 {
                    yearlyGoal = n
                    UserDefaults.standard.set(n, forKey: "yearlyBookGoal")
                }
            }
            Button("İptal", role: .cancel) {}
        }
    }

    // MARK: - Sol sidebar

    private var bookSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Streak + istatistik
            VStack(alignment: .leading, spacing: 10) {
                if currentStreak > 0 {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.orange.opacity(0.15)).frame(width: 36, height: 36)
                            Text("🔥").font(.system(size: 18))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(currentStreak) günlük seri")
                                .font(.system(size: 13, weight: .bold))
                            Text("Okumaya devam et!")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // 7 günlük aktivite
                    HStack(spacing: 3) {
                        ForEach(last7Days, id: \.0) { date, pages in
                            VStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(pages > 0 ? Color.orange : Color.secondary.opacity(0.15))
                                    .frame(width: 18, height: pages > 0 ? min(CGFloat(pages) / 5 + 8, 28) : 8)
                                Text(date.formatted(.dateTime.weekday(.narrow)))
                                    .font(.system(size: 8)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .bottom)
                        }
                    }
                    .frame(height: 40)
                }

                // Mini istatistikler
                HStack(spacing: 0) {
                    miniStat(value: "\(finishedThisYear)", label: "Bu yıl", color: .green)
                    Divider().frame(height: 28)
                    miniStat(value: "\(totalPagesRead)", label: "Sayfa", color: .blue)
                    Divider().frame(height: 28)
                    miniStat(value: "\(books.filter { $0.status == .reading }.count)", label: "Aktif", color: .orange)
                }
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Yıllık hedef
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hedef: \(finishedThisYear)/\(yearlyGoal)")
                            .font(.system(size: 11, weight: .semibold))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.blue.opacity(0.12)).frame(height: 5)
                                Capsule().fill(Color.blue)
                                    .frame(width: geo.size.width * min(Double(finishedThisYear) / Double(yearlyGoal), 1.0), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    Button { goalText = "\(yearlyGoal)"; showingGoalEdit = true } label: {
                        Image(systemName: "pencil").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Divider().opacity(0.3)

            // Filtreler
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    // Tümü
                    sidebarFilterRow(label: "Tüm Kitaplar", icon: "books.vertical",
                                     count: books.count, isSelected: selectedStatus == nil && selectedCollection == nil) {
                        selectedStatus = nil; selectedCollection = nil
                    }

                    // Durumlar
                    ForEach(ReadingStatus.allCases, id: \.self) { s in
                        let count = books.filter { $0.status == s }.count
                        sidebarFilterRow(label: s.label, icon: s.icon, color: s.color,
                                         count: count, isSelected: selectedStatus == s && selectedCollection == nil) {
                            selectedStatus = s; selectedCollection = nil
                        }
                    }

                    if !collections.isEmpty {
                        Text("KOLEKSIYONLAR")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10).padding(.top, 12).padding(.bottom, 4)

                        ForEach(collections) { col in
                            let count = col.books.count
                            sidebarFilterRow(label: col.name, icon: col.icon,
                                             color: Color(hex: col.hexColor),
                                             count: count,
                                             isSelected: selectedCollection?.id == col.id) {
                                selectedCollection = col; selectedStatus = nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
            }

            Spacer()

            // Koleksiyon yönetimi butonu
            Button {
                showingCollections = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus").font(.system(size: 12))
                    Text("Koleksiyon Yönet").font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            Divider().opacity(0.3)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    @ViewBuilder
    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 14, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    @ViewBuilder
    private func sidebarFilterRow(label: String, icon: String, color: Color = .secondary,
                                   count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 16)
                Text(label).font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : .primary)
                Spacer()
                Text("\(count)").font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(isSelected ? Color.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text(selectedCollection?.name ?? selectedStatus?.label ?? "Kitaplık")
                .font(.system(size: 18, weight: .bold))
            Text("\(filteredBooks.count)")
                .font(.system(size: 13)).foregroundStyle(.secondary)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())

            Spacer()

            HStack(spacing: 8) {
                // Grid / List toggle
                HStack(spacing: 2) {
                    ForEach([("square.grid.2x2", BookViewMode.grid), ("list.bullet", BookViewMode.list)],
                            id: \.0) { icon, mode in
                        Button { viewMode = mode } label: {
                            Image(systemName: icon).font(.system(size: 12))
                                .frame(width: 26, height: 26)
                                .background(viewMode == mode ? Color.blue : Color.clear)
                                .foregroundStyle(viewMode == mode ? .white : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 7))

                Button { showingSearch = true } label: {
                    Label("Ara", systemImage: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered).controlSize(.small)

                Button { showingAddBook = true } label: {
                    Label("Manuel Ekle", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent).tint(.blue).controlSize(.small)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Grid

    private var bookGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 16)],
                spacing: 20
            ) {
                ForEach(filteredBooks) { book in
                    BookCard(book: book)
                        .onTapGesture { selectedBook = book }
                        .contextMenu { bookContextMenu(book) }
                }
            }
            .padding(16)
        }
    }

    // MARK: - List

    private var bookList: some View {
        List {
            ForEach(filteredBooks) { book in
                BookListRow(book: book)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onTapGesture { selectedBook = book }
                    .contextMenu { bookContextMenu(book) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func bookContextMenu(_ book: BookItem) -> some View {
        Menu("Durumu Değiştir") {
            ForEach(ReadingStatus.allCases, id: \.self) { s in
                Button {
                    book.status = s
                    if s == .reading  && book.startDate  == nil { book.startDate  = Date() }
                    if s == .finished && book.finishDate == nil { book.finishDate = Date() }
                    try? context.save()
                } label: { Label(s.label, systemImage: s.icon) }
            }
        }
        if !collections.isEmpty {
            Menu("Koleksiyona Ekle") {
                ForEach(collections) { col in
                    Button {
                        if !book.collections.contains(where: { $0.id == col.id }) {
                            book.collections.append(col)
                            try? context.save()
                        }
                    } label: {
                        Label(col.name, systemImage: col.icon)
                    }
                }
            }
        }
        Divider()
        Button(role: .destructive) {
            context.delete(book); try? context.save()
        } label: { Label("Sil", systemImage: "trash") }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color.blue.opacity(0.06)).frame(width: 80, height: 80)
                Image(systemName: "books.vertical")
                    .font(.system(size: 30, weight: .light)).foregroundStyle(.secondary.opacity(0.4))
            }
            Text("Henüz kitap yok").font(.system(size: 16, weight: .medium)).foregroundStyle(.primary.opacity(0.6))
            Text("API'den ara veya manuel ekle")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button { showingSearch = true } label: {
                    Label("Kitap Ara", systemImage: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent).tint(.blue).controlSize(.regular)
                Button { showingAddBook = true } label: {
                    Label("Manuel Ekle", systemImage: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered).controlSize(.regular)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Kitap list satırı

struct BookListRow: View {
    let book: BookItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Kapak
            Group {
                if let img = book.coverImage {
                    Image(nsImage: img).resizable().scaledToFill()
                        .frame(width: 40, height: 56).clipped().clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: book.hexColor).opacity(0.2))
                        .frame(width: 40, height: 56)
                        .overlay(Image(systemName: "book.closed").font(.system(size: 14))
                            .foregroundStyle(Color(hex: book.hexColor).opacity(0.5)))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text(book.author).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)

                if book.status == .reading && book.totalPages > 0 {
                    HStack(spacing: 6) {
                        Text("\(book.currentPage)/\(book.totalPages) s.")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.secondary.opacity(0.12)).frame(height: 3)
                                Capsule().fill(Color(hex: book.hexColor))
                                    .frame(width: geo.size.width * book.progressPercent, height: 3)
                            }
                        }
                        .frame(width: 80, height: 3)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: book.status.icon).font(.system(size: 10))
                    Text(book.status.label).font(.system(size: 10))
                }
                .foregroundStyle(book.status.color)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(book.status.color.opacity(0.1))
                .clipShape(Capsule())

                if book.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= book.rating ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(i <= book.rating ? .yellow : .secondary.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovered ? 0.7 : 0.4))
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .padding(.horizontal, 12).padding(.bottom, 4)
    }
}
