import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BudgetEntry.date, order: .reverse) private var entries: [BudgetEntry]
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \BudgetCard.name)     private var cards: [BudgetCard]

    @State private var selectedMonth = Date()
    @State private var showingAddEntry = false
    @State private var showingManageCategories = false
    @State private var showingManageCards = false
    @State private var selectedType: EntryType? = nil
    @State private var editingEntry: BudgetEntry? = nil
    @State private var currency = CurrencyHelper.current
    @State private var searchText = ""

    // MARK: - Computed

    private var monthEntries: [BudgetEntry] {
        entries.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var totalIncome:  Double { monthEntries.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Double { monthEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var balance:      Double { totalIncome - totalExpense }

    private var filteredEntries: [BudgetEntry] {
        monthEntries
            .filter { entry in
                if let t = selectedType, entry.type != t { return false }
                if !searchText.isEmpty,
                   !entry.title.localizedCaseInsensitiveContains(searchText) { return false }
                return true
            }
    }

    var body: some View {
        HSplitView {
            // Sol: istatistikler + grafikler
            leftPanel
                .frame(minWidth: 260, maxWidth: 320)

            // Sağ: işlem listesi
            rightPanel
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingAddEntry)         { AddBudgetEntryView() }
        .sheet(isPresented: $showingManageCategories) { BudgetCategoryManagerView() }
        .sheet(isPresented: $showingManageCards)      { BudgetCardManagerView() }
        .sheet(item: $editingEntry)                   { EditBudgetEntryView(entry: $0) }
    }

    // MARK: - Sol panel

    private var leftPanel: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Ay navigasyonu
                monthNav
                    .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                // Özet kartları
                VStack(spacing: 8) {
                    summaryRow("Bakiye",
                               value: balance,
                               color: balance >= 0 ? TickerTheme.blue : TickerTheme.red,
                               icon: "equal.circle.fill",
                               large: true)

                    HStack(spacing: 8) {
                        summaryCard("Gelir", value: totalIncome,
                                    color: TickerTheme.green, icon: "arrow.down.circle.fill")
                        summaryCard("Gider", value: totalExpense,
                                    color: TickerTheme.red, icon: "arrow.up.circle.fill")
                    }
                }
                .padding(14)

                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                // Kategori limitleri
                let limitedCats = categories.filter { $0.monthlyLimit > 0 }
                if !limitedCats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Limitler", icon: "gauge.high")
                            .padding(.horizontal, 14).padding(.top, 12)

                        VStack(spacing: 6) {
                            ForEach(limitedCats) { cat in
                                CategoryLimitRow(category: cat, month: selectedMonth)
                            }
                        }
                        .padding(.horizontal, 14).padding(.bottom, 12)
                    }
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                }

                // Donut chart
                if !monthEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Kategoriye göre", icon: "chart.pie.fill")
                            .padding(.horizontal, 14).padding(.top, 12)
                        BudgetDonutChart(entries: monthEntries, categories: categories)
                            .padding(.horizontal, 14).padding(.bottom, 12)
                    }
                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                }

                // 6 aylık bar chart
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("6 aylık özet", icon: "chart.bar.fill")
                        .padding(.horizontal, 14).padding(.top, 12)
                    MonthlyBarChart(entries: entries)
                        .padding(.horizontal, 14).padding(.bottom, 12)
                }
            }
        }
        .background(TickerTheme.bgSidebar)
    }

    private var monthNav: some View {
        HStack(spacing: 0) {
            Button {
                selectedMonth = Calendar.current.date(
                    byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 12))
                    .frame(width: 28, height: 28).foregroundStyle(TickerTheme.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { selectedMonth = Date() }
            } label: {
                Text(selectedMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                selectedMonth = Calendar.current.date(
                    byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right").font(.system(size: 12))
                    .frame(width: 28, height: 28).foregroundStyle(TickerTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func summaryRow(_ label: String, value: Double,
                             color: Color, icon: String, large: Bool = false) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                Text(CurrencyHelper.format(value))
                    .font(.system(size: large ? 18 : 14, weight: .bold))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.7).lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(color.opacity(0.12), lineWidth: 1))
    }

    @ViewBuilder
    private func summaryCard(_ label: String, value: Double,
                              color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color)
            Text(CurrencyHelper.format(value))
                .font(.system(size: 13, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(color.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Sağ panel

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Toolbar
            rightToolbar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Liste
            if filteredEntries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .background(TickerTheme.bgApp)
    }

    private var rightToolbar: some View {
        HStack(spacing: 10) {
            // Başlık
            Text("İşlemler")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)

            Text("\(filteredEntries.count)")
                .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(TickerTheme.bgPill).clipShape(Capsule())

            Spacer()

            // Arama
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                TextField("Ara...", text: $searchText)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textPrimary).frame(width: 100)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(TickerTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Filtre
            HStack(spacing: 2) {
                filterChip("Tümü", tag: nil)
                filterChip("Gelir", tag: .income)
                filterChip("Gider", tag: .expense)
            }
            .padding(2).background(TickerTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 7))

            // Para birimi
            Menu {
                ForEach(CurrencyHelper.supported, id: \.code) { c in
                    Button { CurrencyHelper.current = c.code; currency = c.code } label: {
                        Text("\(c.symbol) \(c.label)")
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(currency).font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.down").font(.system(size: 8))
                }
                .foregroundStyle(TickerTheme.textSecondary)
                .padding(.horizontal, 7).padding(.vertical, 5)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton).fixedSize()

            // Yönet
            Menu {
                Button { showingManageCategories = true } label: {
                    Label("Kategoriler", systemImage: "tag")
                }
                Button { showingManageCards = true } label: {
                    Label("Kartlar", systemImage: "creditcard")
                }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton).fixedSize()

            // Ekle
            Button { showingAddEntry = true } label: {
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

    @ViewBuilder
    private func filterChip(_ label: String, tag: EntryType?) -> some View {
        let isSelected = selectedType == tag
        Button { selectedType = tag } label: {
            Text(label).font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? TickerTheme.textPrimary : TickerTheme.textTertiary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(isSelected ? TickerTheme.bgPill : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }

    private var entryList: some View {
        List {
            ForEach(filteredEntries) { entry in
                BudgetEntryRow(entry: entry)
                    .listRowInsets(EdgeInsets(top: 2, leading: 14, bottom: 2, trailing: 14))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onTapGesture { editingEntry = entry }
                    .contextMenu {
                        Button { editingEntry = entry } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            context.delete(entry); try? context.save()
                        } label: { Label("Sil", systemImage: "trash") }
                    }
            }
            Color.clear.frame(height: 40)
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
        .background(TickerTheme.bgApp)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(TickerTheme.textTertiary)
            VStack(spacing: 4) {
                Text("Bu ay işlem yok")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TickerTheme.textSecondary)
                Text("Ekle butonuna basarak başla")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            Button { showingAddEntry = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus").font(.system(size: 11))
                    Text("İşlem Ekle").font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(TickerTheme.blue)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(TickerTheme.blue.opacity(0.12)).clipShape(Capsule())
                .overlay(Capsule().stroke(TickerTheme.blue.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity).background(TickerTheme.bgApp)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }
}

// MARK: - Entry Row

struct BudgetEntryRow: View {
    let entry: BudgetEntry
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Tip ikonu
            ZStack {
                Circle()
                    .fill(entry.type.color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: entry.type.icon)
                    .font(.system(size: 13)).foregroundStyle(entry.type.color)
            }

            // Bilgi
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TickerTheme.textPrimary).lineLimit(1)

                HStack(spacing: 6) {
                    if let cat = entry.category {
                        HStack(spacing: 3) {
                            Circle().fill(Color(hex: cat.hexColor)).frame(width: 5, height: 5)
                            Text(cat.name).font(.system(size: 10))
                                .foregroundStyle(TickerTheme.textTertiary)
                        }
                    }
                    if let card = entry.card {
                        Text("·").foregroundStyle(TickerTheme.textTertiary)
                            .font(.system(size: 10))
                        Text(card.name).font(.system(size: 10))
                            .foregroundStyle(TickerTheme.textTertiary)
                    }
                    if entry.isRecurring {
                        Image(systemName: "repeat").font(.system(size: 9))
                            .foregroundStyle(TickerTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Tutar + tarih
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(entry.type == .income ? "+" : "-")\(CurrencyHelper.format(entry.amount))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(entry.type.color)
                Text(entry.date, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                .opacity(isHovered ? 0.6 : 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(isHovered ? TickerTheme.bgCardHover : TickerTheme.bgCard)
        )
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(TickerTheme.borderSub, lineWidth: 1))
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Kategori Limit Satırı

struct CategoryLimitRow: View {
    let category: BudgetCategory
    let month: Date

    private var spent: Double { category.spent(in: month) }
    private var progress: Double {
        guard category.monthlyLimit > 0 else { return 0 }
        return min(spent / category.monthlyLimit, 1.0)
    }
    private var isOver: Bool { spent > category.monthlyLimit }

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                ZStack {
                    Circle().fill(Color(hex: category.hexColor).opacity(0.12)).frame(width: 20, height: 20)
                    Image(systemName: category.icon).font(.system(size: 9))
                        .foregroundStyle(Color(hex: category.hexColor))
                }
                Text(category.name).font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TickerTheme.textSecondary)
                Spacer()
                Text(CurrencyHelper.format(spent))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isOver ? TickerTheme.red : TickerTheme.textPrimary)
                Text("/ \(CurrencyHelper.format(category.monthlyLimit))")
                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TickerTheme.bgPill).frame(height: 3)
                    Capsule()
                        .fill(isOver ? TickerTheme.red : Color(hex: category.hexColor))
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(TickerTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(
            isOver ? TickerTheme.red.opacity(0.2) : TickerTheme.borderSub, lineWidth: 1))
    }
}
