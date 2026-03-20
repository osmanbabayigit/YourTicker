import Foundation
import SwiftData
import SwiftUI

// MARK: - Kart

@Model
class BudgetCard {
    var id: UUID = UUID()
    var name: String = ""
    var lastFour: String = ""     // Son 4 hane
    var hexColor: String = "#4C8EF7"
    var icon: String = "creditcard"
    var entries: [BudgetEntry] = []

    init(name: String, lastFour: String = "", hexColor: String = "#4C8EF7", icon: String = "creditcard") {
        self.name = name
        self.lastFour = lastFour
        self.hexColor = hexColor
        self.icon = icon
    }

    var color: Color { Color(hex: hexColor) }
}

// MARK: - Kategori

@Model
class BudgetCategory {
    var id: UUID = UUID()
    var name: String = ""
    var hexColor: String = "#4C8EF7"
    var icon: String = "tag"
    var monthlyLimit: Double = 0   // 0 = limit yok
    var entries: [BudgetEntry] = []

    init(name: String, hexColor: String = "#4C8EF7", icon: String = "tag", monthlyLimit: Double = 0) {
        self.name = name
        self.hexColor = hexColor
        self.icon = icon
        self.monthlyLimit = monthlyLimit
    }

    var color: Color { Color(hex: hexColor) }

    func spent(in month: Date) -> Double {
        let cal = Calendar.current
        return entries
            .filter { $0.type == .expense && cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var limitProgress: Double {
        guard monthlyLimit > 0 else { return 0 }
        return min(spent(in: Date()) / monthlyLimit, 1.0)
    }
}

// MARK: - Giriş tipi

enum EntryType: String, Codable, CaseIterable {
    case income  = "income"
    case expense = "expense"

    var label: String { self == .income ? "Gelir" : "Gider" }
    var icon: String  { self == .income ? "arrow.down.circle" : "arrow.up.circle" }
    var color: Color  { self == .income ? .green : .red }
}

// MARK: - İşlem kaydı

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
    @Relationship(inverse: \BudgetCard.entries) var card: BudgetCard?

    var type: EntryType {
        get { EntryType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var recurrenceRule: RecurrenceRule {
        get { RecurrenceRule(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    init(
        title: String,
        amount: Double,
        type: EntryType = .expense,
        date: Date = Date(),
        notes: String = "",
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule = .none
    ) {
        self.title = title
        self.amount = amount
        self.typeRaw = type.rawValue
        self.date = date
        self.notes = notes
        self.isRecurring = isRecurring
        self.recurrenceRaw = recurrenceRule.rawValue
    }
}
