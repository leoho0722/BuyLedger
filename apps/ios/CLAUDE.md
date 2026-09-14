# iOS／iPadOS 平台指引

本檔記錄 `apps/ios` 隨時適用的硬規則與 gotcha；跨平台規範見根目錄 [`CLAUDE.md`](../../CLAUDE.md)，環境設定與 build／test 流程見本目錄 [`README.md`](README.md)。

只和特定目錄相關的規則放在根目錄 `.claude/rules/`，讀到相符檔案時自動載入：

| 規則檔 | 涵蓋 |
|---|---|
| `ios-data-layer.md` | 容器與注入、訂單寫入、跨檔不變式、生成型別、SwiftData 遷移 |
| `ios-navigation.md` | 根導覽與啟動、App 鎖定、呈現、焦點與鍵盤 |
| `ios-design-system.md` | Design System 結構、格式化與字級、色彩、系統元件 |
| `ios-accessibility-localization.md` | Dynamic Type、無障礙、本地化 |
| `ios-integrations.md` | 外部 API、EventKit |
| `ios-firebase-privacy.md` | Firebase、隱私清單、簽署設定 |
| `ios-unit-tests.md` | TestStore、守門測試、效能與 snapshot 測試 |
| `ios-ui-tests.md` | XCUITest |

## 技術棧 gotcha

- **`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`，不改成 `MainActor`**：`MainActor` 會讓 SwiftData `@Model` 與 `@ModelActor` 編不過；需要主執行緒的型別個別標 `@MainActor`。
- **TCA Reducer body 寫 `some Reducer<State, Action>`，不寫 `some ReducerOf<Self>`**：後者會 circular reference。
- **`IPHONEOS_DEPLOYMENT_TARGET = 18.0`，`ForEach` 吃 `enumerated()` 時一律包 `Array(x.enumerated())`**：`EnumeratedSequence` 遵循 `RandomAccessCollection` 需要 iOS 26，拿掉 `Array()` 會編不過。
- **`Feature.State` 上顯式標註的 `Sendable` 是編譯期契約，不可當冗餘刪除** (`SettingsFeature`／`FxFeature`／`QuoteFeature`／`OrderEditFeature`／`CampaignEditFeature`)：刪掉後 State 混入非 Sendable 成員也不會報錯，且沒有測試會轉紅。
    - 其餘 State 尚未統一標註是刻意保留的範圍，不要以此為由移除既有標註。
- **Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 除了 Context7 也對照 Apple docs MCP**；兩邊文件矛盾時列出差異與建議選項問使用者。

## 建置與開發指令

- **不退回原生 `xcodebuild`／`xcrun`／`simctl`**，明文例外只有兩個：
    - `agvtool` (版本管理不在 XcodeBuildMCP 能力範圍)。
    - CI (`.github/workflows/ci.yml`) 以 `npm install -g xcodebuildmcp@<釘選版本>` 安裝 CLI，之後所有 build 與 test 仍經它執行；升級 CLI 時同步更新 workflow 的釘選版本。
- **每次 build 或 build-and-run 前先 `cd apps/ios && agvtool next-version -all` 把 build number +1**，跑 test 不遞增 (test binary 不會安裝或散佈，遞增只製造 pbxproj 雜訊)。
    - 同一輪以 `&&` 串接的多平台 build 只遞增一次；遞增產生的 pbxproj 變更隨當次工作 commit，不丟棄。
- **改 marketing version 直接編輯 pbxproj 的 `MARKETING_VERSION`**：`agvtool new-marketing-version` 會報 Cannot find YES 且不更新 pbxproj (版號在 build settings，Info.plist 沒有版號 key)。
- **模擬器跑 App 用 `build-and-run`**，不先 `build` 再 `build-and-run`。
- **iOS 與 iPadOS simulator build 共用 `build.db`，要序列化 (`cmd1 && cmd2`)**：並行會 `database is locked`。
- **看詳細 build error 加 `xcodebuildmcp --log-level error <subcommand>`**，否則只回 `BUILD FAILED`。
- **模擬器以識別碼指定，先 `xcodebuildmcp simulator list-sims` 查可用清單**，不寫死名稱。
    - CI 找不到符合版本的執行環境時 job 要明確失敗，不退回舊版執行環境。
- **erase 模擬器是安全的復原手段**，不影響 `DatePicker` 的日期格式。
    - 進系統設定可用 `xcodebuildmcp ui-automation` (`simulator launch-app --bundle-id com.apple.Preferences` 後 `snapshot-ui`／`tap`)，不需要 `computer-use`；但設定頁的開關與滑桿不一定能取得 ref。
- **加 SPM 產品一律在 Xcode 操作，不手改 pbxproj**。
    - 原始碼直接具名使用 TCA 傳遞相依的 API (如 `@Shared`／`SharedKey`) 時，要把該套件產品加入 `BuyLedger` 與 `BuyLedgerTests` 的連結清單：只靠 `@_exported import` 會編譯通過、連結失敗 (`Undefined symbols ... nominal type descriptor`)。
    - 加入沒有宣告 traits 的套件 (如 `swift-sharing`) 後，Xcode 可能在其 `XCRemoteSwiftPackageReference` 插入空的 `traits = ( );`，使依賴解析失敗 (`Disabled default traits ... declares no traits`)；移除該套件的這個區塊即可 (`swift-composable-architecture` 本身有宣告 traits，同樣的空區塊合法、不要動)。
- **跑 snapshot 測試前把模擬器外觀鎖淺色** (`xcodebuildmcp simulator-management set-appearance --mode light`)：自動外觀入夜切深色會讓整批 baseline 誤判失敗。
- **UI 測試 (`BuyLedgerUITests`) 走獨立 scheme，只覆蓋 iOS 26.x 模擬器**：
    - `-only-testing` 跑 UI 測試要指定 `BuyLedgerUITests` scheme；該 target 不在 `BuyLedger` scheme 的 test plan 內，指定 `--scheme BuyLedger` 會回「isn't a member of the specified test plan or scheme」。
    - 跑全功能回歸不靠 `--extra-args -testPlan` (CLI 會忽略、退回 scheme 預設的效能計畫)，改用 `--extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests`；單一類別用 `-only-testing:BuyLedgerUITests/<類別>`。
    - 測試計畫：`BuyLedger.xctestplan` (單元測試，鎖 zh-Hant／TW、字母序執行)、`BuyLedgerUITests.xctestplan` (UI 主回歸，鎖 zh-Hant／TW、關閉隨機順序、排除效能測試)、`BuyLedgerUITests-Performance.xctestplan` (效能)；三份都只統計 App target 覆蓋率、不設門檻。
    - 訂單編輯表單 TextField 偶發「Activation point invalid」的 hittability 失敗屬環境雜訊：失敗的測試與元素在連續重跑間不一致即為雜訊，單獨重跑轉綠即可，不改測試碼或放寬斷言；同一條穩定重現才是真缺陷。
- **以 `xcodebuildmcp ui-automation` 驅動模擬器時不用 `type-text` 打數字**：它走 Mac 當前輸入法，注音模式會把數字轉成注音符號；`toggle-connect-hardware-keyboard` 需要未必已授權的輔助使用權限。UI 測試碼內的輸入用 `XCUIElement.typeText`。
- **macOS BSD `sed -E` 清尾隨空白用 `[[:space:]]+$`，不用 `[ \t]`**：`[ \t]` 會匹配字面的反斜線與 `t`，把行尾的 t 一起吃掉，落在註解或字串內時編譯器不會發現。

## 架構分層

- **`Core/` 與 `Shared/` 不引用 `Features/` 下的任何型別**：依賴只能向下。Core 需要的 API client 放 `Core/Networking/`，領域層的 fallback 表放 `Core/Domain/`。
    - 組裝根例外：`App/Testing/` 的 `BLUITest*` 認得所有 feature，與 `App/AppLaunchConfigurator` 同層，不放 Core。
    - 文件註解內以反引號引用 Feature 符號不算違規，只有程式碼依賴才算。
    - `LayerBoundaryTests` 動態掃描 `Core/` 與 `Shared/` 守門；`App/` 刻意不在掃描範圍。
- **綁 store 的畫面只吃自己 feature 的 scoped store**：跨 feature 資料走根 feature 單向同步的唯讀投影，跨 feature 意圖以 delegate action 轉發到根 feature 既有的導覽 case，不新增平行的根 case；純顯示值 (如目前的 App 語言) 走建構參數。
    - 可宣告根 store 的只有四個導覽宿主 `RootView`／`RootTabLayout`／`RootSidebarLayout`／`MoreView`，由 `LayerBoundaryTests.rootStoreDeclarationsMatchTheNavigationHostWhitelist` 鎖住。
    - 投影的變更監看集中在 `RootFeature.body` 尾端的連續 `onChange(of:)`；漏掛一條會讓畫面顯示舊資料而不易察覺。
- **商業邏輯與資料計算 (彙總、分組、排序、格式化) 放 reducer 或可測試的 helper**，View (含 Swift Charts) 只負責呈現。
- **大型 reducer 以同域輔助型別拆分，不拆成子 reducer**：無 case 的 enum (如 `OrdersFilterOperations`) 只放 `static func`，以 `inout State` 與明確參數溝通。
    - 輔助型別不宣告 `@Dependency`，也不呼叫 `Date()`／`UUID()`／`Calendar.current`，由 reducer 解析後傳入；被它跨檔呼叫的 State 方法或靜態工廠要是 internal。
    - 主 switch 維持窮舉、零預設分支 (`TestSuiteIntegrityTests` 守門，不得改寫成 `default:` 換行再 `return .none` 等規避形式)；因型別檢查逾時拆成多段 `Reduce` 時，段間以明列的 case 清單交出，不用預設分支。
    - 草稿型別標 `@ObservableState` (只標 `Equatable` 會退化成整張表單重繪)；非同步載入的欄位不參與草稿相等比較，另以旗標追蹤。
- **使用者可見訊息與診斷輸出不內插完整 URL 或 `URLRequest`** (含 `absoluteString`／`description` 等攤平存取)：避免憑證外洩；`TestSuiteIntegrityTests` 以子字串比對守門，改名後再內插等迂迴寫法仍要人工複核。
- **Reducer body 內呼叫 State 上的 instance method 走 `store.state.method(...)`**，不透過 `@dynamicMemberLookup` 的 `store.method(...)`。
- **不用 `switch`／`if` 運算式賦值** (`let x = switch …`)：先宣告 `let x: T` 再於各分支賦值；在 `@ViewBuilder` 內與 result builder 衝突時抽成 helper。
- **不為補註解新增顯式 `init`**：能用合成的 memberwise init 就用；只有需要 `@ViewBuilder` trailing closure、無標籤的語意化參數、驗證、轉換或相依注入時才寫。

## 環境相依性與依賴注入

- **Repository 以 type-based `@Dependency(SomeRepository.self)` 注入**，不新增 `DependencyValues` keyPath。
- **所有 repository 的 `liveValue` 共用 `PersistenceContainer.shared`，不各自建立 container**：同一 process 內多個 container (即使 SQLite 同名) 會讓 SwiftData 內部狀態錯亂；建立 container 的工廠函式維持 `private`。
- **`liveValue` 不 seed sample 資料**：首次啟動是真正的空狀態；`previewValue` 用 in-memory container 並傳 `seedSampleOrdersIfEmpty: true`，讓 Preview 與 snapshot 有內容。
    - `LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback`、`FxRates` 只給 Preview、單元測試與 `previewValue`，runtime path 不讀。
- **production code 走 `@Dependency`，不直接呼叫 `Date()`／`UUID()`／`Locale.current`／`TimeZone.current`／`Calendar.current`** (dependency 註冊處除外)。
    - Reducer 在 `// MARK: - Dependencies` 宣告 `@Dependency(\.date) private var date`，以 `date.now`、`uuid()` 取值；SwiftUI View 也可以同樣宣告。
    - State 的 computed property 不呼叫 `Date()`，改成 `func foo(referenceDate: Date)` 由 reducer 或 view 傳入注入後的值。
    - 測試：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；Calendar 相關測試固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)`。

## ios-dev-kit 規範與既有差異

- **程式風格、排版、MARK 分區與新檔樣板一律依 `/ios-dev-kit`**：分區見 `references/formatting.md`，TCA Feature 型別見 `references/tca-architecture.md`，新檔從 `assets/templates/` 複製 (樣板選擇表見 `references/file-templates.md`)。
    - codebase 仍有 `View Properties`／`Dependency Properties`／`ViewBuilder`／`Reducer Body` 等舊段名，新檔與新增分區不延續。
- **下列是本專案既有架構與 skill 的差異，新程式碼沿用現有寫法，直到另開 change 重構**：
    - Reducer body 型別用 `some Reducer<State, Action>` (見技術棧 gotcha)，不用樣板的 `some ReducerOf<Self>`。
    - `Core/Dependencies/` 以 Repository 包裝 SwiftData persistence；系統與網路能力以 struct-of-closures Client 註冊並宣告 `testValue` (如 `Core/Dependencies/` 的 `PhotoClient`、`CalendarReminderClient`，`Core/Networking/` 的 `ExchangeRateClient`)。skill 的 protocol Service、「不補 Repository」、「不宣告 `testValue`」不適用。
    - `@Shared` 用於主檔目錄 `@Shared(.lookupCatalog)` 的記憶體內共享 (規則見 `ios-data-layer.md`)。
    - `exhaustivity = .off` 有既有數處，由 `TestSuiteIntegrityTests` 限制總數不增加：新增一處必須同時移除他處。
    - 通用 extension 放 `Shared/Extensions/`，不是 `Core/Extensions/`。
    - 金額、百分比、日期格式化用 `BLFormatters`／`OrderFormatters`／`CampaignFormatters` 的靜態函式，不是 `FormatStyle`。
    - `OrdersFeaturePerformanceTests` 維持 XCTest，其餘單元測試用 Swift Testing。

## 已裁定的產品決策

- **App 沒有資料匯出或備份出口，store 維持系統預設檔案保護等級 (裝置首次解鎖後可讀)**：store 含客戶姓名、備註與照片，此取捨由使用者裁定並接受，不是疏漏。
    - 未記錄的省略不得僅因無人反對就視為已接受，本條即是該項記錄。
    - store 開不起來時的救援是 `PersistenceFailureFeature` 把檔案搬到隔離備份目錄，不依賴匯出功能。
