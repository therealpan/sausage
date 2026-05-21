import Foundation

struct AdminCostResult: Codable, Sendable {
    // amount = cents as decimal string, e.g. "123.45" = $1.23
    let amount: String
    let currency: String
    let costType: String?
    let model: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case costType = "cost_type"
        case model
    }

    var amountUSD: Double { (Double(amount) ?? 0) / 100 }
}

struct AdminCostBucket: Codable, Sendable {
    let startingAt: Date
    let endingAt: Date
    let results: [AdminCostResult]

    enum CodingKeys: String, CodingKey {
        case startingAt = "starting_at"
        case endingAt = "ending_at"
        case results
    }
}

struct CostReportResponse: Codable, Sendable {
    let data: [AdminCostBucket]
    let hasMore: Bool
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}
