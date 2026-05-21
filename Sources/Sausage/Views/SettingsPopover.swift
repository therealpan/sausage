import SwiftUI
import AppKit

struct SettingsPopover: View {
    @Environment(AppState.self) private var state
    @State private var limitText = ""
    @State private var adminKey = ""
    @State private var keySaved = false
    @Environment(\.dismiss) private var dismiss

    private let terra = Color(red: 0.85, green: 0.40, blue: 0.19)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                if let url = Bundle.module.url(forResource: "icon", withExtension: "png") ?? Bundle.main.url(forResource: "icon", withExtension: "png"),
                   let nsImg = NSImage(contentsOf: url) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sausage")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Claude Max 20x monitor")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }

            // Token limit
            VStack(alignment: .leading, spacing: 6) {
                label("Token limit per 5h block")
                HStack {
                    TextField("88000000", text: $limitText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Text("tokens")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                caption("Default: 88M (Claude Max 20x estimate)")
            }

            Divider().background(Color.white.opacity(0.1))

            // Anthropic Admin API key
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    label("Anthropic Admin API Key")
                    Spacer()
                    if state.adminHasKey {
                        Label("Configured", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(red: 0.64, green: 0.90, blue: 0.21))
                    } else {
                        Label("Not set", systemImage: "exclamationmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
                SecureField("sk-ant-admin01-…", text: $adminKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                caption("For API usage & cost data. Stored in macOS Keychain.")
                if let err = state.adminError {
                    Text(err)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                if keySaved {
                    Text("Key saved to Keychain ✓")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.64, green: 0.90, blue: 0.21))
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white.opacity(0.5))
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(terra)
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
        .onAppear {
            limitText = "\(state.planLimits.tokenLimitPerBlock)"
        }
    }

    private func save() {
        if let v = Int(limitText), v > 0 {
            state.updateTokenLimit(v)
        }
        let trimmed = adminKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            Task {
                await state.saveAdminKey(trimmed)
                keySaved = true
            }
        }
        dismiss()
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.6))
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(Color.white.opacity(0.30))
    }
}
