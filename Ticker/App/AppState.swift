import SwiftUI
import AppKit
import Combine

class AppState: ObservableObject {
    @Published var searchText: String = ""
    @Published var showingQuickCapture: Bool = false
    @Published var sidebarVisible: Bool = true

    private var eventMonitor: Any?

    init() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // ⌘N → Hızlı not
            if event.keyCode == 45 &&
               event.modifierFlags.contains(.command) &&
               !event.modifierFlags.contains(.shift) &&
               !event.modifierFlags.contains(.option) {
                DispatchQueue.main.async { self.showingQuickCapture = true }
                return nil
            }

            // ⌘⇧S → Sidebar toggle
            if event.keyCode == 1 &&
               event.modifierFlags.contains(.command) &&
               event.modifierFlags.contains(.shift) &&
               !event.modifierFlags.contains(.option) {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        self.sidebarVisible.toggle()
                    }
                }
                return nil
            }

            return event
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
