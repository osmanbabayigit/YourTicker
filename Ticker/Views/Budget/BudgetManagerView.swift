import SwiftUI
import SwiftData

// MARK: - Bütçe renk paleti

struct BudgetColor: Identifiable, Hashable {
    let id: String
    let hex: String
    let label: String
    var color: Color { Color(hex: hex) }

    static let palette: [BudgetColor] = [
        BudgetColor(id: "sky",     hex: "#5B9CF6", label: "Gökyüzü"),
        BudgetColor(id: "ocean",   hex: "#2DD4BF", label: "Okyanus"),
        BudgetColor(id: "indigo",  hex: "#818CF8", label: "İndigo"),
        BudgetColor(id: "mint",    hex: "#34D399", label: "Nane"),
        BudgetColor(id: "lime",    hex: "#A3E635", label: "Limon"),
        BudgetColor(id: "coral",   hex: "#FB7185", label: "Mercan"),
        BudgetColor(id: "sunset",  hex: "#FB923C", label: "Günbatımı"),
        BudgetColor(id: "amber",   hex: "#FBBF24", label: "Kehribar"),
        BudgetColor(id: "violet",  hex: "#C084FC", label: "Viyole"),
        BudgetColor(id: "rose",    hex: "#F472B6", label: "Gül"),
        BudgetColor(id: "slate",   hex: "#94A3B8", label: "Arduvaz"),
        BudgetColor(id: "sand",    hex: "#D4A574", label: "Kum"),
    ]
}

// MARK: - Renk seçici

struct BudgetColorPicker: View {
    @Binding var selectedHex: String
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(BudgetColor.palette) { bc in
                Button { selectedHex = bc.hex } label: {
                    ZStack {
                        Circle().fill(bc.color.opacity(0.2)).frame(width: 30, height: 30)
                        Circle().fill(bc.color)
                            .frame(width: selectedHex == bc.hex ? 20 : 16,
                                   height: selectedHex == bc.hex ? 20 : 16)
                        if selectedHex == bc.hex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .heavy)).foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.2), value: selectedHex)
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
    @State private var categoryToDelete: BudgetCategory? = nil
    @FocusState private var focused: Bool

    let icons = [
        "tag", "cart", "house", "car", "fork.knife",
        "tshirt", "pills", "gamecontroller", "airplane", "gift",
        "graduationcap", "film", "music.note", "dumbbell", "leaf"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle().fill(Color(hex: newColorHex)).frame(width: 10, height: 10)
                Text("Kategoriler")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    // Yeni kategori formu
                    VStack(alignment: .leading, spacing: 12) {
                        // Ad + Limit
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                sectionLabel("Kategori adı", icon: "tag")
                                TextField("Market, Kira...", text: $newName)
                                    .textFieldStyle(.plain).font(.system(size: 13))
                                    .foregroundStyle(TickerTheme.textPrimary).focused($focused)
                                    .padding(8).background(TickerTheme.bgPill)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                    .onSubmit { addCategory() }
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                sectionLabel("Aylık limit", icon: "turkish.lira.sign")
                                TextField("0", text: $newLimit)
                                    .textFieldStyle(.plain).font(.system(size: 13))
                                    .foregroundStyle(TickerTheme.textPrimary)
                                    .padding(8).background(TickerTheme.bgPill)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                    .frame(width: 90)
                            }
                        }

                        // İkon
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("İkon", icon: "square.grid.2x2")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button { newIcon = icon } label: {
                                            Image(systemName: icon).font(.system(size: 14))
                                                .frame(width: 34, height: 34)
                                                .background(newIcon == icon
                                                            ? Color(hex: newColorHex).opacity(0.15)
                                                            : TickerTheme.bgPill)
                                                .foregroundStyle(newIcon == icon
                                                                 ? Color(hex: newColorHex)
                                                                 : TickerTheme.textTertiary)
                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .stroke(newIcon == icon
                                                                ? Color(hex: newColorHex).opacity(0.3)
                                                                : TickerTheme.borderSub, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.spring(response: 0.2), value: newIcon)
                                    }
                                }
                            }
                        }

                        // Renk
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Renk", icon: "circle.hexagongrid")
                            BudgetColorPicker(selectedHex: $newColorHex)
                        }

                        // Önizleme + Ekle
                        HStack(spacing: 10) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(Color(hex: newColorHex).opacity(0.12)).frame(width: 30, height: 30)
                                    Image(systemName: newIcon).font(.system(size: 13))
                                        .foregroundStyle(Color(hex: newColorHex))
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(newName.isEmpty ? "Kategori adı" : newName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(newName.isEmpty ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                                    if let limit = Double(newLimit.replacingOccurrences(of: ",", with: ".")), limit > 0 {
                                        Text(CurrencyHelper.format(limit) + " limit")
                                            .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: newColorHex).opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: newColorHex).opacity(0.12), lineWidth: 1))

                            Button("Ekle") { addCategory() }
                                .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: newColorHex))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color(hex: newColorHex).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(18)

                    // Mevcut kategoriler
                    if !categories.isEmpty {
                        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                        sectionLabel("Mevcut kategoriler", icon: "list.bullet")
                            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 6)

                        VStack(spacing: 0) {
                            ForEach(categories) { cat in
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle().fill(Color(hex: cat.hexColor).opacity(0.12)).frame(width: 30, height: 30)
                                        Image(systemName: cat.icon).font(.system(size: 12))
                                            .foregroundStyle(Color(hex: cat.hexColor))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cat.name).font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(TickerTheme.textPrimary)
                                        if cat.monthlyLimit > 0 {
                                            Text("Limit: \(CurrencyHelper.format(cat.monthlyLimit))")
                                                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                                        }
                                    }
                                    Spacer()
                                    Text("\(cat.entries.count) işlem")
                                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)

                                    // ✅ Sil butonu — doğrudan, alert ile onay
                                    Button {
                                        categoryToDelete = cat
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11)).foregroundStyle(TickerTheme.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 18).padding(.vertical, 9)

                                if cat.id != categories.last?.id {
                                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1).padding(.leading, 18)
                                }
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .frame(width: 420, height: 660)
        .background(Color(hex: "#161618"))
        .confirmationDialog(
            "Kategoriyi sil?",
            isPresented: Binding(get: { categoryToDelete != nil }, set: { if !$0 { categoryToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                if let cat = categoryToDelete { context.delete(cat); try? context.save() }
                categoryToDelete = nil
            }
            Button("İptal", role: .cancel) { categoryToDelete = nil }
        } message: {
            if let cat = categoryToDelete {
                Text("\"\(cat.name)\" kategorisini ve \(cat.entries.count) kaydı sil?")
            }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
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
    @State private var cardToDelete: BudgetCard? = nil
    @FocusState private var focused: Bool

    let cardIcons = ["creditcard", "creditcard.fill", "banknote", "building.columns", "wallet.pass"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Circle().fill(Color(hex: newColorHex)).frame(width: 10, height: 10)
                Text("Kartlar")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Ad + Son 4
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                sectionLabel("Kart adı", icon: "creditcard")
                                TextField("Ziraat Visa, Akbank...", text: $newName)
                                    .textFieldStyle(.plain).font(.system(size: 13))
                                    .foregroundStyle(TickerTheme.textPrimary).focused($focused)
                                    .padding(8).background(TickerTheme.bgPill)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                sectionLabel("Son 4 hane", icon: "number")
                                TextField("0000", text: $newLastFour)
                                    .textFieldStyle(.plain).font(.system(size: 13))
                                    .foregroundStyle(TickerTheme.textPrimary)
                                    .padding(8).background(TickerTheme.bgPill)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                    .frame(width: 80)
                            }
                        }

                        // İkon
                        HStack(spacing: 6) {
                            ForEach(cardIcons, id: \.self) { icon in
                                Button { newIcon = icon } label: {
                                    Image(systemName: icon).font(.system(size: 15))
                                        .frame(width: 44, height: 34)
                                        .background(newIcon == icon
                                                    ? Color(hex: newColorHex).opacity(0.15) : TickerTheme.bgPill)
                                        .foregroundStyle(newIcon == icon ? Color(hex: newColorHex) : TickerTheme.textTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                        .overlay(RoundedRectangle(cornerRadius: 7)
                                            .stroke(newIcon == icon ? Color(hex: newColorHex).opacity(0.3) : TickerTheme.borderSub, lineWidth: 1))
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.2), value: newIcon)
                            }
                        }

                        // Renk
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Renk", icon: "circle.hexagongrid")
                            BudgetColorPicker(selectedHex: $newColorHex)
                        }

                        // Önizleme + Ekle
                        HStack(spacing: 10) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color(hex: newColorHex).opacity(0.12))
                                        .frame(width: 40, height: 26)
                                    Image(systemName: newIcon).font(.system(size: 13))
                                        .foregroundStyle(Color(hex: newColorHex))
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(newName.isEmpty ? "Kart adı" : newName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(newName.isEmpty ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                                    if !newLastFour.isEmpty {
                                        Text("·· \(newLastFour)").font(.system(size: 10))
                                            .foregroundStyle(TickerTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: newColorHex).opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: newColorHex).opacity(0.12), lineWidth: 1))

                            Button("Ekle") { addCard() }
                                .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: newColorHex))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color(hex: newColorHex).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(18)

                    if !cards.isEmpty {
                        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                        sectionLabel("Mevcut kartlar", icon: "list.bullet")
                            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 6)

                        VStack(spacing: 0) {
                            ForEach(cards) { card in
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color(hex: card.hexColor).opacity(0.12))
                                            .frame(width: 36, height: 24)
                                        Image(systemName: card.icon).font(.system(size: 11))
                                            .foregroundStyle(Color(hex: card.hexColor))
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(card.name).font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(TickerTheme.textPrimary)
                                        if !card.lastFour.isEmpty {
                                            Text("·· \(card.lastFour)").font(.system(size: 10))
                                                .foregroundStyle(TickerTheme.textTertiary)
                                        }
                                    }
                                    Spacer()
                                    Text("\(card.entries.count) işlem")
                                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)

                                    // ✅ Sil butonu
                                    Button { cardToDelete = card } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11)).foregroundStyle(TickerTheme.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 18).padding(.vertical, 9)

                                if card.id != cards.last?.id {
                                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1).padding(.leading, 18)
                                }
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .frame(width: 400, height: 600)
        .background(Color(hex: "#161618"))
        .confirmationDialog(
            "Kartı sil?",
            isPresented: Binding(get: { cardToDelete != nil }, set: { if !$0 { cardToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                if let card = cardToDelete { context.delete(card); try? context.save() }
                cardToDelete = nil
            }
            Button("İptal", role: .cancel) { cardToDelete = nil }
        } message: {
            if let card = cardToDelete {
                Text("\"\(card.name)\" kartını ve \(card.entries.count) kaydı sil?")
            }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func addCard() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let card = BudgetCard(name: trimmed, lastFour: newLastFour, hexColor: newColorHex, icon: newIcon)
        context.insert(card); try? context.save()
        newName = ""; newLastFour = ""; focused = true
    }
}
