import SwiftUI
import SwiftData

enum StatsPeriod: String, CaseIterable {
    case today = "Bugün"
    case week  = "Bu Hafta"
    case month = "Bu Ay"
}

struct StatsView: View {
    @Query private var pomodoroSessions: [PomodoroSession]
    @Query private var tasks: [TaskItem]
    @Query private var habits: [Habit]

    @State private var period: StatsPeriod = .today

    // MARK: - Filtered data

    private var filteredPomodoro: [PomodoroSession] {
        let cal = Calendar.current
        let now = Date()
        return pomodoroSessions.filter { s in
            switch period {
            case .today: return cal.isDateInToday(s.date)
            case .week:  return cal.isDate(s.date, equalTo: now, toGranularity: .weekOfYear)
            case .month: return cal.isDate(s.date, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var filteredTasks: [TaskItem] {
        let cal = Calendar.current
        let now = Date()
        return tasks.filter { t in
            guard t.isCompleted, let d = t.dueDate else { return false }
            switch period {
            case .today: return cal.isDateInToday(d)
            case .week:  return cal.isDate(d, equalTo: now, toGranularity: .weekOfYear)
            case .month: return cal.isDate(d, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var focusSessions: Int { filteredPomodoro.filter { $0.pomodoroMode == .focus && $0.completed }.count }
    private var focusMinutes:  Int { filteredPomodoro.filter { $0.pomodoroMode == .focus }.reduce(0) { $0 + $1.durationMinutes } }
    private var completedTasks: Int { filteredTasks.count }

    private var habitScore: String {
        let active = habits.filter { !$0.isArchived && $0.isExpectedToday }
        let done   = active.filter { $0.isCompletedOn(Date()) }
        guard !active.isEmpty else { return "—" }
        return "\(done.count)/\(active.count)"
    }

    // MARK: - Saatlik yoğunluk (pomodoro seansları saate göre)

    private var hourlyData: [(hour: Int, count: Int)] {
        let grouped = Dictionary(grouping: filteredPomodoro.filter { $0.pomodoroMode == .focus }) {
            Calendar.current.component(.hour, from: $0.date)
        }
        let hours = Array(Set(grouped.keys)).sorted()
        guard !hours.isEmpty else { return [] }
        return hours.map { h in (h, grouped[h]?.count ?? 0) }
    }

    // MARK: - Haftalık trend

    private var weeklyTrend: [(date: Date, minutes: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> (Date, Int) in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let mins = pomodoroSessions
                .filter { cal.isDate($0.date, inSameDayAs: date) && $0.pomodoroMode == .focus && $0.completed }
                .reduce(0) { $0 + $1.durationMinutes }
            return (date, mins)
        }
    }

    // MARK: - Etiket dağılımı

    private var tagDistribution: [(name: String, color: String, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        let periodTasks = tasks.filter { t in
            let d = t.dueDate ?? t.dueDate
            switch period {
            case .today: return d.map { cal.isDateInToday($0) } ?? false
            case .week:  return d.map { cal.isDate($0, equalTo: now, toGranularity: .weekOfYear) } ?? false
            case .month: return d.map { cal.isDate($0, equalTo: now, toGranularity: .month) } ?? false
            }
        }
        var map: [String: (String, Int)] = [:]
        for task in periodTasks {
            for tag in task.tags {
                map[tag.name, default: (tag.hexColor, 0)].1 += 1
            }
        }
        let result: [(name: String, color: String, count: Int)] = map.map { (name: $0.key, color: $0.value.0, count: $0.value.1) }
        return result.sorted { $0.count > $1.count }.prefix(5).map { $0 }
    }

    // MARK: - Alışkanlık serileri

    private var topStreaks: [(emoji: String, title: String, streak: Int)] {
        habits
            .filter { !$0.isArchived }
            .compactMap { h -> (emoji: String, title: String, streak: Int)? in
                let streak = h.currentStreak
                guard streak > 0 else { return nil }
                return (h.emoji, h.title, streak)
            }
            .sorted { $0.streak > $1.streak }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 12) {
                    summaryCards
                    chartsRow
                    if !tagDistribution.isEmpty { tagDistributionCard }
                    if !habits.filter({ !$0.isArchived }).isEmpty { streakCard }
                    if !filteredPomodoro.isEmpty { pomodoroHistoryCard }
                }
                .padding(16)
            }
        }
        .background(TickerTheme.bgApp)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("İstatistikler")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerTheme.textPrimary)
            Spacer()
            HStack(spacing: 2) {
                ForEach(StatsPeriod.allCases, id: \.self) { p in
                    Button { withAnimation(.spring(response: 0.2)) { period = p } } label: {
                        Text(p.rawValue).font(.system(size: 11, weight: .medium))
                            .foregroundStyle(period == p ? TickerTheme.red : TickerTheme.textTertiary)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(period == p ? TickerTheme.red.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2).background(TickerTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    // MARK: - Özet kartlar

    private var summaryCards: some View {
        HStack(spacing: 10) {
            statCard(value: "\(focusSessions)", label: "Pomodoro",
                     color: TickerTheme.red, icon: "timer")
            statCard(value: focusMinutes >= 60
                     ? "\(focusMinutes/60)s \(focusMinutes%60)dk"
                     : "\(focusMinutes)dk",
                     label: "Odak", color: TickerTheme.blue, icon: "brain.head.profile")
            statCard(value: "\(completedTasks)", label: "Görev",
                     color: TickerTheme.green, icon: "checkmark.circle")
            statCard(value: habitScore, label: "Alışkanlık",
                     color: Color(hex: "#A78BFA"), icon: "repeat.circle")
        }
    }

    @ViewBuilder
    private func statCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Grafikler (2 yan yana)

    private var chartsRow: some View {
        HStack(spacing: 10) {
            // Saatlik yoğunluk
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Saatlik Yoğunluk", icon: "clock")
                if hourlyData.isEmpty {
                    emptyChart("Veri yok")
                } else {
                    hourlyChart
                }
            }
            .padding(14)
            .background(TickerTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(TickerTheme.borderSub, lineWidth: 1))
            .frame(maxWidth: .infinity)

            // Haftalık trend
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Haftalık Trend", icon: "chart.bar")
                weeklyChart
            }
            .padding(14)
            .background(TickerTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(TickerTheme.borderSub, lineWidth: 1))
            .frame(maxWidth: .infinity)
        }
    }

    private var hourlyChart: some View {
        let maxCount = max(hourlyData.map { $0.count }.max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(hourlyData, id: \.hour) { item in
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(TickerTheme.red.opacity(
                            0.2 + 0.6 * Double(item.count) / Double(maxCount)
                        ))
                        .frame(
                            width: 14,
                            height: max(CGFloat(item.count) / CGFloat(maxCount) * 56, 4)
                        )
                    Text("\(item.hour)")
                        .font(.system(size: 8)).foregroundStyle(TickerTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 72)
    }

    private var weeklyChart: some View {
        let maxMins = max(weeklyTrend.map { $0.minutes }.max() ?? 1, 1)
        let dayLabels = ["Pzt","Sal","Çar","Per","Cum","Cmt","Bug"]
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(weeklyTrend.enumerated()), id: \.offset) { idx, item in
                let isToday = Calendar.current.isDateInToday(item.date)
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isToday ? TickerTheme.blue : TickerTheme.blue.opacity(
                            item.minutes > 0 ? 0.2 + 0.4 * Double(item.minutes) / Double(maxMins) : 0.05
                        ))
                        .frame(
                            width: 14,
                            height: item.minutes > 0
                            ? max(CGFloat(item.minutes) / CGFloat(maxMins) * 56, 4)
                            : 3
                        )
                    Text(dayLabels[idx % 7])
                        .font(.system(size: 8))
                        .foregroundStyle(isToday ? TickerTheme.blue : TickerTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 72)
    }

    // MARK: - Etiket dağılımı

    private var tagDistributionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Etiket Dağılımı", icon: "tag")
            let maxCount = tagDistribution.map { $0.count }.max() ?? 1
            VStack(spacing: 7) {
                ForEach(tagDistribution, id: \.name) { tag in
                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            Circle().fill(Color(hex: tag.color)).frame(width: 6, height: 6)
                            Text(tag.name).font(.system(size: 11))
                                .foregroundStyle(TickerTheme.textSecondary)
                        }
                        .frame(width: 80, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(TickerTheme.bgPill).frame(height: 5)
                                Capsule()
                                    .fill(Color(hex: tag.color))
                                    .frame(
                                        width: geo.size.width * CGFloat(tag.count) / CGFloat(maxCount),
                                        height: 5
                                    )
                            }
                        }
                        .frame(height: 5)

                        Text("\(tag.count)").font(.system(size: 10))
                            .foregroundStyle(TickerTheme.textTertiary).frame(width: 20, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .background(TickerTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(TickerTheme.borderSub, lineWidth: 1))
    }

    // MARK: - Alışkanlık serileri

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("En Uzun Seriler", icon: "flame.fill")
            if topStreaks.isEmpty {
                Text("Henüz seri yok — alışkanlıkları tamamlamaya başla!")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(topStreaks.enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 10) {
                            Text("\(idx + 1)").font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(TickerTheme.textTertiary).frame(width: 14)
                            Text(item.emoji).font(.system(size: 16))
                            Text(item.title).font(.system(size: 12)).foregroundStyle(TickerTheme.textSecondary)
                            Spacer()
                            Text("🔥").font(.system(size: 12))
                            Text("\(item.streak)")
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(TickerTheme.orange)
                        }
                        if idx < topStreaks.count - 1 {
                            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(TickerTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(TickerTheme.borderSub, lineWidth: 1))
    }

    // MARK: - Pomodoro geçmişi

    private var pomodoroHistoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Pomodoro Geçmişi", icon: "timer")
            VStack(spacing: 4) {
                ForEach(filteredPomodoro.prefix(8)) { s in
                    HStack(spacing: 10) {
                        // Mod rengi + ikonu
                        ZStack {
                            Circle()
                                .fill(s.pomodoroMode.color.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: s.pomodoroMode.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(s.pomodoroMode.color)
                        }

                        // Bilgi
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.pomodoroMode.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(TickerTheme.textPrimary)
                            if !s.linkedTaskTitle.isEmpty {
                                Text(s.linkedTaskTitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(TickerTheme.textTertiary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        // Süre + saat
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(s.durationMinutes) dk")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(s.pomodoroMode.color)
                            Text(s.date, format: .dateTime.hour().minute())
                                .font(.system(size: 9))
                                .foregroundStyle(TickerTheme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(TickerTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(s.pomodoroMode.color.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(TickerTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(TickerTheme.borderSub, lineWidth: 1))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    @ViewBuilder
    private func emptyChart(_ text: String) -> some View {
        Text(text).font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            .frame(maxWidth: .infinity, minHeight: 72)
    }
}
