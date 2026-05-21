import SwiftUI

struct ActivityHeatmap: View {
    let data: [DailyUsage]

    private let cellSize: CGFloat = 10
    private let spacing: CGFloat = 2
    private let weeks = 13
    private let daysPerWeek = 7

    private struct Cell: Identifiable {
        let id: Int
        let date: Date
        let period: String
        let tokens: Int
    }

    private var cells: [Cell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let lookup = Dictionary(uniqueKeysWithValues: data.map { ($0.period, $0.totalTokens) })
        return (0..<(weeks * daysPerWeek)).map { i in
            let offset = -(weeks * daysPerWeek - 1 - i)
            let date = cal.date(byAdding: .day, value: offset, to: today) ?? today
            let period = fmt.string(from: date)
            return Cell(id: i, date: date, period: period, tokens: lookup[period] ?? 0)
        }
    }

    private var maxTokens: Int {
        max(1, cells.map(\.tokens).max() ?? 1)
    }

    @State private var appeared = false

    var body: some View {
        let cols = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: weeks)
        LazyVGrid(columns: cols, spacing: spacing) {
            ForEach(cells) { cell in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(for: cell.tokens))
                    .frame(width: cellSize, height: cellSize)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .easeIn(duration: 0.2).delay(Double(cell.id) * 0.002),
                        value: appeared
                    )
                    .help("\(cell.date.formatted(date: .abbreviated, time: .omitted)): \(cell.tokens.formatted()) tokens")
            }
        }
        .onAppear { appeared = true }
    }

    private func cellColor(for tokens: Int) -> Color {
        guard tokens > 0 else {
            return Color.white.opacity(0.05)
        }
        let ratio = Double(tokens) / Double(maxTokens)
        let opacity = max(0.15, min(1.0, 0.15 + ratio * 0.85))
        return Color(red: 0.85, green: 0.40, blue: 0.19).opacity(opacity)
    }
}
