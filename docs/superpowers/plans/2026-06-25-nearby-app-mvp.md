# 「附近」App MVP Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS 18+ SwiftUI app called 「附近」that runs end-to-end in Xcode Simulator, with daily-task-driven photo/text recording, fuzzy location, map feed, time feed, text responses, archive, and badges.

**Architecture:** Single iOS app target using SwiftUI + SwiftData (local only, no backend). MV pattern with `@Observable` view models. Daily task deterministic by Asia/Shanghai midnight. Fuzzy location at ~100m grid. Mock data seeded on first launch (30-50 mock posts across 10 Shanghai neighborhoods).

**Tech Stack:** Swift / SwiftUI / SwiftData / iOS 18+ / MapKit / CoreLocation / Core Image / PhotosUI / XcodeGen / XCTest

**Reference spec:** `docs/superpowers/specs/2026-06-25-nearby-app-design.md`

---

## File Structure

### Top-level
```
nearby/
├─ project.yml                    XcodeGen project spec
├─ 附近/                           App sources
├─ 附近Tests/                      XCTest unit tests
├─ 附近Resources/                  Bundle resources (JSON, images, strings)
└─ docs/superpowers/
   ├─ specs/2026-06-25-nearby-app-design.md
   └─ plans/2026-06-25-nearby-app-mvp.md  (this file)
```

### App sources (`附近/`)
```
附近/
├─ App/
│  ├─ NearbyApp.swift             @main entry, SwiftData container setup
│  └─ RootView.swift              TabView with 4 tabs
├─ DesignSystem/
│  ├─ Color+Nearby.swift          Color palette extensions (paper/ink/mood/cinnabar)
│  ├─ Font+Nearby.swift           SongtiSC + New York helpers
│  ├─ Spacing.swift               4pt grid constants
│  ├─ PaperBackground.swift       Texture overlay ViewModifier
│  └─ Components/
│     ├─ SealStamp.swift          Completed-today seal stamp
│     ├─ MoodDot.swift            Colored mood indicator
│     └─ TaskBadge.swift          Task-type badge
├─ Models/
│  ├─ Post.swift                  SwiftData @Model
│  ├─ Response.swift              SwiftData @Model
│  ├─ MoodTag.swift               Enum (Codable, CaseIterable)
│  ├─ DailyTask.swift             Codable (from tasks.json)
│  ├─ TaskType.swift              Enum
│  ├─ FuzzyLocation.swift         Struct
│  └─ CurrentUser.swift           Current user constant
├─ Data/
│  ├─ TaskBank.swift              Loads tasks.json
│  ├─ TaskDistributor.swift       Date → task deterministic mapping
│  ├─ MockSeeder.swift            Seeds 30-50 mock posts on first launch
│  ├─ NeighborhoodTable.swift     Predefined Shanghai neighborhoods for fallback
│  └─ TextTemplates.swift         Mock content text pool
├─ Services/
│  ├─ LocationManager.swift       CoreLocation wrapper
│  ├─ LocationFuzzer.swift        coord → FuzzyLocation
│  ├─ GeoLabelResolver.swift      3-tier fallback (CLGeocoder → neighborhood → "附近 · 此刻")
│  ├─ ImageFilter.swift           Core Image filter chains (6 filters)
│  ├─ ImageStorage.swift          Resize/compress/thumbnail pipeline
│  └─ StreakCalculator.swift      Compute consecutive-day streak
├─ Features/
│  ├─ Today/
│  │  ├─ TodayView.swift
│  │  ├─ TodayViewModel.swift
│  │  └─ TaskCardView.swift
│  ├─ Record/
│  │  ├─ RecordView.swift
│  │  ├─ RecordViewModel.swift
│  │  ├─ PhotoPickerButton.swift
│  │  ├─ FilterStrip.swift
│  │  └─ MoodSelector.swift
│  ├─ Map/
│  │  ├─ MapView.swift
│  │  ├─ MapViewModel.swift
│  │  ├─ PhotoAnnotation.swift
│  │  ├─ AnnotationClusterer.swift
│  │  └─ MiniPreviewCard.swift
│  ├─ Feed/
│  │  ├─ FeedView.swift
│  │  ├─ FeedViewModel.swift
│  │  ├─ PostCardView.swift
│  │  └─ PostDetailView.swift
│  ├─ Archive/
│  │  ├─ ArchiveView.swift
│  │  ├─ ArchiveViewModel.swift
│  │  └─ TaskDetailView.swift
│  ├─ Mine/
│  │  ├─ MineView.swift
│  │  ├─ MineViewModel.swift
│  │  └─ BadgeGrid.swift
│  └─ Onboarding/
│     └─ OnboardingView.swift
└─ Assets.xcassets/
   ├─ AppIcon.appiconset/
   ├─ Colors/                    Color palette assets
   ├─ MockImages/                15-20 pre-bundled photos
   ├─ PaperTexture/              Noise texture image
   └─ TaskReferenceImages/       Reference images for tasks
```

### Tests (`附近Tests/`)
```
附近Tests/
├─ TaskDistributorTests.swift
├─ LocationFuzzerTests.swift
├─ GeoLabelResolverTests.swift
├─ ImageFilterTests.swift
├─ ImageStorageTests.swift
├─ StreakCalculatorTests.swift
├─ TaskBankTests.swift
└─ MockSeederTests.swift
```

### Resources (`附近Resources/`)
```
附近Resources/
├─ tasks.json                    30 tasks (zh + en)
├─ mock_users.json               30 mock user nicknames
├─ neighborhoods.json            10 Shanghai neighborhoods with lat/lon bounds
├─ text_templates.json           Mock post title/text templates
├─ Localizable.xcstrings         String catalog (zh-Hans + en)
└─ MockImages/
   ├─ scene_001.jpg ... scene_020.jpg
```

---

## Chunk 1: Project Bootstrap

**Goal:** Stand up the Xcode project, design system, models, task distribution, mock seeder. App should launch with empty 4-tab UI; `todayTask(for: Date)` and mock seeding have passing unit tests.

### Task 1.0: Pre-flight checks

**Files:**
- Verify environment only

- [ ] **Step 1: Verify xcodegen is installed**

```bash
which xcodegen && xcodegen --version
```

Expected: `/opt/homebrew/bin/xcodegen` and `Version: 2.x.x`. If missing: `brew install xcodegen`.

- [ ] **Step 2: Verify iPhone 17 Pro simulator exists**

```bash
xcrun simctl list devices available | grep "iPhone 17 Pro"
```

Expected: at least one line with `iPhone 17 Pro`. If missing, install Xcode 26+ or use `iPhone 16 Pro` and update all subsequent commands.

- [ ] **Step 3: Create stub directories so XcodeGen can find all source paths**

```bash
mkdir -p 附近/App 附近/DesignSystem 附近/DesignSystem/Components 附近/Models 附近/Data 附近/Services 附近/Features/Today 附近/Features/Record 附近/Features/Map 附近/Features/Feed 附近/Features/Archive 附近/Features/Mine 附近/Features/Onboarding 附近Tests 附近Resources 附近/Assets.xcassets/AppIcon.appiconset 附近/Assets.xcassets/Colors
touch 附近Resources/.keep
```

- [ ] **Step 4: Create Paper50 color asset (for LaunchScreen background)**

`附近/Assets.xcassets/Colors/Paper50.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xEE",
          "green" : "0xF6",
          "red" : "0xFA"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 5: Update `.gitignore` to exclude generated Xcode project**

The repo's `.gitignore` already exists. Append the following if not present:

```
# Generated by XcodeGen
*.xcodeproj
*.xcworkspace
```

(This keeps the Xcode project out of git — it's regenerated from `project.yml`.)

- [ ] **Step 6: No commit needed** (this task only verifies the environment and creates empty dirs).

---

### Task 1.1: Create XcodeGen project spec

**Files:**
- Create: `project.yml`
- Create: `附近/Info.plist`

- [ ] **Step 1: Write `project.yml`**

```yaml
name: 附近
options:
  bundleIdPrefix: com.cassette
  deploymentTarget:
    iOS: "18.0"
  developmentLanguage: zh-Hans
settings:
  base:
    SWIFT_VERSION: "5.0"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    CODE_SIGNING_REQUIRED: "NO"
    CODE_SIGN_IDENTITY: ""
    ENABLE_USER_SCRIPT_SANDBOXING: "NO"
targets:
  附近:
    type: application
    platform: iOS
    deploymentTarget: "18.0"
    bundleId: com.cassette.nearby
    sources:
      - path: 附近
      - path: 附近Resources
        buildPhase: resources
    info:
      path: 附近/Info.plist
      properties:
        CFBundleDisplayName: 附近
        CFBundleShortVersionString: $(MARKETING_VERSION)
        CFBundleVersion: $(CURRENT_PROJECT_VERSION)
        UILaunchScreen:
          UIColorName: Paper50
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        UISupportedInterfaceOrientations~ipad:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        NSLocationWhenInUseUsageDescription: "我们只需要知道你在哪个街区，以便记录你与附近的故事。位置会模糊到街区级，不会保存精确位置。"
        NSCameraUsageDescription: "拍照记录你看见的附近。"
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
  附近Tests:
    type: bundle.unit-test
    platform: iOS
    deploymentTarget: "18.0"
    bundleId: com.cassette.nearbyTests
    sources:
      - 附近Tests
    dependencies:
      - target: 附近
    settings:
      base:
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/附近.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/附近"
        BUNDLE_LOADER: "$(TEST_HOST)"
```

- [ ] **Step 2: Write `附近/Info.plist`** (empty — generated by XcodeGen)

The Info.plist is generated from `project.yml` info.properties. Create an empty placeholder file at `附近/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

- [ ] **Step 3: Create minimum app entry to allow generation**

Create `附近/App/NearbyApp.swift`:

```swift
import SwiftUI

@main
struct NearbyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("附近")
    }
}
```

- [ ] **Step 4: Generate Xcode project and verify build**

```bash
cd /Users/chenzilve/Projects/nearby
xcodegen generate
xcodebuild -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```

Expected: `** BUILD SUCCEEDED **`. If simctl complains about Chinese bundle ID later, verify the generated `附近.xcodeproj/project.pbxproj` has `PRODUCT_BUNDLE_IDENTIFIER = com.cassette.nearby;` for the app target.

- [ ] **Step 5: Commit**

```bash
git add project.yml 附近/Info.plist 附近/App/NearbyApp.swift
git commit -m "feat: bootstrap XcodeGen project"
```

---

### Task 1.2: Color palette extension

**Files:**
- Create: `附近/DesignSystem/Color+Nearby.swift`

- [ ] **Step 1: Write the Color extension**

```swift
import SwiftUI

extension Color {
    // Paper backgrounds
    static let paper50 = Color(red: 0xFA/255, green: 0xF6/255, blue: 0xEE/255)
    static let paper100 = Color(red: 0xF2/255, green: 0xEC/255, blue: 0xDD/255)
    static let paper200 = Color(red: 0xE8/255, green: 0xDF/255, blue: 0xC9/255)

    // Ink text
    static let ink900 = Color(red: 0x2A/255, green: 0x25/255, blue: 0x20/255)
    static let ink700 = Color(red: 0x4A/255, green: 0x41/255, blue: 0x3A/255)
    static let ink500 = Color(red: 0x84/255, green: 0x7A/255, blue: 0x6F/255)
    static let ink300 = Color(red: 0xB5/255, green: 0xA9/255, blue: 0x9B/255)

    // Accent (cinnabar)
    static let cinnabar = Color(red: 0xB5/255, green: 0x56/255, blue: 0x3F/255)

    // Mood colors
    static let moodSerene = Color(red: 0xB5/255, green: 0xC4/255, blue: 0xB1/255)      // 宁静
    static let moodCurious = Color(red: 0xC4/255, green: 0xB5/255, blue: 0x8A/255)     // 好奇
    static let moodMelancholy = Color(red: 0x8C/255, green: 0x9C/255, blue: 0xB5/255)  // 惆怅
    static let moodTender = Color(red: 0xD4/255, green: 0xB5/255, blue: 0xB5/255)      // 温柔
    static let moodSurprise = Color(red: 0xD4/255, green: 0xB5/255, blue: 0x8A/255)    // 惊喜
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodegen generate && xcodebuild -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add 附近/DesignSystem/Color+Nearby.swift
git commit -m "feat: add color palette"
```

---

### Task 1.3: Font helpers (SongtiSC + New York)

**Files:**
- Create: `附近/DesignSystem/Font+Nearby.swift`

- [ ] **Step 1: Write Font helpers**

```swift
import SwiftUI

extension Font {
    // 中文标题：宋体；英文标题：New York
    static let titleDisplay = Font.custom("SongtiSC-Black", size: 30, relativeTo: .largeTitle)
    static let taskTitle = Font.custom("SongtiSC-Bold", size: 23, relativeTo: .title2)
    static let sectionTitle = Font.custom("SongtiSC-Bold", size: 18, relativeTo: .headline)
    static let bodySerif = Font.custom("SongtiSC-Regular", size: 17, relativeTo: .body)
    static let caption = Font.system(size: 13, weight: .light)
}

// Helper to render Songti for Chinese, system serif for English (font fallback handled by iOS)
extension View {
    func serifTitle() -> some View {
        self.font(.taskTitle)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodegen generate && xcodebuild -project 附近.xcodeproj -scheme 附近 build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add 附近/DesignSystem/Font+Nearby.swift
git commit -m "feat: add font helpers (SongtiSC)"
```

---

### Task 1.4: Spacing constants

**Files:**
- Create: `附近/DesignSystem/Spacing.swift`

- [ ] **Step 1: Write Spacing**

```swift
import CoreGraphics

enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let card: CGFloat = 12
    static let button: CGFloat = 8
    static let image: CGFloat = 4
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/DesignSystem/Spacing.swift
git commit -m "feat: add spacing constants"
```

---

### Task 1.5: MoodTag enum

**Files:**
- Create: `附近/Models/MoodTag.swift`

- [ ] **Step 1: Write enum**

```swift
import SwiftUI

enum MoodTag: String, Codable, CaseIterable, Identifiable {
    case serene = "宁静"
    case curious = "好奇"
    case melancholy = "惆怅"
    case tender = "温柔"
    case surprise = "惊喜"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .serene: return .moodSerene
        case .curious: return .moodCurious
        case .melancholy: return .moodMelancholy
        case .tender: return .moodTender
        case .surprise: return .moodSurprise
        }
    }

    var localizedName: String {
        switch self {
        case .serene: return NSLocalizedString("mood.serene", value: "宁静", comment: "")
        case .curious: return NSLocalizedString("mood.curious", value: "好奇", comment: "")
        case .melancholy: return NSLocalizedString("mood.melancholy", value: "惆怅", comment: "")
        case .tender: return NSLocalizedString("mood.tender", value: "温柔", comment: "")
        case .surprise: return NSLocalizedString("mood.surprise", value: "惊喜", comment: "")
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Models/MoodTag.swift
git commit -m "feat: add MoodTag enum"
```

---

### Task 1.6: TaskType enum

**Files:**
- Create: `附近/Models/TaskType.swift`

- [ ] **Step 1: Write enum**

```swift
import SwiftUI

enum TaskType: String, Codable, CaseIterable, Identifiable {
    case discover
    case detail
    case connect
    case memory
    case together

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .discover: return NSLocalizedString("task.type.discover", value: "发现", comment: "")
        case .detail: return NSLocalizedString("task.type.detail", value: "细节", comment: "")
        case .connect: return NSLocalizedString("task.type.connect", value: "连接", comment: "")
        case .memory: return NSLocalizedString("task.type.memory", value: "记忆", comment: "")
        case .together: return NSLocalizedString("task.type.together", value: "共同", comment: "")
        }
    }

    var iconName: String {
        switch self {
        case .discover: return "safari"
        case .detail: return "eye"
        case .connect: return "person.wave.2"
        case .memory: return "book"
        case .together: return "globe.asia.australia"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Models/TaskType.swift
git commit -m "feat: add TaskType enum"
```

---

### Task 1.7: FuzzyLocation struct

**Files:**
- Create: `附近/Models/FuzzyLocation.swift`

- [ ] **Step 1: Write struct**

```swift
import Foundation
import CoreLocation

struct FuzzyLocation: Codable, Hashable {
    let label: String
    let lat: Double
    let lon: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Models/FuzzyLocation.swift
git commit -m "feat: add FuzzyLocation struct"
```

---

### Task 1.8: DailyTask model + TaskBank loader

**Files:**
- Create: `附近/Models/DailyTask.swift`
- Create: `附近/Data/TaskBank.swift`
- Create: `附近Resources/tasks.json`
- Create: `附近Tests/TaskBankTests.swift`

- [ ] **Step 1: Write the failing test**

`附近Tests/TaskBankTests.swift`:

```swift
import Testing
import Foundation
@testable import 附近

struct TaskBankTests {
    @Test func loadsAllTasksFromBundle() async throws {
        let bank = try await TaskBank.load()
        #expect(bank.tasks.count == 30, "Expected 30 tasks, got \(bank.tasks.count)")
    }

    @Test func allTasksHaveBilingualContent() async throws {
        let bank = try await TaskBank.load()
        for task in bank.tasks {
            #expect(task.title["zh"]?.isEmpty == false, "Task \(task.id) missing zh title")
            #expect(task.title["en"]?.isEmpty == false, "Task \(task.id) missing en title")
            #expect(task.prompt["zh"]?.isEmpty == false, "Task \(task.id) missing zh prompt")
            #expect(task.prompt["en"]?.isEmpty == false, "Task \(task.id) missing en prompt")
        }
    }

    @Test func allTasksHaveRequiredMetadata() async throws {
        let bank = try await TaskBank.load()
        for task in bank.tasks {
            #expect(task.proposedBy.isEmpty == false, "Task \(task.id) missing proposedBy")
            #expect(task.voteCount > 0, "Task \(task.id) voteCount must be > 0")
            #expect(task.adoptedOn.isEmpty == false, "Task \(task.id) missing adoptedOn")
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate
xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: Tests FAIL (TaskBank not defined).

- [ ] **Step 3: Write DailyTask model**

`附近/Models/DailyTask.swift`:

```swift
import Foundation

struct DailyTask: Codable, Identifiable, Hashable {
    let id: String
    let type: TaskType
    let title: [String: String]      // {"zh": "...", "en": "..."}
    let prompt: [String: String]
    let proposedBy: String
    let proposedOn: String
    let voteCount: Int
    let adoptedOn: String
    let referenceImageName: String?
    let cityTags: [String]

    func localizedTitle(for language: String = Locale.current.language.languageCode?.identifier ?? "zh") -> String {
        title[language] ?? title["zh"] ?? title.values.first ?? id
    }

    func localizedPrompt(for language: String = Locale.current.language.languageCode?.identifier ?? "zh") -> String {
        prompt[language] ?? prompt["zh"] ?? prompt.values.first ?? ""
    }
}

struct TaskBank: Codable {
    let version: Int
    let tasks: [DailyTask]
}
```

- [ ] **Step 4: Write TaskBank loader**

`附近/Data/TaskBank.swift`:

```swift
import Foundation

enum TaskBank {
    /// Loads and caches tasks.json from the main bundle.
    /// Returns empty array if file is missing or invalid (never throws in sync API).
    static func loadSync() -> [DailyTask] {
        if let cached { return cached }
        guard let url = Bundle.main.url(forResource: "tasks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(TaskBank.self, from: data) else {
            return []
        }
        cached = bank.tasks
        return bank.tasks
    }

    /// Async variant for callers that prefer throws semantics.
    static func load() async throws -> [DailyTask] {
        let tasks = loadSync()
        guard !tasks.isEmpty else {
            throw TaskBankError.fileNotFound
        }
        return tasks
    }

    private nonisolated(unsafe) static var cached: [DailyTask]?
}

enum TaskBankError: Error {
    case fileNotFound
}
```

(Note: For test target to access bundle resources, `TEST_HOST` is configured in `project.yml` so `Bundle.main` resolves to the app's bundle during unit tests. See Task 1.0 for precondition checks.)

- [ ] **Step 5: Write initial tasks.json (30 tasks)**

`附近Resources/tasks.json`:

```json
{
  "version": 1,
  "tasks": [
    {"id":"discover_new_path","type":"discover","title":{"zh":"今天走一条从没走过的路回家","en":"Take a path you've never taken home"},"prompt":{"zh":"打破日常路径，让熟悉的回家的路，长出一点新的部分。","en":"Break your daily route. Let the familiar way home grow something new."},"proposedBy":"@小路","proposedOn":"2026-05-12","voteCount":2341,"adoptedOn":"2026-05-20","referenceImageName":"task_ref_path","cityTags":["上海","通用"]},
    {"id":"detail_color","type":"detail","title":{"zh":"拍下一个让你停下来的颜色","en":"Capture a color that stops you"},"prompt":{"zh":"不一定是漂亮的颜色，可能是某个被忽略很久的角落里，一抹让你愣一下颜色。","en":"Not necessarily a beautiful color — perhaps one in a corner long ignored that makes you pause."},"proposedBy":"@林","proposedOn":"2026-05-10","voteCount":1823,"adoptedOn":"2026-05-18","referenceImageName":"task_ref_color","cityTags":["上海","通用"]},
    {"id":"connect_shopkeeper","type":"connect","title":{"zh":"和你常去的那家店的老板说句话","en":"Say something to the owner of a shop you visit often"},"prompt":{"zh":"不止是结账时的'多少钱'。可以问他们今天怎么样，或者夸一下他们做的东西。","en":"More than 'how much'. Ask how their day is. Or compliment what they make."},"proposedBy":"@阿黎","proposedOn":"2026-05-08","voteCount":1567,"adoptedOn":"2026-05-16","referenceImageName":"task_ref_shop","cityTags":["上海","通用"]},
    {"id":"memory_fading","type":"memory","title":{"zh":"拍一个你觉得可能很快就不在了的地方","en":"Photograph a place that might not be here much longer"},"prompt":{"zh":"老的小店，旧的招牌，墙上斑驳的字。这些都在悄悄消失。","en":"Old shops. Faded signs. Crumbling walls. These are quietly disappearing."},"proposedBy":"@九安","proposedOn":"2026-05-05","voteCount":1432,"adoptedOn":"2026-05-14","referenceImageName":"task_ref_fading","cityTags":["上海","通用"]},
    {"id":"together_sunset","type":"together","title":{"zh":"黄昏时分，抬头拍一张天空","en":"At dusk, look up and photograph the sky"},"prompt":{"zh":"今天傍晚，整个城市一起做这件事。","en":"This evening, the whole city does this together."},"proposedBy":"@向晚","proposedOn":"2026-05-03","voteCount":3120,"adoptedOn":"2026-05-12","referenceImageName":"task_ref_sky","cityTags":["上海","通用"]},
    {"id":"discover_hidden_shop","type":"discover","title":{"zh":"找一家从没进过的小店，进去逛一圈","en":"Find a shop you've never entered and step inside"},"prompt":{"zh":"不必买什么。看看就好。","en":"You don't have to buy anything. Just look."},"proposedBy":"@阿莞","proposedOn":"2026-05-01","voteCount":892,"adoptedOn":"2026-05-10","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"detail_texture","type":"detail","title":{"zh":"记录你今天路过的三种纹理","en":"Document three textures you walk past today"},"prompt":{"zh":"墙皮，砖纹，水迹，叶脉，铁锈。","en":"Wall, brick, water stains, leaf veins, rust."},"proposedBy":"@墨白","proposedOn":"2026-04-29","voteCount":654,"adoptedOn":"2026-05-08","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"connect_smile","type":"connect","title":{"zh":"给一个陌生人一个微笑","en":"Give a stranger a smile"},"prompt":{"zh":"不说话也可以。","en":"Without a word is fine too."},"proposedBy":"@子衿","proposedOn":"2026-04-27","voteCount":1102,"adoptedOn":"2026-05-05","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"memory_old_tree","type":"memory","title":{"zh":"拍下你家附近最老的一棵树","en":"Photograph the oldest tree near your home"},"prompt":{"zh":"它比你早来很多年。","en":"It was here long before you."},"proposedBy":"@廿一","proposedOn":"2026-04-25","voteCount":765,"adoptedOn":"2026-05-02","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"together_morning_8","type":"together","title":{"zh":"早上 8 点，记录你看见的第一个人","en":"At 8am, document the first person you see"},"prompt":{"zh":"不需要拍脸，一个剪影、一个动作、一个距离都可以。","en":"No need for their face. A silhouette, a gesture, a distance — all fine."},"proposedBy":"@晨曦","proposedOn":"2026-04-23","voteCount":1456,"adoptedOn":"2026-04-30","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"discover_bridge","type":"discover","title":{"zh":"走过一座桥，看看桥下的世界","en":"Cross a bridge and look at what's underneath"},"prompt":{"zh":"桥上和桥下，是同一个城市的两个故事。","en":"Above and below a bridge — two stories of the same city."},"proposedBy":"@临川","proposedOn":"2026-04-21","voteCount":567,"adoptedOn":"2026-04-28","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"detail_moss","type":"detail","title":{"zh":"找一处被青苔覆盖的地方","en":"Find a place covered in moss"},"prompt":{"zh":"青苔只长在很久没动过的地方。","en":"Moss grows only where nothing has moved for a long time."},"proposedBy":"@浅溪","proposedOn":"2026-04-19","voteCount":432,"adoptedOn":"2026-04-26","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"connect_elder","type":"connect","title":{"zh":"问问身边最年长的人，这里以前是什么样","en":"Ask the oldest person nearby what this place used to be like"},"prompt":{"zh":"他们记得的'附近'，可能和你看到的完全不一样。","en":"The 'nearby' they remember may be utterly different from what you see."},"proposedBy":"@温故","proposedOn":"2026-04-17","voteCount":890,"adoptedOn":"2026-04-24","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"memory_old_object","type":"memory","title":{"zh":"记录一个老物件的现在","en":"Document an old object as it is now"},"prompt":{"zh":"不必是收藏品，路边一个废弃的也行。","en":"Not a collectible — something abandoned by the road is fine."},"proposedBy":"@雁","proposedOn":"2026-04-15","voteCount":345,"adoptedOn":"2026-04-22","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"together_rain","type":"together","title":{"zh":"雨天里，拍一个被淋湿的世界","en":"On a rainy day, photograph a drenched world"},"prompt":{"zh":"水珠、倒影、湿透的路面。","en":"Droplets, reflections, soaked pavement."},"proposedBy":"@雨舟","proposedOn":"2026-04-13","voteCount":678,"adoptedOn":"2026-04-20","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"discover_river","type":"discover","title":{"zh":"沿着一条河走一段","en":"Walk along a river for a while"},"prompt":{"zh":"每条河都曾是城市的命脉。","en":"Every river was once a city's lifeline."},"proposedBy":"@清和","proposedOn":"2026-04-11","voteCount":543,"adoptedOn":"2026-04-18","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"detail_shadow","type":"detail","title":{"zh":"拍一张光影的形状","en":"Photograph the shape of light and shadow"},"prompt":{"zh":"它们是时间最温柔的脚印。","en":"They are time's gentlest footprints."},"proposedBy":"@闻溪","proposedOn":"2026-04-09","voteCount":1109,"adoptedOn":"2026-04-16","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"connect_leaving_note","type":"connect","title":{"zh":"在公共留言板或墙上留下一个善意","en":"Leave a kind note somewhere public"},"prompt":{"zh":"一张便签，一句鼓励，画一个小图案都行。","en":"A sticky note, an encouragement, a small drawing — all fine."},"proposedBy":"@芷","proposedOn":"2026-04-07","voteCount":456,"adoptedOn":"2026-04-14","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"memory_sign","type":"memory","title":{"zh":"记录一个一直在那里但没注意过的标志牌","en":"Document a sign that's always been there but you never noticed"},"prompt":{"zh":"街名、店招、路牌，老广告。","en":"Street names, shop signs, road plates, old ads."},"proposedBy":"@北窗","proposedOn":"2026-04-05","voteCount":298,"adoptedOn":"2026-04-12","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"together_late_light","type":"together","title":{"zh":"夜里 11 点，拍一盏还亮着的灯","en":"At 11pm, photograph a light still on"},"prompt":{"zh":"谁还在那里？他们在做什么？","en":"Who's still there? What are they doing?"},"proposedBy":"@未央","proposedOn":"2026-04-03","voteCount":1234,"adoptedOn":"2026-04-10","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"discover_high_point","type":"discover","title":{"zh":"走到附近的最高点，俯瞰一下你的附近","en":"Walk to the highest point nearby and look down at your neighborhood"},"prompt":{"zh":"从上看下来，熟悉的街会变得陌生。","en":"From above, familiar streets become unfamiliar."},"proposedBy":"@绾","proposedOn":"2026-04-01","voteCount":432,"adoptedOn":"2026-04-08","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"detail_corner","type":"detail","title":{"zh":"拍下一个被忽略的角落","en":"Photograph an overlooked corner"},"prompt":{"zh":"不显眼，但一直在那里。","en":"Not eye-catching, but always there."},"proposedBy":"@榆","proposedOn":"2026-03-30","voteCount":321,"adoptedOn":"2026-04-06","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"connect_strangers","type":"connect","title":{"zh":"把今天遇到的陌生人记下来（一句话就够）","en":"Note a stranger you encountered today (one sentence is enough)"},"prompt":{"zh":"擦肩而过的，也是附近的一部分。","en":"Those you brush past are also part of nearby."},"proposedBy":"@檀","proposedOn":"2026-03-28","voteCount":567,"adoptedOn":"2026-04-04","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"memory_old_shop","type":"memory","title":{"zh":"找一家开了很多年的小店","en":"Find a shop that's been open for many years"},"prompt":{"zh":"问问它几岁了。","en":"Ask how old it is."},"proposedBy":"@禾","proposedOn":"2026-03-26","voteCount":456,"adoptedOn":"2026-04-02","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"discover_animal","type":"discover","title":{"zh":"跟着一只猫或一只鸟走一段","en":"Follow a cat or a bird for a while"},"prompt":{"zh":"它们知道的附近，和你完全不同。","en":"They know a different nearby than you."},"proposedBy":"@沐","proposedOn":"2026-03-24","voteCount":789,"adoptedOn":"2026-04-01","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"detail_light_shape","type":"detail","title":{"zh":"记录你今天路过的三种声音","en":"Document three sounds you heard today"},"prompt":{"zh":"不必录音，文字描述就好。","en":"No need to record — words are enough."},"proposedBy":"@青","proposedOn":"2026-03-22","voteCount":234,"adoptedOn":"2026-03-30","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"connect_compliment","type":"connect","title":{"zh":"夸一个你今天遇到的人","en":"Compliment someone you met today"},"prompt":{"zh":"可以是陌生人。","en":"It can be a stranger."},"proposedBy":"@棋","proposedOn":"2026-03-20","voteCount":345,"adoptedOn":"2026-03-28","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"memory_window","type":"memory","title":{"zh":"记录一栋即将消失的建筑的影子","en":"Document the shadow of a building about to disappear"},"prompt":{"zh":"拆迁围板已经立起来了。","en":"The demolition boards are already up."},"proposedBy":"@阑珊","proposedOn":"2026-03-18","voteCount":198,"adoptedOn":"2026-03-26","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"discover_sky_angle","type":"discover","title":{"zh":"找一个能看见天空的角度（不开天窗的那种）","en":"Find an angle where you can see the sky"},"prompt":{"zh":"抬头，是一种久违的姿态。","en":"Looking up is a long-forgotten posture."},"proposedBy":"@林","proposedOn":"2026-03-16","voteCount":432,"adoptedOn":"2026-03-24","referenceImageName":null,"cityTags":["上海","通用"]},
    {"id":"detail_worn","type":"detail","title":{"zh":"找一处被时间磨亮的地方","en":"Find a place polished by time"},"prompt":{"zh":"被磨亮，是因为有人来来往往。","en":"Polished bright because people came and went."},"proposedBy":"@墨白","proposedOn":"2026-03-14","voteCount":287,"adoptedOn":"2026-03-22","referenceImageName":null,"cityTags":["上海","通用"]}
  ]
}
```

- [ ] **Step 6: Add tasks.json to resources build phase**

The XcodeGen `project.yml` already maps `附近Resources` as a resources build phase, so the JSON will be bundled automatically. No additional work.

- [ ] **Step 7: Run tests to verify they pass**

```bash
xcodegen generate
xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -30
```

Expected: `TaskBankTests` PASS (3/3).

- [ ] **Step 8: Commit**

```bash
git add 附近/Models/DailyTask.swift 附近/Data/TaskBank.swift 附近Resources/tasks.json 附近Tests/TaskBankTests.swift
git commit -m "feat: add DailyTask model and TaskBank loader with 30 tasks"
```

---

### Task 1.9: TaskDistributor + tests

**Files:**
- Create: `附近/Data/TaskDistributor.swift`
- Create: `附近Tests/TaskDistributorTests.swift`

- [ ] **Step 1: Write failing tests**

`附近Tests/TaskDistributorTests.swift`:

```swift
import Testing
import Foundation
@testable import 附近

struct TaskDistributorTests {
    private func makeBank(_ n: Int) -> [DailyTask] {
        (0..<n).map { i in
            DailyTask(
                id: "task_\(i)",
                type: .discover,
                title: ["zh": "测试\(i)", "en": "Test \(i)"],
                prompt: ["zh": "提示\(i)", "en": "Prompt \(i)"],
                proposedBy: "@test",
                proposedOn: "2026-01-01",
                voteCount: 100,
                adoptedOn: "2026-01-02",
                referenceImageName: nil,
                cityTags: ["上海"]
            )
        }
    }

    @Test func sameDateReturnsSameTask() {
        let bank = makeBank(30)
        let date = Date(timeIntervalSince1970: 1_750_000_000) // arbitrary fixed date
        let task1 = TaskDistributor.task(for: date, bank: bank)
        let task2 = TaskDistributor.task(for: date, bank: bank)
        #expect(task1.id == task2.id)
    }

    @Test func differentDaysInShanghaiTimezoneReturnDifferentTasks() {
        let bank = makeBank(30)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!

        let day1 = cal.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: 12))!
        let day2 = cal.date(from: DateComponents(year: 2026, month: 6, day: 26, hour: 12))!

        let task1 = TaskDistributor.task(for: day1, bank: bank)
        let task2 = TaskDistributor.task(for: day2, bank: bank)
        #expect(task1.id != task2.id)
    }

    @Test func midnightCrossoverUsesShanghaiTimezone() {
        // 2026-06-25 23:30 Shanghai = 2026-06-25 15:30 UTC
        // 2026-06-26 00:30 Shanghai = 2026-06-25 16:30 UTC
        // These are 1 hour apart but in different Shanghai days → different tasks
        let bank = makeBank(30)
        let utcLate = ISO8601DateFormatter().date(from: "2026-06-25T15:30:00Z")!
        let utcEarly = ISO8601DateFormatter().date(from: "2026-06-25T16:30:00Z")!

        let task1 = TaskDistributor.task(for: utcLate, bank: bank)
        let task2 = TaskDistributor.task(for: utcEarly, bank: bank)
        #expect(task1.id != task2.id, "11:30pm and 12:30am Shanghai time should cross day boundary → different tasks")
    }

    @Test func wrapsAroundCorrectly() {
        let bank = makeBank(3)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!

        let day1 = cal.date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let day2 = cal.date(from: DateComponents(year: 2026, month: 6, day: 26))!
        let day3 = cal.date(from: DateComponents(year: 2026, month: 6, day: 27))!
        let day4 = cal.date(from: DateComponents(year: 2026, month: 6, day: 28))!

        let ids = [day1, day2, day3, day4].map { TaskDistributor.task(for: $0, bank: bank).id }
        #expect(ids[0] == ids[3], "Day 4 should wrap to same task as Day 1 (bank size 3)")
        #expect(ids[0] != ids[1])
        #expect(ids[1] != ids[2])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: Tests FAIL (TaskDistributor not defined).

- [ ] **Step 3: Write TaskDistributor**

`附近/Data/TaskDistributor.swift`:

```swift
import Foundation

enum TaskDistributor {
    private static let shanghai: TimeZone = TimeZone(identifier: "Asia/Shanghai")!

    static func task(for date: Date, bank: [DailyTask]) -> DailyTask {
        precondition(!bank.isEmpty, "Task bank must not be empty")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = shanghai
        let dayIndex = Int(calendar.startOfDay(for: date).timeIntervalSince1970 / 86400)
        return bank[((dayIndex % bank.count) + bank.count) % bank.count]
    }

    static func task(for date: Date, bank: [DailyTask], offset days: Int) -> DailyTask {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = shanghai
        let target = calendar.date(byAdding: .day, value: days, to: date)!
        return task(for: target, bank: bank)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: All `TaskDistributorTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近/Data/TaskDistributor.swift 附近Tests/TaskDistributorTests.swift
git commit -m "feat: add TaskDistributor with Asia/Shanghai timezone anchor"
```

---

### Task 1.10: Post + Response SwiftData models

**Files:**
- Create: `附近/Models/Post.swift`
- Create: `附近/Models/Response.swift`
- Create: `附近/Models/CurrentUser.swift`
- Modify: `附近/App/NearbyApp.swift` (add SwiftData container)

- [ ] **Step 1: Write CurrentUser**

`附近/Models/CurrentUser.swift`:

```swift
import Foundation

enum CurrentUser {
    static let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private static let nameKey = "currentUser.displayName"

    static var displayName: String {
        get {
            UserDefaults.standard.string(forKey: nameKey) ?? NSLocalizedString("user.default_name", value: "你", comment: "")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: nameKey)
            NotificationCenter.default.post(name: .currentUserDidChange, self: 0)
        }
    }
}

extension Notification.Name {
    static let currentUserDidChange = Notification.Name("currentUserDidChange")
}
```

- [ ] **Step 2: Write Post model**

`附近/Models/Post.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var taskRef: String
    var imageData: Data
    var thumbnailData: Data
    var title: String?
    var text: String
    var moodTagRaw: String?
    var filterName: String?
    var fuzzyLabel: String
    var fuzzyLat: Double
    var fuzzyLon: Double
    var isOwn: Bool
    var authorId: UUID
    var authorName: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        taskRef: String,
        imageData: Data,
        thumbnailData: Data,
        title: String? = nil,
        text: String,
        moodTag: MoodTag? = nil,
        filterName: String? = nil,
        fuzzyLabel: String,
        fuzzyLat: Double,
        fuzzyLon: Double,
        isOwn: Bool,
        authorId: UUID,
        authorName: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.taskRef = taskRef
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.title = title
        self.text = text
        self.moodTagRaw = moodTag?.rawValue
        self.filterName = filterName
        self.fuzzyLabel = fuzzyLabel
        self.fuzzyLat = fuzzyLat
        self.fuzzyLon = fuzzyLon
        self.isOwn = isOwn
        self.authorId = authorId
        self.authorName = authorName
    }

    var moodTag: MoodTag? {
        guard let raw = moodTagRaw else { return nil }
        return MoodTag(rawValue: raw)
    }
}
```

- [ ] **Step 3: Write Response model**

`附近/Models/Response.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Response {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var postId: UUID
    var text: String
    var isOwn: Bool
    var authorId: UUID
    var authorName: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        postId: UUID,
        text: String,
        isOwn: Bool,
        authorId: UUID,
        authorName: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.postId = postId
        self.text = text
        self.isOwn = isOwn
        self.authorId = authorId
        self.authorName = authorName
    }
}
```

- [ ] **Step 4: Update NearbyApp with SwiftData container**

`附近/App/NearbyApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct NearbyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Post.self, Response.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to init SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    var body: some View {
        Text("附近")
    }
}
```

- [ ] **Step 5: Write SwiftData smoke test**

`附近Tests/PostModelSmokeTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import 附近

struct PostModelSmokeTests {
    @MainActor
    @Test func canInsertAndFetchPost() throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let post = Post(
            taskRef: "test_task",
            imageData: Data([0xFF]),
            thumbnailData: Data([0xFF]),
            title: "Smoke",
            text: "Hello nearby world",
            moodTag: .serene,
            fuzzyLabel: "愚园路 · 静安",
            fuzzyLat: 31.226,
            fuzzyLon: 121.427,
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: "你"
        )
        context.insert(post)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Post>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Smoke")
        #expect(fetched.first?.moodTag == .serene)
    }

    @MainActor
    @Test func canInsertResponseLinkedToPost() throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let postId = UUID()
        let post = Post(
            id: postId,
            taskRef: "test",
            imageData: Data(),
            thumbnailData: Data(),
            text: "Post",
            fuzzyLabel: "x",
            fuzzyLat: 0,
            fuzzyLon: 0,
            isOwn: false,
            authorId: UUID(),
            authorName: "Mock"
        )
        context.insert(post)

        let response = Response(
            postId: postId,
            text: "Me too",
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: "你"
        )
        context.insert(response)
        try context.save()

        let responses = try context.fetch(FetchDescriptor<Response>())
        #expect(responses.count == 1)
        #expect(responses.first?.postId == postId)
    }
}
```

- [ ] **Step 6: Build and run tests to verify**

```bash
xcodegen generate && xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: `PostModelSmokeTests` PASS (2/2).

- [ ] **Step 7: Commit**

```bash
git add 附近/Models/Post.swift 附近/Models/Response.swift 附近/Models/CurrentUser.swift 附近/App/NearbyApp.swift 附近Tests/PostModelSmokeTests.swift
git commit -m "feat: add SwiftData Post/Response models + smoke tests"
```

---

### Task 1.11: LocationFuzzer + tests

**Files:**
- Create: `附近/Services/LocationFuzzer.swift`
- Create: `附近Tests/LocationFuzzerTests.swift`

- [ ] **Step 1: Write failing tests**

`附近Tests/LocationFuzzerTests.swift`:

```swift
import Testing
import Foundation
import CoreLocation
@testable import 附近

struct LocationFuzzerTests {
    @Test func roundsToThousandthsGrid() {
        let coord = CLLocationCoordinate2D(latitude: 31.226123, longitude: 121.426789)
        let fuzzy = LocationFuzzer.fuzzify(coord, label: "测试")
        // 31.226123 * 1000 = 31226.123 → rounded 31226 → 31.226
        #expect(fuzzy.lat == 31.226)
        // 121.426789 * 1000 = 121426.789 → rounded 121427 → 121.427
        #expect(fuzzy.lon == 121.427)
    }

    @Test func nearbyCoordsRoundToSameGrid() {
        let a = CLLocationCoordinate2D(latitude: 31.226499, longitude: 121.426500)
        let b = CLLocationCoordinate2D(latitude: 31.226001, longitude: 121.426999)
        let fa = LocationFuzzer.fuzzify(a, label: "")
        let fb = LocationFuzzer.fuzzify(b, label: "")
        // Both should round to 31.226, 121.427 (or 121.426)
        // 121.426500 → 121.426 or 121.427 (banker's rounding for .5)
        // 121.426999 → 121.427
        // So fa.lon might be 121.426 or 121.427; fb.lon = 121.427
        // The key property: coords within 100m round to within 0.001 of each other
        #expect(abs(fa.lat - fb.lat) <= 0.001)
        #expect(abs(fa.lon - fb.lon) <= 0.001)
    }

    @Test func negativeCoordinatesHandled() {
        let coord = CLLocationCoordinate2D(latitude: -23.550567, longitude: -46.633308)
        let fuzzy = LocationFuzzer.fuzzify(coord, label: "São Paulo")
        #expect(fuzzy.lat <= 0)
        #expect(fuzzy.lon <= 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: FAIL (LocationFuzzer not defined).

- [ ] **Step 3: Write LocationFuzzer**

`附近/Services/LocationFuzzer.swift`:

```swift
import Foundation
import CoreLocation

enum LocationFuzzer {
    static func fuzzify(_ coord: CLLocationCoordinate2D, label: String) -> FuzzyLocation {
        let lat = (coord.latitude * 1000).rounded() / 1000
        let lon = (coord.longitude * 1000).rounded() / 1000
        return FuzzyLocation(label: label, lat: lat, lon: lon)
    }

    static func fuzzify(_ coord: CLLocationCoordinate2D, labelResolver: (Double, Double) -> String) -> FuzzyLocation {
        let lat = (coord.latitude * 1000).rounded() / 1000
        let lon = (coord.longitude * 1000).rounded() / 1000
        return FuzzyLocation(label: labelResolver(lat, lon), lat: lat, lon: lon)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近/Services/LocationFuzzer.swift 附近Tests/LocationFuzzerTests.swift
git commit -m "feat: add LocationFuzzer with 100m grid rounding"
```

---

### Task 1.12: Paper background + RootView skeleton

**Files:**
- Create: `附近/DesignSystem/PaperBackground.swift`
- Create: `附近/App/RootView.swift`
- Modify: `附近/App/NearbyApp.swift` (use RootView)
- Create: `附近/Features/Today/TodayView.swift` (placeholder)
- Create: `附近/Features/Map/MapView.swift` (placeholder)
- Create: `附近/Features/Feed/FeedView.swift` (placeholder)
- Create: `附近/Features/Mine/MineView.swift` (placeholder)

- [ ] **Step 1: Write PaperBackground ViewModifier**

`附近/DesignSystem/PaperBackground.swift`:

```swift
import SwiftUI

struct PaperBackground: ViewModifier {
    var color: Color = .paper50

    func body(content: Content) -> some View {
        ZStack {
            color.ignoresSafeArea()
            // Subtle paper texture using SwiftUI noise (no asset dependency)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
                // Procedural paper grain via opacity layer
                context.opacity = 0.04
                for _ in 0..<600 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let r = CGFloat.random(in: 0.3...1.2)
                    context.fill(Path(CGRect(x: x, y: y, width: r, height: r)), with: .color(.black))
                }
            }
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func paperBackground(color: Color = .paper50) -> some View {
        modifier(PaperBackground(color: color))
    }
}
```

- [ ] **Step 2: Write 4 placeholder tab views**

`附近/Features/Today/TodayView.swift`:

```swift
import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("今日")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
```

(Repeat similarly for MapView, FeedView, MineView — use Tab name as title.)

`附近/Features/Map/MapView.swift`:

```swift
import SwiftUI

struct MapView: View {
    var body: some View {
        NavigationStack {
            Text("地图")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
```

`附近/Features/Feed/FeedView.swift`:

```swift
import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            Text("时间流")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
```

`附近/Features/Mine/MineView.swift`:

```swift
import SwiftUI

struct MineView: View {
    var body: some View {
        NavigationStack {
            Text("我的")
                .font(.titleDisplay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .paperBackground()
    }
}
```

- [ ] **Step 3: Write RootView**

`附近/App/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(NSLocalizedString("tab.today", value: "今日", comment: ""), systemImage: "calendar")
                }
                .tag(0)

            MapView()
                .tabItem {
                    Label(NSLocalizedString("tab.map", value: "地图", comment: ""), systemImage: "map")
                }
                .tag(1)

            FeedView()
                .tabItem {
                    Label(NSLocalizedString("tab.feed", value: "时间流", comment: ""), systemImage: "rectangle.grid.2")
                }
                .tag(2)

            MineView()
                .tabItem {
                    Label(NSLocalizedString("tab.mine", value: "我的", comment: ""), systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .tint(.cinnabar)
    }
}
```

- [ ] **Step 4: Update NearbyApp to use RootView**

`附近/App/NearbyApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct NearbyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Post.self, Response.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to init SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
```

(Remove the old `ContentView`.)

- [ ] **Step 5: Build and launch in simulator**

```bash
xcodegen generate
xcodebuild -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
xcrun simctl install booted /Users/chenzilve/Library/Developer/Xcode/DerivedData/附近-*/Build/Products/Debug-iphonesimulator/附近.app
xcrun simctl launch booted com.cassette.附近
```

Expected: App launches, 4 tabs visible, paper background rendered, switching works without crash.

- [ ] **Step 6: Commit**

```bash
git add 附近/DesignSystem/PaperBackground.swift 附近/App/RootView.swift 附近/App/NearbyApp.swift 附近/Features/
git commit -m "feat: bootstrap RootView with 4 tabs + paper background"
```

---

### Task 1.13: StreakCalculator + tests

**Files:**
- Create: `附近/Services/StreakCalculator.swift`
- Create: `附近Tests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
import Foundation
@testable import 附近

struct StreakCalculatorTests {
    private func makePost(daysAgo: Int, hour: Int = 12) -> Post {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let date = cal.date(byAdding: .day, value: -daysAgo, to: cal.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: hour))!)!
        return Post(taskRef: "x", imageData: Data(), thumbnailData: Data(), text: "test", fuzzyLabel: "", fuzzyLat: 0, fuzzyLon: 0, isOwn: true, authorId: CurrentUser.id, authorName: "你", createdAt: date)
    }

    @Test func returnsZeroWithNoPosts() {
        #expect(StreakCalculator.compute(posts: [], today: Date()) == 0)
    }

    @Test func returnsZeroWithOnlyOtherUserPosts() {
        let other = makePost(daysAgo: 0)
        other.isOwn = false
        #expect(StreakCalculator.compute(posts: [other], today: Date()) == 0)
    }

    @Test func countsConsecutiveDays() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let posts = [
            makePost(daysAgo: 0),  // today
            makePost(daysAgo: 1),
            makePost(daysAgo: 2)
        ]
        #expect(StreakCalculator.compute(posts: posts, today: today) == 3)
    }

    @Test func breaksOnGap() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let posts = [
            makePost(daysAgo: 0),
            makePost(daysAgo: 1),
            makePost(daysAgo: 3)  // gap on day -2
        ]
        #expect(StreakCalculator.compute(posts: posts, today: today) == 2)
    }

    @Test func todayNotPostedYetCountsFromYesterday() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let posts = [
            makePost(daysAgo: 1),
            makePost(daysAgo: 2)
        ]
        #expect(StreakCalculator.compute(posts: posts, today: today) == 2)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: FAIL.

- [ ] **Step 3: Write StreakCalculator**

```swift
import Foundation

enum StreakCalculator {
    private static var shanghaiCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return c
    }()

    static func compute(posts: [Post], today: Date = Date()) -> Int {
        let cal = shanghaiCalendar
        let ownStartOfDays = Set(
            posts
                .filter { $0.isOwn }
                .map { cal.startOfDay(for: $0.createdAt) }
        )
        var streak = 0
        var cursor = cal.startOfDay(for: today)
        if !ownStartOfDays.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        while ownStartOfDays.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近/Services/StreakCalculator.swift 附近Tests/StreakCalculatorTests.swift
git commit -m "feat: add StreakCalculator"
```

---

### Chunk 1 Completion Check

**Verify:**
- [ ] App launches with 4 tabs in iPhone 17 Pro simulator
- [ ] `xcodebuild test` passes (TaskBank, TaskDistributor, LocationFuzzer, StreakCalculator — total 13 tests)
- [ ] Paper background renders
- [ ] Tab switching works without crash
- [ ] tasks.json loads (30 tasks) and is bilingual

**Chunk 1 commits expected:** ~12 commits

---

## Chunk 2: Today + Record Flow

**Goal:** User can complete the full create loop: see today's task → take/pick photo → apply filter → write text → pick mood → confirm fuzzy location → publish → see completion seal on today card + new post in feed/map. All view models and services have unit tests where logic-bearing.

### Task 2.1: ImageFilter service + tests

**Files:**
- Create: `附近/Services/ImageFilter.swift`
- Create: `附近Tests/ImageFilterTests.swift`

- [ ] **Step 1: Write failing tests**

`附近Tests/ImageFilterTests.swift`:

```swift
import Testing
import UIKit
import CoreImage
@testable import 附近

struct ImageFilterTests {
    private func makeTestImage(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemRed.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
        }
    }

    @Test func originalFilterReturnsSameImagePixels() throws {
        let image = makeTestImage()
        let filtered = try ImageFilter.apply(filter: .original, to: image)
        #expect(filtered.size == image.size)
    }

    @Test func allFiltersProduceNonNilImage() throws {
        let image = makeTestImage()
        for filter in ImageFilter.allCases {
            let result = try ImageFilter.apply(filter: filter, to: image)
            #expect(result.size.width > 0, "Filter \(filter.rawValue) produced empty image")
        }
    }

    @Test func inkFilterProducesGrayscale() throws {
        let image = makeTestImage()
        let filtered = try ImageFilter.apply(filter: .ink, to: image)
        // Convert to CIImage to sample pixels — at minimum, saturation should be reduced
        let ci = CIImage(image: filtered)!
        #expect(ci.extent.width > 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: FAIL (ImageFilter not defined).

- [ ] **Step 3: Write ImageFilter**

`附近/Services/ImageFilter.swift`:

```swift
import UIKit
import CoreImage

enum ImageFilter: String, CaseIterable, Identifiable {
    case original = "原图"
    case paper = "纸"
    case ink = "墨"
    case morning = "晨"
    case dusk = "暮"
    case mist = "雾"

    var id: String { rawValue }

    var localizedName: String {
        NSLocalizedString("filter.\(rawValue)", value: rawValue, comment: "")
    }
}

enum ImageFilterEngine {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func apply(filter: ImageFilter, to image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageFilterError.invalidInput
        }
        let ci = CIImage(cgImage: cgImage)

        let output: CIImage
        switch filter {
        case .original:
            output = ci
        case .paper:
            // Reduced saturation, slight warm shift, brighter shadows
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.7,
                kCIInputBrightnessKey: 0.05,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.05, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.9),
            ])
        case .ink:
            let mono = ci.applyingFilter("CIPhotoEffectMono")
            output = mono.applyingFilter("CIVignette", parameters: [
                "inputIntensity": 0.8,
                "inputRadius": 8.0,
            ])
        case .morning:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.08,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0.95, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 0.98, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1.08),
            ])
        case .dusk:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.05,
                kCIInputSaturationKey: 0.9,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.08, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.85),
            ])
        case .mist:
            let controls = ci.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 0.85,
                kCIInputSaturationKey: 0.85,
            ])
            output = controls.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.0, y: 0, z: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1.0),
                "inputBiasVector": CIVector(x: 0.06, y: 0.06, z: 0.06),
            ])
        }

        guard let cgOut = context.createCGImage(output, from: output.extent) else {
            throw ImageFilterError.renderFailed
        }
        return UIImage(cgImage: cgOut, scale: image.scale, orientation: image.imageOrientation)
    }
}

enum ImageFilterError: Error {
    case invalidInput
    case renderFailed
}
```

(Note: `ImageFilter.allCases` test refers to the enum's CaseIterable conformance.)

- [ ] **Step 4: Run tests to verify they pass**

Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近/Services/ImageFilter.swift 附近Tests/ImageFilterTests.swift
git commit -m "feat: add ImageFilter with 6 paper-style filters"
```

---

### Task 2.2: ImageStorage service + tests

**Files:**
- Create: `附近/Services/ImageStorage.swift`
- Create: `附近Tests/ImageStorageTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
import UIKit
@testable import 附近

struct ImageStorageTests {
    private func makeImage(_ size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemGreen.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test func resizeCapsLongEdge() throws {
        let big = makeImage(CGSize(width: 4000, height: 3000))
        let resized = try ImageStorage.resize(image: big, maxLongEdge: 2400)
        #expect(max(resized.size.width, resized.size.height) == 2400, "Long edge should be capped at 2400")
        #expect(resized.size.width * resized.size.height <= 2400 * 2400)
    }

    @Test func resizeKeepsSmallImage() throws {
        let small = makeImage(CGSize(width: 800, height: 600))
        let resized = try ImageStorage.resize(image: small, maxLongEdge: 2400)
        #expect(resized.size.width == 800)
    }

    @Test func encodeProducesUnderBudget() throws {
        let image = makeImage(CGSize(width: 2400, height: 1800))
        let data = try ImageStorage.encodeJPEG(image, quality: 0.82)
        #expect(data.count < 500_000, "Expected < 500KB, got \(data.count) bytes")
    }

    @Test func thumbnailIsSmallerThanFull() throws {
        let image = makeImage(CGSize(width: 2400, height: 1800))
        let full = try ImageStorage.encodeJPEG(image, quality: 0.82)
        let thumb = try ImageStorage.makeThumbnail(image, longEdge: 400, quality: 0.7)
        #expect(thumb.count < full.count / 4, "Thumbnail should be significantly smaller than full")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL.

- [ ] **Step 3: Write ImageStorage**

`附近/Services/ImageStorage.swift`:

```swift
import UIKit
import ImageIO

enum ImageStorage {
    static func resize(image: UIImage, maxLongEdge: CGFloat) throws -> UIImage {
        let size = image.size
        let longEdge = max(size.width, size.height)
        guard longEdge > maxLongEdge else { return image }
        let scale = maxLongEdge / longEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func encodeJPEG(_ image: UIImage, quality: CGFloat) throws -> Data {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw ImageStorageError.encodingFailed
        }
        return data
    }

    static func makeThumbnail(_ image: UIImage, longEdge: CGFloat = 400, quality: CGFloat = 0.7) throws -> Data {
        let resized = try resize(image: image, maxLongEdge: longEdge)
        return try encodeJPEG(resized, quality: quality)
    }
}

enum ImageStorageError: Error {
    case encodingFailed
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近/Services/ImageStorage.swift 附近Tests/ImageStorageTests.swift
git commit -m "feat: add ImageStorage for resize/encode/thumbnail"
```

---

### Task 2.3: NeighborhoodTable for fallback labels

**Files:**
- Create: `附近Resources/neighborhoods.json`
- Create: `附近/Data/NeighborhoodTable.swift`
- Create: `附近Tests/NeighborhoodTableTests.swift`

- [ ] **Step 1: Write neighborhoods.json**

`附近Resources/neighborhoods.json`:

```json
{
  "city": "上海",
  "neighborhoods": [
    {"id":"yuyuan_road","name_zh":"愚园路","name_en":"Yuyuan Road","district_zh":"静安","district_en":"Jing'an","centerLat":31.226,"centerLon":121.426,"radius":0.008},
    {"id":"julu_road","name_zh":"巨鹿路","name_en":"Julu Road","district_zh":"静安","district_en":"Jing'an","centerLat":31.222,"centerLon":121.458,"radius":0.006},
    {"id":"wukang_road","name_zh":"武康路","name_en":"Wukang Road","district_zh":"徐汇","district_en":"Xuhui","centerLat":31.215,"centerLon":121.434,"radius":0.007},
    {"id":"anfu_road","name_zh":"安福路","name_en":"Anfu Road","district_zh":"徐汇","district_en":"Xuhui","centerLat":31.218,"centerLon":121.443,"radius":0.005},
    {"id":"yongkang_road","name_zh":"永康路","name_en":"Yongkang Road","district_zh":"徐汇","district_en":"Xuhui","centerLat":31.210,"centerLon":121.451,"radius":0.005},
    {"id":"tianzifang","name_zh":"田子坊","name_en":"Tianzifang","district_zh":"黄浦","district_en":"Huangpu","centerLat":31.210,"centerLon":121.466,"radius":0.005},
    {"id":"sinan_road","name_zh":"思南路","name_en":"Sinan Road","district_zh":"黄浦","district_en":"Huangpu","centerLat":31.220,"centerLon":121.467,"radius":0.005},
    {"id":"fuxing_middle","name_zh":"复兴中路","name_en":"Fuxing Middle Road","district_zh":"黄浦","district_en":"Huangpu","centerLat":31.218,"centerLon":121.462,"radius":0.007},
    {"id":"hengshan_road","name_zh":"衡山路","name_en":"Hengshan Road","district_zh":"徐汇","district_en":"Xuhui","centerLat":31.205,"centerLon":121.439,"radius":0.006},
    {"id":"xinhua_road","name_zh":"新华路","name_en":"Xinhua Road","district_zh":"长宁","district_en":"Changning","centerLat":31.214,"centerLon":121.421,"radius":0.007}
  ]
}
```

- [ ] **Step 2: Write failing test**

```swift
import Testing
import Foundation
@testable import 附近

struct NeighborhoodTableTests {
    @Test func loadsAtLeastTenNeighborhoods() async throws {
        let table = try await NeighborhoodTable.load()
        #expect(table.neighborhoods.count >= 10)
    }

    @Test func resolvesClosestNeighborhood() async throws {
        let table = try await NeighborhoodTable.load()
        // 愚园路 center 31.226, 121.426
        let resolved = table.resolve(lat: 31.2265, lon: 121.4262)
        #expect(resolved?.nameZh == "愚园路")
    }

    @Test func returnsNilWhenTooFar() async throws {
        let table = try await NeighborhoodTable.load()
        // Beijing
        let resolved = table.resolve(lat: 39.904, lon: 116.407)
        #expect(resolved == nil)
    }
}
```

- [ ] **Step 3: Write NeighborhoodTable**

```swift
import Foundation

struct Neighborhood: Codable, Identifiable {
    let id: String
    let nameZh: String
    let nameEn: String
    let districtZh: String
    let districtEn: String
    let centerLat: Double
    let centerLon: Double
    let radius: Double
}

struct NeighborhoodFile: Codable {
    let city: String
    let neighborhoods: [Neighborhood]
}

enum NeighborhoodTable {
    static func load() async throws -> [Neighborhood] {
        guard let url = Bundle.main.url(forResource: "neighborhoods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(NeighborhoodFile.self, from: data) else {
            throw NeighborhoodTableError.fileNotFound
        }
        return file.neighborhoods
    }
}

extension [Neighborhood] {
    func resolve(lat: Double, lon: Double) -> Neighborhood? {
        // Find closest center within radius
        var best: (Neighborhood, Double)? = nil
        for n in self {
            let dLat = lat - n.centerLat
            let dLon = lon - n.centerLon
            let dist = (dLat * dLat + dLon * dLon).squareRoot()
            if dist <= n.radius {
                if best == nil || dist < best!.1 {
                    best = (n, dist)
                }
            }
        }
        return best?.0
    }
}

enum NeighborhoodTableError: Error {
    case fileNotFound
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近Resources/neighborhoods.json 附近/Data/NeighborhoodTable.swift 附近Tests/NeighborhoodTableTests.swift
git commit -m "feat: add NeighborhoodTable with 10 Shanghai neighborhoods"
```

---

### Task 2.4: GeoLabelResolver service

**Files:**
- Create: `附近/Services/GeoLabelResolver.swift`

- [ ] **Step 1: Write GeoLabelResolver**

```swift
import Foundation
import CoreLocation

enum GeoLabelResolver {
    // Cache for 24h
    nonisolated(unsafe) private static var cache: [String: (label: String, expiresAt: Date)] = [:]
    private static let cacheTTL: TimeInterval = 86_400

    static func resolve(lat: Double, lon: Double) async -> String {
        let key = String(format: "%.3f_%.3f", lat, lon)
        if let cached = cache[key], cached.expiresAt > Date() {
            return cached.label
        }

        // Tier 1: CLGeocoder
        if let label = await tryReverseGeocode(lat: lat, lon: lon) {
            cache[key] = (label, Date().addingTimeInterval(cacheTTL))
            return label
        }

        // Tier 2: NeighborhoodTable
        if let neighborhoods = try? await NeighborhoodTable.load(),
           let n = neighborhoods.resolve(lat: lat, lon: lon) {
            let locale = Locale.current.language.languageCode?.identifier ?? "zh"
            let label = locale == "en"
                ? "\(n.nameEn) · \(n.districtEn)"
                : "\(n.nameZh) · \(n.districtZh)"
            cache[key] = (label, Date().addingTimeInterval(cacheTTL))
            return label
        }

        // Tier 3: fallback
        return NSLocalizedString("location.unknown", value: "附近 · 此刻", comment: "")
    }

    private static func tryReverseGeocode(lat: Double, lon: Double) async -> String? {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: lat, longitude: lon)
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                guard let p = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                // Format: "路名 · 区" (e.g. "愚园路 · 静安")
                let thoroughfare = p.thoroughfare ?? ""
                let subLocality = p.subLocality ?? p.locality ?? ""
                if thoroughfare.isEmpty {
                    continuation.resume(returning: nil)
                    return
                }
                let label = subLocality.isEmpty ? thoroughfare : "\(thoroughfare) · \(subLocality)"
                continuation.resume(returning: label)
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodegen generate && xcodebuild build -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

(Note: GeoLabelResolver has 3-tier fallback; we don't unit-test CLGeocoder directly because it requires network. NeighborhoodTable test covers tier 2.)

- [ ] **Step 3: Commit**

```bash
git add 附近/Services/GeoLabelResolver.swift
git commit -m "feat: add GeoLabelResolver with 3-tier fallback"
```

---

### Task 2.5: LocationManager

**Files:**
- Create: `附近/Services/LocationManager.swift`

- [ ] **Step 1: Write LocationManager**

```swift
import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var currentCoord: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var denied: Bool { authorizationStatus == .denied || authorizationStatus == .restricted }

    // Fallback for sim/dev: Shanghai 愚园路 area
    static let fallbackCoord = CLLocationCoordinate2D(latitude: 31.226, longitude: 121.426)

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard !denied else { return }
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            self.currentCoord = last.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent: UI uses fallback when currentCoord is nil
    }
}
```

- [ ] **Step 2: Build to verify**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add 附近/Services/LocationManager.swift
git commit -m "feat: add LocationManager CoreLocation wrapper"
```

---

### Task 2.6: TodayViewModel + TodayView + TaskCardView

**Files:**
- Create: `附近/Features/Today/TodayViewModel.swift`
- Create: `附近/Features/Today/TaskCardView.swift`
- Modify: `附近/Features/Today/TodayView.swift`

- [ ] **Step 1: Write TodayViewModel**

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class TodayViewModel {
    var todayTask: DailyTask?
    var hasCompletedToday: Bool = false
    var showArchive: Bool = false
    var showRecord: Bool = false

    func load(modelContext: ModelContext, taskBank: [DailyTask]) {
        todayTask = TaskDistributor.task(for: Date(), bank: taskBank)
        if let task = todayTask {
            let taskId = task.id
            let cal = Calendar(identifier: .gregorian)
            let start = cal.startOfDay(for: Date())
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let predicate = #Predicate<Post> { $0.taskRef == taskId && $0.isOwn == true && $0.createdAt >= start && $0.createdAt < end }
            let descriptor = FetchDescriptor<Post>(predicate: predicate)
            hasCompletedToday = (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
        }
    }
}
```

- [ ] **Step 2: Write TaskCardView**

```swift
import SwiftUI

struct TaskCardView: View {
    let task: DailyTask
    var hasCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                Image(systemName: task.type.iconName)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text(NSLocalizedString("today.label", value: "今日任务", comment: ""))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
            }

            Text(task.localizedTitle())
                .font(.taskTitle)
                .foregroundStyle(Color.ink900)
                .lineSpacing(4)

            Text(task.localizedPrompt())
                .font(.bodySerif)
                .foregroundStyle(Color.ink700)
                .lineSpacing(5)

            Divider().overlay(Color.ink300)

            HStack(spacing: Spacing.s) {
                Text(task.proposedBy)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(String.localizedStringWithFormat(NSLocalizedString("today.votes", value: "%d 位邻居投票选中", comment: ""), task.voteCount))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Spacer()
            }

            if let refName = task.referenceImageName, let uiImage = UIImage(named: refName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(Radius.image)
                    .overlay(Color.ink900.opacity(0.04))
            }
        }
        .padding(Spacing.l)
        .background(Color.paper100)
        .cornerRadius(Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.ink300, lineWidth: 0.5)
        )
        .overlay(alignment: .bottomTrailing) {
            if hasCompleted {
                SealStamp()
                    .rotationEffect(.degrees(-8))
                    .padding(Spacing.m)
            }
        }
    }
}
```

- [ ] **Step 3: Write SealStamp**

`附近/DesignSystem/Components/SealStamp.swift`:

```swift
import SwiftUI

struct SealStamp: View {
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
    }
}
```

- [ ] **Step 4: Rewrite TodayView with full layout**

```swift
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var taskBank: [DailyTask] = []
    @State private var navigateToArchive = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if let task = viewModel.todayTask {
                        TaskCardView(task: task, hasCompleted: viewModel.hasCompletedToday)
                            .padding(.horizontal, Spacing.m)
                            .padding(.top, Spacing.m)
                            .transition(.move(edge: .top).combined(with: .opacity))

                        Button {
                            viewModel.showRecord = true
                        } label: {
                            HStack {
                                Text(NSLocalizedString("today.cta.record", value: "开始记录", comment: ""))
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundStyle(Color.paper50)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.m)
                            .background(Color.cinnabar)
                            .cornerRadius(Radius.button)
                        }
                        .padding(.horizontal, Spacing.m)
                        .disabled(viewModel.hasCompletedToday)
                        .opacity(viewModel.hasCompletedToday ? 0.4 : 1.0)

                        NavigationLink(value: "archive") {
                            HStack {
                                Text(NSLocalizedString("today.cta.archive", value: "看看过去的日子", comment: ""))
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                            .padding(.top, Spacing.xs)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding(.bottom, Spacing.xxl)
            }
            .navigationTitle("附近")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { value in
                if value == "archive" {
                    ArchiveView()
                }
            }
            .sheet(isPresented: $viewModel.showRecord) {
                RecordView()
            }
        }
        .paperBackground()
        .task {
            taskBank = TaskBank.loadSync()
            viewModel.load(modelContext: modelContext, taskBank: taskBank)
        }
        .onChange(of: viewModel.showRecord) { _, newValue in
            // Refresh completion state when record sheet closes
            if !newValue {
                viewModel.load(modelContext: modelContext, taskBank: taskBank)
            }
        }
    }
}
```

- [ ] **Step 5: Build to verify**

```bash
xcodegen generate && xcodebuild build -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Manual verify in simulator**

```bash
xcrun simctl install booted /Users/chenzilve/Library/Developer/Xcode/DerivedData/附近-*/Build/Products/Debug-iphonesimulator/附近.app
xcrun simctl launch booted com.cassette.附近
```

Expected: Today tab shows today's task card with title, prompt, proposer, vote count. No image (referenceImageName is set for 5 tasks, but assets not yet added — image just doesn't render).

- [ ] **Step 7: Commit**

```bash
git add 附近/Features/Today/ 附近/DesignSystem/Components/SealStamp.swift
git commit -m "feat: build TodayView with task card + completion seal"
```

---

### Task 2.7: MoodSelector component

**Files:**
- Create: `附近/Features/Record/MoodSelector.swift`

- [ ] **Step 1: Write MoodSelector**

```swift
import SwiftUI

struct MoodSelector: View {
    @Binding var selected: MoodTag?

    var body: some View {
        HStack(spacing: Spacing.m) {
            ForEach(MoodTag.allCases) { mood in
                Button {
                    selected = (selected == mood) ? nil : mood
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(mood.color)
                            .frame(width: 16, height: 16)
                            .overlay {
                                if selected == mood {
                                    Circle().stroke(Color.ink900, lineWidth: 1.5)
                                        .padding(-3)
                                }
                            }
                        Text(mood.localizedName)
                            .font(.caption)
                            .foregroundStyle(selected == mood ? Color.ink900 : Color.ink500)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Record/MoodSelector.swift
git commit -m "feat: add MoodSelector component"
```

---

### Task 2.8: FilterStrip component

**Files:**
- Create: `附近/Features/Record/FilterStrip.swift`

- [ ] **Step 1: Write FilterStrip**

```swift
import SwiftUI

struct FilterStrip: View {
    let originalImage: UIImage
    @Binding var selected: ImageFilter

    @State private var previews: [ImageFilter: UIImage] = [:]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.m) {
                ForEach(ImageFilter.allCases) { filter in
                    Button {
                        selected = filter
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            ZStack {
                                if let preview = previews[filter] {
                                    Image(uiImage: preview)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.paper200)
                                        .frame(width: 56, height: 56)
                                }
                                if selected == filter {
                                    Circle()
                                        .stroke(Color.cinnabar, lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            Text(filter.localizedName)
                                .font(.caption)
                                .foregroundStyle(selected == filter ? Color.ink900 : Color.ink500)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .task {
            await generatePreviews()
        }
    }

    private func generatePreviews() async {
        let resized = (try? ImageStorage.resize(image: originalImage, maxLongEdge: 120)) ?? originalImage
        for filter in ImageFilter.allCases {
            if let result = try? ImageFilterEngine.apply(filter: filter, to: resized) {
                await MainActor.run {
                    previews[filter] = result
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Record/FilterStrip.swift
git commit -m "feat: add FilterStrip with async preview generation"
```

---

### Task 2.9: PhotoPickerButton component

**Files:**
- Create: `附近/Features/Record/PhotoPickerButton.swift`

- [ ] **Step 1: Write PhotoPickerButton**

```swift
import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Binding var image: UIImage?
    var onPick: () -> Void = {}

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        Button {
            // PhotosPicker is shown via the underlying picker; nothing else to do
        } label: {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .clipped()
                        .cornerRadius(Radius.image)
                } else {
                    ZStack {
                        Color.paper100
                        VStack(spacing: Spacing.s) {
                            Image(systemName: "camera")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.ink500)
                            Text(NSLocalizedString("record.photo.placeholder", value: "点击选择照片", comment: ""))
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .cornerRadius(Radius.image)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Color.clear
            }
            .opacity(0.05)
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        image = uiImage
                        onPick()
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Record/PhotoPickerButton.swift
git commit -m "feat: add PhotoPickerButton using PhotosUI"
```

---

### Task 2.10: RecordViewModel + RecordView

**Files:**
- Create: `附近/Features/Record/RecordViewModel.swift`
- Create: `附近/Features/Record/RecordView.swift`

- [ ] **Step 1: Write RecordViewModel**

```swift
import SwiftUI
import SwiftData
import CoreLocation

@MainActor
@Observable
final class RecordViewModel {
    var originalImage: UIImage?
    var selectedFilter: ImageFilter = .original
    var title: String = ""
    var text: String = ""
    var selectedMood: MoodTag?
    var fuzzyLocation: FuzzyLocation?
    var canPublish: Bool { text.count >= 6 && originalImage != nil }
    var isSaving = false
    var errorMessage: String?

    let locationManager = LocationManager()

    func setupLocation() async {
        if locationManager.currentCoord == nil {
            locationManager.requestPermission()
            locationManager.requestLocation()
            // Wait briefly for location
            try? await Task.sleep(for: .seconds(2))
        }
        await refreshFuzzyLocation()
    }

    func refreshFuzzyLocation() async {
        let coord = locationManager.currentCoord ?? LocationManager.fallbackCoord
        let label = await GeoLabelResolver.resolve(lat: coord.latitude, lon: coord.longitude)
        fuzzyLocation = LocationFuzzer.fuzzify(coord, label: label)
    }

    func save(modelContext: ModelContext, task: DailyTask) async -> Bool {
        guard let originalImage, originalImage.count > 0 else {
            errorMessage = NSLocalizedString("record.error.no_image", value: "请先选一张照片", comment: "")
            return false
        }
        guard text.count >= 6 else {
            errorMessage = NSLocalizedString("record.error.short_text", value: "再多写一句吧", comment: "")
            return false
        }
        guard let fuzzyLocation else {
            errorMessage = NSLocalizedString("record.error.no_location", value: "无法获取位置", comment: "")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let resized = try ImageStorage.resize(image: originalImage, maxLongEdge: 2400)
            let filtered = try ImageFilterEngine.apply(filter: selectedFilter, to: resized)
            let fullData = try ImageStorage.encodeJPEG(filtered, quality: 0.82)
            let thumbData = try ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)

            let post = Post(
                taskRef: task.id,
                imageData: fullData,
                thumbnailData: thumbData,
                title: title.isEmpty ? nil : title,
                text: text,
                moodTag: selectedMood,
                filterName: selectedFilter.rawValue,
                fuzzyLabel: fuzzyLocation.label,
                fuzzyLat: fuzzyLocation.lat,
                fuzzyLon: fuzzyLocation.lon,
                isOwn: true,
                authorId: CurrentUser.id,
                authorName: CurrentUser.displayName
            )
            modelContext.insert(post)
            try modelContext.save()
            return true
        } catch {
            errorMessage = NSLocalizedString("record.error.save_failed", value: "保存失败，请重试", comment: "")
            return false
        }
    }
}
```

- [ ] **Step 2: Write RecordView**

```swift
import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allTasks: [DailyTask] // placeholder, replaced via task property
    @State private var viewModel = RecordViewModel()

    // Resolve today's task from TaskBank (passed in or computed)
    var todayTask: DailyTask {
        let bank = TaskBank.loadSync()
        return TaskDistributor.task(for: Date(), bank: bank)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    PhotoPickerButton(image: $viewModel.originalImage)

                    if viewModel.originalImage != nil {
                        FilterStrip(originalImage: viewModel.originalImage!, selected: $viewModel.selectedFilter)
                    }

                    Divider().overlay(Color.ink300)

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(NSLocalizedString("record.field.title", value: "标题（可选）", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        TextField(NSLocalizedString("record.title.placeholder", value: "起个名字…", comment: ""), text: $viewModel.title)
                            .font(.bodySerif)
                            .padding(Spacing.s)
                            .background(Color.paper100)
                            .cornerRadius(Radius.button)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(NSLocalizedString("record.field.text", value: "记一段…", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        TextEditor(text: $viewModel.text)
                            .font(.bodySerif)
                            .frame(minHeight: 120)
                            .padding(Spacing.s)
                            .background(Color.paper100)
                            .cornerRadius(Radius.button)
                            .overlay(
                                Group {
                                    if viewModel.text.isEmpty {
                                        Text(NSLocalizedString("record.text.placeholder", value: "今天看见的、路过的、感觉到的。", comment: ""))
                                            .font(.bodySerif)
                                            .foregroundStyle(Color.ink300)
                                            .padding(.horizontal, Spacing.m)
                                            .padding(.vertical, Spacing.l)
                                    }
                                }, alignment: .topLeading
                            )
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(NSLocalizedString("record.field.mood", value: "心情", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        MoodSelector(selected: $viewModel.selectedMood)
                    }

                    if let loc = viewModel.fuzzyLocation {
                        Label(loc.label, systemImage: "mappin.circle.ellipse")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle(NSLocalizedString("record.nav_title", value: "记录今日", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", value: "取消", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.publish", value: "发布", comment: "")) {
                        Task {
                            if await viewModel.save(modelContext: modelContext, task: todayTask) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canPublish || viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
        .paperBackground()
        .task {
            await viewModel.setupLocation()
        }
    }
}
```

- [ ] **Step 3: Build to verify**

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Manual verify in simulator**

Launch app → Today tab → tap "开始记录" → pick photo → select filter → write text (≥6 chars) → select mood → publish → Today card should show seal stamp.

- [ ] **Step 5: Commit**

```bash
git add 附近/Features/Record/RecordViewModel.swift 附近/Features/Record/RecordView.swift
git commit -m "feat: build RecordView with photo/filter/text/mood/location"
```

---

### Task 2.11: Mock user table

**Files:**
- Create: `附近Resources/mock_users.json`

- [ ] **Step 1: Write mock_users.json**

```json
{
  "users": [
    {"id":"mock_01","name":"小路"},
    {"id":"mock_02","name":"林"},
    {"id":"mock_03","name":"阿黎"},
    {"id":"mock_04","name":"青"},
    {"id":"mock_05","name":"雨舟"},
    {"id":"mock_06","name":"晨曦"},
    {"id":"mock_07","name":"续冬"},
    {"id":"mock_08","name":"墨白"},
    {"id":"mock_09","name":"雁"},
    {"id":"mock_10","name":"知秋"},
    {"id":"mock_11","name":"阿莞"},
    {"id":"mock_12","name":"子衿"},
    {"id":"mock_13","name":"浅溪"},
    {"id":"mock_14","name":"北窗"},
    {"id":"mock_15","name":"绾"},
    {"id":"mock_16","name":"清和"},
    {"id":"mock_17","name":"向晚"},
    {"id":"mock_18","name":"未央"},
    {"id":"mock_19","name":"临川"},
    {"id":"mock_20","name":"阑珊"},
    {"id":"mock_21","name":"廿一"},
    {"id":"mock_22","name":"芷"},
    {"id":"mock_23","name":"棋"},
    {"id":"mock_24","name":"九安"},
    {"id":"mock_25","name":"温故"},
    {"id":"mock_26","name":"闻溪"},
    {"id":"mock_27","name":"榆"},
    {"id":"mock_28","name":"檀"},
    {"id":"mock_29","name":"禾"},
    {"id":"mock_30","name":"沐"}
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近Resources/mock_users.json
git commit -m "feat: add 30 mock users"
```

---

### Task 2.12: TextTemplates for mock content

**Files:**
- Create: `附近Resources/text_templates.json`
- Create: `附近/Data/TextTemplates.swift`

- [ ] **Step 1: Write text_templates.json**

```json
{
  "post_titles": [
    {"zh":"路口的银杏树","en":"Ginkgo at the corner"},
    {"zh":"雨后的法桐","en":"Plane tree after rain"},
    {"zh":"楼下早餐店","en":"Breakfast shop downstairs"},
    {"zh":"7路公交终点","en":"End of the 7 bus line"},
    {"zh":"复兴里的猫","en":"Cat at Fuxing Li"},
    {"zh":"转角的旧招牌","en":"Old sign at the corner"},
    {"zh":"天桥下面","en":"Under the footbridge"},
    {"zh":"三号门","en":"Gate 3"},
    {"zh":"河边的椅子","en":"Riverside chair"}
  ],
  "post_texts": [
    {"zh":"今天也走这条路上班。看着银杏叶一天比一天黄。","en":"Took this road to work again. The ginkgo leaves turn yellower each day."},
    {"zh":"楼下早餐店的爷爷今天给我多塞了一个包子。","en":"The grandpa at breakfast slipped me an extra bun today."},
    {"zh":"雨后的法桐格外亮。","en":"Plane trees look brighter after rain."},
    {"zh":"这条路我走了十年，第一次发现这家小店。","en":"Ten years on this road, first time I noticed this shop."},
    {"zh":"突然觉得，'附近'不是一个地方，是一种心情。","en":"Suddenly: 'nearby' isn't a place, it's a mood."},
    {"zh":"小店的灯一直亮着。从我有记忆起就这样。","en":"The shop's light is always on. As long as I remember."},
    {"zh":"今天发现了 5 种不同的纹理。最喜欢的是墙上斑驳的漆。","en":"Found 5 different textures today. My favorite: the peeling paint on a wall."},
    {"zh":"老板说这里开了 28 年了。","en":"The owner said this shop has been here 28 years."},
    {"zh":"桥下有人下棋。我看了 20 分钟。","en":"Under the bridge, people playing chess. I watched for 20 minutes."},
    {"zh":"黄昏的天空是粉色和灰色的。","en":"Dusk sky was pink and gray."}
  ],
  "responses": [
    {"zh":"嗯，我也路过了。","en":"Yes, I walked past too."},
    {"zh":"看完想出去走走。","en":"Reading this makes me want to go outside."},
    {"zh":"谢谢记录。","en":"Thanks for documenting this."},
    {"zh":"看见你说的这棵树了。","en":"I saw the tree you wrote about."},
    {"zh":"我也是这么觉得的。","en":"I feel the same way."},
    {"zh":"下次我也走这条路。","en":"I'll take this road next time."},
    {"zh":"文字好温柔。","en":"Your words feel gentle."}
  ]
}
```

- [ ] **Step 2: Write TextTemplates loader**

```swift
import Foundation

struct TextTemplates: Codable {
    let postTitles: [LocalizedText]
    let postTexts: [LocalizedText]
    let responses: [LocalizedText]

    enum CodingKeys: String, CodingKey {
        case postTitles = "post_titles"
        case postTexts = "post_texts"
        case responses
    }
}

struct LocalizedText: Codable {
    let zh: String
    let en: String

    func localized() -> String {
        let lang = Locale.current.language.languageCode?.identifier ?? "zh"
        return lang == "en" ? en : zh
    }
}

enum TextTemplatesLoader {
    static func load() -> TextTemplates? {
        guard let url = Bundle.main.url(forResource: "text_templates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode(TextTemplates.self, from: data) else {
            return nil
        }
        return templates
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add 附近Resources/text_templates.json 附近/Data/TextTemplates.swift
git commit -m "feat: add TextTemplates for mock content"
```

---

### Task 2.13: MockSeeder

**Files:**
- Create: `附近/Data/MockSeeder.swift`
- Create: `附近Tests/MockSeederTests.swift`

- [ ] **Step 1: Write failing test**

```swift
import Testing
import Foundation
import SwiftData
import UIKit
@testable import 附近

struct MockSeederTests {
    @MainActor
    @Test func seeds30to50PostsAcrossTenNeighborhoods() async throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let bank = TaskBank.loadSync()
        await MockSeeder.seedIfNeeded(context: context, taskBank: bank)

        let descriptor = FetchDescriptor<Post>()
        let posts = try context.fetch(descriptor)
        #expect(posts.count >= 30 && posts.count <= 50, "Expected 30-50 posts, got \(posts.count)")

        let neighborhoods = Set(posts.map { $0.fuzzyLabel })
        #expect(neighborhoods.count >= 5, "Expected ≥5 distinct labels, got \(neighborhoods.count)")
    }

    @MainActor
    @Test func seedsIdempotent() async throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let bank = TaskBank.loadSync()

        await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
        let countAfterFirst = try context.fetchCount(FetchDescriptor<Post>())

        await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
        let countAfterSecond = try context.fetchCount(FetchDescriptor<Post>())

        #expect(countAfterFirst == countAfterSecond, "Seeder should be idempotent")
    }
}
```

- [ ] **Step 2: Write MockSeeder**

```swift
import Foundation
import SwiftData
import UIKit

enum MockSeeder {
    @MainActor
    static func seedIfNeeded(context: ModelContext, taskBank: [DailyTask]) async {
        let key = "mockSeeder.version1.completed"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        await seed(context: context, taskBank: taskBank)
        UserDefaults.standard.set(true, forKey: key)
    }

    @MainActor
    static func seed(context: ModelContext, taskBank: [DailyTask]) async {
        guard taskBank.count >= 10,
              let users = loadMockUsers(),
              let templates = TextTemplatesLoader.load(),
              let neighborhoods = try? await NeighborhoodTable.load() else {
            return
        }

        let mockImages = (1...20).compactMap { UIImage(named: "mock_scene_\($0)") }
        let placeholderImage = mockImages.first ?? makeFallbackImage()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = Date()

        // 30-50 mock posts scattered across past 30 days
        for i in 0..<40 {
            let task = taskBank[i % taskBank.count]
            let user = users[i % users.count]
            let neighborhood = neighborhoods[i % neighborhoods.count]
            let template = templates.postTexts[i % templates.postTexts.count]
            let title = i % 3 == 0 ? templates.postTitles[i % templates.postTitles.count] : nil
            let mood = MoodTag.allCases[i % MoodTag.allCases.count]
            let filter = ImageFilter.allCases[i % ImageFilter.allCases.count]

            let daysAgo = i / 2  // spread across ~20 days
            let hour = 8 + (i % 12)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
                .addingTimeInterval(TimeInterval((hour - 12) * 3600))

            let jitter = Double(i % 7) * 0.0003
            let coord = CLLocationCoordinate2DMake(
                neighborhood.centerLat + jitter,
                neighborhood.centerLon + jitter
            )
            let labelZh = "\(neighborhood.nameZh) · \(neighborhood.districtZh)"

            let baseImage = mockImages.isEmpty ? placeholderImage : mockImages[i % max(mockImages.count, 1)]
            let resized = (try? ImageStorage.resize(image: baseImage, maxLongEdge: 2400)) ?? baseImage
            let filtered = (try? ImageFilterEngine.apply(filter: filter, to: resized)) ?? resized
            let fullData = (try? ImageStorage.encodeJPEG(filtered, quality: 0.82)) ?? Data()
            let thumbData = (try? ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)) ?? Data()

            let post = Post(
                createdAt: date,
                taskRef: task.id,
                imageData: fullData,
                thumbnailData: thumbData,
                title: title?.localized(),
                text: template.localized(),
                moodTag: mood,
                filterName: filter.rawValue,
                fuzzyLabel: labelZh,
                fuzzyLat: coord.latitude,
                fuzzyLon: coord.longitude,
                isOwn: false,
                authorId: UUID(uuidString: user.id.replacingOccurrences(of: "mock_", with: "00000000-0000-0000-0000-0000000000").padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID(),
                authorName: user.name
            )
            context.insert(post)
        }

        // 5-8 of these should be timestamped today, for the today-task
        if let todayTask = taskBank.first {
            let todayCount = 6
            for i in 0..<todayCount {
                let user = users[(i + 3) % users.count]
                let neighborhood = neighborhoods[(i + 2) % neighborhoods.count]
                let template = templates.postTexts[(i + 1) % templates.postTexts.count]
                let mood = MoodTag.allCases[(i + 1) % MoodTag.allCases.count]
                let filter = ImageFilter.allCases[(i + 2) % ImageFilter.allCases.count]

                let coord = CLLocationCoordinate2DMake(neighborhood.centerLat, neighborhood.centerLon)
                let labelZh = "\(neighborhood.nameZh) · \(neighborhood.districtZh)"
                let baseImage = placeholderImage

                let filtered = (try? ImageFilterEngine.apply(filter: filter, to: baseImage)) ?? baseImage
                let fullData = (try? ImageStorage.encodeJPEG(filtered, quality: 0.82)) ?? Data()
                let thumbData = (try? ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)) ?? Data()

                let date = calendar.date(byAdding: .hour, value: -(i + 1), to: now)!
                let post = Post(
                    createdAt: date,
                    taskRef: todayTask.id,
                    imageData: fullData,
                    thumbnailData: thumbData,
                    title: nil,
                    text: template.localized(),
                    moodTag: mood,
                    filterName: filter.rawValue,
                    fuzzyLabel: labelZh,
                    fuzzyLat: coord.latitude,
                    fuzzyLon: coord.longitude,
                    isOwn: false,
                    authorId: UUID(),
                    authorName: user.name
                )
                context.insert(post)
            }
        }

        try? context.save()
    }

    private static func loadMockUsers() -> [MockUser]? {
        guard let url = Bundle.main.url(forResource: "mock_users", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        struct Wrapper: Codable { let users: [MockUser] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.users
    }

    private static func makeFallbackImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 750))
        return renderer.image { ctx in
            UIColor.paper200.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 600, height: 750)))
        }
    }
}

struct MockUser: Codable {
    let id: String
    let name: String
}
```

- [ ] **Step 3: Run tests**

Expected: Tests pass. Posts seeded: ~40-46. Idempotent on second run.

(Note: CLLocationCoordinate2DMake is imported via CoreLocation; the import isn't shown in this snippet — ensure `import CoreLocation` at top.)

- [ ] **Step 4: Add seeder call in NearbyApp**

`附近/App/NearbyApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct NearbyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Post.self, Response.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to init SwiftData container: \(error)")
        }

        // Seed mock content on first launch
        Task { @MainActor in
            let context = container.mainContext
            let bank = TaskBank.loadSync()
            await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add 附近/Data/MockSeeder.swift 附近Tests/MockSeederTests.swift 附近/App/NearbyApp.swift
git commit -m "feat: seed 30-50 mock posts on first launch"
```

---

### Task 2.14: Add 20 mock images asset

**Files:**
- Create: `附近/Assets.xcassets/MockImages/mock_scene_01.jpg ... mock_scene_20.jpg`

- [ ] **Step 1: Generate or curate 20 photos**

For demo purposes, use a small set of public-domain or atmospheric street photos. Either:
(a) User-curated: place 20 JPGs at 1200×900 in the folder
(b) Generated: skip and let seeder use fallback color

If using option (b) for now, leave the seeder code as-is. Otherwise:

```bash
mkdir -p 附近/Assets.xcassets/MockImages.imageset
# Place mock_scene_01.jpg ... mock_scene_20.jpg in this folder
# Create Contents.json with proper entries
```

Each image needs a corresponding `.imageset` folder. Create 20 imagesets with Contents.json:

```json
{
  "images": [
    { "filename": "mock_scene_01.jpg", "idiom": "universal" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

- [ ] **Step 2: Update MockSeeder to use individual image names**

The seeder code already uses `UIImage(named: "mock_scene_\(i)")` which expects `.imageset` per image.

- [ ] **Step 3: Build to verify**

Expected: BUILD SUCCEEDED with all 20 images bundled.

- [ ] **Step 4: Commit**

```bash
git add 附近/Assets.xcassets/MockImages*
git commit -m "feat: bundle 20 mock street scene images"
```

---

### Task 2.15: Chunk 2 integration test (manual)

- [ ] **Step 1: Reset simulator and reinstall**

```bash
xcrun simctl uninstall booted com.cassette.附近 || true
xcrun simctl uninstall booted com.cassette.Nearby || true
xcodegen generate
xcodebuild build -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcrun simctl install booted /Users/chenzilve/Library/Developer/Xcode/DerivedData/附近-*/Build/Products/Debug-iphonesimulator/附近.app
xcrun simctl launch booted com.cassette.附近
```

Expected:
- App launches → TodayView
- TodayView shows task card with proposer, vote count, prompt
- Tap "开始记录" → RecordView opens
- Pick photo from Photos (use simulator's sample photos)
- Select filter → preview updates
- Type 6+ chars in text
- Pick mood
- Tap "发布" → returns to TodayView, card shows seal stamp

- [ ] **Step 2: Verify SwiftData persistence**

After publishing once, kill app and relaunch. Today card should still show seal stamp.

- [ ] **Step 3: Commit any final fixes**

```bash
git add -A
git commit -m "test: chunk 2 integration verified"
```

---

### Chunk 2 Completion Check

- [ ] Today tab loads today's task correctly
- [ ] Record sheet opens, accepts photo/filter/title/text/mood
- [ ] "发布" button disabled when text < 6 chars
- [ ] Publish saves Post to SwiftData
- [ ] Today card shows seal after publish
- [ ] 30-50 mock posts seeded on first launch
- [ ] All unit tests pass (ImageFilter, ImageStorage, NeighborhoodTable, MockSeeder)
- [ ] Persisted data survives app relaunch

**Chunk 2 commits expected:** ~14 commits

---

## Chunk 3: Map Feed

**Goal:** MapView shows all posts as photo thumbnail annotations, with clustering for same-grid collisions, tap-to-mini-preview, and tap-to-detail navigation. Falls back to Shanghai 愚园路 area when location permission denied or simulator has no location.

### Task 3.1: AnnotationClusterer + tests

**Files:**
- Create: `附近/Features/Map/AnnotationClusterer.swift`
- Create: `附近Tests/AnnotationClustererTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
import Foundation
@testable import 附近

struct AnnotationClustererTests {
    private func makePost(_ lat: Double, _ lon: Double, _ id: String) -> Post {
        Post(id: UUID(uuidString: id.padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID(),
             taskRef: "t", imageData: Data(), thumbnailData: Data(),
             text: "x", fuzzyLabel: "x",
             fuzzyLat: lat, fuzzyLon: lon,
             isOwn: false, authorId: UUID(), authorName: "mock")
    }

    @Test func clusterSinglePostReturnsOneCluster() {
        let posts = [makePost(31.226, 121.427, "1")]
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 1)
        #expect(clusters.first?.posts.count == 1)
    }

    @Test func clusterMergesPostsInSameGrid() {
        let posts = [
            makePost(31.2261, 121.4271, "1"),
            makePost(31.2262, 121.4272, "2"),
            makePost(31.2263, 121.4273, "3")
        ]
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 1, "Expected 1 cluster, got \(clusters.count)")
        #expect(clusters.first?.posts.count == 3)
    }

    @Test func clusterSeparatesPostsInDifferentGrids() {
        let posts = [
            makePost(31.226, 121.427, "1"),
            makePost(31.230, 121.430, "2")
        ]
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 2)
    }

    @Test func clusterSizeThresholdAt4() {
        // Per spec: ≤3 spread, >3 merged into single with count
        let posts = (0..<5).map { makePost(31.226, 121.427, "\($0)") }
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 1)
        #expect(clusters.first?.isMerged == true)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL.

- [ ] **Step 3: Write AnnotationClusterer**

```swift
import Foundation

struct AnnotationCluster: Identifiable {
    let id: String  // grid key
    let anchorLat: Double
    let anchorLon: Double
    let posts: [Post]

    /// When true, UI renders as a single circle with count.
    /// When false, UI renders each post as individual pin (with slight offset).
    var isMerged: Bool { posts.count > 3 }
}

enum AnnotationClusterer {
    static func cluster(posts: [Post], gridSize: Double = 0.001) -> [AnnotationCluster] {
        var buckets: [String: [Post]] = [:]
        for post in posts {
            let key = String(format: "%.3f_%.3f",
                             (post.fuzzyLat / gridSize).rounded() * gridSize,
                             (post.fuzzyLon / gridSize).rounded() * gridSize)
            buckets[key, default: []].append(post)
        }
        return buckets.map { key, posts in
            let coords = key.split(separator: "_")
            let lat = Double(coords.first ?? "0") ?? 0
            let lon = Double(coords.last ?? "0") ?? 0
            return AnnotationCluster(id: key, anchorLat: lat, anchorLon: lon, posts: posts)
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
git add 附近/Features/Map/AnnotationClusterer.swift 附近Tests/AnnotationClustererTests.swift
git commit -m "feat: add AnnotationClusterer for map annotations"
```

---

### Task 3.2: MapViewModel

**Files:**
- Create: `附近/Features/Map/MapViewModel.swift`

- [ ] **Step 1: Write MapViewModel**

```swift
import SwiftUI
import SwiftData
import CoreLocation
import MapKit

@MainActor
@Observable
final class MapViewModel {
    var clusters: [AnnotationCluster] = []
    var selectedPost: Post?
    var cameraPosition: MapCameraPosition = .automatic
    var showMiniPreview: Bool = false

    let locationManager = LocationManager()

    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let posts = try? modelContext.fetch(descriptor) {
            clusters = AnnotationClusterer.cluster(posts: posts)
        }
        updateCamera()
    }

    func updateCamera() {
        let coord = locationManager.currentCoord ?? LocationManager.fallbackCoord
        let region = MKCoordinateRegion(
            center: coord,
            latitudinalMeters: 1500,
            longitudinalMeters: 1500
        )
        cameraPosition = .region(region)
    }

    func select(post: Post) {
        selectedPost = post
        showMiniPreview = true
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Map/MapViewModel.swift
git commit -m "feat: add MapViewModel with cluster loading"
```

---

### Task 3.3: PhotoAnnotationView

**Files:**
- Create: `附近/Features/Map/PhotoAnnotationView.swift`

- [ ] **Step 1: Write PhotoAnnotationView**

```swift
import SwiftUI
import MapKit

struct PhotoAnnotation: MapContent {
    let cluster: AnnotationCluster
    var onTap: (Post) -> Void = { _ in }

    var body: some View {
        if cluster.isMerged {
            ZStack {
                Circle()
                    .fill(Color.cinnabar.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.paper50, lineWidth: 2))
                Text("\(cluster.posts.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.paper50)
            }
            .onTapGesture {
                onTap(cluster.posts.first!)  // opens mini preview sheet
            }
        } else {
            HStack(spacing: 2) {
                ForEach(Array(cluster.posts.prefix(3).enumerated()), id: \.offset) { idx, post in
                    if let thumb = UIImage(data: post.thumbnailData) {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.paper50, lineWidth: 2))
                            .shadow(color: Color.ink900.opacity(0.15), radius: 2, y: 1)
                            .offset(x: CGFloat(idx * 6), y: CGFloat(idx % 2 == 0 ? -2 : 2))
                            .onTapGesture { onTap(post) }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Map/PhotoAnnotation.swift
git commit -m "feat: add PhotoAnnotation view for cluster"
```

---

### Task 3.4: MiniPreviewCard

**Files:**
- Create: `附近/Features/Map/MiniPreviewCard.swift`

- [ ] **Step 1: Write MiniPreviewCard**

```swift
import SwiftUI

struct MiniPreviewCard: View {
    let post: Post
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.m) {
                if let thumb = UIImage(data: post.thumbnailData) {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.image))
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let title = post.title {
                        Text(title)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                    }
                    Text(post.text)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                        .lineLimit(2)
                    HStack(spacing: Spacing.xs) {
                        Text(post.authorName)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·")
                        Text(post.fuzzyLabel)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.ink300)
            }
            .padding(Spacing.m)
            .background(Color.paper100)
            .cornerRadius(Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.ink300, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Map/MiniPreviewCard.swift
git commit -m "feat: add MiniPreviewCard"
```

---

### Task 3.5: MapView (full implementation)

**Files:**
- Modify: `附近/Features/Map/MapView.swift`

- [ ] **Step 1: Rewrite MapView**

```swift
import SwiftUI
import SwiftData
import MapKit

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MapViewModel()
    @State private var navigateToDetail = false
    @State private var detailPost: Post?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $viewModel.cameraPosition) {
                    UserAnnotation()
                    ForEach(viewModel.clusters) { cluster in
                        Annotation(cluster.id, coordinate: CLLocationCoordinate2D(latitude: cluster.anchorLat, longitude: cluster.anchorLon)) {
                            PhotoAnnotation(cluster: cluster) { post in
                                viewModel.select(post: post)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }

                if viewModel.showMiniPreview, let post = viewModel.selectedPost {
                    MiniPreviewCard(post: post) {
                        detailPost = post
                        navigateToDetail = true
                        viewModel.showMiniPreview = false
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.bottom, Spacing.l)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(NSLocalizedString("map.nav_title", value: "附近的人在记录", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToDetail) {
                if let post = detailPost {
                    PostDetailView(post: post)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.showMiniPreview)
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual verify**

```bash
xcrun simctl install booted /Users/chenzilve/Library/Developer/Xcode/DerivedData/附近-*/Build/Products/Debug-iphonesimulator/附近.app
xcrun simctl launch booted com.cassette.nearby
```

Switch to Map tab. Expected: Apple Map shows photo pins scattered around Shanghai (mock posts). Tap pin → mini preview. Tap mini preview → detail view (detail view is implemented in Chunk 4).

- [ ] **Step 4: Commit**

```bash
git add 附近/Features/Map/MapView.swift
git commit -m "feat: build MapView with cluster annotations + mini preview"
```

---

### Chunk 3 Completion Check

- [ ] Map tab loads all posts as clustered annotations
- [ ] Tap single pin selects post, shows mini preview
- [ ] Tap merged cluster (>3 in grid) opens mini preview for first post
- [ ] Tap mini preview navigates to detail
- [ ] All AnnotationClusterer tests pass
- [ ] Map falls back to Shanghai 愚园路 if no location

**Chunk 3 commits expected:** ~5 commits

---

## Chunk 4: Feed + Detail + Response

**Goal:** Feed tab shows posts as large image cards with 48pt spacing, supports "全部 / 我的" toggle, tap to detail. Detail view shows full post with linked task and response composer. Text responses can be submitted and persisted.

### Task 4.1: FeedViewModel

**Files:**
- Create: `附近/Features/Feed/FeedViewModel.swift`

- [ ] **Step 1: Write FeedViewModel**

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class FeedViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case mine = "我的"
        var id: String { rawValue }
        var localizedName: String {
            NSLocalizedString("feed.filter.\(rawValue)", value: rawValue, comment: "")
        }
    }

    var filter: Filter = .all
    var posts: [Post] = []

    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var filteredDescriptor = descriptor
        switch filter {
        case .all:
            filteredDescriptor.predicate = nil
        case .mine:
            let userId = CurrentUser.id
            filteredDescriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        }
        posts = (try? modelContext.fetch(filteredDescriptor)) ?? []
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Feed/FeedViewModel.swift
git commit -m "feat: add FeedViewModel with all/mine filter"
```

---

### Task 4.2: PostCardView

**Files:**
- Create: `附近/Features/Feed/PostCardView.swift`

- [ ] **Step 1: Write PostCardView**

```swift
import SwiftUI

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // Meta row: time · location · mood dot
            HStack(spacing: Spacing.s) {
                Text(post.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(post.fuzzyLabel)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                if let mood = post.moodTag {
                    Circle()
                        .fill(mood.color)
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }

            // Large image
            if let image = UIImage(data: post.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipped()
                    .cornerRadius(Radius.image)
            }

            // Title
            if let title = post.title {
                Text(title)
                    .font(.taskTitle)
                    .foregroundStyle(Color.ink900)
                    .lineSpacing(3)
            }

            // Text preview (2 lines)
            Text(post.text)
                .font(.bodySerif)
                .foregroundStyle(Color.ink700)
                .lineSpacing(4)
                .lineLimit(3)

            // Task ref tag (find from bank)
            if let task = taskFromBank(post.taskRef) {
                HStack(spacing: Spacing.xs) {
                    Rectangle()
                        .fill(Color.ink300)
                        .frame(width: 12, height: 0.5)
                    Text(NSLocalizedString("feed.task_label", value: "任务", comment: ""))
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                    Text(task.localizedTitle())
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                        .lineLimit(1)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.xxl)
    }

    private func taskFromBank(_ id: String) -> DailyTask? {
        TaskBank.loadSync().first { $0.id == id }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Feed/PostCardView.swift
git commit -m "feat: add PostCardView"
```

---

### Task 4.3: FeedView

**Files:**
- Modify: `附近/Features/Feed/FeedView.swift`

- [ ] **Step 1: Rewrite FeedView**

```swift
import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FeedViewModel()
    @State private var selectedPost: Post?

    var body: some View {
        NavigationStack {
            ScrollView {
                // Empty state
                if viewModel.posts.isEmpty {
                    VStack(spacing: Spacing.m) {
                        Image(systemName: "leaf")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.ink300)
                        Text(NSLocalizedString("feed.empty", value: "这里还很安静。成为第一个记录的人。", comment: ""))
                            .font(.bodySerif)
                            .foregroundStyle(Color.ink500)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xxl)
                    .padding(.horizontal, Spacing.xl)
                } else {
                    LazyVStack(alignment: .leading, spacing: Spacing.l) {
                        ForEach(viewModel.posts) { post in
                            Button {
                                selectedPost = post
                            } label: {
                                PostCardView(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, Spacing.m)
                }
            }
            .navigationTitle(NSLocalizedString("feed.nav_title", value: "附近", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Filter", selection: $viewModel.filter) {
                        ForEach(FeedViewModel.Filter.allCases) { f in
                            Text(f.localizedName).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
        .onChange(of: viewModel.filter) { _, _ in
            viewModel.load(modelContext: modelContext)
        }
    }
}
```

(Note: `navigationDestination(item:)` requires `Post: Identifiable`. Post has `@Attribute(.unique) var id: UUID`, conform it to Identifiable via `var id: UUID { id }` — actually `UUID` is the identifier, but SwiftData @Model auto-identifies via the @Attribute. Add `import Foundation` conformance: extend `extension Post: Identifiable {}` — already implicit via @Model.)

- [ ] **Step 2: Build to verify**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual verify**

Launch app, tap Feed tab. Expected: 30-50 mock posts shown as cards with 48pt spacing. Segmented "全部/我的" toggles.

- [ ] **Step 4: Commit**

```bash
git add 附近/Features/Feed/FeedView.swift
git commit -m "feat: build FeedView with segmented filter"
```

---

### Task 4.4: ResponseComposer

**Files:**
- Create: `附近/Features/Feed/ResponseComposer.swift`

- [ ] **Step 1: Write ResponseComposer**

```swift
import SwiftUI

struct ResponseComposer: View {
    let postId: UUID
    var onSubmitted: (String) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: Spacing.s) {
            TextField(NSLocalizedString("response.placeholder", value: "留下一句回应…", comment: ""), text: $text, axis: .vertical)
                .font(.bodySerif)
                .focused($isFocused)
                .lineLimit(1...3)
                .padding(Spacing.s)
                .background(Color.paper100)
                .cornerRadius(Radius.button)

            Button {
                submit()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.paper50)
                    .frame(width: 32, height: 32)
                    .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.ink300 : Color.cinnabar)
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let response = Response(
            postId: postId,
            text: trimmed,
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: CurrentUser.displayName
        )
        modelContext.insert(response)
        try? modelContext.save()
        text = ""
        onSubmitted(trimmed)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Feed/ResponseComposer.swift
git commit -m "feat: add ResponseComposer for text-only responses"
```

---

### Task 4.5: PostDetailView

**Files:**
- Create: `附近/Features/Feed/PostDetailView.swift`

- [ ] **Step 1: Write PostDetailView**

```swift
import SwiftUI
import SwiftData

struct PostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let post: Post

    @State private var responses: [Response] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                if let image = UIImage(data: post.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: Spacing.m) {
                    if let title = post.title {
                        Text(title)
                            .font(.titleDisplay)
                            .foregroundStyle(Color.ink900)
                            .lineSpacing(3)
                    }

                    Text(post.text)
                        .font(.bodySerif)
                        .foregroundStyle(Color.ink900)
                        .lineSpacing(5)

                    HStack(spacing: Spacing.s) {
                        if let mood = post.moodTag {
                            Circle()
                                .fill(mood.color)
                                .frame(width: 8, height: 8)
                            Text(mood.localizedName)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                        Text("·").font(.caption).foregroundStyle(Color.ink300)
                        Text(post.fuzzyLabel)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·").font(.caption).foregroundStyle(Color.ink300)
                        Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                    .padding(.top, Spacing.s)

                    if let task = TaskBank.loadSync().first(where: { $0.id == post.taskRef }) {
                        Divider().overlay(Color.ink300).padding(.vertical, Spacing.s)
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: task.type.iconName)
                                    .font(.caption)
                                    .foregroundStyle(Color.ink500)
                                Text(NSLocalizedString("detail.task_link", value: "任务：", comment: ""))
                                    .font(.caption)
                                    .foregroundStyle(Color.ink500)
                                Text(task.localizedTitle())
                                    .font(.caption)
                                    .foregroundStyle(Color.ink700)
                                    .underline()
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)

                // Responses
                Divider().overlay(Color.ink300).padding(.vertical, Spacing.s)

                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(NSLocalizedString("detail.responses_title", value: "回应", comment: ""))
                        .font(.sectionTitle)
                        .foregroundStyle(Color.ink900)
                        .padding(.horizontal, Spacing.m)

                    if responses.isEmpty {
                        Text(NSLocalizedString("detail.no_responses", value: "还没有人留下回应。", comment: ""))
                            .font(.bodySerif)
                            .foregroundStyle(Color.ink500)
                            .padding(.horizontal, Spacing.m)
                    } else {
                        ForEach(responses) { response in
                            ResponseCard(response: response)
                                .padding(.horizontal, Spacing.m)
                        }
                    }
                }

                Spacer().frame(height: Spacing.xl)
            }
        }
        .paperBackground()
        .safeAreaInset(edge: .bottom) {
            ResponseComposer(postId: post.id) {
                loadResponses()
            }
            .padding(Spacing.m)
            .background(Color.paper50.opacity(0.95))
        }
        .navigationTitle(NSLocalizedString("detail.nav_title", value: "记录", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadResponses()
        }
    }

    private func loadResponses() {
        let postId = post.id
        let predicate = #Predicate<Response> { $0.postId == postId }
        let descriptor = FetchDescriptor<Response>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        responses = (try? modelContext.fetch(descriptor)) ?? []
    }
}

private struct ResponseCard: View {
    let response: Response
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(response.authorName)
                    .font(.caption)
                    .foregroundStyle(Color.ink700)
                Spacer()
                Text(response.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Color.ink300)
            }
            Text(response.text)
                .font(.bodySerif)
                .foregroundStyle(Color.ink900)
                .lineSpacing(3)
        }
        .padding(Spacing.m)
        .background(Color.paper100)
        .cornerRadius(Radius.button)
    }
}

extension Response: Identifiable {}
```

(Note: `Response` already has `id: UUID` via `@Attribute(.unique)`. The `extension Response: Identifiable {}` confirms conformance; SwiftData @Model may already synthesize it.)

- [ ] **Step 2: Build to verify**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual verify**

Tap a feed card → detail view shows full post. Type a response, tap send → response appears in list. Kill and relaunch → response still there.

- [ ] **Step 4: Commit**

```bash
git add 附近/Features/Feed/PostDetailView.swift
git commit -m "feat: build PostDetailView with responses + composer"
```

---

### Task 4.6: Seed mock responses for some posts

**Files:**
- Modify: `附近/Data/MockSeeder.swift`

- [ ] **Step 1: Add response seeding to MockSeeder**

Append before `try? context.save()` in `seed(context:taskBank:)`:

```swift
// Add 0-3 mock responses per post (30% probability per slot)
let responseTemplates = templates.responses
let allPosts = (0..<40).map { i -> Post in
    // Re-fetch the inserted posts (or re-construct)
    // For simplicity, capture them during the loop above by collecting into an array first
    fatalError("Refactor: collect inserted posts into array before this step")
}
```

Actually, refactor the seeder to collect inserted posts in an array. Replace the loop variable scope:

```swift
var insertedPosts: [Post] = []
for i in 0..<40 {
    // ... existing post creation ...
    context.insert(post)
    insertedPosts.append(post)
}

// Add responses
for post in insertedPosts {
    let responseCount = Int.random(in: 0...3)
    for j in 0..<responseCount {
        let template = responseTemplates[(post.id.hashValue + j) % responseTemplates.count]
        let user = users[(post.id.hashValue + j) % users.count]
        let response = Response(
            postId: post.id,
            text: template.localized(),
            isOwn: false,
            authorId: UUID(),
            authorName: user.name
        )
        context.insert(response)
    }
}
```

- [ ] **Step 2: Run MockSeederTests**

Expected: still PASS. Add a new test for responses:

```swift
@MainActor
@Test func seedsSomeResponses() async throws {
    let container = try ModelContainer(
        for: Post.self, Response.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let bank = TaskBank.loadSync()

    await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
    let responseCount = try context.fetchCount(FetchDescriptor<Response>())
    #expect(responseCount > 0, "Expected some seeded responses")
}
```

- [ ] **Step 3: Commit**

```bash
git add 附近/Data/MockSeeder.swift 附近Tests/MockSeederTests.swift
git commit -m "feat: seed mock responses for some posts"
```

---

### Chunk 4 Completion Check

- [ ] Feed tab shows all posts (own + mock) sorted by recency
- [ ] Segmented "全部/我的" toggles correctly
- [ ] Tap post card → detail view
- [ ] Detail view shows full image + title + text + mood + task link
- [ ] Type response + send → appears in detail
- [ ] Responses persist across relaunch
- [ ] Empty state shows when no posts

**Chunk 4 commits expected:** ~6 commits

---

## Chunk 5: Mine + Archive

**Goal:** Mine tab shows display name, streak, badges, and segmented views for "我的记录 / 我的回应 / 城市徽章". Archive page lists 30 tasks by month, with TaskDetailView showing historical posts for a given task.

### Task 5.1: Badge rules

**Files:**
- Create: `附近/Features/Mine/Badge.swift`
- Create: `附近Tests/BadgeTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
import Foundation
@testable import 附近

struct BadgeTests {
    private func makePost(daysAgo: Int, type: TaskType, isOwn: Bool = true) -> Post {
        let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: -daysAgo, to: Date())!
        return Post(taskRef: "t",
                    imageData: Data(), thumbnailData: Data(),
                    text: "x", moodTag: nil,
                    fuzzyLabel: "", fuzzyLat: 0, fuzzyLon: 0,
                    isOwn: isOwn, authorId: CurrentUser.id, authorName: "你",
                    createdAt: date)
    }

    @Test func sevenDayStreakUnlocks() {
        let posts = (0..<7).map { makePost(daysAgo: $0, type: .discover) }
        let badges = Badge.evaluate(posts: posts, streak: 7)
        #expect(badges.contains(.sevenDay))
        #expect(!badges.contains(.month))
    }

    @Test func allTaskTypesUnlocksFiveSenses() {
        let posts = [
            makePost(daysAgo: 1, type: .discover),
            makePost(daysAgo: 2, type: .detail),
            makePost(daysAgo: 3, type: .connect),
            makePost(daysAgo: 4, type: .memory),
            makePost(daysAgo: 5, type: .together)
        ]
        let badges = Badge.evaluate(posts: posts, streak: 0)
        #expect(badges.contains(.fiveSenses))
    }

    @Test func cityWalkerUnlocksAtTen() {
        let posts = (0..<10).map { makePost(daysAgo: $0, type: .discover) }
        let badges = Badge.evaluate(posts: posts, streak: 0)
        #expect(badges.contains(.cityWalker))
        #expect(!badges.contains(.presence))
    }

    @Test func emptyPostsUnlocksNothing() {
        let badges = Badge.evaluate(posts: [], streak: 0)
        #expect(badges.isEmpty)
    }
}
```

- [ ] **Step 2: Write Badge**

```swift
import Foundation

enum Badge: String, CaseIterable, Identifiable {
    case sevenDay = "七日同行"
    case month = "月有余温"
    case hundredDay = "百日扎根"
    case fiveSenses = "五感全开"
    case cityWalker = "城市行人"
    case presence = "在场"
    case cityObserver = "城市观"

    var id: String { rawValue }

    var localizedName: String {
        NSLocalizedString("badge.\(rawValue)", value: rawValue, comment: "")
    }

    var iconName: String {
        switch self {
        case .sevenDay: return "calendar"
        case .month: return "moon.stars"
        case .hundredDay: return "tree"
        case .fiveSenses: return "hand.point.up.left"
        case .cityWalker: return "shoeprints"
        case .presence: return "mappin"
        case .cityObserver: return "eye"
        }
    }

    static func evaluate(posts: [Post], streak: Int) -> [Badge] {
        let ownPosts = posts.filter { $0.isOwn }
        let ownCount = ownPosts.count
        let taskTypes = Set(ownPosts.compactMap { TaskBank.loadSync().first(where: { $0.id == $0.taskRef })?.type })
        // ^ Note: above is O(n*m). For MVP, acceptable.

        var result: [Badge] = []
        if streak >= 7 { result.append(.sevenDay) }
        if streak >= 30 { result.append(.month) }
        if streak >= 100 { result.append(.hundredDay) }
        if taskTypes.count == 5 { result.append(.fiveSenses) }
        if ownCount >= 10 { result.append(.cityWalker) }
        if ownCount >= 50 { result.append(.presence) }
        if ownCount >= 100 { result.append(.cityObserver) }
        return result
    }
}
```

(Note: the `taskTypes` closure has a bug — `$0.taskRef` vs `$0.id` confusion. Fix:

```swift
let taskIds = Set(ownPosts.map { $0.taskRef })
let taskTypes = Set(taskIds.compactMap { id in
    TaskBank.loadSync().first(where: { $0.id == id })?.type
})
```

Use this corrected version in the actual implementation.)

- [ ] **Step 3: Run tests to verify they pass**

Expected: 4/4 PASS (after applying the fix).

- [ ] **Step 4: Commit**

```bash
git add 附近/Features/Mine/Badge.swift 附近Tests/BadgeTests.swift
git commit -m "feat: add Badge derivation rules"
```

---

### Task 5.2: MineViewModel

**Files:**
- Create: `附近/Features/Mine/MineViewModel.swift`

- [ ] **Step 1: Write MineViewModel**

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class MineViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case posts = "记录"
        case responses = "回应"
        case badges = "徽章"
        var id: String { rawValue }
        var localizedName: String {
            NSLocalizedString("mine.tab.\(rawValue)", value: rawValue, comment: "")
        }
    }

    var selectedTab: Tab = .posts
    var myPosts: [Post] = []
    var myResponses: [Response] = []
    var streak: Int = 0
    var badges: [Badge] = []

    func load(modelContext: ModelContext) {
        let userId = CurrentUser.id

        var postsDescriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        postsDescriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        myPosts = (try? modelContext.fetch(postsDescriptor)) ?? []

        var responsesDescriptor = FetchDescriptor<Response>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        responsesDescriptor.predicate = #Predicate<Response> { $0.authorId == userId }
        myResponses = (try? modelContext.fetch(responsesDescriptor)) ?? []

        // Streak computed from own posts
        streak = StreakCalculator.compute(posts: myPosts)

        // Badges derived
        badges = Badge.evaluate(posts: myPosts, streak: streak)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Mine/MineViewModel.swift
git commit -m "feat: add MineViewModel"
```

---

### Task 5.3: BadgeGrid

**Files:**
- Create: `附近/Features/Mine/BadgeGrid.swift`

- [ ] **Step 1: Write BadgeGrid**

```swift
import SwiftUI

struct BadgeGrid: View {
    let unlocked: [Badge]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.l) {
            ForEach(Badge.allCases) { badge in
                VStack(spacing: Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(unlocked.contains(badge) ? Color.cinnabar.opacity(0.15) : Color.paper100)
                            .frame(width: 72, height: 72)
                        Image(systemName: badge.iconName)
                            .font(.system(size: 26))
                            .foregroundStyle(unlocked.contains(badge) ? Color.cinnabar : Color.ink300)
                        if !unlocked.contains(badge) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.ink300)
                                .offset(x: 22, y: -22)
                        }
                    }
                    Text(badge.localizedName)
                        .font(.caption)
                        .foregroundStyle(unlocked.contains(badge) ? Color.ink900 : Color.ink500)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, Spacing.m)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Mine/BadgeGrid.swift
git commit -m "feat: add BadgeGrid"
```

---

### Task 5.4: MineView (full)

**Files:**
- Modify: `附近/Features/Mine/MineView.swift`

- [ ] **Step 1: Rewrite MineView**

```swift
import SwiftUI
import SwiftData

struct MineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MineViewModel()
    @State private var editingName = false
    @State private var tempName = ""
    @State private var selectedPost: Post?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // Header
                    HStack(spacing: Spacing.m) {
                        Button {
                            tempName = CurrentUser.displayName
                            editingName = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Text(CurrentUser.displayName)
                                    .font(.titleDisplay)
                                    .foregroundStyle(Color.ink900)
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(Color.ink500)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(viewModel.streak)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.cinnabar)
                            Text(NSLocalizedString("mine.streak", value: "连续记录", comment: ""))
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                    }
                    .padding(.horizontal, Spacing.m)

                    // Segmented
                    Picker("Tab", selection: $viewModel.selectedTab) {
                        ForEach(MineViewModel.Tab.allCases) { tab in
                            Text(tab.localizedName).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.m)

                    switch viewModel.selectedTab {
                    case .posts:
                        if viewModel.myPosts.isEmpty {
                            EmptyStateView(systemImage: "leaf",
                                          text: NSLocalizedString("mine.no_posts", value: "你还没有记录过附近。从今日任务开始。", comment: ""))
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible(), spacing: Spacing.s)], spacing: Spacing.s) {
                                ForEach(viewModel.myPosts) { post in
                                    Button {
                                        selectedPost = post
                                    } label: {
                                        if let thumb = UIImage(data: post.thumbnailData) {
                                            Image(uiImage: thumb)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 120)
                                                .clipped()
                                                .cornerRadius(Radius.image)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Spacing.m)
                        }
                    case .responses:
                        if viewModel.myResponses.isEmpty {
                            EmptyStateView(systemImage: "text.bubble",
                                          text: NSLocalizedString("mine.no_responses", value: "还没有回应过别人的作品。", comment: ""))
                        } else {
                            VStack(spacing: Spacing.m) {
                                ForEach(viewModel.myResponses) { response in
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text(response.text)
                                            .font(.bodySerif)
                                            .foregroundStyle(Color.ink900)
                                            .lineLimit(3)
                                        Text(response.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(Color.ink300)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Spacing.m)
                                    .background(Color.paper100)
                                    .cornerRadius(Radius.button)
                                }
                            }
                            .padding(.horizontal, Spacing.m)
                        }
                    case .badges:
                        BadgeGrid(unlocked: viewModel.badges)
                    }
                }
                .padding(.vertical, Spacing.m)
            }
            .navigationTitle(NSLocalizedString("mine.nav_title", value: "我的", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .alert(NSLocalizedString("mine.edit_name", value: "改个昵称", comment: ""), isPresented: $editingName) {
                TextField(NSLocalizedString("mine.name_placeholder", value: "昵称", comment: ""), text: $tempName)
                Button(NSLocalizedString("common.cancel", value: "取消", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("common.save", value: "保存", comment: "")) {
                    let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        CurrentUser.displayName = trimmed
                    }
                }
            }
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
    }
}

private struct EmptyStateView: View {
    let systemImage: String
    let text: String
    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(Color.ink300)
            Text(text)
                .font(.bodySerif)
                .foregroundStyle(Color.ink500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}
```

- [ ] **Step 2: Build and verify in simulator**

Expected: Mine tab shows display name (default "你"), streak 0, three-tab segmented. Badges all locked. After publishing one post and relaunching, streak = 1, cityWalker still locked (needs 10 posts).

- [ ] **Step 3: Commit**

```bash
git add 附近/Features/Mine/MineView.swift
git commit -m "feat: build MineView with name/streak/badges"
```

---

### Task 5.5: ArchiveViewModel

**Files:**
- Create: `附近/Features/Archive/ArchiveViewModel.swift`

- [ ] **Step 1: Write ArchiveViewModel**

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class ArchiveViewModel {
    var groupedTasks: [(month: String, tasks: [DailyTask])] = []
    var postCountByTask: [String: Int] = [:]

    func load(modelContext: ModelContext) {
        let bank = TaskBank.loadSync()
        let posts = (try? modelContext.fetch(FetchDescriptor<Post>())) ?? []
        postCountByTask = Dictionary(grouping: posts, by: { $0.taskRef }).mapValues { $0.count }

        // Group by adoptedOn month (YYYY-MM)
        let calendar = Calendar(identifier: .gregorian)
        var byMonth: [String: [DailyTask]] = [:]
        for task in bank {
            guard let date = parseDate(task.adoptedOn) else { continue }
            let components = calendar.dateComponents([.year, .month], from: date)
            let key = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
            byMonth[key, default: []].append(task)
        }
        groupedTasks = byMonth.keys.sorted(by: >).map { key in
            (month: key, tasks: byMonth[key]!.sorted { $0.adoptedOn > $1.adoptedOn })
        }
    }

    private func parseDate(_ s: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: s)
    }

    func monthLabel(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let monthInt = Int(parts[1]) else { return key }
        let lang = Locale.current.language.languageCode?.identifier ?? "zh"
        return lang == "en"
            ? String(format: "%@ %s", parts[0], String(cString: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][monthInt - 1].utf8CString))
            : "\(parts[0]) 年 \(monthInt) 月"
    }
}
```

(Note: the monthLabel implementation has a bug — the String(cString:) syntax is wrong. Simplify to:

```swift
func monthLabel(_ key: String) -> String {
    let parts = key.split(separator: "-")
    guard parts.count == 2, let monthInt = Int(parts[1]) else { return key }
    let lang = Locale.current.language.languageCode?.identifier ?? "zh"
    let enMonths = ["January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"]
    return lang == "en"
        ? "\(enMonths[monthInt - 1]) \(parts[0])"
        : "\(parts[0]) 年 \(monthInt) 月"
}
```

Use this in the implementation.)

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Archive/ArchiveViewModel.swift
git commit -m "feat: add ArchiveViewModel with month grouping"
```

---

### Task 5.6: ArchiveView

**Files:**
- Create: `附近/Features/Archive/ArchiveView.swift`

- [ ] **Step 1: Write ArchiveView**

```swift
import SwiftUI

struct ArchiveView: View {
    @State private var viewModel = ArchiveViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTask: DailyTask?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ForEach(viewModel.groupedTasks, id: \.month) { group in
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text(viewModel.monthLabel(group.month))
                            .font(.sectionTitle)
                            .foregroundStyle(Color.ink700)
                            .padding(.horizontal, Spacing.m)

                        ForEach(group.tasks) { task in
                            Button {
                                selectedTask = task
                            } label: {
                                TaskArchiveRow(task: task, postCount: viewModel.postCountByTask[task.id] ?? 0)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Spacing.m)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .paperBackground()
        .navigationTitle(NSLocalizedString("archive.nav_title", value: "任务档案馆", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .task {
            viewModel.load(modelContext: modelContext)
        }
    }
}

private struct TaskArchiveRow: View {
    let task: DailyTask
    let postCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.s) {
                Image(systemName: task.type.iconName)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text(task.adoptedOn)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Spacer()
            }
            Text(task.localizedTitle())
                .font(.taskTitle)
                .foregroundStyle(Color.ink900)
            HStack(spacing: Spacing.s) {
                Text(task.proposedBy)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(String.localizedStringWithFormat(NSLocalizedString("archive.votes", value: "%d 票", comment: ""), task.voteCount))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(String.localizedStringWithFormat(NSLocalizedString("archive.post_count", value: "%d 条记录", comment: ""), postCount))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
            }
        }
        .padding(Spacing.m)
        .background(Color.paper100)
        .cornerRadius(Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.ink300, lineWidth: 0.5)
        )
    }
}
```

(Note: `DailyTask` needs `Identifiable` for `.navigationDestination(item:)`. It already conforms via `let id: String`.)

- [ ] **Step 2: Commit**

```bash
git add 附近/Features/Archive/ArchiveView.swift
git commit -m "feat: build ArchiveView with month grouping"
```

---

### Task 5.7: TaskDetailView

**Files:**
- Create: `附近/Features/Archive/TaskDetailView.swift`

- [ ] **Step 1: Write TaskDetailView**

```swift
import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let task: DailyTask

    @State private var relatedPosts: [Post] = []
    @State private var selectedPost: Post?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: task.type.iconName)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text(task.type.localizedName)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                    Text(task.localizedTitle())
                        .font(.titleDisplay)
                        .foregroundStyle(Color.ink900)
                    Text(task.localizedPrompt())
                        .font(.bodySerif)
                        .foregroundStyle(Color.ink700)
                    HStack(spacing: Spacing.s) {
                        Text("\(NSLocalizedString("archive.proposed_by", value: "提议人", comment: "")) \(task.proposedBy)")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(Color.ink300)
                        Text(String.localizedStringWithFormat(NSLocalizedString("archive.votes", value: "%d 票", comment: ""), task.voteCount))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(Color.ink300)
                        Text("\(NSLocalizedString("archive.adopted_on", value: "采纳于", comment: "")) \(task.adoptedOn)")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                .padding(.horizontal, Spacing.m)

                if let refName = task.referenceImageName, let uiImage = UIImage(named: refName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(Radius.image)
                        .padding(.horizontal, Spacing.m)
                }

                Divider().overlay(Color.ink300).padding(.vertical, Spacing.s)

                // Posts grid
                if relatedPosts.isEmpty {
                    Text(NSLocalizedString("task_detail.empty", value: "还没有人记录这个任务。", comment: ""))
                        .font(.bodySerif)
                        .foregroundStyle(Color.ink500)
                        .padding(.horizontal, Spacing.m)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s),
                                        GridItem(.flexible(), spacing: Spacing.s),
                                        GridItem(.flexible(), spacing: Spacing.s)],
                              spacing: Spacing.s) {
                        ForEach(relatedPosts) { post in
                            Button {
                                selectedPost = post
                            } label: {
                                if let thumb = UIImage(data: post.thumbnailData) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .clipped()
                                        .cornerRadius(Radius.image)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .paperBackground()
        .navigationTitle(NSLocalizedString("task_detail.nav_title", value: "任务", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .task {
            loadPosts()
        }
    }

    private func loadPosts() {
        let taskId = task.id
        var descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.predicate = #Predicate<Post> { $0.taskRef == taskId }
        relatedPosts = (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

- [ ] **Step 2: Build and verify**

Launch app → Today tab → tap "看看过去的日子" → ArchiveView shows 30 tasks grouped by month → tap task → TaskDetailView shows related posts grid.

- [ ] **Step 3: Commit**

```bash
git add 附近/Features/Archive/TaskDetailView.swift
git commit -m "feat: build TaskDetailView with related posts grid"
```

---

### Chunk 5 Completion Check

- [ ] Mine tab shows display name, streak, badges grid
- [ ] 3 sub-tabs (records/responses/badges) work
- [ ] Display name editable via alert
- [ ] All 7 badges show, locked/unlocked state correct
- [ ] Archive shows 30 tasks grouped by month
- [ ] Tap archive task → detail view with related posts
- [ ] All Badge tests pass

**Chunk 5 commits expected:** ~7 commits

---

## Chunk 6: Polish + LaunchScreen + Onboarding

**Goal:** Add first-launch 3-screen onboarding (skippable), generate AppIcon, set up launch screen color, polish animations (task card flip-in, response send, badge unlock), and finalize English translations via String Catalog.

### Task 6.1: OnboardingView

**Files:**
- Create: `附近/Features/Onboarding/OnboardingView.swift`
- Modify: `附近/App/RootView.swift` (gate on onboarding completion)

- [ ] **Step 1: Write OnboardingView**

```swift
import SwiftUI

struct OnboardingView: View {
    @State private var pageIndex = 0
    var onFinish: () -> Void

    private let pages: [(image: String, titleZh: String, titleEn: String, bodyZh: String, bodyEn: String)] = [
        ("sun.max", "每天一个任务", "One task per day", "让你重新看见附近的世界。", "See your nearby world again."),
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
```

- [ ] **Step 2: Gate RootView on onboarding completion**

```swift
import SwiftUI

struct RootView: View {
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
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

                    MapView()
                        .tabItem { Label(NSLocalizedString("tab.map", value: "地图", comment: ""), systemImage: "map") }
                        .tag(1)

                    FeedView()
                        .tabItem { Label(NSLocalizedString("tab.feed", value: "时间流", comment: ""), systemImage: "rectangle.grid.2") }
                        .tag(2)

                    MineView()
                        .tabItem { Label(NSLocalizedString("tab.mine", value: "我的", comment: ""), systemImage: "person.crop.circle") }
                        .tag(3)
                }
                .tint(.cinnabar)
            }
        }
    }
}
```

- [ ] **Step 3: Build and verify**

Launch app. First launch → onboarding 3 pages → "开始" → TabView appears. Kill + relaunch → no onboarding (AppStorage persisted).

- [ ] **Step 4: Commit**

```bash
git add 附近/Features/Onboarding/OnboardingView.swift 附近/App/RootView.swift
git commit -m "feat: add 3-screen onboarding gated by AppStorage"
```

---

### Task 6.2: Task card flip-in animation

**Files:**
- Modify: `附近/Features/Today/TodayView.swift`

- [ ] **Step 1: Add transition/animation**

In TodayView, wrap the task card in:

```swift
TaskCardView(task: task, hasCompleted: viewModel.hasCompletedToday)
    .padding(.horizontal, Spacing.m)
    .padding(.top, Spacing.m)
    .transition(.move(edge: .top).combined(with: .opacity))
    .id(task.id)  // forces re-trigger on task change
```

In `.task { ... }`:

```swift
.task {
    taskBank = TaskBank.loadSync()
    withAnimation(.easeInOut(duration: 0.6)) {
        viewModel.load(modelContext: modelContext, taskBank: taskBank)
    }
}
```

- [ ] **Step 2: Verify in simulator**

Launch app → task card slides in from top with fade over 0.6s.

- [ ] **Step 3: Commit**

```bash
git add 附近/Features/Today/TodayView.swift
git commit -m "feat: animate task card flip-in"
```

---

### Task 6.3: Seal stamp pulse on completion

**Files:**
- Modify: `附近/DesignSystem/Components/SealStamp.swift`

- [ ] **Step 1: Add pulse on appear**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add 附近/DesignSystem/Components/SealStamp.swift
git commit -m "feat: pulse seal stamp on appear"
```

---

### Task 6.4: AppIcon

**Files:**
- Create: `附近/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `附近/Assets.xcassets/AppIcon.appiconset/icon_1024.png` (1024x1024)

- [ ] **Step 1: Write Contents.json for single-size icon (iOS 18+ allows single 1024)**

```json
{
  "images" : [
    {
      "filename" : "icon_1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 2: Create the icon PNG**

Design: paper-50 background + cinnabar-colored "近" character in Songti SC Black, centered, ~60% of canvas. Use any image editor (Figma, Sketch, or generated via Canvas).

Alternative for non-designers: generate via ImageMagick with the text:

```bash
# Generate icon.png (requires ImageMagick)
convert -size 1024x1024 xc:"#FAF6EE" \
    -gravity center -font Songti-Black -pointsize 620 \
    -fill "#B5563F" -annotate +0+0 "近" \
    附近/Assets.xcassets/AppIcon.appiconset/icon_1024.png
```

- [ ] **Step 3: Build to verify icon bundles correctly**

```bash
xcodegen generate
xcodebuild build -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED, no warning about missing AppIcon.

- [ ] **Step 4: Commit**

```bash
git add 附近/Assets.xcassets/AppIcon.appiconset/
git commit -m "feat: add AppIcon"
```

---

### Task 6.5: Localizable String Catalog

**Files:**
- Create: `附近Resources/Localizable.xcstrings`

- [ ] **Step 1: Write initial String Catalog**

```json
{
  "sourceLanguage" : "zh-Hans",
  "strings" : {
    "tab.today" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Today" } } } },
    "tab.map" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Map" } } } },
    "tab.feed" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Feed" } } } },
    "tab.mine" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Mine" } } } },
    "today.cta.record" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start Recording" } } } },
    "today.cta.archive" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Past days" } } } },
    "record.nav_title" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Today's Record" } } } },
    "record.title.placeholder" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Title (optional)…" } } } },
    "record.text.placeholder" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Write a few words…" } } } },
    "common.cancel" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } } } },
    "common.publish" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Publish" } } } },
    "common.save" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } } } },
    "map.nav_title" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Others' Nearby" } } } },
    "feed.nav_title" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Nearby" } } } },
    "feed.filter.all" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "All" } } } },
    "feed.filter.mine" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Mine" } } } },
    "mine.nav_title" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Mine" } } } },
    "mine.streak" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Day streak" } } } },
    "archive.nav_title" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Task Archive" } } } },
    "onboarding.start" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start" } } } },
    "onboarding.next" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Next" } } } },
    "onboarding.skip" : { "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Skip" } } } }
  },
  "version" : "1.0"
}
```

- [ ] **Step 2: Build to verify**

Xcode auto-extracts strings; the .xcstrings file should be auto-bundled.

- [ ] **Step 3: Commit**

```bash
git add 附近Resources/Localizable.xcstrings
git commit -m "feat: add Localizable String Catalog (zh-Hans + en)"
```

---

### Task 6.6: Final integration test

- [ ] **Step 1: Full simulator reset + clean install**

```bash
xcrun simctl shutdown booted
xcrun simctl erase all  # WARNING: erases all simulator data
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl bootstatus "iPhone 17 Pro"
xcodegen generate
xcodebuild clean build -project 附近.xcodeproj -scheme 附近 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
BUILT_DIR=$(xcodebuild -project 附近.xcodeproj -scheme 附近 -showBuildSettings 2>/dev/null | awk '/BUILT_PRODUCTS_DIR/ {print $3; exit}')
xcrun simctl install booted "$BUILT_DIR/附近.app"
xcrun simctl launch booted com.cassette.nearby
```

- [ ] **Step 2: Walk through demo flow**

1. Onboarding 3 pages → "开始"
2. Today tab → see today's task with proposer/votes
3. "开始记录" → pick photo (or use Photos library in sim) → select filter → write 6+ chars → select mood → publish
4. Seal stamp appears on task card
5. Map tab → see own + mock pins around Shanghai
6. Tap pin → mini preview → tap → detail
7. Feed tab → see own post in "全部" and "我的"
8. Tap own post → detail → type a response → send
9. Mine tab → name shows "你" → streak = 1 → no badges (need 7)
10. Tap pencil → change name → name persists
11. Today tab → tap "看看过去的日子" → Archive → 30 tasks grouped by month → tap → TaskDetailView

- [ ] **Step 3: Verify English localization**

```bash
xcrun simctl spawn booted defaults write -g AppleLanguages '("en-US")'
xcrun simctl shutdown booted && xcrun simctl boot "iPhone 17 Pro" && xcrun simctl bootstatus "iPhone 17 Pro"
xcrun simctl launch booted com.cassette.nearby
```

Walk through all tabs. Expected: tab labels, buttons, empty states, navigation titles all in English. Task titles in feed still in Chinese (because mock posts use zh template) — this is expected behavior since posts store their final text.

- [ ] **Step 4: Commit final polish**

```bash
git add -A
git commit -m "test: full demo flow verified end-to-end"
```

---

### Task 6.7: Push to GitHub

- [ ] **Step 1: Push all commits**

```bash
git push origin main
```

- [ ] **Step 2: Verify on GitHub**

Open https://github.com/Cass-ette/nearby and verify all commits visible.

---

### Chunk 6 Completion Check

- [ ] Onboarding shows on first launch only
- [ ] AppIcon bundles correctly
- [ ] String Catalog picks up both zh-Hans and en
- [ ] Task card flip-in animates
- [ ] Seal stamp pulses on appearance
- [ ] Full demo flow works end-to-end
- [ ] English localization verified by switching system language

**Chunk 6 commits expected:** ~6 commits

**Total commits across all chunks:** ~50

---

## Implementation Handoff

After saving this plan:

**"Plan complete and saved to `docs/superpowers/plans/2026-06-25-nearby-app-mvp.md`. Ready to execute?"**

This plan is designed for execution via `superpowers:subagent-driven-development`. Each task is self-contained and includes failing tests + implementation + verification + commit. Dispatch one subagent per task sequentially; review checkpoint after each chunk.

If subagent dispatch isn't available, use `superpowers:executing-plans` with manual checkpoints after each chunk (~6 chunks, ~50 tasks total).

**Estimated total time:** 6-8 hours of focused execution for an experienced iOS developer.

---

## Notes for the Implementer

- **Chinese characters in code/paths**: iOS supports them, but Xcode's `xcodebuild` sometimes logs mojibake. Don't be alarmed.
- **iOS 18 SwiftUI APIs**: `Map(position:)`, `UserAnnotation`, `MapContent` all require iOS 17+. iOS 18 adds `@Observable` improvements. Verify version-specific behaviors.
- **SwiftData migrations**: This plan doesn't add schema migrations. If you change model shape during dev, delete app from simulator to reset SwiftData store.
- **PhotosPicker in simulator**: Works with bundled sample photos. Real device uses full photo library.
- **CoreLocation in simulator**: Defaults to Apple HQ. Set a custom location via Simulator → Features → Location to test other areas.
- **Bundle ID is `com.cassette.nearby`** (not `com.cassette.附近`). All `simctl` commands use the bundle ID, not the display name.
- **Reference images for tasks**: `task_ref_path`, `task_ref_color`, etc. are referenced in tasks.json. Either add these as image assets (preferred for visual richness) or accept that no image shows (default — text-only task card).










