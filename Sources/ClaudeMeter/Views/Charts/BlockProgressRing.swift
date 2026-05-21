import SwiftUI

struct BlockProgressRing: View {
    let progress: Double  // 0.0–1.0
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 10)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(width: 100, height: 100)
        .onAppear { animatedProgress = min(1, max(0, progress)) }
        .onChange(of: progress) { _, v in animatedProgress = min(1, max(0, v)) }
    }
}
