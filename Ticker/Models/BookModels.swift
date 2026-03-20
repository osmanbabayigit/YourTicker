import Foundation
import SwiftData
import SwiftUI

// MARK: - Okuma durumu

enum ReadingStatus: String, CaseIterable, Codable {
    case wantToRead  = "wantToRead"
    case reading     = "reading"
    case finished    = "finished"

    var label: String {
        switch self {
        case .wantToRead: return "Okunacak"
        case .reading:    return "Okuyorum"
        case .finished:   return "Okundu"
        }
    }

    var icon: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading:    return "book.open"
        case .finished:   return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .wantToRead: return .secondary
        case .reading:    return .blue
        case .finished:   return .green
        }
    }
}

// MARK: - Alıntı / Not

@Model
class BookNote {
    var id: UUID = UUID()
    var content: String = ""
    var page: Int = 0
    var isQuote: Bool = false   // true = alıntı, false = not
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
    var statusRaw: String = ReadingStatus.wantToRead.rawValue
    var rating: Int = 0           // 0-5
    var startDate: Date? = nil
    var finishDate: Date? = nil
    var coverImageData: Data? = nil
    var hexColor: String = "#4C8EF7"
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \BookNote.book)
    var notes: [BookNote] = []

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    var coverImage: NSImage? {
        guard let data = coverImageData else { return nil }
        return NSImage(data: data)
    }

    init(
        title: String,
        author: String = "",
        totalPages: Int = 0,
        status: ReadingStatus = .wantToRead,
        hexColor: String = "#4C8EF7"
    ) {
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.statusRaw = status.rawValue
        self.hexColor = hexColor
    }
}
