import SwiftUI

struct SealStamp: View {
    @State private var scale = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.cinnabar.opacity(0.8), lineWidth: 2)
                .background(Circle().fill(Color.cinnabar.opacity(0.08)))
                .frame(width: 64, height: 64)
            VStack(spacing: 0) {
                Text(NSLocalizedString("seal.today_done", value: "今日", comment: ""))
                    .font(.system(size: 11, weight: .bold))
                Text(NSLocalizedString("seal.today_done_2", value: "已完成", comment: ""))
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color.cinnabar.opacity(0.85))
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .rotationEffect(.degrees(-8))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
