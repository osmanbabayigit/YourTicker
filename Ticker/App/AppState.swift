import SwiftUI
import AppKit
import Combine

class AppState: ObservableObject {
    @Published var searchText: String = ""
    @Published var showingQuickCapture: Bool = false
    @Published var sidebarVisible: Bool = true

    init() {
        // Local monitor — uygulama odaktayken
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 45 &&
               event.modifierFlags.contains(.command) &&
               !event.modifierFlags.contains(.shift) &&
               !event.modifierFlags.contains(.option) {
                DispatchQueue.main.async { self?.showingQuickCapture = true }
                return nil
            }
            return event
        }
    }
}
