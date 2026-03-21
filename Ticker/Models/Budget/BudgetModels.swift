import Foundation
import SwiftData
import SwiftUI

// MARK: - Para birimi

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
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = current
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Kart

@Model
class BudgetCard {
    var id: UUID = UUID()
    var name: String = ""
    var lastFour: String = ""
    var hexColor: String = "#3B82F6"
    var icon: String = "creditcard"
    @Relationship(deleteRule: .nullify) var entries: [BudgetEntry] = []

    init(name: String, lastFour: String = "",
         hexColor: String = "#3B82F6", icon: String = "creditcard") {
        self.name = name; self.lastFour = lastFour
        self.hexColor = hexColor; self.icon = icon
    }

    var color: Color { Color(hex: hexColor) }
}

// MARK: - Kategori

@Model
class BudgetCategory {
    var id: UUID = UUID()
    var name: String = ""
    var hexColor: String = "#3B82F6"
    var icon: String = "tag"
    var monthlyLimit: Double = 0
    @Relationship(deleteRule: .nullify) var entries: [BudgetEntry] = []

    init(name: String, hexColor: String = "#3B82F6",
         icon: String = "tag", monthlyLimit: Double = 0) {
        self.name = name; self.hexColor = hexColor
        self.icon = icon; self.monthlyLimit = monthlyLimit
    }

    var color: Color { Color(hex: hexColor) }

    func spent(in month: Date) -> Double {
        let cal = Calendar.current
        return entries
            .filter { $0.type == .expense && cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Giriş tipi

enum EntryType: String, Codable, CaseIterable {
    case income  = "income"
    case expense = "expense"

    var label: String { self == .income ? "Gelir" : "Gider" }
    var icon:  String { self == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill" }

    var color: Color {
        self == .income ? TickerTheme.green : TickerTheme.red
    }
}

// MARK: - İşlem

@Model
class BudgetEntry {
    var id: UUID = UUID()
    var title: String = ""
    var amount: Double = 0
    var typeRaw: String = EntryType.expense.rawValue
    var date: Date = Date()
    var notes: String = ""
    var isRecurring: Bool = false
    var recurrenceRaw: String = RecurrenceRule.none.rawValue

    @Relationship(inverse: \BudgetCategory.entries) var category: BudgetCategory?
    @Relationship(inverse: \BudgetCard.entries)     var card: BudgetCard?

    var type: EntryType {
        get { EntryType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
    var recurrenceRule: RecurrenceRule {
        get { RecurrenceRule(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    init(title: String, amount: Double, type: EntryType = .expense,
         date: Date = Date(), notes: String = "",
         isRecurring: Bool = false, recurrenceRule: RecurrenceRule = .none) {
        self.title = title; self.amount = amount; self.typeRaw = type.rawValue
        self.date = date; self.notes = notes
        self.isRecurring = isRecurring; self.recurrenceRaw = recurrenceRule.rawValue
    }
}
