import SwiftUI
import SwiftData

struct TaskListView: View {

    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState

    @Query private var tasks: [TaskItem]

    let showCompleted: Bool
    let title: String

    @State private var text = ""

    var filtered: [TaskItem] {
        tasks.filter {
            $0.isCompleted == showCompleted &&
            (appState.searchText.isEmpty ||
             $0.title.localizedCaseInsensitiveContains(appState.searchText))
        }
    }

    var body: some View {
        VStack {

            HStack {
                TextField("Yeni görev", text: $text)
                Button("Ekle") {
                    context.insert(TaskItem(title: text))
                    text = ""
                }
            }
            .padding()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filtered) { task in
                        TaskRow(task: task)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(title)
    }
}
//
