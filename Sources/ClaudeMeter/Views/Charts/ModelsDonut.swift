import SwiftUI
import Charts

struct ModelsDonut: View {
    let models: [String]

    private struct Slice: Identifiable {
        let id: String
        let label: String
        let value: Double
    }

    private var slices: [Slice] {
        guard !models.isEmpty else { return [] }
        let weight = 1.0 / Double(models.count)
        return models.map { model in
            Slice(id: model, label: shortName(model), value: weight)
        }
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
