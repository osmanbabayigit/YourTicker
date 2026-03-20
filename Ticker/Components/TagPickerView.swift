import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Query(sort: \TagItem.name) private var allTags: [TagItem]
    @Binding var selectedTags: [TagItem]
    @State private var showingManager = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Etiketler")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(TickerTheme.textTertiary)
                    .textCase(.uppercase).kerning(0.3)
                Spacer()
                Button {
                    showingManager = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            if allTags.isEmpty {
                Text("Henüz etiket yok")
                    .font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(allTags) { tag in
                        let isSelected = selectedTags.contains(where: { $0.id == tag.id })
                        Button {
                            if isSelected {
                                selectedTags.removeAll { $0.id == tag.id }
                            } else {
                                selectedTags.append(tag)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: tag.hexColor))
                                    .frame(width: 5, height: 5)
                                Text(tag.name)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(
                                isSelected
                                ? Color(hex: tag.hexColor).opacity(0.15)
                                : TickerTheme.bgPill
                            )
                            .foregroundStyle(
                                isSelected
                                ? Color(hex: tag.hexColor)
                                : TickerTheme.textSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        isSelected ? Color(hex: tag.hexColor).opacity(0.3) : TickerTheme.borderSub,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.2), value: isSelected)
                    }
                }
            }
        }
        .sheet(isPresented: $showingManager) {
            TagManagerView()
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
