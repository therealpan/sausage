import Foundation

enum AnthropicAdminError: Error {
    case noAPIKey
    case notImplemented
}

actor AnthropicAdminClient {
    var hasKey: Bool {
        KeychainStore.read(service: "claudemeter", account: "anthropic-admin-key") != nil
    }
}
