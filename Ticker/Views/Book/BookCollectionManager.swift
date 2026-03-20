import SwiftUI
import SwiftData

struct BookCollectionManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BookCollection.sortOrder) private var collections: [BookCollection]

    @State private var newName = ""
    @State private var newColorHex = "#3B82F6"
    @State private var newIcon = "books.vertical"
    @State private var deleteConfirm: BookCollection? = nil
    @FocusState private var focused: Bool

    private let icons = [
        "books.vertical","bookmark.fill","heart.fill","star.fill",
        "flame.fill","trophy.fill","graduationcap.fill","brain.head.profile",
        "globe","moon.fill","sun.max.fill","leaf.fill"
    ]
    private let colors = [
        "#3B82F6","#34D399","#FB923C","#F472B6",
        "#C084FC","#FBBF24","#2DD4BF","#FB7185",
        "#818CF8","#A3E635","#94A3B8","#E879F9"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(Color(hex: newColorHex)).frame(width: 10, height: 10)
                Text("Koleksiyonlar")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    // Form
                    VStack(alignment: .leading, spacing: 12) {
                        // Ad
                        VStack(alignment: .leading, spacing: 5) {
                            sectionLabel("Koleksiyon adı", icon: "tag")
                            TextField("Favoriler, Klasikler...", text: $newName)
                                .textFieldStyle(.plain).font(.system(size: 13))
                                .foregroundStyle(TickerTheme.textPrimary).focused($focused)
                                .padding(9).background(TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .onSubmit { addCollection() }
                        }

                        // İkon
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("İkon", icon: "square.grid.2x2")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button { newIcon = icon } label: {
                                            Image(systemName: icon).font(.system(size: 14))
                                                .frame(width: 34, height: 34)
                                                .background(newIcon == icon
                                                            ? Color(hex: newColorHex).opacity(0.15) : TickerTheme.bgPill)
                                                .foregroundStyle(newIcon == icon
                                                                 ? Color(hex: newColorHex) : TickerTheme.textTertiary)
                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                                .overlay(RoundedRectangle(cornerRadius: 7)
                                                    .stroke(newIcon == icon
                                                            ? Color(hex: newColorHex).opacity(0.3) : TickerTheme.borderSub, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain).animation(.spring(response: 0.2), value: newIcon)
                                    }
                                }
                            }
                        }

                        // Renk
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                sectionLabel("Renk", icon: "circle.hexagongrid")
                                Spacer()
                                Circle().fill(Color(hex: newColorHex)).frame(width: 12, height: 12)
                            }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                                ForEach(colors, id: \.self) { hex in
                                    Button { newColorHex = hex } label: {
                                        ZStack {
                                            Circle().fill(Color(hex: hex).opacity(0.2)).frame(width: 28, height: 28)
                                            Circle().fill(Color(hex: hex))
                                                .frame(width: newColorHex == hex ? 18 : 14,
                                                       height: newColorHex == hex ? 18 : 14)
                                            if newColorHex == hex {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain).animation(.spring(response: 0.2), value: newColorHex)
                                }
                            }
                        }

                        // Oluştur
                        Button { addCollection() } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus").font(.system(size: 11))
                                Text("Koleksiyon Oluştur").font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(newName.isEmpty ? TickerTheme.textTertiary : Color(hex: newColorHex))
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(newName.isEmpty ? TickerTheme.bgPill : Color(hex: newColorHex).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(18)

                    // Mevcut koleksiyonlar
                    if !collections.isEmpty {
                        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                        sectionLabel("Koleksiyonlar", icon: "list.bullet")
                            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 6)

                        VStack(spacing: 0) {
                            ForEach(collections) { col in
                                collectionRow(col)
                                if col.id != collections.last?.id {
                                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                                        .padding(.leading, 18)
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .frame(width: 400, height: 620)
        .background(Color(hex: "#161618"))
        // ✅ Silme onayı
        .alert("Koleksiyonu sil?", isPresented: .constant(deleteConfirm != nil)) {
            Button("Sil", role: .destructive) {
                if let col = deleteConfirm { context.delete(col); try? context.save() }
                deleteConfirm = nil
            }
            Button("İptal", role: .cancel) { deleteConfirm = nil }
        } message: {
            if let col = deleteConfirm {
                Text("\"\(col.name)\" koleksiyonu silinecek. Kitaplar etkilenmez.")
            }
        }
    }

    @ViewBuilder
    private func collectionRow(_ col: BookCollection) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color(hex: col.hexColor).opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: col.icon).font(.system(size: 13))
                    .foregroundStyle(Color(hex: col.hexColor))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(col.name).font(.system(size: 13, weight: .medium)).foregroundStyle(TickerTheme.textPrimary)
                Text("\(col.books.count) kitap").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
            }
            Spacer()

            // ✅ Explicit trash butonu
            Button { deleteConfirm = col } label: {
                Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(TickerTheme.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.vertical, 9)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func addCollection() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (collections.map { $0.sortOrder }.max() ?? -1) + 1
        let col = BookCollection(name: trimmed, icon: newIcon, hexColor: newColorHex, sortOrder: order)
        context.insert(col); try? context.save()
        newName = ""; focused = true
    }
}
