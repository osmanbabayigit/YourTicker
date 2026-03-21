import SwiftUI
import SwiftData
import AppKit

// MARK: - Quick Capture Panel

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NoteFolder.sortOrder) private var folders: [NoteFolder]

    @State private var text = ""
    @State private var captureType: CaptureType = .note
    @State private var selectedFolder: NoteFolder? = nil
    @FocusState private var textFocused: Bool

    enum CaptureType: String, CaseIterable {
        case note  = "Not"
        case task  = "Görev"

        var icon: String {
            switch self {
            case .note: return "note.text"
            case .task: return "checkmark.circle"
            }
        }
        var color: Color {
            switch self {
            case .note: return Color(hex: "#FBBF24")
            case .task: return TickerTheme.blue
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tip seçici
            HStack(spacing: 4) {
                ForEach(CaptureType.allCases, id: \.self) { t in
                    Button { captureType = t } label: {
                        HStack(spacing: 5) {
                            Image(systemName: t.icon).font(.system(size: 10))
                            Text(t.rawValue).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(captureType == t ? t.color : TickerTheme.textTertiary)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(captureType == t ? t.color.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.2), value: captureType)
                }

                Spacer()

                // Klasör (sadece not modunda)
                if captureType == .note && !folders.isEmpty {
                    Menu {
                        Button("Klasörsüz") { selectedFolder = nil }
                        Divider()
                        ForEach(folders) { f in
                            Button(f.name) { selectedFolder = f }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(selectedFolder.map { Color(hex: $0.hexColor) } ?? TickerTheme.textTertiary)
                                .frame(width: 6, height: 6)
                            Text(selectedFolder?.name ?? "Klasörsüz")
                                .font(.system(size: 10))
                                .foregroundStyle(TickerTheme.textTertiary)
                            Image(systemName: "chevron.down").font(.system(size: 8))
                                .foregroundStyle(TickerTheme.textTertiary)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .menuStyle(.borderlessButton).fixedSize()
                }

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Metin alanı
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(captureType == .note ? "Aklına gelen bir şeyi yaz..." : "Yeni görev...")
                        .font(.system(size: 14)).foregroundStyle(TickerTheme.textTertiary)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .frame(minHeight: 80, maxHeight: 160)
                    .scrollContentBackground(.hidden)
                    .focused($textFocused)
                    .padding(.horizontal, 10).padding(.vertical, 8)
            }

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Alt bar
            HStack(spacing: 10) {
                Image(systemName: captureType.icon)
                    .font(.system(size: 11)).foregroundStyle(captureType.color)

                Text(captureType == .note ? "Not olarak kaydet" : "Görev olarak kaydet")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)

                Spacer()

                HStack(spacing: 4) {
                    keyboardKey("⌘")
                    keyboardKey("↵")
                }

                Button("Kaydet") { save() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(captureType.color)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(captureType.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
        .background(Color(hex: "#161618"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TickerTheme.borderMid, lineWidth: 1)
        )
        .frame(width: 400)
        .onAppear { textFocused = true }
    }

    @ViewBuilder
    private func keyboardKey(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(TickerTheme.textTertiary)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(TickerTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(TickerTheme.borderMid, lineWidth: 1))
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch captureType {
        case .note:
            // İlk satır başlık, geri kalanı içerik
            let lines = trimmed.components(separatedBy: .newlines)
            let title = lines.first ?? trimmed
            let content = lines.dropFirst().joined(separator: "\n")
            let note = Note(title: title, content: content,
                            hexColor: selectedFolder?.hexColor ?? "#FBBF24")
            note.folder = selectedFolder
            context.insert(note)

        case .task:
            let task = TaskItem(title: trimmed, sortOrder: 999)
            context.insert(task)
        }

        try? context.save()
        text = ""
        dismiss()
    }
}
