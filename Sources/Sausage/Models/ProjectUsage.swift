struct ProjectUsage: Sendable, Identifiable {
    var id: String { name }
    let name: String
    let tokens: Int
    let cost: Double
}
