import SwiftUI

struct BookCard: View {
    let book: BookItem
    @State private var isHovered = false

    private let cardWidth: CGFloat = 140
    private let coverHeight: CGFloat = 196

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverView
            infoView
        }
        .frame(width: cardWidth)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
    }

    // MARK: - Kapak

    private var coverView: some View {
        ZStack(alignment: .topTrailing) {
            // Görsel
            Group {
                if let img = book.coverImage {
                    Image(nsImage: img)
                        .resizable().scaledToFill()
                        .frame(width: cardWidth, height: coverHeight)
                        .clipped()
                } else {
                    ZStack {
                        Color(hex: book.hexColor).opacity(0.18)
                        VStack(spacing: 10) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 30, weight: .light))
                                .foregroundStyle(Color(hex: book.hexColor).opacity(0.5))
                            Text(book.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(TickerTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 10)
                        }
                    }
                    .frame(width: cardWidth, height: coverHeight)
                }
            }

            // Durum rozeti
            statusBadge
                .padding(7)

            // Okuma progress çubuğu (altta)
            if book.status == .reading && book.totalPages > 0 {
                VStack {
                    Spacer()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.black.opacity(0.4)).frame(height: 3)
                            Rectangle()
                                .fill(Color(hex: book.hexColor))
                                .frame(width: geo.size.width * book.progressPercent, height: 3)
                                .animation(.spring(response: 0.5), value: book.progressPercent)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .frame(width: cardWidth, height: coverHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TickerTheme.borderSub, lineWidth: 1)
        )
        .shadow(
            color: Color(hex: book.hexColor).opacity(isHovered ? 0.25 : 0.08),
            radius: isHovered ? 14 : 4, y: isHovered ? 6 : 2
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: book.status.icon).font(.system(size: 7, weight: .semibold))
            Text(book.status.label).font(.system(size: 8, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(book.status.color.opacity(0.85))
        .clipShape(Capsule())
    }

    // MARK: - Bilgi

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)
                .lineLimit(2)
                .frame(width: cardWidth, alignment: .leading)

            if !book.author.isEmpty {
                Text(book.author)
                    .font(.system(size: 10))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .lineLimit(1)
            }

            if book.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= book.rating ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundStyle(i <= book.rating
                                             ? Color(hex: "#FBBF24")
                                             : TickerTheme.textTertiary)
                    }
                }
            }

            if book.status == .reading && book.totalPages > 0 {
                Text("\(Int(book.progressPercent * 100))% tamamlandı")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: book.hexColor))
            }
        }
        .padding(.top, 8).padding(.horizontal, 2).padding(.bottom, 6)
    }
}
