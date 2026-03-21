import Foundation
import SwiftData
import SwiftUI

// MARK: - Klasör

@Model
class NoteFolder {
    var id: UUID = UUID()
    var name: String = ""
    var hexColor: String = "#FBBF24"
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Note.folder)
    var notes: [Note] = []

    init(name: String, hexColor: String = "#FBBF24", sortOrder: Int = 0) {
        self.name = name
        self.hexColor = hexColor
        self.sortOrder = sortOrder
    }

    var color: Color { Color(hex: hexColor) }
}

// MARK: - Not

@Model
class Note {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isPinned: Bool = false
    var hexColor: String = "#FBBF24"

    var folder: NoteFolder? = nil

    init(title: String = "", content: String = "",
         hexColor: String = "#FBBF24") {
        self.title = title
        self.content = content
        self.hexColor = hexColor
    }

    // Önizleme metni
    var preview: String {
        let stripped = content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .dropFirst()
            .first ?? ""
        return stripped.isEmpty ? "Not içeriği yok" : stripped
    }

    // Okuma süresi
    var readingTime: String {
        let words = content.components(separatedBy: .whitespaces).count
        let minutes = max(1, words / 200)
        return "\(minutes) dk okuma"
    }

    // Tarih formatı
    var relativeDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(updatedAt)     { return "Az önce" }
        if cal.isDateInYesterday(updatedAt) { return "Dün" }
        let days = cal.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
        if days < 7 { return "\(days) gün önce" }
        return updatedAt.formatted(.dateTime.day().month(.abbreviated))
    }
}
