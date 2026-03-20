import SwiftUI
import SwiftData

struct BookView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BookItem.createdAt, order: .reverse) private var books: [BookItem]

    @State private var selectedStatus: ReadingStatus? = nil
    @State private var showingAddBook = false
    @State private var selectedBook: BookItem? = nil
    @State private var yearlyGoal: Int = UserDefaults.standard.integer(forKey: "yearlyBookGoal") == 0
        ? 12 : UserDefaults.standard.integer(forKey: "yearlyBookGoal")
    @State private var showingGoalEdit = false
    @State private var goalText = ""

    var filteredBooks: [BookItem] {
        guard let s = selectedStatus else { return books }
        return books.filter { $0.status == s }
    }

    var finishedThisYear: Int {
        let year = Calendar.current.component(.year, from: Date())
        return books.filter {
            $0.status == .finished &&
            ($0.finishDate.map { Calendar.current.component(.year, from: $0) == year } ?? false)
        }.count
    }

    var goalProgress: Double {
        guard yearlyGoal > 0 else { return 0 }
        return min(Double(finishedThisYear) / Double(yearlyGoal), 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kitaplık")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button { showingAddBook = true } label: {
                    Label("Kitap Ekle", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 20) {

                    // Yıllık hedef
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(Calendar.current.component(.year, from: Date())) Okuma Hedefi")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(finishedThisYear)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(.blue)
                                    Text("/ \(yearlyGoal) kitap")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                goalText = "\(yearlyGoal)"
                                showingGoalEdit = true
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width * goalProgress, height: 8)
                                    .animation(.spring(response: 0.5), value: goalProgress)
                            }
                        }
                        .frame(height: 8)

                        HStack(spacing: 16) {
                            ForEach(ReadingStatus.allCases, id: \.self) { status in
                                let count = books.filter { $0.status == status }.count
                                HStack(spacing: 4) {
                                    Image(systemName: status.icon)
                                        .font(.system(size: 11))
                                        .foregroundStyle(status.color)
                                    Text("\(count) \(status.label)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)

                    // Filtreler
                    HStack(spacing: 8) {
                        filterPill(nil, label: "Tümü", count: books.count)
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            filterPill(status, label: status.label,
                                       count: books.filter { $0.status == status }.count)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Grid
                    if filteredBooks.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary.opacity(0.4))
                            Text("Henüz kitap yok")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)],
                            spacing: 16
                        ) {
                            ForEach(filteredBooks) { book in
                                BookCard(book: book)
                                    .onTapGesture { selectedBook = book }
                                    .contextMenu {
                                        Menu("Durum") {
                                            ForEach(ReadingStatus.allCases, id: \.self) { s in
                                                Button {
                                                    book.status = s
                                                    if s == .reading && book.startDate == nil { book.startDate = Date() }
                                                    if s == .finished && book.finishDate == nil { book.finishDate = Date() }
                                                    try? context.save()
                                                } label: { Label(s.label, systemImage: s.icon) }
                                            }
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            context.delete(book); try? context.save()
                                        } label: { Label("Sil", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showingAddBook) { AddBookView() }
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

    @ViewBuilder
    private func filterPill(_ status: ReadingStatus?, label: String, count: Int) -> some View {
        let isSelected = selectedStatus == status
        Button {
            withAnimation(.spring(response: 0.2)) { selectedStatus = status }
        } label: {
            HStack(spacing: 4) {
                Text(label).font(.system(size: 11, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 10))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(nsColor: .controlBackgroundColor))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .foregroundStyle(isSelected ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Kitap Kartı (kapak boyutu düzeltildi)

struct BookCard: View {
    let book: BookItem
    @State private var isHovered = false

    private let cardWidth: CGFloat = 160
    private let coverHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kapak — sabit boyutlu kare konteyner
            ZStack(alignment: .bottomTrailing) {
                if let img = book.coverImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()                          // fill ile doldur
                        .frame(width: cardWidth, height: coverHeight)
                        .clipped()                              // taşanı kes
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: book.hexColor).opacity(0.15))
                        .frame(width: cardWidth, height: coverHeight)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Color(hex: book.hexColor).opacity(0.5))
                                Text(book.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color(hex: book.hexColor).opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal, 8)
                            }
                        )
                }

                // Durum rozeti
                Text(book.status.label)
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(book.status.color)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
            }
            .frame(width: cardWidth, height: coverHeight)   // dış frame de sabit

            // Bilgiler
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .frame(width: cardWidth, alignment: .leading)

                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if book.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= book.rating ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(i <= book.rating ? .yellow : .secondary.opacity(0.3))
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovered ? 0.8 : 0.4))
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.2), value: isHovered)
    }
}
