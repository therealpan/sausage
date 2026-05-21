import SwiftUI
import Charts

struct ModelsDonut: View {
    let models: [String]
    var breakdowns: [ModelBreakdown]? = nil  // real token weights if available

    private struct Slice: Identifiable {
        let id: String
        let label: String
        let value: Double
    }

    private var slices: [Slice] {
        if let bkdn = breakdowns, !bkdn.isEmpty {
            let total = Double(bkdn.reduce(0) { $0 + $1.outputTokens + $1.inputTokens })
            guard total > 0 else { return equalSlices }
            return bkdn.map { mb in
                Slice(id: mb.modelName, label: shortName(mb.modelName),
                      value: Double(mb.outputTokens + mb.inputTokens) / total)
            }
        }
        return equalSlices
    }

    private var equalSlices: [Slice] {
        guard !models.isEmpty else { return [] }
        let w = 1.0 / Double(models.count)
        return models.map { Slice(id: $0, label: shortName($0), value: w) }
    }

    private func shortName(_ name: String) -> String {
        if name.contains("opus") { return "Opus" }
        if name.contains("haiku") { return "Haiku" }
        return "Sonnet"
    }

    @State private var appeared = false

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Usage", appeared ? slice.value : 0),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Model", slice.label))
        }
        .chartForegroundStyleScale([
            "Opus": Color(red: 0.85, green: 0.40, blue: 0.19),
            "Sonnet": Color(red: 0.64, green: 0.90, blue: 0.21),
            "Haiku": Color(red: 0.39, green: 0.40, blue: 0.95)
        ])
        .chartLegend(.hidden)
        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appeared)
        .onAppear { appeared = true }
        .frame(width: 70, height: 70)
    }
}
