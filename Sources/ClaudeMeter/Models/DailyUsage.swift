import Foundation

struct ModelBreakdown: Codable, Sendable {
    let modelName: String
    let cost: Double
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
}

struct DailyUsage: Codable, Sendable, Identifiable {
    var id: String { period }
    let period: String  // "YYYY-MM-DD"
    let totalTokens: Int
    let totalCost: Double
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
}

struct DailyResponse: Codable, Sendable {
    let daily: [DailyUsage]
}
