import Foundation

struct SessionMetadata: Codable, Sendable {
    let lastActivity: String?
}

struct SessionUsage: Codable, Sendable {
    let agent: String
    let period: String  // session UUID — matches JSONL filename
    let totalTokens: Int
    let totalCost: Double
    let modelsUsed: [String]
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let inputTokens: Int
    let outputTokens: Int
    let modelBreakdowns: [ModelBreakdown]
    let metadata: SessionMetadata?
}

struct SessionResponse: Codable, Sendable {
    let session: [SessionUsage]  // ccusage wraps with key "session"
}
