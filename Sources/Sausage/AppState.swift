import SwiftUI
import Observation

@MainActor
@Observable
final class AppState {
    // MARK: - ccusage data
    var activeBlock: Block5hWindow? = nil
    var recentBlocks: [Block5hWindow] = []
    var dailyUsage7d: [DailyUsage] = []
    var dailyUsage90d: [DailyUsage] = []

    // MARK: - V2 data
    var topProjects: [ProjectUsage] = []
    var adminUsageBuckets: [AdminUsageBucket] = []
    var adminTotalCostUSD: Double = 0
    var adminHasKey: Bool = false
    var adminError: String? = nil

    // MARK: - UI state
    var planLimits = PlanLimits()
    var isLoading = false
    var lastRefreshed: Date? = nil
    var error: String? = nil

    // MARK: - Computed (menu bar)

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
        return "\(minutes / 60)h\(String(format: "%02d", minutes % 60))m"
    }

    var todayUsage: DailyUsage? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: Date())
        return dailyUsage7d.first(where: { $0.period == today })
    }

    // MARK: - Services

    private let client = CCUsageClient()
    private let adminClient = AnthropicAdminClient()
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

        // Primary ccusage data
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

        // Secondary data (non-critical)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshTopProjects() }
            group.addTask { await self.refreshAdminData() }
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

    func refreshTopProjects() async {
        do {
            let response = try await client.fetchSessions(days: 7)
            let uuidMap = buildUUIDToProjectMap()
            topProjects = Self.aggregateProjects(from: response.session, map: uuidMap)
        } catch {
            // non-critical
        }
    }

    func refreshAdminData() async {
        adminHasKey = await adminClient.hasKey
        guard adminHasKey else { return }
        do {
            async let usageResult = adminClient.fetchUsageReport(days: 7)
            async let costResult = adminClient.fetchCostReport(days: 7)
            let (usage, cost) = try await (usageResult, costResult)
            adminUsageBuckets = usage.data
            adminTotalCostUSD = cost.data
                .flatMap { $0.results }
                .reduce(0) { $0 + $1.amountUSD }
            adminError = nil
        } catch AnthropicAdminError.noAPIKey {
            adminHasKey = false
        } catch {
            adminError = error.localizedDescription
        }
    }

    // MARK: - Settings

    func updateTokenLimit(_ newLimit: Int) {
        planLimits.tokenLimitPerBlock = newLimit
        UserDefaults.standard.set(newLimit, forKey: "tokenLimitPerBlock")
    }

    func saveAdminKey(_ key: String) async {
        do {
            try await adminClient.saveKey(key)
            adminHasKey = true
            await refreshAdminData()
        } catch {
            adminError = error.localizedDescription
        }
    }

    // MARK: - Project mapping (synchronous, fast I/O)

    private func buildUUIDToProjectMap() -> [String: String] {
        let fm = FileManager.default
        let projectsDir = fm.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")
        var map: [String: String] = [:]
        guard let dirs = try? fm.contentsOfDirectory(at: projectsDir, includingPropertiesForKeys: nil) else { return map }
        for dir in dirs where dir.hasDirectoryPath {
            let name = Self.extractProjectName(from: dir.lastPathComponent)
            guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for file in files where file.pathExtension == "jsonl" {
                map[file.deletingPathExtension().lastPathComponent] = name
            }
        }
        return map
    }

    private static func extractProjectName(from dirName: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let encodedHome = home.replacingOccurrences(of: "/", with: "-")
        var name = dirName
        // Strip home prefix: "-Users-username-"
        let prefix = encodedHome + "-"
        if name.hasPrefix(prefix) { name = String(name.dropFirst(prefix.count)) }
        // Strip common path segment
        for seg in ["Progetti-Claude-", "Projects-Claude-", "Developer-"] {
            if name.hasPrefix(seg) { name = String(name.dropFirst(seg.count)); break }
        }
        // Strip worktree suffix
        for suffix in ["--claude-worktrees", "--.claude-worktrees"] {
            if let range = name.range(of: suffix) { name = String(name[..<range.lowerBound]); break }
        }
        return name.isEmpty ? dirName : name
    }

    private static func aggregateProjects(from sessions: [SessionUsage], map: [String: String]) -> [ProjectUsage] {
        var totals: [String: (tokens: Int, cost: Double)] = [:]
        for s in sessions {
            let name = map[s.period] ?? "Other"
            let existing = totals[name] ?? (0, 0.0)
            totals[name] = (existing.tokens + s.totalTokens, existing.cost + s.totalCost)
        }
        return totals
            .map { ProjectUsage(name: $0.key, tokens: $0.value.tokens, cost: $0.value.cost) }
            .sorted { $0.tokens > $1.tokens }
            .prefix(5)
            .map { $0 }
    }
}
