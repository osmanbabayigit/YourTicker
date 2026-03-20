import SwiftUI

struct GlassView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        v.appearance = NSAppearance(named: .darkAqua)
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

// MARK: - Sheet background helper

struct DarkSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(hex: "#161618"))
    }
}

extension View {
    func darkSheet() -> some View {
        modifier(DarkSheetBackground())
    }
}
