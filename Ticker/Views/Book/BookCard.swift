import SwiftUI

struct BookCard: View {
    let book: BookItem
    @State private var isHovered = false

    private let cardWidth: CGFloat = 140
    private let coverHeight: CGFloat = 196

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Kapak
            ZStack(alignment: .bottom) {
                // Kapak görseli
                if let img = book.coverImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: coverHeight)
                        .clipped()
                } else {
                    // Kapak yok — güzel placeholder
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(hex: book.hexColor).opacity(0.6),
                                Color(hex: book.hexColor).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(spacing: 8) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(book.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .padding(.horizontal, 8)
                        }
                    }
                    .frame(width: cardWidth, height: coverHeight)
                }

                // Alt gradient overlay
                if book.status == .reading {
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(height: 50)
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color(hex: book.hexColor))
                                .frame(width: geo.size.width * book.progressPercent, height: 3)
                        }
                        .frame(height: 3)
                    }
                }

                // Durum rozeti
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: book.status.icon).font(.system(size: 8))
                            Text(book.status.label).font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(book.status.color)
                        .clipShape(Capsule())
                        .padding(6)
                    }
                    Spacer()
                }
            }
            .frame(width: cardWidth, height: coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color(hex: book.hexColor).opacity(isHovered ? 0.3 : 0.1),
                    radius: isHovered ? 12 : 4, y: isHovered ? 6 : 2)

            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .frame(width: cardWidth, alignment: .leading)

                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if book.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= book.rating ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(i <= book.rating ? .yellow : .secondary.opacity(0.25))
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
        .frame(width: cardWidth)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
    }
}
