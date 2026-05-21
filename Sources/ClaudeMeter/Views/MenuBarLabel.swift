import SwiftUI
import AppKit

struct MenuBarLabel: View {
    @Environment(AppState.self) private var state

    var body: some View {
        HStack(spacing: 4) {
            if let nsImg = menuBarImage {
                Image(nsImage: nsImg)
                    .renderingMode(.template)
                    .foregroundStyle(state.menuBarColor)
            } else {
                PulseIndicator(color: state.menuBarColor, active: state.usagePercent > 0.85)
            }
            Text(labelText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(state.menuBarColor)
        }
    }

    private var menuBarImage: NSImage? {
        if let url = Bundle.main.url(forResource: "menubar_icon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            return img
        }
        return nil
    }

    private var labelText: String {
        guard state.activeBlock != nil else { return "·· ----" }
        return "\(Int(state.usagePercent * 100))% · \(state.remainingFormatted)"
    }
}
