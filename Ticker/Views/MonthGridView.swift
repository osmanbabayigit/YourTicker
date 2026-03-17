import SwiftUI

struct MonthGridView: View {

    @Binding var selectedDate: Date
    let tasks: [TaskItem]

    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var days: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!

        return range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: start)
        }
    }

    var body: some View {
        VStack {

            Text(selectedDate, format: .dateTime.month().year())
                .font(.title)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(days, id: \.self) { day in
                    DayCell(
                        date: day,
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                        tasks: tasksFor(day)
                    )
                    .onTapGesture {
                        selectedDate = day
                    }
                }
            }
        }
        .padding()
    }

    func count(for date: Date) -> Int {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }.count
    }
    
    func tasksFor(_ date: Date) -> [TaskItem] {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }
}
//
