import SwiftUI

struct PulseIndicator: View {
    let color: Color
    let active: Bool

    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .opacity(active ? (pulsing ? 1.0 : 0.3) : 1.0)
            .animation(
                active
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: pulsing
            )
            .onAppear { if active { pulsing = true } }
            .onChange(of: active) { _, newValue in pulsing = newValue }
    }
}
