import Foundation
import Combine
import SwiftUI

final class AppState: ObservableObject {
    @Published var searchText: String = ""
    @Published var sidebarVisible: Bool = true
}
