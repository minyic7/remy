import SwiftUI

struct TypingIndicator: View {
    @State private var animationPhase = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.3),
                        value: animationPhase
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onReceive(timer) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
}

#Preview {
    TypingIndicator()
}
