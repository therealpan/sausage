import SwiftUI
import Observation

@MainActor
@Observable
final class AppState {
    var activeBlock: Block5hWindow? = nil
    var recentBlocks: [Block5hWindow] = []
    var dailyUsage7d: [DailyUsage] = []
    var dailyUsage90d: [DailyUsage] = []
    var planLimits = PlanLimits()
    var isLoading = false
    var lastRefreshed: Date? = nil
    var error: String? = nil

    // MARK: - Computed

    var usagePercent: Double {
        guard let block = activeBlock, !block.isGap, block.isActive else { return 0 }
        return min(1.0, Double(block.totalTokens) / Double(planLimits.tokenLimitPerBlock))
    }

    var menuBarColor: Color {
        switch usagePercent {
        case ..<0.60: return Color(red: 0.40, green: 0.80, blue: 0.40)
        case 0.60..<0.85: return Color(red: 1.0, green: 0.70, blue: 0.0)
        default: return Color(red: 0.85, green: 0.25, blue: 0.20)
        }
    }

    var remainingFormatted: String {
        guard let block = activeBlock, block.isActive else { return "--:--" }
        let minutes: Int
        if let proj = block.projection {
            minutes = max(0, proj.remainingMinutes)
        } else {
            minutes = max(0, Int(block.endTime.timeIntervalSince(Date()) / 60))
        }
        let h = minutes / 60
        let m = minutes % 60
        return "\(h)h\(String(format: "%02d", m))m"
    }

    var todayUsage: DailyUsage? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: Date())
        return dailyUsage7d.first(where: { $0.period == today })
    }

    // MARK: - Private

    private let client = CCUsageClient()
    private var menuBarTask: Task<Void, Never>?
    private var fullRefreshTask: Task<Void, Never>?

    init() {
        if let saved = UserDefaults.standard.object(forKey: "tokenLimitPerBlock") as? Int {
            planLimits.tokenLimitPerBlock = saved
        }
        Task { await self.startPolling() }
    }

    // MARK: - Polling

    func startPolling() {
        Task { await refreshAll() }
        menuBarTask?.cancel()
        menuBarTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                await self?.refreshMenuBarData()
            }
        }
        fullRefreshTask?.cancel()
        fullRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { break }
                await self?.refreshAll()
            }
        }
    }

    // MARK: - Refresh

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let activeResult = client.fetchActiveBlock()
            async let recentResult = client.fetchRecentBlocks()
            async let daily7Result = client.fetchDailySince(days: 7)
            async let daily90Result = client.fetchDailySince(days: 90)
            let (active, recent, daily7, daily90) = try await (
                activeResult, recentResult, daily7Result, daily90Result
            )
            activeBlock = active.blocks.first(where: { $0.isActive })
            recentBlocks = recent.blocks.filter { !$0.isGap }
            dailyUsage7d = Array(daily7.daily.suffix(7))
            dailyUsage90d = daily90.daily
            lastRefreshed = Date()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refreshMenuBarData() async {
        do {
            let result = try await client.fetchActiveBlock()
            activeBlock = result.blocks.first(where: { $0.isActive })
            lastRefreshed = Date()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Settings

    func updateTokenLimit(_ newLimit: Int) {
        planLimits.tokenLimitPerBlock = newLimit
        UserDefaults.standard.set(newLimit, forKey: "tokenLimitPerBlock")
    }
}
