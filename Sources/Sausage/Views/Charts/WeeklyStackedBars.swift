import SwiftUI
import Charts

struct WeeklyStackedBars: View {
    let data: [DailyUsage]

    private struct ModelDay: Identifiable {
        let id: String
        let period: String
        let modelName: String
        let tokens: Int
    }

    private var chartData: [ModelDay] {
        data.flatMap { day in
            day.modelBreakdowns.map { mb in
                ModelDay(
                    id: "\(day.period)-\(mb.modelName)",
                    period: day.period,
                    modelName: shortModelName(mb.modelName),
                    tokens: mb.outputTokens + mb.inputTokens
                )
            }
        }
    }

    private func shortModelName(_ name: String) -> String {
        if name.contains("opus") { return "Opus" }
        if name.contains("haiku") { return "Haiku" }
        return "Sonnet"
    }

    @State private var appeared = false

    var body: some View {
        Chart(chartData) { item in
            BarMark(
                x: .value("Day", item.period),
                y: .value("Tokens", appeared ? item.tokens : 0)
            )
            .foregroundStyle(by: .value("Model", item.modelName))
        }
        .chartForegroundStyleScale([
            "Opus": Color(red: 0.85, green: 0.40, blue: 0.19),
            "Sonnet": Color(red: 0.64, green: 0.90, blue: 0.21),
            "Haiku": Color(red: 0.39, green: 0.40, blue: 0.95)
        ])
        .chartXAxis {
            AxisMarks(values: .automatic) {
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYAxis(.hidden)
        .chartLegend(position: .bottom, alignment: .leading)
        .animation(.easeOut(duration: 0.5), value: appeared)
        .frame(height: 100)
        .onAppear { appeared = true }
    }
}
