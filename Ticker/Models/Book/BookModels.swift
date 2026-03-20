import Foundation
import SwiftData
import SwiftUI

// MARK: - Okuma durumu

enum ReadingStatus: String, CaseIterable, Codable {
    case wantToRead = "wantToRead"
    case reading    = "reading"
    case finished   = "finished"
    case queue      = "queue"       // Sırada bekliyor

    var label: String {
        switch self {
        case .wantToRead: return "Okunacak"
        case .reading:    return "Okuyorum"
        case .finished:   return "Okundu"
        case .queue:      return "Sırada"
        }
    }

    var icon: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading:    return "book.open"
        case .finished:   return "checkmark.seal.fill"
        case .queue:      return "list.number"
        }
    }

    var color: Color {
        switch self {
        case .wantToRead: return .secondary
        case .reading:    return .blue
        case .finished:   return .green
        case .queue:      return .orange
        }
    }
}

// MARK: - Kitap koleksiyonu (raf)

@Model
class BookCollection {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "books.vertical"
    var hexColor: String = "#4C8EF7"
    var sortOrder: Int = 0
    @Relationship var books: [BookItem] = []

    init(name: String, icon: String = "books.vertical", hexColor: String = "#4C8EF7", sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.hexColor = hexColor
        self.sortOrder = sortOrder
    }

    var color: Color { Color(hex: hexColor) }
}

// MARK: - Okuma seansı

@Model
class ReadingSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var pagesRead: Int = 0
    var durationMinutes: Int = 0
    var notes: String = ""
    var book: BookItem?

    init(date: Date = Date(), pagesRead: Int, durationMinutes: Int = 0, notes: String = "") {
        self.date = date
        self.pagesRead = pagesRead
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

// MARK: - Not / Alıntı

@Model
class BookNote {
    var id: UUID = UUID()
    var content: String = ""
    var page: Int = 0
    var isQuote: Bool = false
    var createdAt: Date = Date()
    var book: BookItem?

    init(content: String, page: Int = 0, isQuote: Bool = false) {
        self.content = content
        self.page = page
        self.isQuote = isQuote
    }
}

// MARK: - Kitap

@Model
class BookItem {
    var id: UUID = UUID()
    var title: String = ""
    var author: String = ""
    var totalPages: Int = 0
    var currentPage: Int = 0
    var statusRaw: String = ReadingStatus.wantToRead.rawValue
    var rating: Int = 0
    var startDate: Date? = nil
    var finishDate: Date? = nil
    var coverImageData: Data? = nil
    var hexColor: String = "#4C8EF7"
    var createdAt: Date = Date()
    var queueOrder: Int = 0
    var isbn: String = ""
    var publisher: String = ""
    var publishYear: Int = 0
    var genre: String = ""

    @Relationship(deleteRule: .cascade, inverse: \BookNote.book)
    var notes: [BookNote] = []

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var sessions: [ReadingSession] = []

    @Relationship(inverse: \BookCollection.books)
    var collections: [BookCollection] = []

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    var coverImage: NSImage? {
        guard let data = coverImageData else { return nil }
        return NSImage(data: data)
    }

    var progressPercent: Double {
        guard totalPages > 0 else { return 0 }
        return min(Double(currentPage) / Double(totalPages), 1.0)
    }

    var totalPagesRead: Int { sessions.reduce(0) { $0 + $1.pagesRead } }
    var totalReadingMinutes: Int { sessions.reduce(0) { $0 + $1.durationMinutes } }

    init(title: String, author: String = "", totalPages: Int = 0,
         status: ReadingStatus = .wantToRead, hexColor: String = "#4C8EF7") {
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.statusRaw = status.rawValue
        self.hexColor = hexColor
    }
}

// MARK: - Okuma serisi yardımcısı

struct ReadingStreakHelper {
    static func currentStreak(sessions: [ReadingSession]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        let sessionDates = Set(sessions.map { cal.startOfDay(for: $0.date) })

        // Bugün veya dün okuduysa başlat
        if !sessionDates.contains(today) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  sessionDates.contains(yesterday) else { return 0 }
            checkDate = yesterday
        }

        while sessionDates.contains(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    static func longestStreak(sessions: [ReadingSession]) -> Int {
        let cal = Calendar.current
        let dates = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted()
        guard !dates.isEmpty else { return 0 }

        var longest = 1, current = 1
        for i in 1..<dates.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: dates[i-1]),
               cal.isDate(prev, inSameDayAs: dates[i]) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    static func last7DaysSessions(sessions: [ReadingSession]) -> [(Date, Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> (Date, Int) in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let pages = sessions
                .filter { cal.isDate(cal.startOfDay(for: $0.date), inSameDayAs: date) }
                .reduce(0) { $0 + $1.pagesRead }
            return (date, pages)
        }
    }
}
