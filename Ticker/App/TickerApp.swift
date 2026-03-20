import SwiftUI
import SwiftData

@main
struct TickerApp: App {
    @StateObject private var appState = AppState()

    let container: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            TagItem.self,
            SubTaskItem.self,
            BudgetCard.self,
            BudgetCategory.self,
            BudgetEntry.self,
            BookItem.self,
            BookNote.self,
            BookCollection.self,
            ReadingSession.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("ModelContainer oluşturulamadı: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(container)
    }
}
