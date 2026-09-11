import SwiftUI

struct AudioWaveView: View {
    var isAnimating: Bool
    var color: Color = .accentColor

    @State private var heights: [CGFloat] = [0.3, 0.6, 0.9, 0.6, 0.3]

    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 6, height: isAnimating ? heights[index] * 30 : 5)
                    .animation(.easeInOut(duration: 0.15), value: heights)
            }
        }
        .frame(height: 30)
        .onReceive(timer) { _ in
            guard isAnimating else { return }
            heights = (0..<5).map { _ in CGFloat.random(in: 0.2...1.0) }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioWaveView(isAnimating: true)
        AudioWaveView(isAnimating: false, color: .gray)
    }
}
