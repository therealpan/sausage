import Foundation

struct TokenCounts: Codable, Sendable {
    let cacheCreationInputTokens: Int
    let cacheReadInputTokens: Int
    let inputTokens: Int
    let outputTokens: Int
}

struct BurnRate: Codable, Sendable {
    let costPerHour: Double
    let tokensPerMinute: Double
    let tokensPerMinuteForIndicator: Double
}

struct BlockProjection: Codable, Sendable {
    let remainingMinutes: Int
    let totalCost: Double
    let totalTokens: Int
}

struct Block5hWindow: Codable, Sendable, Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date
    let actualEndTime: Date?
    let entries: Int
    let isActive: Bool
    let isGap: Bool
    let costUSD: Double
    let totalTokens: Int
    let tokenCounts: TokenCounts
    let models: [String]
    let burnRate: BurnRate?
    let projection: BlockProjection?
}

struct BlocksResponse: Codable, Sendable {
    let blocks: [Block5hWindow]
}
