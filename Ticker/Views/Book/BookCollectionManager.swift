import SwiftUI
import SwiftData

struct BookCollectionManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BookCollection.sortOrder) private var collections: [BookCollection]

    @State private var newName = ""
    @State private var newColorHex = "#4C8EF7"
    @State private var newIcon = "books.vertical"
    @FocusState private var focused: Bool

    let collectionIcons = [
        "books.vertical", "bookmark.fill", "heart.fill", "star.fill",
        "flame.fill", "trophy.fill", "graduationcap.fill", "brain.head.profile",
        "globe", "moon.fill", "sun.max.fill", "leaf.fill"
    ]

    let colorOptions = [
        "#5B9CF6", "#34D399", "#FB923C", "#F472B6",
        "#C084FC", "#FBBF24", "#2DD4BF", "#FB7185",
        "#818CF8", "#A3E635", "#E879F9", "#94A3B8"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Koleksiyonlar").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            VStack(spacing: 14) {
                // Yeni koleksiyon
                VStack(alignment: .leading, spacing: 10) {
                    Text("Yeni Koleksiyon")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)

                    TextField("Koleksiyon adı (Favori, Klasikler...)", text: $newName)
                        .textFieldStyle(.plain).font(.system(size: 13))
                        .padding(9).background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .focused($focused).onSubmit { addCollection() }

                    // İkon seçici
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(collectionIcons, id: \.self) { icon in
                                Button { newIcon = icon } label: {
                                    Image(systemName: icon).font(.system(size: 14))
                                        .frame(width: 34, height: 34)
                                        .background(newIcon == icon
                                                    ? Color(hex: newColorHex).opacity(0.2)
                                                    : Color(nsColor: .controlBackgroundColor))
                                        .foregroundStyle(newIcon == icon ? Color(hex: newColorHex) : .secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(newIcon == icon ? Color(hex: newColorHex).opacity(0.4) : Color.clear, lineWidth: 1.5))
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.2), value: newIcon)
                            }
                        }
                    }

                    // Renk seçici
                    HStack(spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button { newColorHex = hex } label: {
                                ZStack {
                                    Circle().fill(Color(hex: hex).opacity(0.2)).frame(width: 28, height: 28)
                                    Circle().fill(Color(hex: hex)).frame(width: newColorHex == hex ? 18 : 14, height: newColorHex == hex ? 18 : 14)
                                    if newColorHex == hex {
                                        Image(systemName: "checkmark").font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain).animation(.spring(response: 0.2), value: newColorHex)
                        }
                    }

                    Button("Koleksiyon Oluştur") { addCollection() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: newColorHex))
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(14)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)

            if !collections.isEmpty {
                Divider().opacity(0.4)
                List {
                    ForEach(collections) { col in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(Color(hex: col.hexColor).opacity(0.15)).frame(width: 32, height: 32)
                                Image(systemName: col.icon).font(.system(size: 14))
                                    .foregroundStyle(Color(hex: col.hexColor))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col.name).font(.system(size: 13, weight: .medium))
                                Text("\(col.books.count) kitap").font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear).listRowSeparator(.hidden).padding(.vertical, 3)
                    }
                    .onDelete { indexSet in
                        for i in indexSet { context.delete(collections[i]) }
                        try? context.save()
                    }
                    .onMove { from, to in
                        var reordered = collections
                        reordered.move(fromOffsets: from, toOffset: to)
                        for (i, col) in reordered.enumerated() { col.sortOrder = i }
                        try? context.save()
                    }
                }
                .listStyle(.plain).scrollContentBackground(.hidden).frame(maxHeight: 200)
            }
        }
        .frame(width: 400, height: 580)
        .background(GlassView(material: .hudWindow))
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
