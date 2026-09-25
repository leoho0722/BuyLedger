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

- **不退回原生 `xcodebuild`／`xcrun`／`simctl`**，明文例外有三項：
    - `agvtool` (版本管理不在 XcodeBuildMCP 能力範圍)。
    - CI (`.github/workflows/ci.yml`) 以 `npm install -g xcodebuildmcp@<釘選版本>` 安裝 CLI，之後所有 build 與 test 仍經它執行；升級 CLI 時同步更新 workflow 的釘選版本。
    - `xcrun xcresulttool get test-results summary --path <bundle>` 僅用於唯讀讀取 result bundle 摘要 (XcodeBuildMCP 沒有等價指令)。
- **每次 build 或 build-and-run 前先 `cd apps/ios && agvtool next-version -all` 把 build number +1**，跑 test 不遞增 (test binary 不會安裝或散佈，遞增只製造 pbxproj 雜訊)。
    - 同一輪以 `&&` 串接的多平台 build 只遞增一次；遞增產生的 pbxproj 變更隨當次工作 commit，不丟棄。
- **改 marketing version 直接編輯 pbxproj 的 `MARKETING_VERSION`**：`agvtool new-marketing-version` 會報 Cannot find YES 且不更新 pbxproj (版號在 build settings，Info.plist 沒有版號 key)。
- **模擬器跑 App 用 `build-and-run`**，不先 `build` 再 `build-and-run`。
- **iOS 與 iPadOS simulator build 共用 `build.db`，要序列化 (`cmd1 && cmd2`)**：並行會 `database is locked`。
- **看詳細 build error 加 `xcodebuildmcp --log-level error <subcommand>`**，否則只回 `BUILD FAILED`。
- **模擬器以識別碼指定，先 `xcodebuildmcp simulator list` 查可用清單**，不寫死名稱。
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
    - 執行 iPad UI 主回歸前，必須確認模擬器的軟體鍵盤可顯示，也就是硬體鍵盤連線已斷開。實測證明 `xcodebuildmcp simulator-management toggle-connect-hardware-keyboard` 不可靠：它送出 `Cmd+Shift+K`，Simulator 不在前景時會無聲失效；直接寫入 `ConnectHardwareKeyboard` 偏好設定對已 booted 的裝置也無效。目前可靠的處置是在 Simulator 視窗手動按 `Cmd+Shift+K`，或從 I/O 選單取消勾選 Connect Hardware Keyboard。
    - 若回歸出現「數字鍵盤工具列的完成鍵未能收起鍵盤」，判別方式是看失敗時可及性樹的 `Keyboard` 元素 y 起點是否大於視窗高度；修正環境後，單獨執行 `KeyboardDismissTests` 兩條測試且兩條都綠，才算確認軟體鍵盤前提成立。這類現象不要先改產品端鍵盤工具列。
    - 測試計畫：`BuyLedger.xctestplan` (單元測試，鎖 zh-Hant／TW、字母序執行)、`BuyLedgerUITests.xctestplan` (UI 主回歸，鎖 zh-Hant／TW、關閉隨機順序、排除效能測試)、`BuyLedgerUITests-Performance.xctestplan` (效能)；三份都只統計 App target 覆蓋率、不設門檻。
    - 訂單編輯表單 TextField 偶發「Activation point invalid」的 hittability 失敗屬環境雜訊：失敗的測試與元素在連續重跑間不一致即為雜訊，單獨重跑轉綠即可，不改測試碼或放寬斷言；同一條穩定重現才是真缺陷。
- **以 `xcodebuildmcp ui-automation` 驅動模擬器時不用 `type-text` 打數字**：它走 Mac 當前輸入法，注音模式會把數字轉成注音符號；`toggle-connect-hardware-keyboard` 需要未必已授權的輔助使用權限。UI 測試碼內的輸入用 `XCUIElement.typeText`。
- **macOS BSD `sed -E` 清尾隨空白用 `[[:space:]]+$`，不用 `[ \t]`**：`[ \t]` 會匹配字面的反斜線與 `t`，把行尾的 t 一起吃掉，落在註解或字串內時編譯器不會發現。

## 架構分層

- **`Core/` 與 `Shared/` 不引用 `Features/` 下的任何型別**：依賴只能向下。Core 需要的 API client 放 `Core/Networking/`，領域層的 fallback 表放 `Core/Domain/`。
    - 組裝根例外：`App/Testing/` 的 `BLUITest*` 認得所有 feature，與 `App/AppLaunchConfigurator` 同層，不放 Core。
    - 文件註解內以反引號引用 Feature 符號不算違規，只有程式碼依賴才算。
    - `LayerBoundaryTests` 動態掃描 `Core/` 與 `Shared/` 守門；`App/` 刻意不在掃描範圍。
- **`Shared/DesignSystem/` 不得引用 `Core/Domain/` 的領域型別，也不得 import `ComposableArchitecture`**：可重用元件以 primitive 或 Design System 自有型別接收資料，架構相依由 Feature 端保留。
    - `LayerBoundaryTests` 會納入 `Core/Domain/Generated/` 的宣告名稱，並以變異驗證確認兩條守門真的會轉紅。
- **綁 store 的畫面只吃自己 feature 的 scoped store**：跨 feature 資料走根 feature 單向同步的唯讀投影，跨 feature 意圖以 delegate action 轉發到根 feature 既有的導覽 case，不新增平行的根 case；純顯示值 (如目前的 App 語言) 走建構參數。
    - 可宣告根 store 的只有四個導覽宿主 `RootView`／`RootTabLayout`／`RootSidebarLayout`／`MoreView`，由 `LayerBoundaryTests.rootStoreDeclarationsMatchTheNavigationHostWhitelist` 鎖住。
    - 投影的變更監看集中在 `RootFeature.body` 尾端的連續 `onChange(of:)`；漏掛一條會讓畫面顯示舊資料而不易察覺。
    - **父層不送出也不攔截子層的 `.view(...)` action**：子層畫面事件只由自己的 Feature 處理，父層不得以 `.send` 或 reducer case 包裝子層 `view` action。
    - **子層啟動所需資料在建立 State 時帶齊**：`BuyLedgerApp` 讀出的設定快照與 App 版本直接傳入 `SettingsFeature.State`，首幀不依賴額外的載入 action。
    - **跨 feature 意圖由子層以 delegate 請父層做事**：父層只把 delegate 轉發到既有 action，不新增平行的根 action。
- **商業邏輯與資料計算 (彙總、分組、排序、格式化) 放 reducer 或可測試的 helper**，View (含 Swift Charts) 只負責呈現。
- **Feature 超過 300 行依 `tca-architecture.md` 的拆分順序**：`Destination` 移到 `<Name>+Destination.swift` → 可獨立的流程抽成子 Feature 以 `Scope` 組合 (沒有自己 View 的子 Feature 不設 `view` 分組，由父層轉送，如 `QuoteRateFeature`、`PaymentMethodCorrectionFeature`)。重複的計算或讀寫分派收進同域輔助型別：純計算放無 case 的 enum，只放 `static func`，以 `inout State` 與明確參數溝通 (如 `OrdersFilterOperations`)；需要依賴的讀寫分派放持有依賴值的 struct，由 reducer 以自己的 `@Dependency` 建立 (如 `LookupItemOperations`)。
    - 輔助型別不宣告 `@Dependency`，也不呼叫 `Date()`／`UUID()`／`Calendar.current`，由 reducer 解析後傳入；被它跨檔呼叫的 State 方法或靜態工廠要是 internal。
    - 主 switch 維持窮舉、零預設分支 (`TestSuiteIntegrityTests` 守門，不得改寫成 `default:` 換行再 `return .none` 等規避形式)。
    - 因型別檢查逾時拆成多段 `Reduce` 時，段間以明列的 case 清單交出，不用預設分支，且每段一樣抽成具名方法 (見「ios-dev-kit 規範與既有差異」的 `Reduce(core)` 規則)。
    - 草稿型別標 `@ObservableState` (只標 `Equatable` 會退化成整張表單重繪)；非同步載入的欄位不參與草稿相等比較，另以旗標追蹤。
- **自訂錯誤型別以 `underlying` 保留原始錯誤，不遵循 `Equatable`**：帶底層失敗的 case 宣告 `underlying: any Error & Sendable`，純分類 case (如 `APIError.http(statusCode:)`) 維持原形狀。
    - **框架錯誤 (SwiftData、Foundation、EventKit、URL loading、`DecodingError`) 一律 `error as NSError` 橋接**：typed catch 拿到的是 `any Error`，`as NSError` 是唯一無條件成立且保留 domain、code、userInfo 的轉換。
    - **App 自己定義的錯誤原樣承載、不橋接** (目前只有 `RecordDecodingError`)：橋接會把結構化欄位壓成字串，呼叫端與測試就無法 pattern-match。
    - 不要為 App 自己判斷出的狀況偽造 `NSURLErrorDomain` 之類的框架 domain，需要可辨識的診斷碼時用自有 domain (如 `com.leoho.BuyLedger.networking`)。
    - 只有真的顯示給使用者的錯誤型別才遵循 `LocalizedError` (目前只有 `PersistenceRecoveryError`，經 `PersistenceFailureFeature` 以無型別 catch 取 `localizedDescription`)。
- **使用者可見訊息與診斷輸出不內插完整 URL 或 `URLRequest`** (含 `absoluteString`／`description` 等攤平存取)：避免憑證外洩；`TestSuiteIntegrityTests` 以子字串比對守門，改名後再內插等迂迴寫法仍要人工複核。
- **Reducer body 內呼叫 State 上的 instance method 走 `store.state.method(...)`**，不透過 `@dynamicMemberLookup` 的 `store.method(...)`。
- **不用 `switch`／`if` 運算式賦值** (`let x = switch …`)：先宣告 `let x: T` 再於各分支賦值；在 `@ViewBuilder` 內與 result builder 衝突時抽成 helper。
- **不為補註解新增顯式 `init`**：能用合成的 memberwise init 就用；只有需要 `@ViewBuilder` trailing closure、無標籤的語意化參數、驗證、轉換或相依注入時才寫。

## 環境相依性與依賴注入

- **Repository 以 type-based `@Dependency(SomeRepository.self)` 注入**，不新增 `DependencyValues` keyPath。
- **所有 repository 的 `liveValue` 共用 `PersistenceContainer.shared`，不各自建立 container**：同一 process 內多個 container (即使 SQLite 同名) 會讓 SwiftData 內部狀態錯亂；建立 container 的工廠函式維持 `private`。
- **`liveValue` 不 seed sample 資料**：首次啟動是真正的空狀態；`previewValue` 用 in-memory container 並傳 `shouldSeedSampleOrders: true`，讓 Preview 與 snapshot 有內容。
    - `LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback`、`FxRates` 只給 Preview、單元測試與 `previewValue`，runtime path 不讀。
- **production code 走 `@Dependency`，不直接呼叫 `Date()`／`UUID()`／`Locale.current`／`TimeZone.current`／`Calendar.current`** (dependency 註冊處除外)。
    - Reducer 在 `// MARK: - Dependencies` 宣告 `@Dependency(\.date) private var date`，以 `date.now`、`uuid()` 取值；SwiftUI View 也可以同樣宣告。
    - State 的 computed property 不呼叫 `Date()`，改成 `func foo(referenceDate: Date)` 由 reducer 或 view 傳入注入後的值。
    - 測試：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；Calendar 相關測試固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)`。

## ios-dev-kit 規範與既有差異

- **程式風格、排版、MARK 分區與新檔樣板一律依 `/ios-dev-kit`**：分區見 `references/formatting.md`，TCA Feature 型別見 `references/tca-architecture.md`，新檔從 `assets/templates/` 複製 (樣板選擇表見 `references/file-templates.md`)。
    - 新增或修改的 Swift 檔依 `/ios-dev-kit` 的固定 MARK 分區；尚未納入本 change 的既有 Feature 檔，留待各自的後續 change 處理。
    - `switch` 的 `case` 之間空一行 (`formatting.md`)；既有檔案多數仍是不空行，改到某個 `switch` 時整個 `switch` 一起改，同一個 `switch` 不混用兩種寫法。
- **SwiftUI View 不以跨檔 `extension` 作為超過 300 行的第一選擇**：跨檔 extension 無法存取同一 View 的 `private @State`／`private @Environment`；為了編譯而降為 `internal` 會破壞狀態封裝。超過 300 行時優先抽成獨立 View 型別並傳入必要值與 closure；確實抽不動時才在 `findings.md` 登記行數例外，寫明原因與使用者裁決。
- **檔頭日期一律不補零 `YYYY/M/D`** (如 `2026/9/20`)，不是 `file-templates.md` 的 `YYYY/MM/DD`：Xcode 新檔樣板產生的就是不補零格式，補零等於每個新檔都要手動改一次。
    - 檔頭其餘規則仍依 `file-templates.md`：四行結構、不加版權宣告與修改紀錄、建立後不再更新日期。
- **宣告的大括號本體一律換行，不壓成單行**：`guard ... else { return x }`、`var x: T { expr }`、`func f() -> T { expr }` 都要把本體與結尾大括號各自獨立一行。`formatting.md` 的 `guard let self else { return }` 與單行 closure 範例不適用於宣告本體；作為引數傳入的 inline closure (`map { $0.id }`) 不在此限。
- **屬性包裝器與宣告同行**：`@Dependency(X.self) private var x`，不拆成兩行；整行超過 100 字元時才換行。
- **由外部注入的 State 值用 `let` 且不給宣告處預設值**，只從 `init` 參數帶入 (如 `SettingsFeature.State.appVersion`)；宣告處放佔位值再於 `init` 覆寫會讓「未注入」與「注入了佔位值」無法區分。
- **不為了單一呼叫點抽出 helper method**：只被上方一個 computed property 使用的格式化邏輯直接寫在該 property 內 (如 `Bundle.appVersion`)。
- **reducer 的 `body` 只組合，不寫 `Reduce { state, action in }` 閉包**：分支主體抽成 `Private Method` 的第一個方法 `core(state:action:)`，`body` 寫 `Reduce(core)`。
    - 因型別檢查逾時而必須分段時 (見「架構分層」的多段 `Reduce` 規則)，每段各自抽成具名方法再以 `Reduce(段名)` 組合，不保留 inline closure。
- **一個檔只放一個頂層型別**：同檔多個型別會讓檔案層級的 `// MARK: - Internal Method` 等固定區名重複出現，Xcode jump bar 分不出歸屬。獨立 model 型別各自一檔；巢狀型別 (含 TCA 的 `State`／`Action`) 依 `formatting.md` 把成員就地寫在本體，不另開 extension。
    - 例外：`@Reducer enum` 的 `Destination.State` 由巨集產生，本體無法加成員，alert 建構方法與 `Equatable` 遵循寫在 `extension <Feature>.Destination.State` (如 `LookupManagementFeature+Destination.swift`)。
- **下列是本專案既有架構與 skill 的差異，新程式碼沿用現有寫法，直到另開 change 重構**：
    - Reducer body 型別用 `some Reducer<State, Action>` (見技術棧 gotcha)，不用樣板的 `some ReducerOf<Self>`。
    - `Core/Dependencies/` 的 Repository 與 Client 已是 struct 裝 closure，但尚未對齊 `tca-architecture.md` 的 Service 規則：命名 (`XxxRepository`／`XxxClient`，不是 `<Feature>Service`)、沒有每個 closure 的 typealias、`testValue` 不是全部 `unimplemented`、以型別下標取用 (`@Dependency(CategoryRepository.self)`、`$0[CategoryRepository.self]`) 而非 `DependencyValues` 屬性。整批改造另開 change，在此之前新程式碼沿用型別下標，不局部混用兩種寫法。
    - 既有的 `extension <Feature>.State` (如 `OrdersFeature+StateQuery.swift`) 尚未把成員移回 `State` 本體，於各 Feature 的修正步驟處理。
    - `@Shared` 用於主檔目錄 `@Shared(.lookupCatalog)` 的記憶體內共享 (規則見 `ios-data-layer.md`)。
    - `exhaustivity = .off` 有既有數處，由 `TestSuiteIntegrityTests` 限制總數不增加：新增一處必須同時移除他處。
    - 通用 extension 放 `Shared/Extensions/`，不是 `Core/Extensions/`。
    - 金額、百分比、日期格式化用 `BLFormatters`／`OrderFormatters`／`CampaignFormatters` 的靜態函式，不是 `FormatStyle`。
    - 測試方法名稱維持單段 lowerCamel，方法層 selector 以 `()` 精準選取，避免以底線拆成多段命名。
    - 設定寫入維持 reducer 內同步呼叫，讓連續輸入依序保存，避免非同步效果重排快照。
    - `OrdersFeaturePerformanceTests` 維持 XCTest，其餘單元測試用 Swift Testing。

## 已裁定的產品決策

- **App 沒有資料匯出或備份出口，store 維持系統預設檔案保護等級 (裝置首次解鎖後可讀)**：store 含客戶姓名、備註與照片，此取捨由使用者裁定並接受，不是疏漏。
    - 未記錄的省略不得僅因無人反對就視為已接受，本條即是該項記錄。
    - store 開不起來時的救援是 `PersistenceFailureFeature` 把檔案搬到隔離備份目錄，不依賴匯出功能。
