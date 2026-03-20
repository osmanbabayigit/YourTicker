import SwiftUI
import SwiftData

// MARK: - Para birimi yardımcı

struct CurrencyHelper {
    static let supported: [(code: String, symbol: String, label: String)] = [
        ("TRY", "₺", "Türk Lirası"),
        ("USD", "$", "ABD Doları"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "İngiliz Sterlini"),
    ]

    static var current: String {
        get { UserDefaults.standard.string(forKey: "budgetCurrency") ?? "TRY" }
        set { UserDefaults.standard.set(newValue, forKey: "budgetCurrency") }
    }

    static func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = current
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Ana BudgetView

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BudgetEntry.date, order: .reverse) private var entries: [BudgetEntry]
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \BudgetCard.name) private var cards: [BudgetCard]

    @State private var selectedMonth = Date()
    @State private var showingAddEntry = false
    @State private var showingManageCategories = false
    @State private var showingManageCards = false
    @State private var selectedType: EntryType? = nil
    @State private var currency = CurrencyHelper.current

    var monthEntries: [BudgetEntry] {
        entries.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    var totalIncome:  Double { monthEntries.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount } }
    var totalExpense: Double { monthEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var balance:      Double { totalIncome - totalExpense }

    var filteredEntries: [BudgetEntry] {
        guard let t = selectedType else { return monthEntries }
        return monthEntries.filter { $0.type == t }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Üst bar
            HStack {
                HStack(spacing: 0) {
                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    } label: { Image(systemName: "chevron.left").frame(width: 28, height: 28) }
                    .buttonStyle(.plain)

                    Button { selectedMonth = Date() } label: {
                        Text(selectedMonth, format: .dateTime.month(.wide).year())
                            .font(.system(size: 15, weight: .bold)).frame(minWidth: 160)
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    } label: { Image(systemName: "chevron.right").frame(width: 28, height: 28) }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 8) {
                    Menu {
                        ForEach(CurrencyHelper.supported, id: \.code) { c in
                            Button { CurrencyHelper.current = c.code; currency = c.code } label: {
                                Text("\(c.symbol) \(c.label)")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currency).font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.down").font(.system(size: 9))
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .menuStyle(.borderlessButton).fixedSize()

                    Button { showingManageCards = true } label: {
                        Label("Kartlar", systemImage: "creditcard").font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered).controlSize(.small)

                    Button { showingManageCategories = true } label: {
                        Label("Kategoriler", systemImage: "tag").font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered).controlSize(.small)

                    Button { showingAddEntry = true } label: {
                        Label("Ekle", systemImage: "plus").font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent).tint(.blue).controlSize(.small)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {

                    // Özet kartları
                    HStack(spacing: 12) {
                        summaryCard("Bakiye",  value: balance,       color: balance >= 0 ? .blue : .red, icon: "equal.circle.fill")
                        summaryCard("Gelir",   value: totalIncome,   color: .green, icon: "arrow.down.circle.fill")
                        summaryCard("Gider",   value: totalExpense,  color: .red,   icon: "arrow.up.circle.fill")
                    }
                    .padding(.horizontal, 16)

                    // Kategori limitleri
                    let limitedCats = categories.filter { $0.monthlyLimit > 0 }
                    if !limitedCats.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aylık limitler")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(limitedCats) { cat in
                                        CategoryLimitCard(category: cat, month: selectedMonth)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // Grafikler — tam genişlik, dikey
                    VStack(spacing: 12) {
                        BudgetDonutChart(entries: monthEntries, categories: categories)
                        MonthlyBarChart(entries: entries)
                    }
                    .padding(.horizontal, 16)

                    // İşlem listesi
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("İşlemler")
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Picker("", selection: $selectedType) {
                                Text("Tümü").tag(Optional<EntryType>.none)
                                Text("Gelir").tag(Optional<EntryType>.some(.income))
                                Text("Gider").tag(Optional<EntryType>.some(.expense))
                            }
                            .pickerStyle(.segmented).frame(width: 160)
                        }
                        .padding(.horizontal, 16)

                        if filteredEntries.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray").font(.system(size: 28)).foregroundStyle(.secondary.opacity(0.4))
                                Text("Bu ay işlem yok").font(.system(size: 13)).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(filteredEntries) { entry in
                                    BudgetEntryRow(entry: entry)
                                        .padding(.horizontal, 16)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                context.delete(entry); try? context.save()
                                            } label: { Label("Sil", systemImage: "trash") }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showingAddEntry)         { AddBudgetEntryView() }
        .sheet(isPresented: $showingManageCategories) { BudgetCategoryManagerView() }
        .sheet(isPresented: $showingManageCards)      { BudgetCardManagerView() }
    }

    @ViewBuilder
    private func summaryCard(_ label: String, value: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color); Spacer() }
            Text(CurrencyHelper.format(value))
                .font(.system(size: 16, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Entry Row

struct BudgetEntryRow: View {
    let entry: BudgetEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.type.icon).font(.system(size: 16)).foregroundStyle(entry.type.color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                HStack(spacing: 6) {
                    if let cat = entry.category {
                        HStack(spacing: 3) {
                            Circle().fill(Color(hex: cat.hexColor)).frame(width: 5, height: 5)
                            Text(cat.name).font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                    if let card = entry.card {
                        Text("·").foregroundStyle(.secondary).font(.system(size: 10))
                        Text(card.name).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    if entry.isRecurring { Image(systemName: "repeat").font(.system(size: 9)).foregroundStyle(.secondary) }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.type == .income ? "+" : "-")\(CurrencyHelper.format(entry.amount))")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(entry.type.color)
                Text(entry.date, format: .dateTime.day().month(.abbreviated)).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Kategori limit kartı

struct CategoryLimitCard: View {
    let category: BudgetCategory
    let month: Date

    var spent:    Double { category.spent(in: month) }
    var progress: Double {
        guard category.monthlyLimit > 0 else { return 0 }
        return min(spent / category.monthlyLimit, 1.0)
    }
    var isOver: Bool { spent > category.monthlyLimit }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) { Circle().fill(Color(hex: category.hexColor)).frame(width: 7, height: 7); Text(category.name).font(.system(size: 11, weight: .semibold)) }
            Text(CurrencyHelper.format(spent)).font(.system(size: 13, weight: .bold)).foregroundStyle(isOver ? .red : .primary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(nsColor: .controlBackgroundColor)).frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isOver ? Color.red : Color(hex: category.hexColor))
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 5)
            Text("/ \(CurrencyHelper.format(category.monthlyLimit))").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(10).frame(width: 130)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
