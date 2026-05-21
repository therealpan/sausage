import SwiftUI
import Charts

// MARK: - Root

struct DetailPanel: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            PanelHeader()
            if let err = state.error {
                ErrorBanner(message: err)
            }
            ScrollView {
                VStack(spacing: 20) {
                    CurrentBlockSection()
                    TodaySection()
                    WeeklySection()
                    HeatmapSection()
                }
                .padding(16)
            }
            PanelFooter()
        }
        .frame(width: 400)
        .frame(minHeight: 480, maxHeight: 620)
        .background(Color(red: 0.059, green: 0.059, blue: 0.055))
        .task { await state.refreshAll() }
    }
}

// MARK: - Header

private struct PanelHeader: View {
    @Environment(AppState.self) private var state

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ClaudeMeter")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                if let refreshed = state.lastRefreshed {
                    Text("Updated \(refreshed.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            Spacer()
            if state.isLoading {
                ProgressView().controlSize(.mini).tint(.white)
            } else {
                Button {
                    Task { await state.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.07))
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
    }
}

// MARK: - Current Block

private struct CurrentBlockSection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("CURRENT BLOCK")

            if let block = state.activeBlock {
                HStack(spacing: 16) {
                    BlockProgressRing(
                        progress: state.usagePercent,
                        color: state.menuBarColor
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        LiveCounter(value: block.totalTokens, label: "tokens used")

                        HStack(spacing: 4) {
                            Text("$\(String(format: "%.2f", block.costUSD))")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.64, green: 0.90, blue: 0.21))
                            if let proj = block.projection {
                                Text("→ $\(String(format: "%.2f", proj.totalCost))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.4))
                            Text(state.remainingFormatted + " left")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }

                        ModelsDonut(models: block.models)
                    }
                }

                // Model chips
                if !block.models.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(block.models, id: \.self) { model in
                                ModelChip(name: model)
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "moon.zzz")
                        .foregroundStyle(Color.white.opacity(0.3))
                    Text("No active block")
                        .font(.callout)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }
        }
        .sectionStyle()
    }
}

// MARK: - Today

private struct TodaySection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("TODAY")

            if let today = state.todayUsage {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(today.totalTokens.formatted(.number.notation(.compactName)) + " tokens")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("$\(String(format: "%.2f", today.totalCost))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color(red: 0.64, green: 0.90, blue: 0.21))
                    }
                    Spacer()
                    Text("\(today.modelsUsed.count) models")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            } else {
                Text("No usage today")
                    .font(.callout)
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            if !state.dailyUsage7d.isEmpty {
                TokensSparkline(data: state.dailyUsage7d)
            }
        }
        .sectionStyle()
    }
}

// MARK: - Weekly

private struct WeeklySection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("LAST 7 DAYS")
            if state.dailyUsage7d.isEmpty {
                placeholder
            } else {
                WeeklyStackedBars(data: state.dailyUsage7d)
            }
        }
        .sectionStyle()
    }

    private var placeholder: some View {
        Text("Loading…")
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.3))
            .frame(height: 100, alignment: .center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Heatmap

private struct HeatmapSection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("90 DAYS")
            if state.dailyUsage90d.isEmpty {
                Text("Loading…")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.3))
                    .frame(height: 90, alignment: .center)
                    .frame(maxWidth: .infinity)
            } else {
                ActivityHeatmap(data: state.dailyUsage90d)
            }
        }
        .sectionStyle()
    }
}

// MARK: - Footer

private struct PanelFooter: View {
    @Environment(AppState.self) private var state
    @State private var showSettings = false

    var body: some View {
        HStack {
            Button {
                showSettings.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gear").font(.system(size: 11))
                    Text("Settings").font(.system(size: 11))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white.opacity(0.4))
            .popover(isPresented: $showSettings) {
                SettingsPopover().environment(state)
            }

            Spacer()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.08, green: 0.08, blue: 0.07))
    }
}

// MARK: - Reusable helpers

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Color.white.opacity(0.35))
    }
}

private struct ModelChip: View {
    let name: String
    private var label: String {
        if name.contains("opus") { return "Opus" }
        if name.contains("haiku") { return "Haiku" }
        return "Sonnet"
    }
    private var chipColor: Color {
        if name.contains("opus") { return Color(red: 0.85, green: 0.40, blue: 0.19) }
        if name.contains("haiku") { return Color(red: 0.39, green: 0.40, blue: 0.95) }
        return Color(red: 0.64, green: 0.90, blue: 0.21)
    }
    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(chipColor.opacity(0.18))
            .foregroundStyle(chipColor)
            .clipShape(Capsule())
    }
}

private extension View {
    func sectionStyle() -> some View {
        self
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
