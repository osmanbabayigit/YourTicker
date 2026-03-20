import SwiftUI

struct DateTimePickerField: View {
    let label: String
    let icon: String
    @Binding var date: Date
    var showTime: Bool = false

    @State private var showDatePicker = false
    @State private var showTimePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(TickerTheme.textTertiary)
                .textCase(.uppercase)
                .kerning(0.3)

            HStack(spacing: 6) {
                // Tarih butonu
                Button {
                    showTimePicker = false
                    showDatePicker.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(date.formatted(.dateTime.day().month().year()))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(showDatePicker ? TickerTheme.blue.opacity(0.15) : TickerTheme.bgPill)
                    .foregroundStyle(showDatePicker ? TickerTheme.blue : TickerTheme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(showDatePicker ? TickerTheme.blue.opacity(0.3) : TickerTheme.borderMid, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                    VStack(spacing: 0) {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical).labelsHidden().frame(width: 260)
                        Divider().background(TickerTheme.borderSub)
                        Button("Tamam") { showDatePicker = false }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(TickerTheme.blue)
                            .padding(10)
                    }
                    .background(Color(hex: "#1C1C1E"))
                }

                // Saat butonu
                if showTime {
                    Button {
                        showDatePicker = false
                        showTimePicker.toggle()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(showTimePicker ? TickerTheme.blue.opacity(0.15) : TickerTheme.bgPill)
                        .foregroundStyle(showTimePicker ? TickerTheme.blue : TickerTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(showTimePicker ? TickerTheme.blue.opacity(0.3) : TickerTheme.borderMid, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
                        VStack(spacing: 8) {
                            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.stepperField).labelsHidden()
                            Button("Tamam") { showTimePicker = false }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(TickerTheme.blue)
                        }
                        .padding(14)
                        .background(Color(hex: "#1C1C1E"))
                    }
                }
            }
        }
    }
}

// MARK: - Toggle'lı opsiyonel tarih

struct OptionalDateField: View {
    let label: String
    let icon: String
    @Binding var isEnabled: Bool
    @Binding var date: Date
    var showTime: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden().toggleStyle(.switch).controlSize(.small)

            if isEnabled {
                DateTimePickerField(label: label, icon: icon, date: $date, showTime: showTime)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(TickerTheme.textTertiary)
                        .textCase(.uppercase).kerning(0.3)
                    Text("Kapalı")
                        .font(.system(size: 12))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
            }
            Spacer()
        }
        .animation(.spring(response: 0.2), value: isEnabled)
    }
}
