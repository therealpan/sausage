import SwiftUI
import AppKit

struct SettingsPopover: View {
    @Environment(AppState.self) private var state
    @State private var limitText = ""
    @State private var selectedPlan: Plan = .max20x
    @State private var adminKey = ""
    @State private var keySaved = false
    @Environment(\.dismiss) private var dismiss

    private let terra = Color(red: 0.85, green: 0.40, blue: 0.19)

    enum Plan: String, CaseIterable, Identifiable {
        case pro = "Pro"
        case max5x = "Max 5x"
        case max20x = "Max 20x"
        case custom = "Custom"

        var id: String { rawValue }

        var tokenLimit: Int? {
            switch self {
            case .pro: return 4_400_000
            case .max5x: return 22_000_000
            case .max20x: return 88_000_000
            case .custom: return nil
            }
        }

        static func from(limit: Int) -> Plan {
            switch limit {
            case 4_400_000: return .pro
            case 22_000_000: return .max5x
            case 88_000_000: return .max20x
            default: return .custom
            }
        }
    }

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
                    Text("Claude usage monitor")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }

            // Plan selector
            VStack(alignment: .leading, spacing: 6) {
                label("Plan")
                Picker("", selection: $selectedPlan) {
                    ForEach(Plan.allCases) { plan in
                        Text(plan.rawValue).tag(plan)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .onChange(of: selectedPlan) { _, new in
                    if let limit = new.tokenLimit {
                        limitText = "\(limit)"
                    }
                }
            }

            // Token limit
            VStack(alignment: .leading, spacing: 6) {
                label("Token limit per 5h block")
                HStack {
                    TextField("88000000", text: $limitText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: limitText) { _, new in
                            if let v = Int(new) {
                                let derived = Plan.from(limit: v)
                                if derived != selectedPlan { selectedPlan = derived }
                            }
                        }
                    Text("tokens")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                caption("Estimates: Pro 4.4M · Max 5x 22M · Max 20x 88M")
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
            let saved = state.planLimits.tokenLimitPerBlock
            limitText = "\(saved)"
            selectedPlan = Plan.from(limit: saved)
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
