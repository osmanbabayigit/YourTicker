import Foundation
import SwiftData
import SwiftUI

@Model
class TagItem {
    var id: UUID = UUID()
    var name: String = ""
    var hexColor: String = "#4C8EF7"
    var tasks: [TaskItem] = []

    init(name: String, hexColor: String = "#4C8EF7") {
        self.name = name
        self.hexColor = hexColor
    }

    var color: Color { Color(hex: hexColor) }
}
