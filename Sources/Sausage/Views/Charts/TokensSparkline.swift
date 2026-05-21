import SwiftUI
import Charts

struct TokensSparkline: View {
    let data: [DailyUsage]

    private let terra = Color(red: 0.85, green: 0.40, blue: 0.19)

    var body: some View {
        Chart(data) { day in
            AreaMark(
                x: .value("Date", day.period),
                y: .value("Tokens", day.totalTokens)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [terra.opacity(0.7), terra.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Date", day.period),
                y: .value("Tokens", day.totalTokens)
            )
            .foregroundStyle(terra)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 44)
    }
}
