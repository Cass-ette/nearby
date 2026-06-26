# 附近 / Nearby

> 每天一个任务，让你重新看见身边的世界。
>
> 一个以每日轻任务驱动的图文社交平台——苹果移动创新赛参赛项目。

## 这是什么

「附近」回应社会学家项飙提出的"附近的消失"问题。我们每天被算法和效率逻辑包裹，对脚下的世界越来越陌生。这个 App 用每天一个轻任务，把你从屏幕里拉出来，重新看见身边的街、人、和故事。

## 核心功能

- **每日任务**：全城同步，社区投票选出一个轻任务（发现/细节/连接/记忆/共同 5 种类型）
- **图文记录**：一张图 + 一段文字 + 心情标签 + 6 种纸质感滤镜 + 模糊定位
- **模糊定位**：精确到街区级（~100m），保护隐私
- **地图流**：城市人文图层——在地图上看见这条街、这个街区里别人记录了什么
- **时间流**：作品集质感的图文流
- **文字回应**：不能点赞，只能文字回应——鼓励真诚连接
- **任务档案馆**：所有历史任务的浏览页
- **城市徽章**：连续记录、5 种任务类型探索等成就

## 技术栈

| 层 | 选型 |
|---|---|
| UI | SwiftUI (iOS 26+) |
| 状态 | `@Observable` + `@Environment` |
| 持久化 | SwiftData (本地) |
| 位置 | CoreLocation + CLGeocoder |
| 地图 | MapKit |
| 图片 | PhotosUI + Core Image |
| 项目 | XcodeGen (`project.yml`) |
| 测试 | XCTest (`import Testing`) |

## 项目结构

```
附近/
├─ App/                  入口 + RootView
├─ DesignSystem/         颜色/字体/间距/纸质感背景/SealStamp
├─ Models/               Post, Response, DailyTask, MoodTag, TaskType, FuzzyLocation
├─ Data/                 TaskBank, TaskDistributor, MockSeeder, NeighborhoodTable
├─ Services/             LocationManager, ImageFilter, ImageStorage, GeoLabelResolver, StreakCalculator
├─ Features/
│  ├─ Today/             今日任务卡 + 完成印章
│  ├─ Record/            拍照编辑发布
│  ├─ Map/               照片钉子地图流
│  ├─ Feed/              时间流 + 详情 + 文字回应
│  ├─ Archive/           任务档案馆
│  ├─ Mine/              我的页 + 徽章
│  └─ Onboarding/        3 屏首次引导
└─ Assets.xcassets/      颜色 + AppIcon

附近Resources/            任务库 JSON + mock 内容 + String Catalog
附近Tests/                单元测试（38 个）
```

## 跑起来

需要 macOS + Xcode 26+ + iPhone 17 Pro 模拟器（推荐）。

```bash
# 安装 xcodegen（如果还没有）
brew install xcodegen

# 拉代码 + 生成 Xcode 项目
git clone https://github.com/Cass-ette/nearby.git
cd nearby
xcodegen generate

# 构建 + 跑测试
xcodebuild test -project 附近.xcodeproj -scheme 附近 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 装到模拟器
xcodebuild build -project 附近.xcodeproj -scheme 附近 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
APP=$(find ~/Library/Developer/Xcode/DerivedData/附近-* \
  -name "附近.app" -path "*Debug-iphonesimulator*" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.cassette.nearby
```

App 首次启动会自动种入 ~40 条 mock 内容（来自 30 位虚构邻居，分布在中山西路/巨鹿路/武康路等 10 个上海街区）。

## Demo 走查脚本

| 步骤 | 操作 | 期望 |
|---|---|---|
| 1 | 启动 App | 显示 3 屏 onboarding → 点"开始" |
| 2 | Today tab | 任务卡显示今日任务（标题/引导/提案人/票数） |
| 3 | 点"开始记录" | 进入 RecordView |
| 4 | 选图 → 选滤镜 → 起标题 → 写 ≥6 字 → 选心情 | "发布"按钮变可点 |
| 5 | 点"发布" | 回到 Today，卡片右下角盖朱砂红"今日已完成"印章 |
| 6 | Map tab | 看见 mock 钉子散布在上海街区 |
| 7 | 点钉子 → mini preview → 详情 | 详情页显示完整 Post + 回应 |
| 8 | 在详情页留一句回应 | 回应即时出现在列表 |
| 9 | Feed tab | 时间流单列大图卡片，"全部/我的"切换 |
| 10 | Mine tab | "你"昵称 + 连续天数 + 3 段 segmented（记录/回应/徽章） |
| 11 | 点"看看过去的日子" | 任务档案馆，30 个任务按月分组 |
| 12 | 切换系统语言到 English | TabBar / 按钮 / 任务文案全部切换 |

## 设计语言

| 维度 | 方向 |
|---|---|
| 色彩 | paper-50 暖米白 / ink 暖炭黑 / cinnabar 朱砂红（强调） / 5 种心情色 |
| 字体 | 中文宋体（Songti SC）+ 英文 New York（标题）/ PingFang SC（正文） |
| 间距 | 4pt grid，最大 48pt 用于卡片大留白 |
| 质感 | 纸质纹理、柔光阴影、0.5pt 细线 |
| 反对 | 算法焦虑、表演感、信息流瀑布、积分内卷 |

## 测试覆盖

38 个单元测试覆盖：
- TaskBank / TaskDistributor（日期派发 + 时区）
- StreakCalculator（连续天数）
- LocationFuzzer（100m 网格）
- ImageFilter / ImageStorage（6 种滤镜 + resize/encode）
- NeighborhoodTable（10 个上海街区）
- MockSeeder（幂等性）
- PostModel smoke（SwiftData 插入/查询）
- AnnotationClusterer（地图聚类）
- Badge（7 种徽章派生规则）

## 商业模式（轻量说明）

| 阶段 | 方向 |
|---|---|
| 初期 | 免费，专注社区氛围 |
| 中期 | 实体周边（城市人文地图、纸质任务手账） |
| 长期 | 与城市文化机构、独立书店、本地商户合作 |

不做：信息流广告、算法推荐电商、付费会员分层。

## 评委 Q&A

**Q：每天的任务谁写的？** A：任务全部来自社区——任何用户都可以提议明天的任务，得票最高的经审核后全员推送。我们不做算法推荐，只做投票共识。

**Q：怎么避免变成下一个朋友圈？** A：弱化关注关系、不能点赞只能回应、按地图/时间浏览。把"表演给粉丝看"的动机结构拆掉。

**Q：和朋友圈/小红书的根本差别？** A：内容驱动模式不同——朋友圈是关系驱动、小红书是消费驱动、附近是任务驱动。我们做的是"重新看见生活"，不是"展示生活"。

**Q：技术亮点？** A：模糊定位算法保护隐私；地图人文图层是全新产品形态；任务 deterministic 派发实现"全城同步"仪式感而无需后端。

## License

MIT
