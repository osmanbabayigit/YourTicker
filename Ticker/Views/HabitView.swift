import SwiftUI
import SwiftData

struct HabitView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var showingAddHabit = false
    @State private var editingHabit: Habit? = nil

    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Bug"]

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }

    private var todayExpected: Int { activeHabits.filter { $0.isExpectedToday }.count }
    private var todayCompleted: Int {
        activeHabits.filter { $0.isExpectedToday && $0.isCompletedOn(Date()) }.count
    }

    private var overallWeekRate: Double {
        let rates = activeHabits.map { $0.weeklyRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            weekHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if activeHabits.isEmpty {
                emptyState
            } else {
                habitList
            }
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingAddHabit) { AddHabitView() }
        .sheet(item: $editingHabit) { EditHabitView(habit: $0) }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Alışkanlıklar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Text(Date(), format: .dateTime.day().month(.wide).year())
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }

            Spacer()

            // Günlük özet
            if todayExpected > 0 {
                HStack(spacing: 6) {
                    Text("\(todayCompleted)/\(todayExpected)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(todayCompleted == todayExpected ? TickerTheme.green : TickerTheme.textPrimary)
                    Text("bugün")
                        .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)

                    // Mini progress
                    ZStack(alignment: .leading) {
                        Capsule().fill(TickerTheme.bgPill).frame(width: 50, height: 4)
                        Capsule()
                            .fill(todayCompleted == todayExpected ? TickerTheme.green : TickerTheme.blue)
                            .frame(
                                width: todayExpected > 0
                                ? 50 * CGFloat(todayCompleted) / CGFloat(todayExpected) : 0,
                                height: 4
                            )
                            .animation(.spring(response: 0.4), value: todayCompleted)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(TickerTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(TickerTheme.borderSub, lineWidth: 1))
            }

            // Bu hafta
            Text("Bu hafta %\(Int(overallWeekRate * 100))")
                .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Button { showingAddHabit = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 10))
                    Text("Ekle").font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(TickerTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Hafta başlık satırı

    private var weekHeader: some View {
        HStack(spacing: 0) {
            // Sol boşluk (alışkanlık ismi alanı)
            Spacer()

            // 7 gün
            ForEach(0..<7, id: \.self) { i in
                let date = Calendar.current.date(
                    byAdding: .day, value: -(6 - i),
                    to: Calendar.current.startOfDay(for: Date())
                )!
                let isToday = Calendar.current.isDateInToday(date)
                VStack(spacing: 2) {
                    Text(weekdays[i])
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isToday ? TickerTheme.blue : TickerTheme.textTertiary)
                    Text(date, format: .dateTime.day())
                        .font(.system(size: 10, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? TickerTheme.blue : TickerTheme.textTertiary)
                }
                .frame(width: 36)
            }

            // Streak sütunu
            Text("Seri").font(.system(size: 9, weight: .semibold))
                .foregroundStyle(TickerTheme.textTertiary)
                .frame(width: 44)
            Spacer().frame(width: 12)
        }
        .padding(.horizontal, 16).padding(.vertical, 7)
        .background(TickerTheme.bgPill.opacity(0.5))
    }

    // MARK: - Alışkanlık listesi

    private var habitList: some View {
        List {
            ForEach(activeHabits) { habit in
                HabitRow(habit: habit)
                    .listRowInsets(EdgeInsets(top: 3, leading: 14, bottom: 3, trailing: 14))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        Button { editingHabit = habit } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        Divider()
                        Button {
                            habit.isArchived = true
                            try? context.save()
                        } label: { Label("Arşivle", systemImage: "archivebox") }
                        Button(role: .destructive) {
                            context.delete(habit); try? context.save()
                        } label: { Label("Sil", systemImage: "trash") }
                    }
            }
            .onMove { from, to in
                var reordered = activeHabits
                reordered.move(fromOffsets: from, toOffset: to)
                for (i, h) in reordered.enumerated() { h.sortOrder = i }
                try? context.save()
            }

            Color.clear.frame(height: 40)
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(TickerTheme.bgApp)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "repeat.circle")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(TickerTheme.textTertiary)
            VStack(spacing: 4) {
                Text("Henüz alışkanlık yok")
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(TickerTheme.textSecondary)
                Text("Küçük adımlar büyük değişimlere yol açar")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            Button { showingAddHabit = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 11))
                    Text("Alışkanlık Ekle").font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(TickerTheme.green)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(TickerTheme.green.opacity(0.12)).clipShape(Capsule())
                .overlay(Capsule().stroke(TickerTheme.green.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity).background(TickerTheme.bgApp)
    }
}

// MARK: - Alışkanlık satırı

struct HabitRow: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var context
    @State private var isHovered = false

    private var days: [(date: Date, status: DayStatus)] { habit.last7Days() }

    var body: some View {
        HStack(spacing: 0) {
            // Sol: emoji + isim
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: habit.hexColor).opacity(0.12))
                        .frame(width: 32, height: 32)
                    Text(habit.emoji).font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TickerTheme.textPrimary).lineLimit(1)
                    Text(habit.frequency.label)
                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                }
            }
            .frame(minWidth: 140, alignment: .leading)

            Spacer()

            // 7 günlük kutucuklar
            HStack(spacing: 4) {
                ForEach(days, id: \.date) { day in
                    DayCheckbox(
                        date: day.date,
                        status: day.status,
                        color: Color(hex: habit.hexColor)
                    ) {
                        toggleDay(day.date)
                    }
                }
            }

            // Streak
            HStack(spacing: 3) {
                if habit.currentStreak > 0 {
                    Text("🔥")
                        .font(.system(size: 12))
                    Text("\(habit.currentStreak)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(TickerTheme.orange)
                } else {
                    Text("—")
                        .font(.system(size: 12))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
            }
            .frame(width: 44, alignment: .center)

            Spacer().frame(width: 4)
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(isHovered ? TickerTheme.bgCardHover : TickerTheme.bgCard)
        )
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(TickerTheme.borderSub, lineWidth: 1))
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }

    private func toggleDay(_ date: Date) {
        let cal = Calendar.current
        if let existing = habit.completions.first(where: { cal.isDate($0.date, inSameDayAs: date) }) {
            context.delete(existing)
        } else {
            let c = HabitCompletion(date: date)
            c.habit = habit
            context.insert(c)
        }
        try? context.save()
    }
}

// MARK: - Gün checkbox

struct DayCheckbox: View {
    let date: Date
    let status: DayStatus
    let color: Color
    let onTap: () -> Void

    @State private var isHovered = false

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(bgColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor, lineWidth: isToday ? 1.5 : 0.5)
                    )

                switch status {
                case .completed:
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)
                case .missed:
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundStyle(TickerTheme.textTertiary.opacity(0.5))
                case .pending:
                    EmptyView()
                case .notExpected:
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundStyle(TickerTheme.textTertiary.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .disabled(status == .notExpected)
        .scaleEffect(isHovered && status != .notExpected ? 1.1 : 1.0)
        .animation(.spring(response: 0.2), value: isHovered)
    }

    private var bgColor: Color {
        switch status {
        case .completed:   return color.opacity(0.15)
        case .missed:      return Color.white.opacity(0.03)
        case .pending:     return isHovered ? color.opacity(0.08) : Color.white.opacity(0.04)
        case .notExpected: return Color.clear
        }
    }

    private var borderColor: Color {
        switch status {
        case .completed:   return color.opacity(0.3)
        case .pending:     return isToday ? color.opacity(0.4) : Color.white.opacity(0.08)
        case .missed:      return Color.white.opacity(0.05)
        case .notExpected: return Color.clear
        }
    }
}

// MARK: - Alışkanlık Ekleme

struct AddHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]

    @State private var title = ""
    @State private var emoji = "⭐"
    @State private var hexColor = "#34D399"
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: [Int] = []
    @FocusState private var titleFocused: Bool

    private let colorOptions = [
        "#34D399","#3B82F6","#A78BFA","#FB923C",
        "#F472B6","#FBBF24","#2DD4BF","#F87171"
    ]
    private let emojiOptions = [
        "⭐","🏃","📖","💧","🧘","💪","🎨","💻",
        "🌱","❤️","🥗","😴","✍️","🎵","🚴","🧹"
    ]
    private let dayNames = ["Paz","Pzt","Sal","Çar","Per","Cum","Cmt"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 18))
                Text("Yeni Alışkanlık")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
                Button("Ekle") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: hexColor))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: hexColor).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    // Başlık
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Alışkanlık Adı", icon: "repeat")
                        TextField("Ne yapmak istiyorsun?", text: $title)
                            .textFieldStyle(.plain).font(.system(size: 14))
                            .foregroundStyle(TickerTheme.textPrimary).focused($titleFocused)
                            .padding(10).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Emoji
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Emoji", icon: "face.smiling")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button { emoji = e } label: {
                                    Text(e).font(.system(size: 18))
                                        .frame(width: 34, height: 34)
                                        .background(emoji == e
                                                    ? Color(hex: hexColor).opacity(0.15) : TickerTheme.bgPill)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.2), value: emoji)
                            }
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Renk
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Renk", icon: "circle.hexagongrid")
                        HStack(spacing: 8) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button { hexColor = hex } label: {
                                    ZStack {
                                        Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                                        if hexColor == hex {
                                            Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2)
                                                .frame(width: 24, height: 24)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.15), value: hexColor)
                            }
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Sıklık
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Sıklık", icon: "calendar.badge.clock")
                        HStack(spacing: 6) {
                            ForEach(HabitFrequency.allCases, id: \.self) { f in
                                Button { frequency = f } label: {
                                    Text(f.label).font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(frequency == f
                                                         ? Color(hex: hexColor) : TickerTheme.textTertiary)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(frequency == f
                                                    ? Color(hex: hexColor).opacity(0.12) : TickerTheme.bgPill)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.2), value: frequency)
                            }
                        }

                        if frequency == .custom {
                            HStack(spacing: 5) {
                                ForEach(1...7, id: \.self) { day in
                                    let isSelected = customDays.contains(day)
                                    Button {
                                        if isSelected { customDays.removeAll { $0 == day } }
                                        else { customDays.append(day) }
                                    } label: {
                                        Text(dayNames[day - 1])
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(isSelected ? Color(hex: hexColor) : TickerTheme.textTertiary)
                                            .frame(width: 34, height: 28)
                                            .background(isSelected ? Color(hex: hexColor).opacity(0.12) : TickerTheme.bgPill)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(18)
                    .animation(.spring(response: 0.25), value: frequency)
                }
            }
        }
        .frame(width: 400)
        .background(Color(hex: "#161618"))
        .onAppear { titleFocused = true }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (habits.map { $0.sortOrder }.max() ?? -1) + 1
        let habit = Habit(title: trimmed, emoji: emoji,
                          hexColor: hexColor, frequency: frequency)
        habit.customWeekdays = frequency == .custom ? customDays : []
        habit.sortOrder = order
        context.insert(habit); try? context.save(); dismiss()
    }
}

// MARK: - Alışkanlık Düzenleme

struct EditHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit

    @State private var title: String
    @State private var emoji: String
    @State private var hexColor: String
    @State private var frequency: HabitFrequency
    @State private var customDays: [Int]

    init(habit: Habit) {
        self.habit = habit
        _title = State(initialValue: habit.title)
        _emoji = State(initialValue: habit.emoji)
        _hexColor = State(initialValue: habit.hexColor)
        _frequency = State(initialValue: habit.frequency)
        _customDays = State(initialValue: habit.customWeekdays)
    }

    private let colorOptions = [
        "#34D399","#3B82F6","#A78BFA","#FB923C",
        "#F472B6","#FBBF24","#2DD4BF","#F87171"
    ]
    private let emojiOptions = [
        "⭐","🏃","📖","💧","🧘","💪","🎨","💻",
        "🌱","❤️","🥗","😴","✍️","🎵","🚴","🧹"
    ]
    private let dayNames = ["Paz","Pzt","Sal","Çar","Per","Cum","Cmt"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 18))
                Text("Düzenle").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
                Button("Kaydet") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: hexColor))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: hexColor).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            VStack(spacing: 14) {
                TextField("Alışkanlık adı", text: $title)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .padding(9).background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 8), spacing: 5) {
                    ForEach(emojiOptions, id: \.self) { e in
                        Button { emoji = e } label: {
                            Text(e).font(.system(size: 16))
                                .frame(width: 30, height: 30)
                                .background(emoji == e ? Color(hex: hexColor).opacity(0.15) : TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Button { hexColor = hex } label: {
                            ZStack {
                                Circle().fill(Color(hex: hex)).frame(width: 22, height: 22)
                                if hexColor == hex {
                                    Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2).frame(width: 22, height: 22)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Sıklık
                HStack(spacing: 5) {
                    ForEach(HabitFrequency.allCases, id: \.self) { f in
                        Button { frequency = f } label: {
                            Text(f.label).font(.system(size: 11))
                                .foregroundStyle(frequency == f ? Color(hex: hexColor) : TickerTheme.textTertiary)
                                .padding(.horizontal, 9).padding(.vertical, 5)
                                .background(frequency == f ? Color(hex: hexColor).opacity(0.12) : TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if frequency == .custom {
                    HStack(spacing: 4) {
                        ForEach(1...7, id: \.self) { day in
                            let isSel = customDays.contains(day)
                            Button {
                                if isSel { customDays.removeAll { $0 == day } }
                                else { customDays.append(day) }
                            } label: {
                                Text(dayNames[day-1]).font(.system(size: 10, weight: .semibold))
                                    .frame(width: 30, height: 26)
                                    .foregroundStyle(isSel ? Color(hex: hexColor) : TickerTheme.textTertiary)
                                    .background(isSel ? Color(hex: hexColor).opacity(0.12) : TickerTheme.bgPill)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Sil
                Button(role: .destructive) {
                    context.delete(habit); try? context.save(); dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash").font(.system(size: 12))
                        Text("Alışkanlığı Sil").font(.system(size: 13))
                    }
                    .foregroundStyle(TickerTheme.red)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .frame(width: 380)
        .background(Color(hex: "#161618"))
    }

    private func save() {
        habit.title = title.trimmingCharacters(in: .whitespaces)
        habit.emoji = emoji; habit.hexColor = hexColor
        habit.frequency = frequency
        habit.customWeekdays = frequency == .custom ? customDays : []
        try? context.save(); dismiss()
    }
}
