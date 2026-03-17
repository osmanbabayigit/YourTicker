import SwiftUI
import SwiftData

@main
struct TickerApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(for: TaskItem.self)
    }
}
//
