import SwiftUI

// MARK: - Tek satır, temiz tarih+saat seçici

struct DateTimePickerField: View {
    let label: String
    let icon: String
    @Binding var date: Date
    var showTime: Bool = false

    @State private var showDatePicker = false
    @State private var showTimePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                // Tarih butonu
                Button {
                    showTimePicker = false
                    showDatePicker.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(date.formatted(.dateTime.day().month().year()))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(showDatePicker
                                ? Color.blue.opacity(0.15)
                                : Color(nsColor: .controlBackgroundColor))
                    .foregroundStyle(showDatePicker ? .blue : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(showDatePicker
                                    ? Color.blue.opacity(0.4)
                                    : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                    VStack(spacing: 0) {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .frame(width: 260)
                        Divider()
                        Button("Tamam") { showDatePicker = false }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.blue)
                            .padding(10)
                    }
                    .padding(4)
                }

                // Saat butonu (opsiyonel)
                if showTime {
                    Button {
                        showDatePicker = false
                        showTimePicker.toggle()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(showTimePicker
                                    ? Color.blue.opacity(0.15)
                                    : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(showTimePicker ? .blue : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(showTimePicker
                                        ? Color.blue.opacity(0.4)
                                        : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
                        VStack(spacing: 8) {
                            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.stepperField)
                                .labelsHidden()
                            Button("Tamam") { showTimePicker = false }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                        .padding(12)
                    }
                }
            }
        }
    }
}

// MARK: - Toggle'lı tarih seçici (opsiyonel tarih için)

struct OptionalDateField: View {
    let label: String
    let icon: String
    @Binding var isEnabled: Bool
    @Binding var date: Date
    var showTime: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)

            if isEnabled {
                DateTimePickerField(
                    label: label,
                    icon: icon,
                    date: $date,
                    showTime: showTime
                )
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Label(label, systemImage: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Kapalı")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .animation(.spring(response: 0.2), value: isEnabled)
    }
}
