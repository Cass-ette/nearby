# 「附近」App 设计稿

> 一个以每日任务驱动的图文社交 App，用游戏化的方式引导人们重新关注被忽略的"附近"。
> 目标：苹果移动创新赛参赛 demo，Xcode 模拟器可完整跑通。

---

## 一、概述

### 1.1 产品定位
- **名称**：附近（Nearby）
- **类型**：生活记录 / 轻社交 App
- **平台**：iOS 18+（兼容 iPadOS）
- **一句话定位**：每天一个任务，让你重新看见身边的世界
- **参赛主题**：人文关怀 × 软件创新

### 1.2 核心价值主张
用每天一个任务，把人的注意力从屏幕里拉出来，放回脚下的土地。

### 1.3 长期产品叙事（影响 UI 文案与设计）
- 每日任务来自**社区发布 → 社区投票 → 后台审核**
- 评委问"运营"时，回答："任务全部来自社区——任何用户都可以提议明天的任务，得票最高的经审核后全员推送。我们不做算法推荐，只做投票共识。"
- 不做点赞、不做粉丝、不做算法推荐，只做"回应"

### 1.4 比赛参赛原则
- 本地 mock 数据，无后端依赖
- 完整闭环可演示，多台设备同一天看到同一任务（deterministic 派发）
- 充分调用 Apple 生态能力（CoreLocation / MapKit / PhotoKit / SwiftUI）
- 中英双语

---

## 二、MVP 范围

### 2.1 包含功能
| 功能 | 说明 |
|---|---|
| 每日任务 | 日期 deterministic 派发，全设备同一天同一任务 |
| 图文记录 | 一张图（相册/相机）+ 一段文字（≥6 字） |
| 6 种纸质感滤镜 | 原图 / 纸 / 墨 / 晨 / 暮 / 雾 |
| 心情标签 | 宁静 / 好奇 / 惆怅 / 温柔 / 惊喜（单选） |
| 模糊定位 | 街区级（~100m），仅显示街区名 |
| 地图流 | Apple MapKit + 照片钉子 |
| 时间流 | 单列大图卡片，"全部 / 我的"切换 |
| 任务档案馆 | 看历史所有任务，每个有提案人/票数/记录数 |
| 文字回应 | 在他人 Post 下留文字回应（不可点赞） |
| 我的页 | 我的记录网格 / 我的回应 / 城市徽章 / 连续天数 |

### 2.2 不做（明确排除）
- Widget / Live Activity（阶段二再考虑）
- CloudKit 后端（本地 SwiftData 即可）
- Apple Intelligence 集成
- PhotoKit 关联相册历史
- 用户 Profile 页（彻底贯彻"轻身份"）
- 积分排行榜
- 关注关系
- 视频上传
- 真实投票 UI（只展示已采纳任务的票数叙事）

### 2.3 不做的"长期愿景"
- 任何形式的点赞、关注、转发
- 信息流广告、算法推荐电商、付费会员分层

---

## 三、技术架构

### 3.1 技术栈
| 层 | 选型 |
|---|---|
| UI | SwiftUI (iOS 18+) |
| 状态管理 | `@Observable` + `@Environment`，无 Combine |
| 持久化 | SwiftData（本地） |
| 本地化 | String Catalog (`.xcstrings`) |
| 位置 | CoreLocation |
| 地图 | MapKit (iOS 17+ SwiftUI API) |
| 图片 | PhotosUI (PhotosPicker) + Camera (UIImagePickerController) |
| 图片处理 | Core Image (CIFilter) |
| 包/模块 | 单 app target，不拆 package |

### 3.2 项目目录结构
```
附近.xcodeproj
附近/
├─ App/
│  ├─ NearbyApp.swift              @main 入口
│  └─ RootView.swift               TabView 容器
├─ Models/                         SwiftData @Model
│  ├─ Post.swift
│  ├─ Response.swift
│  ├─ DailyTask.swift              Codable (from JSON)
│  ├─ FuzzyLocation.swift
│  └─ MoodTag.swift
├─ Data/
│  ├─ TaskBank.swift               加载 tasks.json
│  ├─ TaskDistributor.swift        deterministic 派发算法
│  ├─ MockSeeder.swift             首次启动种 mock 内容
│  └─ Resources/
│     ├─ tasks.json                任务库（30+ 条）
│     ├─ mock_users.json           mock 用户昵称表
│     └─ MockImages/               预置图片资源（10-20 张）
├─ Services/
│  ├─ LocationManager.swift        CoreLocation 包装
│  ├─ ImageFilter.swift            Core Image 滤镜
│  └─ LocationFuzzer.swift         把精确定位糊到 100m 网格
├─ Features/
│  ├─ Today/
│  │  ├─ TodayView.swift
│  │  ├─ TodayViewModel.swift
│  │  └─ TaskCardView.swift
│  ├─ Record/
│  │  ├─ RecordView.swift
│  │  ├─ RecordViewModel.swift
│  │  ├─ PhotoPickerButton.swift
│  │  ├─ FilterPicker.swift
│  │  └─ MoodSelector.swift
│  ├─ Map/
│  │  ├─ MapView.swift
│  │  ├─ MapViewModel.swift
│  │  ├─ PhotoAnnotation.swift
│  │  └─ MiniPreviewCard.swift
│  ├─ Feed/
│  │  ├─ FeedView.swift
│  │  ├─ FeedViewModel.swift
│  │  ├─ PostCardView.swift
│  │  └─ PostDetailView.swift
│  ├─ Archive/
│  │  ├─ ArchiveView.swift
│  │  └─ ArchiveViewModel.swift
│  └─ Mine/
│     ├─ MineView.swift
│     ├─ MineViewModel.swift
│     └─ BadgeGrid.swift
├─ DesignSystem/
│  ├─ Color.swift                  palette + mood
│  ├─ Typography.swift             font helpers
│  ├─ Spacing.swift                4pt grid
│  ├─ PaperBackground.swift        纸质感 ViewModifier
│  └─ Components/
│     ├─ TaskBadge.swift
│     ├─ MoodDot.swift
│     └─ SealStamp.swift           完成印章
├─ Localization/
│  └─ Localizable.xcstrings        中英双语
└─ Assets.xcassets/
   ├─ AppIcon
   ├─ MockImages/                  预置 mock 图（10-20 张生活气息街景）
   ├─ PaperTexture/                纸质纹理叠图
   └─ Colors/                      palette colors
```

### 3.3 项目配置
- Bundle ID: `com.cassette.nearby`
- Display Name (中文): 附近
- Display Name (英文): Nearby
- iOS Deployment Target: 18.0
- Device: iPhone (主要) + iPad (兼容)
- Orientation: Portrait only (iPhone), All (iPad)
- Info.plist 权限文案：
  - `NSLocationWhenInUseUsageDescription`: "我们只需要知道你在哪个街区，以便记录你与附近的故事。位置会模糊到街区级，不会保存精确位置。"
  - `NSCameraUsageDescription`: "拍照记录你看见的附近。"

> 注：PhotosPicker (PhotosUI) 走 out-of-process 进程，**不需要** `NSPhotoLibraryUsageDescription`。仅在直接调用 PHPhotoLibrary API 时才需要。

---

## 四、数据模型

### 4.1 SwiftData Models

```swift
@Model final class Post {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var taskRef: String              // 关联 DailyTask.id
    var imageData: Data              // 压缩 JPEG (~80-180KB, 长边 ≤2400px)
    var thumbnailData: Data          // 缩略图 JPEG (~10-30KB, 长边 400px)
    var title: String?               // 可选作品标题
    var text: String                 // 必填，≥6 字
    var moodTagRaw: String?          // MoodTag.rawValue
    var filterName: String?          // 用了的滤镜名
    var fuzzyLabel: String           // "愚园路 · 静安"
    var fuzzyLat: Double             // 精确到 0.001 (~100m)
    var fuzzyLon: Double
    var isOwn: Bool                  // true=自己发布；false=mock（缓存字段，authorId == CurrentUser.id 时同步）
    var authorId: UUID               // 区分用户身份（mock 用预置 UUID）
    var authorName: String

    init(...) { ... }
}

@Model final class Response {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var postId: UUID
    var text: String                 // 文字 only
    var isOwn: Bool
    var authorName: String
}

enum MoodTag: String, Codable, CaseIterable {
    case serene = "宁静"
    case curious = "好奇"
    case melancholy = "惆怅"
    case tender = "温柔"
    case surprise = "惊喜"
}

// 当前用户身份（轻身份设计：只一个常量 + 可改昵称）
enum CurrentUser {
    static let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static var displayName: String {
        get { UserDefaults.standard.string(forKey: "currentUser.name") ?? "你" }
        set { UserDefaults.standard.set(newValue, forKey: "currentUser.name") }
    }
}

// "isOwn" 不再存到 Post/Response，统一通过 authorId == CurrentUser.id 判断
// 但为简化 SwiftData 查询，保留 isOwn 作为缓存字段，写入时同步设置
```

### 4.2.1 连续记录天数计算（Streak）

```swift
func computeStreak(posts: [Post]) -> Int {
    let cal = Calendar(identifier: .gregorian)
    let days = Set(posts.filter { $0.isOwn }.map { cal.startOfDay(for: $0.createdAt) })
    var streak = 0
    var cursor = cal.startOfDay(for: Date())
    // 如果今天还没发布，从昨天开始算
    if !days.contains(cursor) { cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
    while days.contains(cursor) {
        streak += 1
        cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
    }
    return streak
}
```

### 4.2.2 城市徽章规则（Badge）

不持久化徽章（避免同步问题），所有徽章都是**派生计算**：

| 徽章 | 触发条件 |
|---|---|
| 七日同行 | 连续记录 ≥ 7 天 |
| 月有余温 | 连续记录 ≥ 30 天 |
| 百日扎根 | 连续记录 ≥ 100 天 |
| 五感全开 | 5 种任务类型都有过记录 |
| 城市行人 | 累计发布 ≥ 10 条 |
| 在场 | 累计发布 ≥ 50 条 |
| 城市观 | 累计发布 ≥ 100 条 |

UI 上徽章未解锁时灰色 + 锁图标，解锁后朱砂红 + 解锁日期。
```

### 4.2 任务模型（JSON Bundle）

```swift
struct DailyTask: Codable, Identifiable {
    let id: String                   // "discover_new_path"
    let type: TaskType               // .discover / .detail / .connect / .memory / .together
    let title: LocalizedString       // {zh: "...", en: "..."}
    let prompt: LocalizedString      // 引导文案
    let proposedBy: String           // "@小路"
    let proposedOn: String           // "2026-05-12"
    let voteCount: Int               // 2341
    let adoptedOn: String            // "2026-05-20"
    let referenceImageName: String?  // Asset 名
    let cityTags: [String]           // ["上海"]
}

enum TaskType: String, Codable {
    case discover, detail, connect, memory, together
}

typealias LocalizedString = [String: String]  // {"zh": "...", "en": "..."}
```

### 4.3 任务派发算法

```swift
func todayTask(for date: Date, bank: [DailyTask]) -> DailyTask {
    // 用 Asia/Shanghai 时区的当日 0 点作为日期边界
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    let dayIndex = calendar.startOfDay(for: date).timeIntervalSince1970 / 86400
    return bank[Int(dayIndex) % bank.count]
}
```

**时区选择理由**：MVP 主要面向中文用户，固定 Asia/Shanghai 让所有用户在同一时刻跨入新任务（北京时间 0 点换任务）。后续若出海可改成设备本地时区。

所有设备同一天得到同一个任务。Mock 内容的 `taskRef` 也按这个算法对应到"今天"，营造"今天大家都在做这件事"。

### 4.4 模糊定位算法

```swift
func fuzzify(_ coord: CLLocationCoordinate2D) -> FuzzyLocation {
    let lat = (coord.latitude * 1000).rounded() / 1000   // ~100m 网格
    let lon = (coord.longitude * 1000).rounded() / 1000
    let label = GeoLabelResolver.resolve(lat: lat, lon: lon)
    return FuzzyLocation(label: label, lat: lat, lon: lon)
}
```

**网格碰撞处理（Clustering）**：地图流上多个 Post 落在同一个 0.001° 网格的情况很常见。处理策略：
- 地图层：MapView 默认使用 iOS 17+ 的 `Map` + 自定义 annotation。同网格内 ≤3 个 Post 时分别画钉子（视觉上轻微错开 offset），>3 个时合并为一个带数字的圆形钉子，点击展开为小列表
- 数据层：保留 `fuzzyLat / fuzzyLon` 作为存储值；展示时由 `Clusterer` 在 view model 内做实时聚合

**`GeoLabelResolver` fallback 层级**：
1. CLGeocoder 反查（异步，缓存 24h）：取 `CLPlacemark.subLocality` 或 `thoroughfare`，拼接成 "愚园路 · 静安" 格式
2. 反查失败 / 离线 → 用 `(lat, lon)` 落到预置街区表（上海主要 10 个街区，含中心坐标范围）匹配
3. 都失败 → 显示 "附近 · 此刻"

模拟器无定位时 fallback 到上海愚园路周边坐标 (31.226, 121.426)。

### 4.5 图片存储策略（ImageStorage）

Post.imageData 存的是烘焙后的 JPEG。流程：

```
[PhotosPicker/Camera 原图]
  ↓ resize 长边 ≤ 2400px (CGImageSource / CIImage resize)
  ↓ 应用 CIFilter 链（如选了滤镜）
  ↓ JPEG encode (compressionQuality: 0.82)
[Post.imageData: Data, ~80-180KB]
```

**缩略图策略**：
- 地图钉子（40-56pt）、时间流网格（200pt 宽）需要缩略图，避免每次解码 2400px JPEG
- 写入 Post 时同步生成 thumbnail Data（长边 400px JPEG q=0.7，~10-30KB），存到 `Post.thumbnailData`
- 列表/地图加载只读 thumbnailData；详情页才读全图

**内存管理**：
- FeedView/MapView 用 `AsyncImage` 包装（但 `AsyncImage` 不支持 Data 直接喂，需自定义 `ThumbnailView` ViewModifier）
- 滚动时缓存最近 20 张缩略图（NSCache），其他从 SwiftData lazy 加载

**预算**：30-50 条 mock Post × 平均 25KB thumbnail ≈ 1MB；全图按需加载不入 SwiftData 内存。

---

## 五、页面结构与导航

### 5.1 4 Tab 结构
| Tab | 页面 | 图标 |
|---|---|---|
| 今日 | TodayView | calendar |
| 地图 | MapView | map |
| 时间流 | FeedView | rectangle.grid.2 |
| 我的 | MineView | person.crop.circle |

### 5.2 完整路由图

```
[RootView]
├─ TodayView
│  ├─ → RecordView           (开始记录按钮)
│  ├─ → ArchiveView          (顶部档案馆按钮)
│  └─ → FeedView(filter=todayTask)  (看看今天大家)
├─ MapView
│  ├─ → PostDetailView       (点钉子 → mini preview → 详情)
│  └─ → FilterSheet          (筛选按钮)
├─ FeedView
│  ├─ → PostDetailView       (点卡片)
│  └─ Toggle: 全部 / 我的
├─ MineView
│  ├─ → PostDetailView       (点自己的 Post)
│  └─ → BadgeGridView        (徽章入口)
├─ RecordView (sheet)
│  └─ → PhotoPickerSheet / Camera (底层)
├─ ArchiveView (pushed)
│  └─ → TaskDetailView       (看任务历史记录)
└─ PostDetailView (pushed)
   └─ → ResponseComposer     (留回应)
```

---

## 六、核心页面 UI 详细

### 6.1 今日任务页（TodayView）

**布局：**
- 顶部：标题"附近"（左）+ 日期"6月25日 周四"（右）
- 中央：任务卡（见下）
- 卡片底部："开始记录"主按钮
- 卡片下方：分割线 + "看看今天大家 ↗" 次按钮

**任务卡内容（自上而下）：**
1. 标签行："今日任务"小字 + 任务类型图标
2. 标题（思源宋体 24pt）："今天走一条从没走过的路回家"
3. 引导文案（16pt 灰）："打破日常路径，让熟悉的回家的路，长出一点新的部分。"
4. 分隔线
5. 元信息行：`@小路` · `2,341 票` · `发现 · 共同`
6. 参考图（4:3，圆角 4pt，加 5% 暖色调）

**视觉细节：**
- 卡片用 paper-100 底色，0.5pt ink-300 边框
- 卡片内 padding 24pt
- 完成记录后右下角盖朱砂红"今日已完成"印章（80% opacity，旋转 -8°）

**交互：**
- 进入页面时 0.6s 翻纸动画（横向 fade + 8pt 上推）
- "开始记录"按钮：cinnabar 底色 + 白字，圆角 8pt，全宽

### 6.2 记录编辑页（RecordView）

**布局（自上而下）：**
1. 导航栏：左"取消" + 中"记录今日" + 右"发布"
2. 图片预览区（4:5，paper-200 边框 1pt，圆角 4pt）—— 点击换图
3. 滤镜行：横向滚动的圆形滤镜选择器（6 个：原图/纸/墨/晨/暮/雾），带名称
4. 分隔线
5. 标题输入（可选，placeholder "起个名字…"，单行）
6. 文字输入（必填，placeholder "记一段…，至少一句"，最小高度 120pt，多行）
7. 心情选择（5 个圆点 + 文字标签）
8. 位置预览："📍 愚园路 · 静安（街区级）"

**核心交互：**
- 进入即请求 CoreLocation 一次性权限
- 文字 <6 字时"发布"按钮禁用，下方提示"再多写一句吧"
- 发布成功 → 0.4s 印章/纸飞机动画 → dismiss → TabBar 切回"今日"，卡片右下角出现印章

**图片选择：**
- PhotosPicker (PhotosUI) 选相册图
- UIImagePickerController sourceType=.camera 真机时可用
- 模拟器测试主要走 PhotosPicker

### 6.3 地图流（MapView）

**布局：**
- 顶部：导航栏 + 筛选按钮（按任务类型 / 按心情 / 按时间）
- 中央：Apple Map（standard 配置，无交通无 3D）
- 钉子：Post 图片缩略图，圆形遮罩（直径 40-56pt 根据该位置 Post 数量），白边 2pt
- 当前定位：蓝色圆点 + 柔光圈（半径 100m 显示模糊精度）
- 底部 sheet：选中的钉子 → mini preview card（图 + 标题 + 作者 + 位置）

**视觉：**
- 默认聚焦当前定位 + 1.5km 范围
- 拖动地图时钉子有"漂浮"动画（offset 随 map camera 抖动 ±2pt）
- 钉子聚集时（同街区多个 Post）合并为带数字的圆形

### 6.4 时间流（FeedView）

**布局：**
- 顶部：标题"附近" + Segmented "全部 | 我的"
- 卡片流（单列）：
  - 元信息行：`14:32 · 愚园路 · ● 好奇`（圆点为心情色）
  - 大图（4:5，圆角 4pt）
  - 标题（思源宋体 22pt）
  - 正文（16pt，2 行预览，点击展开）
  - 任务标签行：`── 任务：今天走一条从没走过的路回家 ──`（细线下划线）
  - 互动行：`3 条回应 · 留下你的回应`（点击进入详情）

**视觉：**
- 卡片间距 48pt（大留白）
- 卡片之间无背景色区分，仅用空白和细线分隔
- 心情圆点直径 8pt

### 6.5 我的页（MineView）

**布局：**
- 顶部：用户昵称（可点击编辑）+ "连续记录 N 天"数字
- Segmented："我的记录 | 我的回应 | 城市徽章"
- 我的记录：3 列网格（小图 + 标题）
- 我的回应：列表项（被回应的 Post 缩略 + 自己的回应文字）
- 城市徽章：grid 圆形徽章（连续 7/30/100 天、5 种任务类型全完成等）

**克制设计：**
- 没有粉丝数
- 没有点赞总数
- 没有自我介绍栏
- 没有 cover photo

### 6.6 任务档案馆（ArchiveView）

**布局：**
- 时间线样式，按月份分组
- 每个任务卡：
  - 日期 + 类型标签
  - 任务标题（思源宋体 18pt）
  - 元信息：`@提案人 · 票数 · 已记录 N`
- 点击 → TaskDetailView（看任务的所有历史记录网格）

### 6.7 作品详情页（PostDetailView）

**布局：**
- 大图全屏（顶部）
- 标题 + 全文
- 心情圆点 + 模糊位置 + 时间
- 关联任务（可点击）
- 回应列表（每个 Response 一个 mini 卡片）
- 底部回应输入框（"留下一句回应…"）

### 6.8 空状态、错误状态、离线

**空状态设计**（避免"无数据"的尴尬）：

| 场景 | 显示 |
|---|---|
| 时间流无任何记录 | 一张纸质背景 + "这里还很安静。成为第一个记录的人。" |
| 时间流"我的"无记录 | "你还没有记录过附近。从今日任务开始。" + 跳转按钮 |
| 地图流无钉子（区域空） | 地图正常显示 + 底部 sheet "换个区域看看，或者拖一下地图" |
| Post 无回应 | "还没有人留下回应。"（不带 CTA，避免施压） |
| 档案馆空 | 不应发生（任务库预置 30 条），fallback "任务正在路上" |

**错误状态**：

| 场景 | 处理 |
|---|---|
| 定位权限拒绝 | RecordView 显示"无法获取位置。可在设置中开启。" + 手动输入街区名 fallback |
| 相机权限拒绝 | PhotosPicker 仍可用，Camera 按钮置灰 |
| CLGeocoder 失败 | 走 §4.4 fallback 层级 |
| SwiftData 写入失败 | Toast "保存失败，请重试" + 保留 RecordView 内容 |
| PhotoPicker 取消 | 静默，无错误 |

**离线行为**：
- 本地数据全功能可用
- CLGeocoder 离线时直接走 fallback 层级 2/3，不阻塞发布
- 不显示"网络错误"提示（产品不应让人意识到"网络"这件事）

### 6.9 启动体验（Onboarding / LaunchScreen / AppIcon）

**LaunchScreen**：
- 纯色 paper-50 背景 + 居中"附近"宋体 28pt + 朱砂红小圆点
- 不放 logo，不放进度条，< 1s 消失

**Onboarding（首次启动 3 屏，可跳过）**：
1. "每天一个任务，让你重新看见附近" + 一张氛围图
2. "你可以记录，也可以看看今天大家记录了什么" + 双 tab 示意
3. "我们不会保存你的精确位置，街区级是最大的颗粒度" + 隐私图标

第 3 屏结束按钮："开始" → 进入 TodayView。

权限 priming：在第 3 屏之后、RecordView 首次进入时才真正请求定位权限（场景化请求，不冷启动请求）。

**AppIcon**：
- 单一 1024×1024 App Icon
- 视觉：paper-50 背景 + 朱砂红"近"字（宋体），或一个抽象的"圆点 + 同心圆涟漪"图形
- 不做图标字体过小的复杂插画

### 6.10 任务详情页（TaskDetailView）

**布局**：
- 顶部：任务标题 + 类型 + 提案人 + 票数 + 采纳日期 + 参考图
- 引导文案
- 历史记录网格（3 列）：所有用了此 taskRef 的 Post 缩略图，按时间倒序
- 点击网格项 → PostDetailView

---

## 七、视觉系统

### 7.1 色彩
```
背景层
  paper-50    #FAF6EE   主背景
  paper-100   #F2ECDD   卡片底
  paper-200   #E8DFC9   分割线/边框

文字层
  ink-900     #2A2520   主文字
  ink-700     #4A413A   次文字
  ink-500     #847A6F   辅助
  ink-300     #B5A99B   占位

心情色（柔和低饱和）
  宁静 serene       #B5C4B1   灰绿
  好奇 curious      #C4B58A   暖芥末
  惆怅 melancholy   #8C9CB5   雾蓝
  温柔 tender       #D4B5B5   灰粉
  惊喜 surprise     #D4B58A   暖橘

强调色
  cinnabar    #B5563F   朱砂红
```

### 7.2 字体
| 用途 | 中文 | 英文 | 字号 |
|---|---|---|---|
| 大标题 | 思源宋体 Heavy | New York Semibold | 28-32 |
| 任务标题 | 思源宋体 Bold | New York Medium | 22-24 |
| 正文 | PingFang SC | SF Pro Text | 16-17 |
| 辅助 | PingFang SC Light | SF Pro Caption | 13-14 |

注：iOS 没有内置思源宋体，使用 CTFont + PostScript name `SongtiSC-Black` / `SongtiSC-Bold`（系统内置宋体）。

### 7.3 间距（4pt grid）
```
xs: 4pt   s: 8pt   m: 16pt   l: 24pt   xl: 32pt   xxl: 48pt
```

### 7.4 圆角
- card: 12pt
- button: 8pt
- image: 4pt
- pill: 999pt

### 7.5 质感
- 所有页面背景叠加 5% opacity 纸张噪声纹理（asset）
- 卡片阴影：`0 4 16 rgba(42,37,32,0.06)`，不用毛玻璃
- 分割线：0.5pt + ink-300
- 图片可选叠加 5% 暖色调（按滤镜）

### 7.6 六种纸质感滤镜（Core Image）

| 名称 | 效果 | CIFilter 串联 |
|---|---|---|
| 原图 | 无处理 | — |
| 纸 | 降饱和 + 暖偏色 + 提亮阴影 | CIColorControls(saturation:0.7, brightness:0.05) → CIColorMatrix(暖偏色 vector) |
| 墨 | 黑白 + 高对比 + 暗角 | CIPhotoEffectMono → CIVignette(intensity:0.8) |
| 晨 | 提亮 + 蓝偏色 | CIColorControls(brightness:0.08) → CIColorMatrix(蓝偏 vector) |
| 暮 | 降亮 + 红橙偏色 | CIColorControls(brightness:-0.05, saturation:0.9) → CIColorMatrix(暖偏 vector) |
| 雾 | 雾化 + 降对比 + 白叠 | CIColorControls(contrast:0.85, saturation:0.85) → CIMinimumComponent → 半透明白叠 |

> 雾 filter 不用 CIGaussianBlur（radius 单位是图像像素，对大图无效），改用对比度+饱和度+白叠层模拟雾化。最终参数实施时再微调。

滤镜在发布时烘焙到 JPEG 保存。所有 CIFilter 串行链 ≤ 3 个，原图先 resize 长边 ≤ 2400px 再处理。

---

## 八、Mock 社交内容策略

### 8.1 设计原则
让模拟器跑起来时看起来"有人"，但不真实连接后端。

### 8.2 Mock 用户表（mock_users.json）
20-30 个虚构昵称，符合中文气质：小路、林、阿黎、青、雨舟、晨曦、续冬、墨白、雁、知秋、阿莞、子衿、浅溪、北窗、绾、清和、向晚、未央、临川、阑珊、廿一、芷、棋、九安、温故、闻溪、榆、檀、禾、沐

### 8.3 Mock 内容（MockSeeder）

首次启动时种入 30-50 条 mock Post：
- 每条对应一个真实任务（taskRef）
- 散布在上海 5-10 个街区（愚园路、巨鹿路、武康路、安福路、永康路、田子坊、思南路、复兴中路、衡山路、新华路）
- 时间分布：过去 30 天，每日 1-3 条
- 图片来自 `MockImages/` 资源目录（预置 15-20 张生活气息街景）
- moodTag 均匀分布在 5 种心情
- 标题/文字预写好 30+ 段诗意短句模板

**今日的 mock 内容**：把今天的 taskRef 对应的 5-8 条 mock Post 时间戳设到今天，营造"今天大家都在做这件事"的氛围。

### 8.4 Mock 回应
每条 mock Post 30% 概率有 1-3 条 mock Response，从预置短句模板池里抽。

### 8.5 文字模板池（示例）
- "今天也走这条路上班。看着银杏叶一天比一天黄。"
- "楼下早餐店的爷爷今天给我多塞了一个包子。"
- "雨后的法桐格外亮。"
- "这条路我走了十年，第一次发现这家小店。"
- "突然觉得，'附近'不是一个地方，是一种心情。"

---

## 九、任务库设计（tasks.json）

### 9.1 任务数量
30 条，覆盖 1 个月（足够 demo 周期）。

### 9.2 任务类型分布
- 发现类：8 条
- 细节类：8 条
- 连接类：5 条
- 记忆类：5 条
- 共同类：4 条

### 9.3 任务样例

```json
{
  "id": "discover_new_path_2026",
  "type": "discover",
  "title": {
    "zh": "今天走一条从没走过的路回家",
    "en": "Take a path you've never taken home"
  },
  "prompt": {
    "zh": "打破日常路径，让熟悉的回家的路，长出一点新的部分。",
    "en": "Break your daily route. Let the familiar way home grow something new."
  },
  "proposedBy": "@小路",
  "proposedOn": "2026-05-12",
  "voteCount": 2341,
  "adoptedOn": "2026-05-20",
  "referenceImageName": "task_ref_discover_path",
  "cityTags": ["上海", "通用"]
}
```

### 9.4 任务库草稿（30 条标题）

发现类（8）：
1. 今天走一条从没走过的路回家
2. 找一家从没进过的小店，进去逛一圈
3. 在你最熟悉的路口，往一个新方向拐
4. 沿着一条河走一段
5. 走过一座桥，看看桥下的世界
6. 找一个能看见天空的角度（不开天窗的那种）
7. 走到附近的最高点，俯瞰一下你的附近
8. 跟着一只猫或一只鸟走一段

细节类（8）：
9. 拍下一个让你停下来的颜色
10. 找一处被青苔覆盖的地方
11. 拍下一个被忽略的角落
12. 记录一个一直在那里但没注意过的标志牌
13. 找一种让你想起童年的声音
14. 拍一张光影的形状
15. 记录你今天路过的三种纹理
16. 找一处被时间磨亮的地方

连接类（5）：
17. 和你常去的那家店的老板说句话
18. 给一个陌生人一个微笑
19. 在公共留言板或墙上留下一个善意
20. 问问身边最年长的人，这里以前是什么样
21. 把今天遇到的陌生人记下来（一句话就够）

记忆类（5）：
22. 拍一个你觉得可能很快就不在了的地方
23. 记录一个老物件的现在
24. 找一家开了很多年的小店
25. 拍下你家附近最老的一棵树
26. 记录一栋即将消失的建筑的影子

共同类（4）：
27. 黄昏时分，抬头拍一张天空
28. 早上 8 点，记录你看见的第一个人
29. 雨天里，拍一个被淋湿的世界
30. 夜里 11 点，拍一盏还亮着的灯

---

## 十、本地化

### 10.1 String Catalog
- 文件：`Localization/Localizable.xcstrings`
- 语言：`zh-Hans`（简中，主）+ `en`（英文）
- App 名称：附近 / Nearby

### 10.2 任务文案
任务库 `tasks.json` 用 `{zh, en}` 字典存双语，运行时按当前 locale 取。

### 10.3 系统文案样例
| Key | zh-Hans | en |
|---|---|---|
| `tab.today` | 今日 | Today |
| `tab.map` | 地图 | Map |
| `tab.feed` | 时间流 | Feed |
| `tab.mine` | 我的 | Mine |
| `record.cta` | 开始记录 | Start Recording |
| `record.title.placeholder` | 起个名字… | Title (optional)… |
| `record.text.placeholder` | 记一段…，至少一句 | Write a few words… |
| `record.submit` | 发布 | Publish |
| `record.text.too_short` | 再多写一句吧 | A few more words… |
| `today.completed` | 今日已完成 | Done today |
| `feed.filter.all` | 全部 | All |
| `feed.filter.mine` | 我的 | Mine |
| `archive.title` | 任务档案馆 | Task Archive |
| `response.placeholder` | 留下一句回应… | Leave a response… |

---

## 十一、测试与验证

### 11.1 验证范围（MVP 阶段）
| 范围 | 工具 |
|---|---|
| 编译 | xcodebuild -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' |
| 单元测试 | XCTest：TaskDistributor、LocationFuzzer、ImageFilter |
| 手动测试 | 模拟器走通完整闭环 |

### 11.2 关键测试用例
1. 今日任务 deterministic 派发：同一天多次启动 App，看到的任务一致
2. 模糊定位：精确定位经纬度 → fuzzify 后保留 3 位小数，label 反查正确
3. 滤镜：原图 + 5 种滤镜都能正确生成 JPEG
4. 完整闭环：今日任务 → 拍照/选图 → 滤镜 → 标题 → 文字 → 心情 → 位置 → 发布 → 时间流可见 → 地图流可见 → 留回应 → 我的页可见
5. 本地化：切到英文，所有 UI 文字（含任务标题/引导文案）切换
6. Mock 内容：首次启动有 30+ 条 mock 内容散布在地图和时间流

### 11.3 已知不验证
- Widget / Live Activity（未实现）
- CloudKit 同步（未实现）
- 真实多人互动（无后端）

---

## 十二、项目里程碑

按比赛准备时间倒序：

| 阶段 | 内容 | 估时 |
|---|---|---|
| M1: 骨架 | Xcode 项目 + 4 Tab + 导航 + Design System 落地 | 1 天 |
| M2: 数据层 | SwiftData models + tasks.json + MockSeeder + TaskDistributor | 0.5 天 |
| M3: 今日 + 记录 | TodayView + RecordView（含滤镜、心情、定位）完整闭环 | 1.5 天 |
| M4: 地图流 | MapView + 照片钉子 + mini preview | 1 天 |
| M5: 时间流 + 详情 + 回应 | FeedView + PostDetailView + ResponseComposer | 1 天 |
| M6: 我的 + 档案馆 | MineView + ArchiveView + BadgeGrid | 0.5 天 |
| M7: 打磨 | 动画、纸质感、字体微调、英文翻译审稿 | 1 天 |
| M8: 演练 | 模拟器 demo 走查 + bug fix | 0.5 天 |

总计：~7 天工作量（含审稿与调试 buffer）。

---

## 十三、风险与对策

| 风险 | 概率 | 对策 |
|---|---|---|
| 模拟器无定位 | 高 | fallback 到上海愚园路坐标 |
| PhotosPicker 模拟器行为差异 | 中 | 提前在模拟器相册预置图片 |
| Core Image 滤镜性能 | 中 | 限制原图大小 ≤ 2400px，串行 filter 链 ≤ 3 个 |
| 中英双语翻译质量 | 中 | 任务文案由人审稿，不用机翻 |
| SwiftData 模拟器迁移问题 | 低 | 不做 schema migration，开发期 reset container |
| 比赛现场设备无 iPhone 17 Pro 模拟器 | 低 | 至少在 iPhone 16/15 各测一遍 |

---

## 十四、验收标准

App 完成标准（Acceptance Criteria）：

**编译与启动**
1. ✅ `xcodebuild -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` 编译成功，0 warning（dependencies warning 不计）
2. ✅ iPhone 17 Pro 模拟器（iOS 18+）冷启动 < 2s 到 TodayView 渲染完成
3. ✅ iPhone 16 / iPhone 15 各跑一遍，无 layout 崩溃

**4 Tab 与导航**
4. ✅ 4 个 Tab 全部可访问，切换无闪烁、无内存泄漏（Xcode Memory Graph 5 分钟内 stable）
5. ✅ Onboarding 首次启动显示，跳过后不再显示
6. ✅ LaunchScreen 在 < 1s 内消失

**今日任务**
7. ✅ TodayView 显示 1 个任务，含：类型、标题、引导文案、提案人、票数、参考图
8. ✅ 同一天多次启动 App，任务一致
9. ✅ 完成记录后任务卡右下角出现"今日已完成"印章

**记录闭环**
10. ✅ PhotosPicker 选图 → 滤镜 → 标题 → 文字 → 心情 → 位置 → 发布 全流程可走通
11. ✅ 文字 < 6 字时"发布"按钮禁用 + 提示"再多写一句吧"
12. ✅ 发布后 Post 出现在时间流"我的"、地图流钉子、我的页网格

**地图流**
13. ✅ 默认聚焦当前定位 + 1.5km 范围（无定位时 fallback 上海愚园路）
14. ✅ 钉子为 Post 缩略图圆形，点击 → mini preview → 详情
15. ✅ 同网格 > 3 个 Post 时合并为带数字钉子

**时间流与回应**
16. ✅ 时间流单列大图，间距 48pt，纸质感背景
17. ✅ 在他人 Post 下留文字回应（≥ 1 字），详情页可立即看到
18. ✅ Segmented "全部 / 我的" 切换正确

**我的页**
19. ✅ 显示"连续记录 N 天"（首次启动为 0）
20. ✅ 我的记录网格 3 列正确显示缩略图
21. ✅ 徽章规则正确派生（七日同行 / 五感全开 / 在场 等）

**档案馆**
22. ✅ ArchiveView 显示 30 个任务，按月份分组
23. ✅ 点击任务 → TaskDetailView 显示历史记录网格

**本地化**
24. ✅ 切换系统语言到英文：TabBar、按钮、占位符、任务标题/引导文案、心情标签全部切换
25. ✅ 任务档案馆在英文环境下也显示英文标题

**Mock 内容**
26. ✅ 首次启动后 SwiftData 含 30-50 条 mock Post（覆盖过去 30 天）
27. ✅ 今日的 mock Post 数量 = 5-8 条（营造"今天大家都在做这件事"）
28. ✅ Mock Post 散布在上海 10 个街区，无重复坐标（除非测试 clustering）

**离线/权限**
29. ✅ 飞行模式下 App 全功能可用（CLGeocoder 走 fallback）
30. ✅ 拒绝定位权限后 RecordView 显示手动输入 fallback，不崩溃

---

## 附录 A：参考产品

- **异环（NTE）- 呗果系统**：拍照创作平台，参考其"作品感"和"逛的愉悦"
- **光·遇 - 留言蜡烛**：异步文字留言的仪式感
- **Day One / Stoa**：日记 App 的纸质感与字体
- **Apple Journal**：iOS 原生日记的交互范式
- **Nolte**：克制社交的设计语言

---

## 附录 B：评委可能问题与回答

**Q：每天的任务谁写的？**
A：任务全部来自社区——任何用户都可以提议明天的任务，得票最高的经审核后全员推送。我们不做算法推荐，只做投票共识。

**Q：怎么避免变成下一个朋友圈？？**
A：三个设计选择：弱化关注关系、不能点赞只能回应、按地图/时间浏览而不是按人浏览。这些选择共同把"表演给粉丝看"的动机结构拆掉。

**Q：商业模式？**
A：初期免费，专注社区氛围；中期推实体周边（如城市人文地图、纸质任务手账），与"附近"气质契合；长期与城市文化机构、独立书店合作。不做信息流广告、不做算法推荐电商。

**Q：和朋友圈/小红书的根本差别？**
A：内容驱动模式不同——朋友圈是关系驱动、小红书是消费驱动、附近是任务驱动。我们做的是"重新看见生活"，不是"展示生活"。

**Q：技术亮点？**
A：模糊定位算法保护隐私的同时保留地理意义；地图人文图层是全新产品形态；任务 deterministic 派发实现"全城同步"的仪式感而无需后端。

---

*这份设计稿公开commit到 git 后，将由 spec-document-reviewer 子代理评审，再交给 writing-plans 转化为实施计划。*
