import SwiftUI

struct TopProjectsBars: View {
    let data: [ProjectUsage]

    private var maxTokens: Int { max(1, data.map(\.tokens).max() ?? 1) }

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, project in
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(1)
                        .frame(width: 90, alignment: .trailing)

                    GeometryReader { geo in
                        let ratio = CGFloat(project.tokens) / CGFloat(maxTokens)
                        let targetWidth = appeared ? geo.size.width * ratio : 0
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.85, green: 0.40, blue: 0.19),
                                        Color(red: 0.85, green: 0.40, blue: 0.19).opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: targetWidth, height: 14)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.07),
                                value: appeared
                            )
                    }
                    .frame(height: 14)

                    Text(project.tokens.formatted(.number.notation(.compactName)))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .frame(width: 36, alignment: .leading)
                }
            }
        }
        .onAppear { appeared = true }
    }
}
