import SwiftUI

struct SettingsPopover: View {
    @Environment(AppState.self) private var state
    @State private var limitText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("Token limit per 5h block")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
                HStack {
                    TextField("88000000", text: $limitText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Text("tokens")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                Text("Default: 88M (Claude Max 20x estimate)")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.35))
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white.opacity(0.6))
                Button("Save") {
                    if let v = Int(limitText), v > 0 {
                        state.updateTokenLimit(v)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.85, green: 0.40, blue: 0.19))
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
        .onAppear { limitText = "\(state.planLimits.tokenLimitPerBlock)" }
    }
}
