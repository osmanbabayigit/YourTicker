import SwiftUI

struct AgendaView: View {

    let date: Date
    let tasks: [TaskItem]

    var filtered: [TaskItem] {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {

            Text(date, style: .date)
                .font(.largeTitle.bold())
                .padding()

            if filtered.isEmpty {
                Spacer()
                Text("Boş gün")
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filtered) { task in
                            TaskRow(task: task)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
//
