import SwiftUI
import SwiftData

// MARK: - Görev Seçici

struct TaskPickerView: View {
    let tasks: [TaskItem]
    @Binding var selected: TaskItem?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [TaskItem] {
        search.isEmpty ? tasks : tasks.filter {
            $0.title.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Görev Seç")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("Kapat") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Arama
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                TextField("Ara...", text: $search)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textPrimary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(TickerTheme.bgInput)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 24)).foregroundStyle(TickerTheme.textTertiary)
                    Text("Bekleyen görev yok")
                        .font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filtered) { task in
                        Button {
                            selected = task; dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Capsule()
                                    .fill(Color(hex: task.hexColor))
                                    .frame(width: 3, height: 24)
                                Text(task.title)
                                    .font(.system(size: 13))
                                    .foregroundStyle(TickerTheme.textPrimary)
                                Spacer()
                                if selected?.id == task.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(TickerTheme.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 340, height: 420)
        .background(Color(hex: "#161618"))
    }
}

// MARK: - Pomodoro Ayarları

struct PomodoroSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var focusMinutes   = PomodoroSettings.focusMinutes
    @State private var shortMinutes   = PomodoroSettings.shortBreakMinutes
    @State private var longMinutes    = PomodoroSettings.longBreakMinutes
    @State private var sessionsPerSet = PomodoroSettings.sessionsUntilLongBreak
    @State private var autoStart      = PomodoroSettings.autoStartBreaks
    @State private var soundEnabled   = PomodoroSettings.soundEnabled

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pomodoro Ayarları")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("Kaydet") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerTheme.blue)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(TickerTheme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            VStack(spacing: 0) {
                stepperRow("Odak süresi", value: $focusMinutes, unit: "dk", range: 5...60)
                divider
                stepperRow("Kısa mola", value: $shortMinutes, unit: "dk", range: 1...30)
                divider
                stepperRow("Uzun mola", value: $longMinutes, unit: "dk", range: 5...60)
                divider
                stepperRow("Seans / set", value: $sessionsPerSet, unit: "seans", range: 2...8)
                divider

                HStack {
                    rowLabel("Mola otomatik başlasın", icon: "play.circle")
                    Spacer()
                    Toggle("", isOn: $autoStart)
                        .labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                .padding(.horizontal, 18).padding(.vertical, 12)

                divider

                HStack {
                    rowLabel("Ses bildirimi", icon: "speaker.wave.2")
                    Spacer()
                    Toggle("", isOn: $soundEnabled)
                        .labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .frame(width: 340)
        .background(Color(hex: "#161618"))
    }

    @ViewBuilder
    private func stepperRow(_ label: String, value: Binding<Int>,
                              unit: String, range: ClosedRange<Int>) -> some View {
        HStack {
            rowLabel(label, icon: "timer")
            Spacer()
            HStack(spacing: 8) {
                Button {
                    if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus").font(.system(size: 10))
                        .frame(width: 22, height: 22)
                        .background(TickerTheme.bgPill).clipShape(Circle())
                        .foregroundStyle(TickerTheme.textSecondary)
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue) \(unit)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .frame(width: 64, alignment: .center)

                Button {
                    if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                } label: {
                    Image(systemName: "plus").font(.system(size: 10))
                        .frame(width: 22, height: 22)
                        .background(TickerTheme.bgPill).clipShape(Circle())
                        .foregroundStyle(TickerTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    @ViewBuilder
    private func rowLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11))
                .foregroundStyle(TickerTheme.textTertiary).frame(width: 16)
            Text(text).font(.system(size: 13))
                .foregroundStyle(TickerTheme.textSecondary)
        }
    }

    private var divider: some View {
        Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
    }

    private func save() {
        PomodoroSettings.focusMinutes           = focusMinutes
        PomodoroSettings.shortBreakMinutes      = shortMinutes
        PomodoroSettings.longBreakMinutes       = longMinutes
        PomodoroSettings.sessionsUntilLongBreak = sessionsPerSet
        PomodoroSettings.autoStartBreaks        = autoStart
        PomodoroSettings.soundEnabled           = soundEnabled
        dismiss()
    }
}
