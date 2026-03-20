import SwiftUI
import SwiftData

struct AddBudgetEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \BudgetCard.name) private var cards: [BudgetCard]

    @State private var title = ""
    @State private var amountText = ""
    @State private var type: EntryType = .expense
    @State private var date = Date()
    @State private var selectedCategory: BudgetCategory? = nil
    @State private var selectedCard: BudgetCard? = nil
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrenceRule: RecurrenceRule = .monthly

    var amount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Yeni İşlem")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                Button("Kaydet") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(type.color)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(title.isEmpty || amount <= 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {

                    // Tip seçici
                    Picker("", selection: $type) {
                        ForEach(EntryType.allCases, id: \.self) { t in
                            Label(t.label, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Başlık & Tutar
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Başlık", systemImage: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("Ne için?", text: $title)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Tutar (₺)", systemImage: "turkishlirasign")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("0,00", text: $amountText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(width: 120)
                        }
                    }

                    // Tarih
                    HStack {
                        Label("Tarih", systemImage: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                    }

                    // Kategori
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Kategori", systemImage: "tag")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        if categories.isEmpty {
                            Text("Henüz kategori yok — Kategoriler menüsünden ekle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    // Kategorisiz seçeneği
                                    Button {
                                        selectedCategory = nil
                                    } label: {
                                        Text("Yok")
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedCategory == nil ? Color.blue.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                                            .foregroundStyle(selectedCategory == nil ? .blue : .secondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)

                                    ForEach(categories) { cat in
                                        Button {
                                            selectedCategory = cat
                                        } label: {
                                            HStack(spacing: 4) {
                                                Circle().fill(Color(hex: cat.hexColor)).frame(width: 6, height: 6)
                                                Text(cat.name).font(.system(size: 11, weight: .medium))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                selectedCategory?.id == cat.id
                                                ? Color(hex: cat.hexColor).opacity(0.2)
                                                : Color(nsColor: .controlBackgroundColor)
                                            )
                                            .foregroundStyle(
                                                selectedCategory?.id == cat.id
                                                ? Color(hex: cat.hexColor)
                                                : .secondary
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // Kart
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Kart", systemImage: "creditcard")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        if cards.isEmpty {
                            Text("Henüz kart yok — Kartlar menüsünden ekle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    Button {
                                        selectedCard = nil
                                    } label: {
                                        Text("Yok")
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedCard == nil ? Color.blue.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                                            .foregroundStyle(selectedCard == nil ? .blue : .secondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)

                                    ForEach(cards) { card in
                                        Button {
                                            selectedCard = card
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: card.icon)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Color(hex: card.hexColor))
                                                Text(card.name)
                                                    .font(.system(size: 11, weight: .medium))
                                                if !card.lastFour.isEmpty {
                                                    Text("·· \(card.lastFour)")
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                selectedCard?.id == card.id
                                                ? Color(hex: card.hexColor).opacity(0.2)
                                                : Color(nsColor: .controlBackgroundColor)
                                            )
                                            .foregroundStyle(
                                                selectedCard?.id == card.id
                                                ? Color(hex: card.hexColor)
                                                : .secondary
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // Tekrarlayan
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Tekrarlayan işlem", isOn: $isRecurring)
                                .toggleStyle(.switch)
                                .font(.system(size: 13))
                            Spacer()
                        }
                        if isRecurring {
                            Picker("", selection: $recurrenceRule) {
                                ForEach([RecurrenceRule.daily, .weekly, .monthly], id: \.self) { rule in
                                    Text(rule.label).tag(rule)
                                }
                            }
                            .pickerStyle(.segmented)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.spring(response: 0.25), value: isRecurring)

                    // Not
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Not", systemImage: "note.text")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .font(.system(size: 13))
                            .frame(height: 60)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .scrollContentBackground(.hidden)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 440)
        .background(GlassView(material: .hudWindow))
    }

    private func save() {
        let entry = BudgetEntry(
            title: title,
            amount: amount,
            type: type,
            date: date,
            notes: notes,
            isRecurring: isRecurring,
            recurrenceRule: isRecurring ? recurrenceRule : .none
        )
        entry.category = selectedCategory
        entry.card = selectedCard
        context.insert(entry)
        try? context.save()
        dismiss()
    }
}
