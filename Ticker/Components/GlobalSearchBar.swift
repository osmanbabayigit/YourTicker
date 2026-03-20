import SwiftUI

struct GlobalSearchBar: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(isFocused ? TickerTheme.blue : TickerTheme.textTertiary)
                .animation(.easeOut(duration: 0.15), value: isFocused)

            TextField("Ara...", text: $appState.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(TickerTheme.textPrimary)
                .focused($isFocused)

            if !appState.searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.2)) { appState.searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "command")
                        .font(.system(size: 8))
                    Text("K")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(TickerTheme.textTertiary)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(TickerTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(TickerTheme.bgApp)
        .animation(.spring(response: 0.2), value: appState.searchText.isEmpty)
    }
}
