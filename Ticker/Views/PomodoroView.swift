import SwiftUI
import SwiftData
import AppKit

struct PomodoroView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PomodoroSession.date, order: .reverse) private var sessions: [PomodoroSession]
    @Query private var tasks: [TaskItem]

    @StateObject private var nowPlaying = NowPlayingManager.shared

    // Timer state
    @State private var mode: PomodoroMode = .focus
    @State private var isRunning = false
    @State private var secondsLeft: Int = PomodoroSettings.focusMinutes * 60
    @State private var totalSeconds: Int = PomodoroSettings.focusMinutes * 60
    @State private var completedFocusSessions = 0
    @State private var consecutiveSessions = 0  // Kesintisiz seans sayısı
    @State private var timer: Timer? = nil

    // Görev
    @State private var linkedTask: TaskItem? = nil
    @State private var showingTaskPicker = false
    @State private var showingSettings = false

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(secondsLeft) / Double(totalSeconds)
    }

    private var timeString: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    private var focusScore: Int {
        // Kesintisiz seans * 25 + (bugün toplam dakika / 5)
        let base = consecutiveSessions * 25
        let bonus = min(PomodoroStatsHelper.todayFocusMinutes(sessions) / 5, 50)
        return min(base + bonus, 100)
    }

    private var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }.sorted { $0.priority > $1.priority }
    }

    private var todayFocusCount: Int { PomodoroStatsHelper.todayFocusCount(sessions) }
    private var todayFocusMinutes: Int { PomodoroStatsHelper.todayFocusMinutes(sessions) }

    var body: some View {
        HSplitView {
            timerPanel.frame(minWidth: 340)
            sidePanel.frame(minWidth: 200, maxWidth: 260)
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingSettings) { PomodoroSettingsView() }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(tasks: pendingTasks, selected: $linkedTask)
        }
        .onDisappear { stopTimer() }
    }

    // MARK: - Timer paneli

    private var timerPanel: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("Pomodoro")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13)).foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18).padding(.vertical, 12)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Mod seçici
            HStack(spacing: 4) {
                ForEach(PomodoroMode.allCases, id: \.self) { m in
                    Button { switchMode(m) } label: {
                        Text(m.label).font(.system(size: 11, weight: .medium))
                            .foregroundStyle(mode == m ? m.color : TickerTheme.textTertiary)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(mode == m ? m.color.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.2), value: mode)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 10)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            Spacer()

            // Ring
            ringView

            Spacer().frame(height: 24)

            // Kontroller
            controls

            Spacer().frame(height: 18)

            // Seans dots
            sessionDots

            Spacer()
        }
        .background(TickerTheme.bgApp)
    }

    // MARK: - Ring (güzel animasyonlu)

    private var ringView: some View {
        ZStack {
            // Dış halka - arka plan
            Circle()
                .stroke(mode.color.opacity(0.08), lineWidth: 14)
                .frame(width: 210, height: 210)

            // Parlayan efekt — koşunca aktif
            if isRunning {
                Circle()
                    .stroke(
                        mode.color.opacity(0.04),
                        lineWidth: 24
                    )
                    .frame(width: 210, height: 210)
                    .blur(radius: 8)
            }

            // İlerleme halkası
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [mode.color.opacity(0.6), mode.color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Uç nokta parlaması
            if progress > 0.01 {
                Circle()
                    .fill(mode.color)
                    .frame(width: 14, height: 14)
                    .shadow(color: mode.color, radius: 6)
                    .offset(y: -105)
                    .rotationEffect(.degrees(-90 + 360 * progress))
                    .animation(.linear(duration: 1), value: progress)
            }

            // İç içerik
            VStack(spacing: 5) {
                Text(timeString)
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.color)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: secondsLeft)

                Text(mode.label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .kerning(1.5)
            }
        }
    }

    // MARK: - Kontroller

    private var controls: some View {
        HStack(spacing: 18) {
            Button { resetTimer() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(TickerTheme.bgPill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button { isRunning ? pauseTimer() : startTimer() } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(mode.color)
                    .clipShape(Circle())
                    .shadow(color: mode.color.opacity(0.35), radius: 12, y: 4)
                    .scaleEffect(isRunning ? 1.0 : 0.97)
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.2), value: isRunning)

            Button { skipToNext() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(TickerTheme.bgPill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Seans noktaları

    private var sessionDots: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ForEach(0..<PomodoroSettings.sessionsUntilLongBreak, id: \.self) { i in
                    Capsule()
                        .fill(i < (completedFocusSessions % PomodoroSettings.sessionsUntilLongBreak)
                              ? mode.color : TickerTheme.bgPill)
                        .frame(width: i < (completedFocusSessions % PomodoroSettings.sessionsUntilLongBreak)
                               ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: completedFocusSessions)
                }
            }
            Text("\(completedFocusSessions) seans tamamlandı")
                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
        }
    }

    // MARK: - Yan panel

    private var sidePanel: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Now Playing
                nowPlayingSection
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                // Odak skoru
                focusScoreSection
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                // Aktif görev
                activeTaskSection
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                // Sıradaki görevler
                nextTasksSection
                Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                // Bugün
                todayStatsSection
            }
        }
        .background(TickerTheme.bgSidebar)
    }

    // MARK: - Now Playing

    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                // EQ animasyonu
                if nowPlaying.info.isPlaying {
                    EQBarsView(color: TickerTheme.green)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                }
                Text("Şu an çalıyor").font(.system(size: 10, weight: .medium)).kerning(0.3)
                    .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
            }

            if nowPlaying.info.isEmpty {
                Text("Müzik uygulaması açık değil")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    .padding(.vertical, 4)
            } else {
                HStack(spacing: 10) {
                    // Albüm art
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(TickerTheme.green.opacity(0.15))
                            .frame(width: 38, height: 38)
                        if let data = nowPlaying.info.artworkData,
                           let img = NSImage(data: data) {
                            Image(nsImage: img).resizable().scaledToFill()
                                .frame(width: 38, height: 38).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 14)).foregroundStyle(TickerTheme.green)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlaying.info.title.isEmpty ? "Bilinmiyor" : nowPlaying.info.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TickerTheme.textPrimary).lineLimit(1)
                        Text(nowPlaying.info.artist.isEmpty ? "—" : nowPlaying.info.artist)
                            .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary).lineLimit(1)
                    }
                }

                // Progress bar
                if nowPlaying.info.duration > 0 {
                    VStack(spacing: 3) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(TickerTheme.bgPill).frame(height: 2)
                                Capsule().fill(TickerTheme.green)
                                    .frame(width: geo.size.width * nowPlaying.info.progressRatio, height: 2)
                            }
                        }
                        .frame(height: 2)

                        HStack {
                            Text(nowPlaying.info.elapsedString)
                            Spacer()
                            Text(nowPlaying.info.durationString)
                        }
                        .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                    }
                }
            }
        }
        .padding(14)
    }

    // MARK: - Odak skoru

    private var focusScoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Odak Skoru", icon: "bolt.fill")

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(mode.color.opacity(0.1), lineWidth: 5)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: Double(focusScore) / 100)
                        .stroke(mode.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                        .animation(.spring(response: 0.5), value: focusScore)
                    Text("\(focusScore)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(mode.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(scoreLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TickerTheme.textPrimary)
                    Text("Kesintisiz \(consecutiveSessions) seans")
                        .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                }
            }
        }
        .padding(14)
    }

    private var scoreLabel: String {
        switch focusScore {
        case 80...100: return "Mükemmel 🔥"
        case 60..<80:  return "Çok iyi 💪"
        case 40..<60:  return "İyi gidiyor"
        default:       return "Devam et"
        }
    }

    // MARK: - Aktif görev

    private var activeTaskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Aktif Görev", icon: "link")

            if let task = linkedTask {
                HStack(spacing: 8) {
                    Capsule().fill(Color(hex: task.hexColor)).frame(width: 3, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title).font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TickerTheme.textPrimary).lineLimit(2)
                        Text("Bağlı görev").font(.system(size: 9))
                            .foregroundStyle(TickerTheme.textTertiary)
                    }
                    Spacer()
                    Button { linkedTask = nil } label: {
                        Image(systemName: "xmark").font(.system(size: 9))
                            .foregroundStyle(TickerTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(9)
                .background(Color(hex: task.hexColor).opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: task.hexColor).opacity(0.15), lineWidth: 1))
            } else {
                Button { showingTaskPicker = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle").font(.system(size: 12))
                        Text("Görev bağla").font(.system(size: 11))
                    }
                    .foregroundStyle(TickerTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(9).background(TickerTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(TickerTheme.borderSub, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }

    // MARK: - Sıradaki görevler

    private var nextTasksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Sıradaki", icon: "list.bullet")
            VStack(spacing: 4) {
                ForEach(pendingTasks.prefix(4)) { task in
                    Button { linkedTask = task } label: {
                        HStack(spacing: 7) {
                            Capsule().fill(Color(hex: task.hexColor)).frame(width: 2, height: 18)
                            Text(task.title).font(.system(size: 11))
                                .foregroundStyle(linkedTask?.id == task.id
                                                 ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            if linkedTask?.id == task.id {
                                Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(TickerTheme.blue)
                            }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(linkedTask?.id == task.id ? TickerTheme.blue.opacity(0.06) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Bugün istatistikleri

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Bugün", icon: "chart.bar.fill")
            HStack(spacing: 8) {
                statCard("\(todayFocusCount)", label: "seans", color: mode.color)
                statCard("\(todayFocusMinutes)", label: "dakika", color: TickerTheme.blue)
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private func statCard(_ value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    // MARK: - Timer logic

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 { secondsLeft -= 1 }
            else { timerCompleted() }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate(); timer = nil
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate(); timer = nil
    }

    private func resetTimer() {
        stopTimer()
        secondsLeft = totalSeconds
    }

    private func switchMode(_ newMode: PomodoroMode) {
        stopTimer()
        mode = newMode
        let mins: Int
        switch newMode {
        case .focus:      mins = PomodoroSettings.focusMinutes
        case .shortBreak: mins = PomodoroSettings.shortBreakMinutes
        case .longBreak:  mins = PomodoroSettings.longBreakMinutes
        }
        totalSeconds = mins * 60
        secondsLeft  = mins * 60
    }

    private func skipToNext() {
        stopTimer(); timerCompleted()
    }

    private func timerCompleted() {
        stopTimer()

        let session = PomodoroSession(
            mode: mode, durationMinutes: totalSeconds / 60,
            completed: true,
            linkedTaskTitle: linkedTask?.title ?? "",
            linkedTaskID: linkedTask?.id
        )
        context.insert(session); try? context.save()

        if PomodoroSettings.soundEnabled { NSSound.beep() }

        if mode == .focus {
            completedFocusSessions += 1
            consecutiveSessions += 1
            let isLong = completedFocusSessions % PomodoroSettings.sessionsUntilLongBreak == 0
            switchMode(isLong ? .longBreak : .shortBreak)
        } else {
            switchMode(.focus)
        }

        if PomodoroSettings.autoStartBreaks { startTimer() }
    }
}

// MARK: - EQ Bars animasyonu

struct EQBarsView: View {
    let color: Color
    @State private var heights: [CGFloat] = [6, 10, 8, 12, 7]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: heights[i])
                    .animation(
                        .easeInOut(duration: 0.4 + Double(i) * 0.1)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.07),
                        value: heights[i]
                    )
            }
        }
        .frame(height: 12)
        .onAppear { animateBars() }
    }

    private func animateBars() {
        withAnimation { heights = [10, 6, 12, 8, 11] }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                heights = heights.map { _ in CGFloat.random(in: 4...12) }
            }
        }
    }
}
