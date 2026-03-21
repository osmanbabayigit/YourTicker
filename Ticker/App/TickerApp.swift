import SwiftUI
import SwiftData
import AppKit

@main
struct TickerApp: App {
    @StateObject private var appState = AppState()

    let container: ModelContainer = {
        let schema = Schema([
            TaskItem.self, TagItem.self, SubTaskItem.self,
            BudgetCard.self, BudgetCategory.self, BudgetEntry.self,
            BookItem.self, BookNote.self, BookCollection.self,
            ReadingSession.self, PomodoroSession.self,
            Goal.self, GoalMilestone.self,
            Habit.self, HabitCompletion.self,
            Note.self, NoteFolder.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do { return try ModelContainer(for: schema, configurations: [fallback]) }
            catch { fatalError("ModelContainer oluşturulamadı: \(error)") }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    NSApp.appearance = NSAppearance(named: .darkAqua)
                    configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Hızlı Not") { appState.showingQuickCapture = true }
                    .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .modelContainer(container)
    }

    private func configureWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = NSColor(calibratedRed: 0.047, green: 0.047, blue: 0.055, alpha: 1)
            window.styleMask.insert(.fullSizeContentView)
        }
    }
}
