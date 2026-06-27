import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var taskBank: [DailyTask] = []
    @State private var autoShowRecord: Bool = {
        ProcessInfo.processInfo.arguments.contains("--show-record")
    }()
    @State private var showIdea = false
    @State private var showTopicHub = false

    var body: some View {
        NavigationStack {
            Group {
                if let task = viewModel.todayTask {
                    TodayBubbleGarden(
                        task: task,
                        todayRecordCount: viewModel.todayRecordCount,
                        hasCompleted: viewModel.hasCompletedToday,
                        onRecord: { viewModel.showRecord = true },
                        onIdea: { showIdea = true },
                        onTopicHub: { showTopicHub = true }
                    )
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.s)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("附近")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper50, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .containerBackground(Color.paper50, for: .navigation)
            .navigationDestination(for: String.self) { value in
                if value == "archive" {
                    ArchiveView()
                }
            }
            .sheet(isPresented: $viewModel.showRecord) {
                RecordView()
            }
            .sheet(isPresented: $showIdea) {
                if let task = viewModel.todayTask {
                    IdeaSheet(task: task) {
                        showIdea = false
                        viewModel.showRecord = true
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showTopicHub) {
                TopicHubSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .paperBackground()
        .task {
            taskBank = TaskBank.loadSync()
            viewModel.load(modelContext: modelContext, taskBank: taskBank)
            if autoShowRecord {
                viewModel.showRecord = true
                autoShowRecord = false
            }
        }
        .onChange(of: viewModel.showRecord) { _, newValue in
            if !newValue {
                viewModel.load(modelContext: modelContext, taskBank: taskBank)
            }
        }
    }
}

private struct TodayBubbleGarden: View {
    let task: DailyTask
    let todayRecordCount: Int
    let hasCompleted: Bool
    let onRecord: () -> Void
    let onIdea: () -> Void
    let onTopicHub: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    Spacer(minLength: max(Spacing.s, height * 0.02))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("今天")
                            .font(.meta)
                            .foregroundStyle(Color.ink500)
                        Text("附近有什么值得留下？")
                            .font(.titleDisplay)
                            .foregroundStyle(Color.ink900)
                            .lineSpacing(1)
                    }
                    .padding(.horizontal, Spacing.xs)

                    Button(action: onRecord) {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 25, weight: .semibold))
                                    .foregroundStyle(Color.paper50)
                                    .frame(width: 56, height: 56)
                                    .background(Color.paper50.opacity(0.18))
                                    .clipShape(Circle())

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color.paper50.opacity(0.82))
                                    .frame(width: 44, height: 44)
                                    .background(Color.paper50.opacity(0.14))
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text("开始记录")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                Text("照片、文字，或者只是此刻。")
                                    .font(.calloutText)
                                    .opacity(0.78)
                            }
                            .foregroundStyle(Color.paper50)
                        }
                        .padding(Spacing.l)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: min(height * 0.32, 232))
                        .background(
                            ZStack {
                                LinearGradient(
                                    colors: [Color.cinnabar, Color.cinnabarDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.white.opacity(0.24), Color.white.opacity(0.02)],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 90
                                        )
                                    )
                                    .frame(width: 180, height: 180)
                                    .offset(x: -92, y: -74)

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.sand.opacity(0.26), Color.sand.opacity(0.03)],
                                            center: .center,
                                            startRadius: 12,
                                            endRadius: 110
                                        )
                                    )
                                    .frame(width: 220, height: 220)
                                    .offset(x: 122, y: 72)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
                                .stroke(Color.white.opacity(0.34), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.02), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blendMode(.screen)
                        }
                        .shadow(color: Color.cinnabar.opacity(0.22), radius: 24, x: 0, y: 16)
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: Spacing.m), GridItem(.flexible(), spacing: Spacing.m)],
                        spacing: Spacing.m
                    ) {
                        TodayMiniCard(
                            title: NSLocalizedString("today.label", value: "灵感", comment: ""),
                            value: "今日",
                            systemImage: task.type.iconName,
                            tint: Color.glassSage.opacity(0.56),
                            action: onIdea
                        )

                        TodayMiniCard(
                            title: NSLocalizedString("topic.hub.entry", value: "共创", comment: ""),
                            value: NSLocalizedString("topic.hub.votes_short", value: "3票", comment: ""),
                            systemImage: "sparkles",
                            tint: Color.glassBlush.opacity(0.58),
                            action: onTopicHub
                        )

                        TodayInfoCard(
                            value: "\(todayRecordCount)",
                            label: NSLocalizedString("today.stats.today", value: "今日留下", comment: ""),
                            systemImage: "circle.grid.2x2.fill",
                            tint: Color.glassButter.opacity(0.50)
                        )

                        NavigationLink(value: "archive") {
                            TodayInfoCard(
                                value: "回看",
                                label: "过往瞬间",
                                systemImage: "tray.full",
                                tint: Color.glassMist.opacity(0.54)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.s)
                .padding(.bottom, Spacing.xl)
                .frame(minHeight: height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TodayMiniCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.cinnabar)
                    .frame(width: 42, height: 42)
                    .background(Color.cinnabar.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.sectionTitle)
                        .foregroundStyle(Color.ink900)
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
            .glassCard(tint: tint)
        }
        .buttonStyle(.plain)
    }
}

private struct TodayInfoCard: View {
    let value: String
    let label: String
    let systemImage: String
    var tint: Color = .paper100.opacity(0.34)

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.cinnabar)
                .frame(width: 30, height: 30)
                .background(Color.cinnabar.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.ink900)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.m)
        .glassCard(tint: tint)
    }
}

private struct IdeaSheet: View {
    let task: DailyTask
    let onRecord: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(spacing: Spacing.s) {
                Image(systemName: task.type.iconName)
                    .foregroundStyle(Color.cinnabar)
                Text(NSLocalizedString("today.label", value: "今日灵感", comment: ""))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.ink500)
            }

            Text(task.localizedTitle())
                .font(.titleDisplay)
                .foregroundStyle(Color.ink900)
                .lineSpacing(4)

            Text(task.localizedPrompt())
                .font(.bodySerif)
                .foregroundStyle(Color.ink700)
                .lineSpacing(5)

            Button(action: onRecord) {
                Text(NSLocalizedString("today.cta.record", value: "记录一下", comment: ""))
            }
            .buttonStyle(NearbyPrimaryButtonStyle())
            .padding(.top, Spacing.s)
        }
        .padding(Spacing.l)
        .paperBackground()
    }
}

private struct TopicHubSheet: View {
    private let topics = [
        TopicVoteOption(title: "在附近发现一处小小春天", votes: 128, isLeading: true),
        TopicVoteOption(title: "今天路过的声音", votes: 96, isLeading: false),
        TopicVoteOption(title: "把晚霞装进照片里", votes: 84, isLeading: false)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.cinnabar)
                        Text("今日共创")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.ink500)
                    }

                    Text("一起选出明天的灵感")
                        .font(.titleDisplay)
                        .foregroundStyle(Color.ink900)
                }

                HStack(spacing: Spacing.s) {
                    TopicStatPill(value: "3", label: "剩余票")
                    TopicStatPill(value: "明天", label: "最高票上新")
                }

                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("正在投票")
                        .font(.headline)
                        .foregroundStyle(Color.ink900)

                    ForEach(topics) { topic in
                        TopicVoteCard(topic: topic)
                    }
                }

                CreateTopicCard()
            }
            .padding(Spacing.l)
        }
        .paperBackground()
    }
}

private struct TopicVoteOption: Identifiable {
    let id = UUID()
    let title: String
    let votes: Int
    let isLeading: Bool
}

private struct TopicStatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink900)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.ink500)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
        .background(Color.paper100.opacity(0.82))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.ink300.opacity(0.22), lineWidth: 0.7))
    }
}

private struct TopicVoteCard: View {
    let topic: TopicVoteOption

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    if topic.isLeading {
                        Text("暂时领先")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.paper50)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cinnabar)
                            .clipShape(Capsule())
                    }
                    Text("\(topic.votes) 票")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.ink500)
                }

                Text(topic.title)
                    .font(.headline)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(2)
            }

            Spacer(minLength: Spacing.s)

            Button {
            } label: {
                Text("投一票")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.paper50)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, 10)
                    .background(Color.ink900)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.m)
        .nearbyCard(
            fill: topic.isLeading ? Color.moodTender.opacity(0.30) : .surfaceElevated,
            strokeOpacity: topic.isLeading ? 0.26 : 0.16,
            shadowOpacity: 0.035
        )
    }
}

private struct CreateTopicCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.m) {
                Image(systemName: "plus.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(Color.cinnabar)
                    .frame(width: 42, height: 42)
                    .background(Color.cinnabar.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("创建一个话题")
                        .font(.headline)
                        .foregroundStyle(Color.ink900)
                }
            }

            HStack(spacing: Spacing.s) {
                Text("比如：收集今天的蓝色")
                    .font(.bodySerif)
                    .foregroundStyle(Color.ink500)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.ink500)
            }
            .padding(Spacing.m)
            .background(Color.paper50.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
        }
        .padding(Spacing.m)
        .nearbyCard(fill: .surfaceElevated, strokeOpacity: 0.16, shadowOpacity: 0.035)
    }
}
