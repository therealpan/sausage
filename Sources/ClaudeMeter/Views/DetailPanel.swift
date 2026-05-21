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
                VStack(spacing: 16) {
                    CurrentBlockSection()
                    TodaySection()
                    WeeklySection()
                    TopProjectsSection()
                    HeatmapSection()
                    APIUsageSection()
                }
                .padding(16)
            }
            PanelFooter()
        }
        .frame(width: 400)
        .frame(minHeight: 480, maxHeight: 700)
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
                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
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
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            Text(message).font(.caption).foregroundStyle(Color.white.opacity(0.7)).lineLimit(2)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
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
                    BlockProgressRing(progress: state.usagePercent, color: state.menuBarColor)

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
                            Image(systemName: "clock").font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.4))
                            Text(state.remainingFormatted + " left")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }

                        // Donut with real model breakdown from today's data
                        ModelsDonut(
                            models: block.models,
                            breakdowns: state.todayUsage?.modelBreakdowns
                        )
                    }
                }

                if !block.models.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(block.models, id: \.self) { model in ModelChip(name: model) }
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "moon.zzz").foregroundStyle(Color.white.opacity(0.3))
                    Text("No active block").font(.callout).foregroundStyle(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
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
                Text("No usage today").font(.callout).foregroundStyle(Color.white.opacity(0.4))
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
                loadingRow(height: 100)
            } else {
                WeeklyStackedBars(data: state.dailyUsage7d)
            }
        }
        .sectionStyle()
    }
}

// MARK: - Top Projects

private struct TopProjectsSection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("TOP PROJECTS (7 DAYS)")
            if state.topProjects.isEmpty {
                Text("Loading…")
                    .font(.caption).foregroundStyle(Color.white.opacity(0.3))
                    .frame(height: 60, alignment: .center).frame(maxWidth: .infinity)
            } else {
                TopProjectsBars(data: state.topProjects)
            }
        }
        .sectionStyle()
    }
}

// MARK: - Heatmap

private struct HeatmapSection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("90 DAYS")
            if state.dailyUsage90d.isEmpty {
                loadingRow(height: 90)
            } else {
                ActivityHeatmap(data: state.dailyUsage90d)
            }
        }
        .sectionStyle()
    }
}

// MARK: - API Usage

private struct APIUsageSection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("API USAGE (DEVELOPER)")
                Spacer()
                if state.adminHasKey {
                    Circle().fill(Color(red: 0.64, green: 0.90, blue: 0.21)).frame(width: 5, height: 5)
                }
            }

            if !state.adminHasKey {
                HStack(spacing: 8) {
                    Image(systemName: "key").foregroundStyle(Color.white.opacity(0.3))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Admin API key configured")
                            .font(.caption).foregroundStyle(Color.white.opacity(0.5))
                        Text("Add key in Settings to see API spend data")
                            .font(.caption2).foregroundStyle(Color.white.opacity(0.3))
                    }
                }
                .padding(.vertical, 8)
            } else if let err = state.adminError {
                Text(err).font(.caption2).foregroundStyle(.red).lineLimit(3)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(String(format: "%.2f", state.adminTotalCostUSD))")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("API spend (7 days)")
                            .font(.caption2).foregroundStyle(Color.white.opacity(0.4))
                    }
                    Spacer()
                    if !state.adminUsageBuckets.isEmpty {
                        let totalTokens = state.adminUsageBuckets
                            .flatMap { $0.results }
                            .reduce(0) { $0 + $1.totalTokens }
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(totalTokens.formatted(.number.notation(.compactName)))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.64, green: 0.90, blue: 0.21))
                            Text("API tokens").font(.caption2).foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                }
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
                .buttonStyle(.plain).font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(red: 0.08, green: 0.08, blue: 0.07))
    }
}

// MARK: - Helpers

private func loadingRow(height: CGFloat) -> some View {
    Text("Loading…")
        .font(.caption).foregroundStyle(Color.white.opacity(0.3))
        .frame(height: height, alignment: .center).frame(maxWidth: .infinity)
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold)).tracking(1.2)
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
    private var color: Color {
        if name.contains("opus") { return Color(red: 0.85, green: 0.40, blue: 0.19) }
        if name.contains("haiku") { return Color(red: 0.39, green: 0.40, blue: 0.95) }
        return Color(red: 0.64, green: 0.90, blue: 0.21)
    }
    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color.opacity(0.18)).foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private extension View {
    func sectionStyle() -> some View {
        self.padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
