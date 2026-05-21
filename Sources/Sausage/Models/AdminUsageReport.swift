import Foundation

struct CacheCreationTokens: Codable, Sendable {
    let ephemeral1hInputTokens: Int
    let ephemeral5mInputTokens: Int

    enum CodingKeys: String, CodingKey {
        case ephemeral1hInputTokens = "ephemeral_1h_input_tokens"
        case ephemeral5mInputTokens = "ephemeral_5m_input_tokens"
    }

    var total: Int { ephemeral1hInputTokens + ephemeral5mInputTokens }
}

struct ServerToolUse: Codable, Sendable {
    let webSearchRequests: Int

    enum CodingKeys: String, CodingKey {
        case webSearchRequests = "web_search_requests"
    }
}

struct AdminUsageResult: Codable, Sendable {
    let model: String?
    let uncachedInputTokens: Int
    let cacheReadInputTokens: Int
    let cacheCreation: CacheCreationTokens
    let outputTokens: Int
    let serverToolUse: ServerToolUse?

    enum CodingKeys: String, CodingKey {
        case model
        case uncachedInputTokens = "uncached_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cacheCreation = "cache_creation"
        case outputTokens = "output_tokens"
        case serverToolUse = "server_tool_use"
    }

    var totalTokens: Int {
        uncachedInputTokens + cacheReadInputTokens + cacheCreation.total + outputTokens
    }
}

struct AdminUsageBucket: Codable, Sendable {
    let startingAt: Date
    let endingAt: Date
    let results: [AdminUsageResult]

    enum CodingKeys: String, CodingKey {
        case startingAt = "starting_at"
        case endingAt = "ending_at"
        case results
    }
}

struct UsageReportResponse: Codable, Sendable {
    let data: [AdminUsageBucket]
    let hasMore: Bool
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}
