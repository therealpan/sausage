import Foundation

enum CCUsageError: Error {
    case nonZeroExit(Int32, String)
    case npxNotFound
}

actor CCUsageClient {
    private let npxPath: String

    init() {
        self.npxPath = CCUsageClient.resolveNpxPath()
    }

    private static func resolveNpxPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        // Try NVM default alias
        let aliasPath = "\(home)/.nvm/alias/default"
        if let version = try? String(contentsOfFile: aliasPath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
           !version.isEmpty {
            let candidate = "\(home)/.nvm/versions/node/\(version)/bin/npx"
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        // Scan all installed NVM node versions, pick latest
        let nvmBase = "\(home)/.nvm/versions/node"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmBase) {
            if let latest = versions.filter({ $0.hasPrefix("v") }).sorted().last {
                let candidate = "\(nvmBase)/\(latest)/bin/npx"
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }
        // Common fallbacks
        for path in ["/usr/local/bin/npx", "/opt/homebrew/bin/npx", "/usr/bin/npx"] {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return "/usr/local/bin/npx"
    }

    func fetchActiveBlock() async throws -> BlocksResponse {
        let output = try await run(args: ["ccusage", "blocks", "--json", "--active"])
        return try Self.decoder.decode(BlocksResponse.self, from: Data(output.utf8))
    }

    func fetchRecentBlocks() async throws -> BlocksResponse {
        let output = try await run(args: ["ccusage", "blocks", "--json", "--recent"])
        return try Self.decoder.decode(BlocksResponse.self, from: Data(output.utf8))
    }

    func fetchDailySince(days: Int) async throws -> DailyResponse {
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        let output = try await run(args: ["ccusage", "daily", "--json", "--since", fmt.string(from: since)])
        return try Self.decoder.decode(DailyResponse.self, from: Data(output.utf8))
    }

    // ISO8601 with fractional seconds (ccusage timestamps: "2026-05-21T18:00:00.000Z")
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let fmtMs = ISO8601DateFormatter()
        fmtMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmtPlain = ISO8601DateFormatter()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let str = try c.decode(String.self)
            if let date = fmtMs.date(from: str) { return date }
            if let date = fmtPlain.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Cannot parse date: \(str)")
        }
        return d
    }()

    private func run(args: [String]) async throws -> String {
        let npx = npxPath
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let binDir = URL(fileURLWithPath: npx).deletingLastPathComponent().path

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: npx)
            process.arguments = args
            process.environment = [
                "HOME": home,
                "PATH": "\(binDir):/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin",
                "NO_UPDATE_NOTIFIER": "1",
                "npm_config_loglevel": "silent"
            ]
            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            process.terminationHandler = { p in
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                if p.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? ""
                    continuation.resume(throwing: CCUsageError.nonZeroExit(p.terminationStatus, errStr))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
