import SwiftUI

struct GlobalSearchBar: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField("Ara...", text: $appState.searchText)
                .textFieldStyle(.plain)

            if !appState.searchText.isEmpty {
                Button {
                    appState.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(10)
        .background(GlassView())
        .cornerRadius(12)
        .padding()
    }
}
//
