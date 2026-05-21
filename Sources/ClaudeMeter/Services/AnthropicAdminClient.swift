import Foundation

enum AnthropicAdminError: Error {
    case noAPIKey
    case invalidResponse
    case httpError(Int)
}

actor AnthropicAdminClient {
    private let baseURL = "https://api.anthropic.com"
    private let apiVersion = "2023-06-01"

    var hasKey: Bool {
        KeychainStore.read(service: "claudemeter", account: "anthropic-admin-key") != nil
    }

    func saveKey(_ key: String) throws {
        try KeychainStore.write(service: "claudemeter", account: "anthropic-admin-key", value: key)
    }

    func fetchUsageReport(days: Int) async throws -> UsageReportResponse {
        guard let key = KeychainStore.read(service: "claudemeter", account: "anthropic-admin-key") else {
            throw AnthropicAdminError.noAPIKey
        }
        let url = try buildURL(
            path: "/v1/organizations/usage_report/messages",
            days: days,
            extra: [
                URLQueryItem(name: "bucket_width", value: "1d"),
                URLQueryItem(name: "group_by[]", value: "model"),
                URLQueryItem(name: "limit", value: "\(min(days, 31))")
            ]
        )
        let data = try await fetch(url: url, key: key)
        return try Self.decoder.decode(UsageReportResponse.self, from: data)
    }

    func fetchCostReport(days: Int) async throws -> CostReportResponse {
        guard let key = KeychainStore.read(service: "claudemeter", account: "anthropic-admin-key") else {
            throw AnthropicAdminError.noAPIKey
        }
        let url = try buildURL(
            path: "/v1/organizations/cost_report",
            days: days,
            extra: [URLQueryItem(name: "limit", value: "\(min(days, 31))")]
        )
        let data = try await fetch(url: url, key: key)
        return try Self.decoder.decode(CostReportResponse.self, from: data)
    }

    // MARK: - Private

    private func buildURL(path: String, days: Int, extra: [URLQueryItem]) throws -> URL {
        var components = URLComponents(string: baseURL + path)!
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let now = Date()
        let since = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        components.queryItems = [
            URLQueryItem(name: "starting_at", value: fmt.string(from: since)),
            URLQueryItem(name: "ending_at", value: fmt.string(from: now))
        ] + extra
        return components.url!
    }

    private func fetch(url: URL, key: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("ClaudeMeter/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AnthropicAdminError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw AnthropicAdminError.httpError(http.statusCode)
        }
        return data
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let str = try c.decode(String.self)
            if let date = fmt.date(from: str) { return date }
            if let date = plain.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Cannot parse date: \(str)")
        }
        return d
    }()
}
