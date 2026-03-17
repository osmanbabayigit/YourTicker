import SwiftUI
import Foundation

struct DayCell: View {

    let date: Date
    let isSelected: Bool
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(tasks.prefix(3)) { task in
                    Text(task.title)
                        .font(.system(size: 9))
                        .lineLimit(1)
                        .padding(2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)
                }
            }

            Spacer()
        }
        .padding(4)
        .frame(height: 70)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}
//
