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
    @State private var viewMode: ViewMode = .grid
    @State private var yearlyGoal = UserDefaults.standard.integer(forKey: "yearlyBookGoal") == 0
        ? 12 : UserDefaults.standard.integer(forKey: "yearlyBookGoal")
    @State private var showingGoalEdit = false
    @State private var goalText = ""

    enum ViewMode { case grid, list }

    private var filteredBooks: [BookItem] {
        var r = books
        if let s = selectedStatus { r = r.filter { $0.status == s } }
        if let col = selectedCollection { r = r.filter { $0.collections.contains { $0.id == col.id } } }
        return r
    }

    private var finishedThisYear: Int {
        let y = Calendar.current.component(.year, from: Date())
        return books.filter { $0.status == .finished && ($0.finishDate.map { Calendar.current.component(.year, from: $0) == y } ?? false) }.count
    }
    private var currentStreak: Int { ReadingStreakHelper.currentStreak(sessions: allSessions) }
    private var last7Days: [(Date, Int)] { ReadingStreakHelper.last7Days(sessions: allSessions) }
    private var totalPagesRead: Int { allSessions.reduce(0) { $0 + $1.pagesRead } }

    var body: some View {
        HSplitView {
            bookSidebar.frame(minWidth: 200, maxWidth: 240)
            mainContent
        }
        .background(TickerTheme.bgApp)
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

    // MARK: - Sidebar

    private var bookSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Streak kartı
            if currentStreak > 0 {
                streakCard.padding(12)
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            }

            // Mini istatistikler
            HStack(spacing: 0) {
                miniStat(value: "\(finishedThisYear)", label: "Bu yıl", color: TickerTheme.green)
                Rectangle().fill(TickerTheme.borderSub).frame(width: 1, height: 28)
                miniStat(value: "\(totalPagesRead)", label: "Sayfa", color: TickerTheme.blue)
                Rectangle().fill(TickerTheme.borderSub).frame(width: 1, height: 28)
                miniStat(value: "\(books.filter { $0.status == .reading }.count)", label: "Aktif", color: TickerTheme.orange)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)

            // Yıllık hedef
            goalBar.padding(.horizontal, 12).padding(.bottom, 8)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Filtreler
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    // Tümü
                    filterRow(label: "Tüm Kitaplar", icon: "books.vertical",
                               count: books.count,
                               isSelected: selectedStatus == nil && selectedCollection == nil) {
                        selectedStatus = nil; selectedCollection = nil
                    }

                    ForEach(ReadingStatus.allCases, id: \.self) { s in
                        filterRow(label: s.label, icon: s.icon, color: s.color,
                                   count: books.filter { $0.status == s }.count,
                                   isSelected: selectedStatus == s && selectedCollection == nil) {
                            selectedStatus = s; selectedCollection = nil
                        }
                    }

                    if !collections.isEmpty {
                        sidebarSectionLabel("KOLEKSİYONLAR")
                        ForEach(collections) { col in
                            filterRow(label: col.name, icon: col.icon,
                                       color: Color(hex: col.hexColor),
                                       count: col.books.count,
                                       isSelected: selectedCollection?.id == col.id) {
                                selectedCollection = col; selectedStatus = nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
            }

            Spacer(minLength: 0)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            Button {
                showingCollections = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus").font(.system(size: 11))
                    Text("Koleksiyon Yönet").font(.system(size: 11))
                }
                .foregroundStyle(TickerTheme.textTertiary)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
            }
            .buttonStyle(.plain)
        }
        .background(TickerTheme.bgApp)
    }

    // MARK: - Streak kartı

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(TickerTheme.orange.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14)).foregroundStyle(TickerTheme.orange)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(currentStreak) günlük seri")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(TickerTheme.textPrimary)
                    Text("Okumaya devam et!")
                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                }
            }

            // 7 günlük bar
            let maxPages = max(last7Days.map { $0.1 }.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(last7Days, id: \.0) { date, pages in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(pages > 0 ? TickerTheme.orange : TickerTheme.bgPill)
                            .frame(
                                width: 16,
                                height: max(CGFloat(pages) / CGFloat(maxPages) * 24, pages > 0 ? 4 : 3)
                            )
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 8)).foregroundStyle(TickerTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 36)
        }
        .padding(10)
        .background(TickerTheme.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(TickerTheme.orange.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 14, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }

    private var goalBar: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(finishedThisYear)/\(yearlyGoal) kitap hedefi")
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                Spacer()
                Button {
                    goalText = "\(yearlyGoal)"; showingGoalEdit = true
                } label: {
                    Image(systemName: "pencil").font(.system(size: 9))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TickerTheme.bgPill).frame(height: 4)
                    Capsule().fill(TickerTheme.blue)
                        .frame(
                            width: geo.size.width * min(Double(finishedThisYear) / Double(yearlyGoal), 1.0),
                            height: 4
                        )
                        .animation(.spring(response: 0.5), value: finishedThisYear)
                }
            }
            .frame(height: 4)
        }
    }

    @ViewBuilder
    private func filterRow(label: String, icon: String, color: Color = TickerTheme.textTertiary,
                            count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon).font(.system(size: 11))
                    .foregroundStyle(isSelected ? TickerTheme.textPrimary : color)
                    .frame(width: 14)
                Text(label).font(.system(size: 12))
                    .foregroundStyle(isSelected ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                Spacer()
                if count > 0 {
                    Text("\(count)").font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.07) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sidebarSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium)).foregroundStyle(TickerTheme.textTertiary)
            .kerning(0.5).padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 2)
    }

    // MARK: - Ana içerik

    private var mainContent: some View {
        VStack(spacing: 0) {
            mainTopBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if filteredBooks.isEmpty {
                emptyState
            } else if viewMode == .grid {
                bookGrid
            } else {
                bookList
            }
        }
        .background(TickerTheme.bgApp)
    }

    private var mainTopBar: some View {
        HStack {
            Text(selectedCollection?.name ?? selectedStatus?.label ?? "Kitaplık")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)

            Text("\(filteredBooks.count)")
                .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(TickerTheme.bgPill).clipShape(Capsule())

            Spacer()

            // Grid / List
            HStack(spacing: 2) {
                ForEach([(ViewMode.grid, "square.grid.2x2"), (ViewMode.list, "list.bullet")], id: \.1) { mode, icon in
                    Button { viewMode = mode } label: {
                        Image(systemName: icon).font(.system(size: 11))
                            .frame(width: 24, height: 24)
                            .background(viewMode == mode ? TickerTheme.bgPill : Color.clear)
                            .foregroundStyle(viewMode == mode ? TickerTheme.textPrimary : TickerTheme.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2).background(TickerTheme.bgCard).clipShape(RoundedRectangle(cornerRadius: 7))

            Button { showingSearch = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass").font(.system(size: 10))
                    Text("Ara").font(.system(size: 11))
                }
                .foregroundStyle(TickerTheme.textSecondary)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(TickerTheme.bgPill).clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(TickerTheme.borderMid, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { showingAddBook = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus").font(.system(size: 10))
                    Text("Ekle").font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(TickerTheme.blue).clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

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
        .listStyle(.plain).scrollContentBackground(.hidden)
        .background(TickerTheme.bgApp)
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
                            book.collections.append(col); try? context.save()
                        }
                    } label: { Label(col.name, systemImage: col.icon) }
                }
            }
        }
        Divider()
        Button(role: .destructive) {
            context.delete(book); try? context.save()
        } label: { Label("Sil", systemImage: "trash") }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(TickerTheme.textTertiary)
            VStack(spacing: 4) {
                Text("Kitaplık boş").font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TickerTheme.textSecondary)
                Text("API'den ara veya manuel ekle")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            HStack(spacing: 8) {
                Button { showingSearch = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass").font(.system(size: 11))
                        Text("Kitap Ara").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(TickerTheme.blue)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(TickerTheme.blue.opacity(0.12)).clipShape(Capsule())
                    .overlay(Capsule().stroke(TickerTheme.blue.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button { showingAddBook = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 11))
                        Text("Manuel Ekle").font(.system(size: 12))
                    }
                    .foregroundStyle(TickerTheme.textSecondary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(TickerTheme.bgPill).clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity).background(TickerTheme.bgApp)
    }
}

// MARK: - Liste satırı

struct BookListRow: View {
    let book: BookItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Kapak
            Group {
                if let img = book.coverImage {
                    Image(nsImage: img).resizable().scaledToFill()
                        .frame(width: 38, height: 52).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5).fill(Color(hex: book.hexColor).opacity(0.15))
                        Image(systemName: "book.closed.fill").font(.system(size: 14))
                            .foregroundStyle(Color(hex: book.hexColor).opacity(0.4))
                    }
                    .frame(width: 38, height: 52)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke(TickerTheme.borderSub, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary).lineLimit(1)
                if !book.author.isEmpty {
                    Text(book.author).font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary).lineLimit(1)
                }
                if book.status == .reading && book.totalPages > 0 {
                    HStack(spacing: 6) {
                        Text("\(book.currentPage)/\(book.totalPages)")
                            .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                        ZStack(alignment: .leading) {
                            Capsule().fill(TickerTheme.bgPill).frame(width: 60, height: 3)
                            Capsule().fill(Color(hex: book.hexColor))
                                .frame(width: 60 * book.progressPercent, height: 3)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: book.status.icon).font(.system(size: 9))
                    Text(book.status.label).font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(book.status.color)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(book.status.color.opacity(0.1)).clipShape(Capsule())

                if book.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= book.rating ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(i <= book.rating ? Color(hex: "#FBBF24") : TickerTheme.textTertiary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? TickerTheme.bgCardHover : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .padding(.horizontal, 12).padding(.bottom, 2)
    }
}
