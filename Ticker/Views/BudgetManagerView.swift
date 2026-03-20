import SwiftUI
import SwiftData

// MARK: - Bütçe renk paleti

struct BudgetColor: Identifiable, Hashable {
    let id: String
    let hex: String
    let label: String

    var color: Color { Color(hex: hex) }

    static let palette: [BudgetColor] = [
        // Maviler
        BudgetColor(id: "sky",      hex: "#5B9CF6", label: "Gökyüzü"),
        BudgetColor(id: "ocean",    hex: "#2DD4BF", label: "Okyanus"),
        BudgetColor(id: "indigo",   hex: "#818CF8", label: "İndigo"),

        // Yeşiller
        BudgetColor(id: "mint",     hex: "#34D399", label: "Nane"),
        BudgetColor(id: "lime",     hex: "#A3E635", label: "Limon"),
        BudgetColor(id: "forest",   hex: "#4ADE80", label: "Orman"),

        // Kırmızı / Turuncu
        BudgetColor(id: "coral",    hex: "#FB7185", label: "Mercan"),
        BudgetColor(id: "sunset",   hex: "#FB923C", label: "Günbatımı"),
        BudgetColor(id: "amber",    hex: "#FBBF24", label: "Kehribar"),

        // Mor / Pembe
        BudgetColor(id: "violet",   hex: "#C084FC", label: "Viyole"),
        BudgetColor(id: "rose",     hex: "#F472B6", label: "Gül"),
        BudgetColor(id: "fuchsia",  hex: "#E879F9", label: "Fuşya"),

        // Nötr
        BudgetColor(id: "slate",    hex: "#94A3B8", label: "Arduvaz"),
        BudgetColor(id: "sand",     hex: "#D4A574", label: "Kum"),
        BudgetColor(id: "charcoal", hex: "#6B7280", label: "Kömür"),
    ]
}

// MARK: - Renk seçici grid

struct BudgetColorPicker: View {
    @Binding var selectedHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(BudgetColor.palette) { bc in
                let isSelected = selectedHex == bc.hex
                Button {
                    selectedHex = bc.hex
                } label: {
                    ZStack {
                        Circle()
                            .fill(bc.color.opacity(0.25))
                            .frame(width: 36, height: 36)
                        Circle()
                            .fill(bc.color)
                            .frame(width: isSelected ? 24 : 20, height: isSelected ? 24 : 20)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.2), value: isSelected)
                .help(bc.label)
            }
        }
    }
}

// MARK: - Kategori Yönetimi

struct BudgetCategoryManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]

    @State private var newName = ""
    @State private var newColorHex = BudgetColor.palette[0].hex
    @State private var newLimit = ""
    @State private var newIcon = "tag"
    @FocusState private var focused: Bool

    let categoryIcons = [
        "tag", "cart", "house", "car", "fork.knife",
        "tshirt", "pills", "gamecontroller", "airplane", "gift",
        "graduationcap", "film", "music.note", "dumbbell", "leaf"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Kategoriler").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            // Yeni kategori formu
            ScrollView {
                VStack(spacing: 14) {

                    // İsim + Limit
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Kategori adı")
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            TextField("Örn: Market", text: $newName)
                                .textFieldStyle(.plain).font(.system(size: 13))
                                .padding(8).background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .focused($focused).onSubmit { addCategory() }
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Aylık limit (₺)")
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            TextField("0", text: $newLimit)
                                .textFieldStyle(.plain).font(.system(size: 13))
                                .padding(8).background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .frame(width: 100)
                        }
                    }

                    // İkon seçici
                    VStack(alignment: .leading, spacing: 6) {
                        Text("İkon").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(categoryIcons, id: \.self) { icon in
                                    Button { newIcon = icon } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 14))
                                            .frame(width: 36, height: 36)
                                            .background(newIcon == icon
                                                        ? Color(hex: newColorHex).opacity(0.2)
                                                        : Color(nsColor: .controlBackgroundColor))
                                            .foregroundStyle(newIcon == icon
                                                             ? Color(hex: newColorHex)
                                                             : .secondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(newIcon == icon
                                                            ? Color(hex: newColorHex).opacity(0.5)
                                                            : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(response: 0.2), value: newIcon)
                                }
                            }
                        }
                    }

                    // Renk seçici
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Renk").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            Spacer()
                            // Seçili rengi önizle
                            HStack(spacing: 6) {
                                Circle().fill(Color(hex: newColorHex).opacity(0.2)).frame(width: 18, height: 18)
                                    .overlay(Circle().fill(Color(hex: newColorHex)).frame(width: 10, height: 10))
                                Text(BudgetColor.palette.first { $0.hex == newColorHex }?.label ?? "")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                        }
                        BudgetColorPicker(selectedHex: $newColorHex)
                    }

                    // Önizleme + Ekle butonu
                    HStack(spacing: 10) {
                        // Mini önizleme
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: newColorHex).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: newIcon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: newColorHex))
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(newName.isEmpty ? "Kategori adı" : newName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(newName.isEmpty ? .secondary : .primary)
                                if let limit = Double(newLimit.replacingOccurrences(of: ",", with: ".")), limit > 0 {
                                    Text(CurrencyHelper.format(limit) + " limit")
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: newColorHex).opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: newColorHex).opacity(0.2), lineWidth: 1)
                        )

                        Button("Ekle") { addCategory() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: newColorHex))
                            .font(.system(size: 13, weight: .medium))
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(16)
            }

            Divider().opacity(0.4)

            // Mevcut kategoriler
            if !categories.isEmpty {
                List {
                    ForEach(categories) { cat in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(Color(hex: cat.hexColor).opacity(0.15)).frame(width: 30, height: 30)
                                Image(systemName: cat.icon).font(.system(size: 13))
                                    .foregroundStyle(Color(hex: cat.hexColor))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.name).font(.system(size: 13, weight: .medium))
                                if cat.monthlyLimit > 0 {
                                    Text("Limit: \(CurrencyHelper.format(cat.monthlyLimit))")
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(cat.entries.count) işlem")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 3)
                    }
                    .onDelete { indexSet in
                        for i in indexSet { context.delete(categories[i]) }
                        try? context.save()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 220)
            }
        }
        .frame(width: 420, height: 680)
        .background(GlassView(material: .hudWindow))
    }

    private func addCategory() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let limit = Double(newLimit.replacingOccurrences(of: ",", with: ".")) ?? 0
        let cat = BudgetCategory(name: trimmed, hexColor: newColorHex, icon: newIcon, monthlyLimit: limit)
        context.insert(cat); try? context.save()
        newName = ""; newLimit = ""; focused = true
    }
}

// MARK: - Kart Yönetimi

struct BudgetCardManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BudgetCard.name) private var cards: [BudgetCard]

    @State private var newName = ""
    @State private var newLastFour = ""
    @State private var newColorHex = BudgetColor.palette[0].hex
    @State private var newIcon = "creditcard"
    @FocusState private var focused: Bool

    let cardIcons = ["creditcard", "creditcard.fill", "banknote", "building.columns", "wallet.pass"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kartlar").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            VStack(spacing: 14) {
                // İsim + Son 4 hane
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Kart adı").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        TextField("Örn: Ziraat Visa", text: $newName)
                            .textFieldStyle(.plain).font(.system(size: 13))
                            .padding(8).background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .focused($focused)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Son 4 hane").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        TextField("0000", text: $newLastFour)
                            .textFieldStyle(.plain).font(.system(size: 13))
                            .padding(8).background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .frame(width: 80)
                    }
                }

                // İkon seçici
                HStack(spacing: 8) {
                    ForEach(cardIcons, id: \.self) { icon in
                        Button { newIcon = icon } label: {
                            Image(systemName: icon).font(.system(size: 16))
                                .frame(width: 44, height: 36)
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

                // Renk seçici
                VStack(alignment: .leading, spacing: 8) {
                    Text("Renk").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    BudgetColorPicker(selectedHex: $newColorHex)
                }

                // Önizleme kart + Ekle
                HStack(spacing: 10) {
                    // Kart önizleme
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: newColorHex).opacity(0.15))
                                .frame(width: 42, height: 28)
                            Image(systemName: newIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: newColorHex))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(newName.isEmpty ? "Kart adı" : newName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(newName.isEmpty ? .secondary : .primary)
                            if !newLastFour.isEmpty {
                                Text("·· \(newLastFour)")
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: newColorHex).opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: newColorHex).opacity(0.2), lineWidth: 1))

                    Button("Ekle") { addCard() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: newColorHex))
                        .font(.system(size: 13, weight: .medium))
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(16)

            Divider().opacity(0.4)

            if !cards.isEmpty {
                List {
                    ForEach(cards) { card in
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(hex: card.hexColor).opacity(0.15))
                                    .frame(width: 34, height: 24)
                                Image(systemName: card.icon).font(.system(size: 12))
                                    .foregroundStyle(Color(hex: card.hexColor))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.name).font(.system(size: 13, weight: .medium))
                                if !card.lastFour.isEmpty {
                                    Text("·· ·· ·· \(card.lastFour)")
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(card.entries.count) işlem")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 3)
                    }
                    .onDelete { indexSet in
                        for i in indexSet { context.delete(cards[i]) }
                        try? context.save()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 180)
            }
        }
        .frame(width: 400, height: 620)
        .background(GlassView(material: .hudWindow))
    }

    private func addCard() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let card = BudgetCard(name: trimmed, lastFour: newLastFour, hexColor: newColorHex, icon: newIcon)
        context.insert(card); try? context.save()
        newName = ""; newLastFour = ""; focused = true
    }
}
