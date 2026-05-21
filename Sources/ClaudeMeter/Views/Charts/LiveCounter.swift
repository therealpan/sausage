import SwiftUI

struct LiveCounter: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .contentTransition(.numericText(countsDown: false))
                .foregroundStyle(.white)
                .animation(.default, value: value)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }
}
