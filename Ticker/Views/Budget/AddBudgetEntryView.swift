import SwiftUI
import SwiftData

// MARK: - Yeni İşlem

struct AddBudgetEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \BudgetCard.name)     private var cards: [BudgetCard]

    @State private var title = ""
    @State private var amountText = ""
    @State private var type: EntryType = .expense
    @State private var date = Date()
    @State private var selectedCategory: BudgetCategory? = nil
    @State private var selectedCard: BudgetCard? = nil
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrenceRule: RecurrenceRule = .monthly
    @FocusState private var amountFocused: Bool

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Circle().fill(type.color).frame(width: 10, height: 10)
                Text("Yeni İşlem")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
                Button("Kaydet") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(type.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(title.isEmpty || amount <= 0)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {

                    // Tip seçici
                    HStack(spacing: 6) {
                        ForEach(EntryType.allCases, id: \.self) { t in
                            Button { type = t } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: t.icon).font(.system(size: 12))
                                    Text(t.label).font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(type == t ? .white : TickerTheme.textTertiary)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(type == t ? t.color : TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain).animation(.spring(response: 0.2), value: type)
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Başlık + Tutar
                    VStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Başlık", icon: "pencil")
                            TextField("Ne için?", text: $title)
                                .textFieldStyle(.plain).font(.system(size: 13))
                                .foregroundStyle(TickerTheme.textPrimary)
                                .padding(9).background(TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                sectionLabel("Tutar (\(CurrencyHelper.current))", icon: "banknote")
                                TextField("0.00", text: $amountText)
                                    .textFieldStyle(.plain).font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(type.color).focused($amountFocused)
                                    .padding(9).background(TickerTheme.bgPill)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                sectionLabel("Tarih", icon: "calendar")
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden().colorScheme(.dark)
                            }
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Kategori
                    if !categories.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Kategori", icon: "tag")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    // Yok seçeneği
                                    Button { selectedCategory = nil } label: {
                                        Text("Yok")
                                            .font(.system(size: 11))
                                            .foregroundStyle(selectedCategory == nil
                                                             ? TickerTheme.textPrimary : TickerTheme.textTertiary)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(selectedCategory == nil
                                                        ? TickerTheme.bgCardHover : TickerTheme.bgPill)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)

                                    ForEach(categories) { cat in
                                        Button { selectedCategory = cat } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: cat.icon).font(.system(size: 10))
                                                Text(cat.name).font(.system(size: 11))
                                            }
                                            .foregroundStyle(selectedCategory?.id == cat.id
                                                             ? Color(hex: cat.hexColor) : TickerTheme.textTertiary)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(selectedCategory?.id == cat.id
                                                        ? Color(hex: cat.hexColor).opacity(0.12) : TickerTheme.bgPill)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6)
                                                .stroke(selectedCategory?.id == cat.id
                                                        ? Color(hex: cat.hexColor).opacity(0.2) : Color.clear, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                    }

                    // Kart
                    if !cards.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Kart", icon: "creditcard")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    Button { selectedCard = nil } label: {
                                        Text("Yok").font(.system(size: 11))
                                            .foregroundStyle(selectedCard == nil
                                                             ? TickerTheme.textPrimary : TickerTheme.textTertiary)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(selectedCard == nil
                                                        ? TickerTheme.bgCardHover : TickerTheme.bgPill)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)

                                    ForEach(cards) { card in
                                        Button { selectedCard = card } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: card.icon).font(.system(size: 10))
                                                Text(card.name).font(.system(size: 11))
                                                if !card.lastFour.isEmpty {
                                                    Text("··\(card.lastFour)").font(.system(size: 9))
                                                        .foregroundStyle(TickerTheme.textTertiary)
                                                }
                                            }
                                            .foregroundStyle(selectedCard?.id == card.id
                                                             ? Color(hex: card.hexColor) : TickerTheme.textTertiary)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(selectedCard?.id == card.id
                                                        ? Color(hex: card.hexColor).opacity(0.12) : TickerTheme.bgPill)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                    }

                    // Tekrarlama
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            sectionLabel("Tekrarlama", icon: "repeat")
                            Spacer()
                            Toggle("", isOn: $isRecurring)
                                .labelsHidden().toggleStyle(.switch).controlSize(.small)
                        }
                        if isRecurring {
                            HStack(spacing: 5) {
                                ForEach([RecurrenceRule.daily, .weekly, .monthly], id: \.self) { rule in
                                    Button { recurrenceRule = rule } label: {
                                        Text(rule.label).font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(recurrenceRule == rule
                                                        ? TickerTheme.blue.opacity(0.15) : TickerTheme.bgPill)
                                            .foregroundStyle(recurrenceRule == rule
                                                             ? TickerTheme.blue : TickerTheme.textTertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(18)
                    .animation(.spring(response: 0.25), value: isRecurring)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Not
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Not", icon: "note.text")
                        TextField("Opsiyonel not...", text: $notes)
                            .textFieldStyle(.plain).font(.system(size: 13))
                            .foregroundStyle(TickerTheme.textSecondary)
                            .padding(9).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .padding(18)
                }
            }
        }
        .frame(width: 420)
        .background(Color(hex: "#161618"))
        .onAppear { amountFocused = true }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func save() {
        let entry = BudgetEntry(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount, type: type, date: date,
            notes: notes, isRecurring: isRecurring,
            recurrenceRule: isRecurring ? recurrenceRule : .none
        )
        entry.category = selectedCategory
        entry.card = selectedCard
        context.insert(entry); try? context.save(); dismiss()
    }
}

// MARK: - İşlem Düzenleme

struct EditBudgetEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \BudgetCard.name)     private var cards: [BudgetCard]

    @Bindable var entry: BudgetEntry

    @State private var title: String
    @State private var amountText: String
    @State private var type: EntryType
    @State private var date: Date
    @State private var selectedCategory: BudgetCategory?
    @State private var selectedCard: BudgetCard?
    @State private var notes: String
    @State private var isRecurring: Bool

    init(entry: BudgetEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _amountText = State(initialValue: String(entry.amount))
        _type = State(initialValue: entry.type)
        _date = State(initialValue: entry.date)
        _selectedCategory = State(initialValue: entry.category)
        _selectedCard = State(initialValue: entry.card)
        _notes = State(initialValue: entry.notes)
        _isRecurring = State(initialValue: entry.isRecurring)
    }

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle().fill(type.color).frame(width: 10, height: 10)
                Text("İşlemi Düzenle")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                Button("Kaydet") { saveEdits() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(type.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(title.isEmpty || amount <= 0)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 14) {
                    // Tip
                    HStack(spacing: 6) {
                        ForEach(EntryType.allCases, id: \.self) { t in
                            Button { type = t } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: t.icon).font(.system(size: 12))
                                    Text(t.label).font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(type == t ? .white : TickerTheme.textTertiary)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(type == t ? t.color : TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain).animation(.spring(response: 0.2), value: type)
                        }
                    }

                    // Başlık
                    VStack(alignment: .leading, spacing: 5) {
                        label("Başlık", icon: "pencil")
                        TextField("Ne için?", text: $title)
                            .textFieldStyle(.plain).font(.system(size: 13))
                            .foregroundStyle(TickerTheme.textPrimary)
                            .padding(9).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            label("Tutar", icon: "banknote")
                            TextField("0.00", text: $amountText)
                                .textFieldStyle(.plain).font(.system(size: 15, weight: .bold))
                                .foregroundStyle(type.color)
                                .padding(9).background(TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            label("Tarih", icon: "calendar")
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden().colorScheme(.dark)
                        }
                    }

                    // Sil butonu
                    Button(role: .destructive) {
                        context.delete(entry); try? context.save(); dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash").font(.system(size: 12))
                            Text("İşlemi Sil").font(.system(size: 13))
                        }
                        .foregroundStyle(TickerTheme.red)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .padding(18)
            }
        }
        .frame(width: 380)
        .background(Color(hex: "#161618"))
    }

    @ViewBuilder
    private func label(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func saveEdits() {
        entry.title = title.trimmingCharacters(in: .whitespaces)
        entry.amount = amount; entry.type = type; entry.date = date
        entry.notes = notes; entry.isRecurring = isRecurring
        entry.category = selectedCategory; entry.card = selectedCard
        try? context.save(); dismiss()
    }
}
