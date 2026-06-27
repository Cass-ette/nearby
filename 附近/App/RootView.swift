import SwiftUI

struct RootView: View {
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding = false
    @State private var selectedTab: Int = {
        // Allow launching directly into a specific tab via --tab N
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--tab"), idx + 1 < args.count, let n = Int(args[idx + 1]) {
            return n
        }
        return 0
    }()

    var body: some View {
        ZStack {
            Color.paper50
                .ignoresSafeArea()

            Group {
                if !hasCompletedOnboarding {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                } else {
                    TabView(selection: $selectedTab) {
                        TodayView()
                            .tabItem { Label(NSLocalizedString("tab.today", value: "今日", comment: ""), systemImage: "calendar") }
                            .tag(0)

                        Group {
                            if ProcessInfo.processInfo.arguments.contains("--map-classic") {
                                MapViewClassic()
                            } else {
                                MapView()
                            }
                        }
                        .tabItem { Label(NSLocalizedString("tab.map", value: "地图", comment: ""), systemImage: "map") }
                        .tag(1)

                        FeedView()
                            .tabItem { Label(NSLocalizedString("tab.feed", value: "时间流", comment: ""), systemImage: "rectangle.stack") }
                            .tag(2)

                        MineView()
                            .tabItem { Label(NSLocalizedString("tab.mine", value: "我的", comment: ""), systemImage: "person.crop.circle") }
                            .tag(3)
                    }
                    .tint(.cinnabar)
                    .toolbarBackground(Color.paper50, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
