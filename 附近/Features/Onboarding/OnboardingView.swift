import SwiftUI

struct OnboardingView: View {
    @State private var pageIndex = 0
    var onFinish: () -> Void

    private let pages: [(image: String, titleZh: String, titleEn: String, bodyZh: String, bodyEn: String)] = [
        ("sun.max", "每天一点灵感", "A small daily spark", "让你重新看见附近的世界。", "See your nearby world again."),
        ("map", "记录，也看看大家", "Record — and see others", "你可以记录，也可以看看今天大家记录了什么。", "You can record — and see what others recorded today."),
        ("lock.shield", "我们只模糊到街区", "We only fuzz to neighborhood", "不会保存精确位置，街区级是最大的颗粒度。", "We never store precise location. Neighborhood is the grain.")
    ]

    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer()

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                    VStack(spacing: Spacing.l) {
                        Image(systemName: page.image)
                            .font(.system(size: 64))
                            .foregroundStyle(Color.cinnabar)

                        VStack(spacing: Spacing.s) {
                            Text(Locale.current.language.languageCode?.identifier == "en" ? page.titleEn : page.titleZh)
                                .font(.titleDisplay)
                                .foregroundStyle(Color.ink900)
                                .multilineTextAlignment(.center)

                            Text(Locale.current.language.languageCode?.identifier == "en" ? page.bodyEn : page.bodyZh)
                                .font(.bodySerif)
                                .foregroundStyle(Color.ink700)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 480)

            Spacer()

            Button {
                if pageIndex == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation { pageIndex += 1 }
                }
            } label: {
                Text(pageIndex == pages.count - 1
                     ? NSLocalizedString("onboarding.start", value: "开始", comment: "")
                     : NSLocalizedString("onboarding.next", value: "下一步", comment: ""))
                    .font(.headline)
                    .foregroundStyle(Color.paper50)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .background(Color.cinnabar)
                    .cornerRadius(Radius.button)
            }
            .padding(.horizontal, Spacing.l)

            Button {
                onFinish()
            } label: {
                Text(NSLocalizedString("onboarding.skip", value: "跳过", comment: ""))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
            }
            .padding(.top, Spacing.s)

            Spacer().frame(height: Spacing.l)
        }
        .paperBackground()
    }
}
