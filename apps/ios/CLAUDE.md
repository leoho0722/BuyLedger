# iOS／iPadOS 平台指引

本檔記錄 `apps/ios` 隨時適用的硬規則與 gotcha；跨平台規範見根目錄 [`CLAUDE.md`](../../CLAUDE.md)，環境設定與 build／test 流程見本目錄 [`README.md`](README.md)。

只和特定目錄相關的規則放在根目錄 `.claude/rules/`，讀到相符檔案時自動載入：

| 規則檔 | 涵蓋 |
| --- | --- |
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
- **`$store.draft.name` 這類巢狀欄位綁定，SwiftUI 會寫回整個 `draft`，送出 `.set(\.draft, …)`**：TCA 的 `BindingAction ~=` 要求 key path 完全相等，reducer 的 `.binding(\.draft.name)` 永遠不成立。
  - 要對單一欄位的變更反應時，在 State 加可寫的 computed property 並讓畫面綁定它 (開團表單的 `CampaignEditFeature.State.draftName`，reducer 比對 `.binding(\.draftName)`)；其他欄位的變更走 `case .binding:`。
- **`Feature.State` 上顯式標註的 `Sendable` 是編譯期契約，不可當冗餘刪除** (`SettingsFeature`／`FxFeature`／`QuoteFeature`／`OrderEditFeature`／`CampaignEditFeature`)：刪掉後 State 混入非 Sendable 成員也不會報錯，且沒有測試會轉紅。
  - 其餘 State 尚未統一標註是刻意保留的範圍，不要以此為由移除既有標註。
- **`MemberImportVisibility` 已開啟：只 `import ComposableArchitecture` 的檔 (如 reducer，不 `import SwiftUI`) 若寫 `TextState("…")` 字面值或插值，要另外 `import Foundation`**：字面值走 `LocalizedStringResource` 初始化器，缺 import 會編譯失敗。
  - `TextState` 一律直接寫字面值 (含插值)，不先組成 `String` 再傳入：`StringProtocol` 初始化器走 verbatim，不經本地化。
- **Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 除了 Context7 也以 Xcode 27 MCP 內建的 Apple Documentation Search (`DocumentationSearch`) 對照**；兩邊文件矛盾時列出差異與建議選項問使用者。

## 建置與開發指令

### 工具選擇

- **不退回原生 `xcodebuild`／`xcrun`／`simctl`**：`mobilebuildmcp` 做不到或無法使用時改用 Xcode 27 MCP (`mcp__xcode__*`)。原生指令的明文例外有三項：
  - 發版一律跑 `scripts/upload-testflight.sh` (以 `xcodebuild archive`／`-exportArchive` 打包上傳，MobileBuildMCP 沒有對應工具)，不另寫 xcodebuild 指令。
    - 腳本不遞增 build 號，執行前先提交版號；代為上傳前先取得使用者確認。
  - CI (`.github/workflows/ci.yml`) 以 `npm install -g mobilebuildmcp@<釘選版本>` 安裝 CLI，build 與 test 仍經它執行；升級 CLI 時同步更新釘選版本。
  - 唯讀讀取 result bundle 摘要用 `xcrun xcresulttool get test-results summary --path <bundle>` (MobileBuildMCP 與 Xcode MCP 都沒有等價工具)。
- **實測橫向畫面用 Xcode 27 MCP 的 `orientation` 指令**：`mobilebuildmcp` 沒有轉向指令，Device Hub 轉向不能驗證版面。
  - Xcode MCP 的裝置互動 (`DeviceInteraction*`) 只接受 iOS 27 以上的模擬器。
  - 前提與流程見 `.claude/rules/ios-ui-tests.md`「轉向測試」段；該檔只在碰到 UI 測試檔時自動載入，不寫 UI 測試的實測要主動讀。
- **會讓 Xcode 開啟 BuyLedger 的 Xcode MCP 工具 (如 `BuildProject`、`RunSomeTests`、`RenderPreview`) 用完要看 `git status --short`**：Xcode 開啟 BuyLedger 時可能刪除 `Package.resolved`。

### 專案檔與版號

- **每次 build 或 build-and-run 前把 `CURRENT_PROJECT_VERSION` +1，跑 test 不遞增**：test binary 不會安裝或散佈，遞增只製造雜訊。
  - 版號 (含 `MARKETING_VERSION`) 一律直接編輯 `project.xcproj`，App 與兩個測試 target 同步；不用 `agvtool` (寫死讀 `project.pbxproj`，不支援 JSON 格式)。
  - 同一輪以 `&&` 串接的多平台 build 只遞增一次；遞增的變更隨當次工作 commit，不丟棄。
- **加 SPM 產品直接編輯 `project.xcproj`**，改完以 `mobilebuildmcp` 建置確認套件解析與連結。
  - 原始碼直接具名使用 TCA 傳遞相依的 API (如 `@Shared`／`SharedKey`) 時，該套件產品要加入 `BuyLedger` 與 `BuyLedgerTests` 的連結清單：只靠 `@_exported import` 會編譯通過、連結失敗 (`Undefined symbols ... nominal type descriptor`)。

### 模擬器建置

- **跑 App 用 `build-and-run`**，不先 `build` 再 `build-and-run`。
- **iOS 與 iPadOS simulator build 共用 `build.db`，要序列化 (`cmd1 && cmd2`)**：並行會 `database is locked`。
- **看詳細 build error 加 `mobilebuildmcp --log-level error <subcommand>`**，否則只回 `BUILD FAILED`。
- **模擬器以識別碼指定，先 `mobilebuildmcp simulator list` 查**，不寫死名稱；CI 找不到符合版本的執行環境時 job 要明確失敗，不退回舊版。
- **erase 模擬器是安全的復原手段**，不影響 `DatePicker` 的日期格式。
- **跑 snapshot 測試前把外觀鎖淺色** (`mobilebuildmcp simulator-management set-appearance --mode light`)：自動外觀入夜切深色會讓整批 baseline 誤判失敗。

### UI 測試

- **`BuyLedgerUITests` 走獨立 scheme，只覆蓋 iOS 26.x 模擬器**：`-only-testing` 跑 UI 測試要指定 `BuyLedgerUITests` scheme，指定 `--scheme BuyLedger` 會回「isn't a member of the specified test plan or scheme」。
  - 全功能回歸用 `--extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests`，不靠 `--extra-args -testPlan` (CLI 會忽略、退回 scheme 預設的效能計畫)；單一類別用 `-only-testing:BuyLedgerUITests/<類別>`。
  - 測試計畫：`BuyLedger.xctestplan` (單元測試，鎖 zh-Hant／TW、字母序執行)、`BuyLedgerUITests.xctestplan` (UI 主回歸，鎖 zh-Hant／TW、關閉隨機順序、排除效能測試)、`BuyLedgerUITests-Performance.xctestplan` (效能)；三份都只統計 App target 覆蓋率、不設門檻。
- **iPad UI 主回歸前確認軟體鍵盤可顯示 (硬體鍵盤已斷開)，並先單獨跑 `KeyboardDismissTests`，兩條都綠才算前提成立**：
  - 優先在 Device Hub 未執行時以 `mobilebuildmcp simulator-management boot` 開機：不連接硬體鍵盤，也滿足轉向測試不可開 Device Hub 的條件 (見 `.claude/rules/ios-ui-tests.md`)。
  - 否則在 Device Hub 選單取消勾選 Device › Keyboard › Simulate Hardware Keyboard；模擬器重開機後會恢復勾選，每次都要重做。
  - `toggle-connect-hardware-keyboard` 不可靠：送出 `Cmd+Shift+K`，Simulator 不在前景時無聲失效，且需要未必已授權的輔助使用權限；寫入 `ConnectHardwareKeyboard` 偏好設定對已 booted 的裝置也無效。
  - 回歸出現「數字鍵盤工具列的完成鍵未能收起鍵盤」時，看失敗時可及性樹 `Keyboard` 元素的 y 起點是否大於視窗高度；這類現象先修環境，不改產品端鍵盤工具列。
- **訂單編輯表單 TextField 偶發的「Activation point invalid」屬環境雜訊**：失敗的測試與元素在連續重跑間不一致即為雜訊，單獨重跑轉綠即可，不改測試碼或放寬斷言；同一條穩定重現才是真缺陷。

### `ui-automation` 實測

- **不用 `type-text` 輸入**：它走 Mac 當前輸入法，注音模式會轉換數字與英文字母，中文字直接被拒絕 (只支援美式鍵盤字元)。
  - 數字改點軟體數字鍵盤的按鍵元素；UI 測試碼內的輸入用 `XCUIElement.typeText`。
- **`simulator launch-app` 會結束並重開 App**，不會把背景中的 App 帶回前景：驗證背景與前景改按 `ui-automation button --button-type lock`，再按兩次 `home` 喚醒並解鎖。
  - 一閃即過的畫面 (如自動解鎖) 用 `simulator record-video` 錄影逐格確認。
- **`--launch-args` 的純數字值會驗證失敗**，改用 `--json '{"launchArgs":[...]}'`；`-BLUITest` 模式的設定存在記憶體，驗證「重開後仍保留設定」要以正式模式啟動。
- **列位於分頁列範圍下方時 `touch` 會點到分頁列**，先捲動讓目標露出再點。
- **sheet 內 `List` 最後一列的 `touch`／`tap` 可能回報成功卻沒觸發** (同一 sheet 其他列正常)：改以 XCUITest 驗證 (正式 UI 測試，或量完即刪的暫時測試)，不反覆重試。
- **iPad 模擬器多工模式維持「全螢幕 App」**：「視窗 App」模式下 `snapshot-ui` 取不到可及性樹。
- **進系統設定用 `simulator launch-app --bundle-id com.apple.Preferences` 後 `snapshot-ui`／`tap`**，不需要 `computer-use`；設定頁的開關與滑桿不一定取得到 ref。

### 其他

- **macOS BSD `sed -E` 清尾隨空白用 `[[:space:]]+$`，不用 `[ \t]`**：`[ \t]` 會匹配字面的反斜線與 `t`，吃掉行尾的 t，落在註解或字串內時編譯器不會發現。

## 架構分層

### 依賴方向

- **`Core/` 與 `Shared/` 不引用 `Features/` 的任何型別**：依賴只能向下；Core 需要的 API client 放 `Core/Networking/`，領域層的 fallback 表放 `Core/Domain/`。
  - 組裝根例外：`App/Testing/` 的 `BLUITest*` 認得所有 feature，與 `App/AppLaunchConfigurator` 同層，不放 Core。
  - 只有程式碼依賴算違規，文件註解以反引號引用 Feature 符號不算。
  - `LayerBoundaryTests` 動態掃描 `Core/` 與 `Shared/` 守門，`App/` 刻意不掃。
- **`Shared/DesignSystem/` 不引用 `Core/Domain/` 的領域型別，也不 import `ComposableArchitecture`**：可重用元件以 primitive 或 Design System 自有型別接收資料，架構相依留在 Feature 端。
  - `LayerBoundaryTests` 納入 `Core/Domain/Generated/` 的宣告名稱，並以變異驗證確認兩條守門真的會轉紅。
- **商業邏輯與資料計算 (彙總、分組、排序、格式化) 放 reducer 或可測試的 helper**，View (含 Swift Charts) 只負責呈現。

### Feature 之間

- **綁 store 的畫面只吃自己 feature 的 scoped store**：跨 feature 資料走根 feature 單向同步的唯讀投影，純顯示值 (如目前的 App 語言) 走建構參數。
  - 只有 `RootView`／`RootTabLayout`／`RootSidebarLayout` 三個導覽宿主可宣告根 store，由 `LayerBoundaryTests.filesDeclaringRootStore_功能目錄_僅由三個根導覽宿主持有` 鎖住；`MoreView` 只持有 `MoreFeature` 的 scoped store。
  - 投影的變更監看集中在 `RootFeature.body` 尾端的連續 `onChange(of:)`，涵蓋訂單 (開團與「更多」的 `$orders`、總覽與分析的副本)、開團 (`orders.$campaigns`、總覽與分析的副本)、載入狀態、偏好 (`appLock.isBiometricUnlockEnabled`、`dashboard.monthlyProfitGoalTWD`、`more.preferences`、`orders.defaultCurrency`、`orders.aiSummarySettings`) 與辨識類型 (`more.biometryType`)；漏掛一條會讓畫面顯示舊資料而不易察覺。
- **跨 feature 意圖由子層 reducer 以 delegate 交給根 feature**：畫面只送自身 Feature 的 `view` action，由 reducer 轉成 delegate；Root 的 view case 與子層 delegate case 呼叫同一個 `RootNavigationOperations` 方法 (如 `showOrders(customer:state:)`、`showCampaign(named:state:)`)，不以 `.send` 轉成另一個根 case，也不新增平行的根 action。
- **父層不以 `.send` 或 reducer case 送出、攔截子層的 `.view(...)` action**。
- **父層要求子層載入或套用資料時送專用請求 action，子層是有 View 的容器也一樣**：請求只由父層送、子層 reducer 處理，不代替使用者互動。
  - Root 對 Orders 送 `rootRequest(OrdersRootRequest)` (`load`、`cascade`、`receiptStatusChange`、`paymentMethodFlagsApply`、`optionAdditionCompleted`)，由容器轉給載入、寫入或呈現子 Feature；需要父層處理的結果經 delegate 回報，其餘成功結果由共用資料觀察。
  - 例外：無 View 的呈現與導覽子 Feature (`OrdersPresentationFeature`、`OrdersDetailNavigationFeature`、`CampaignPresentationFeature`) 在同一次更新內必須完成的呈現與導覽 (Root 開新訂單、寫入結果關閉表單、顯示詳情、表單關閉收尾)，由容器直接呼叫子 State 的 `mutating` 方法；寫入失敗等一次性通知仍送 `noticeRequested` action，維持下一個 action 才呈現的時序。
- **子層啟動所需資料在建立 State 時帶齊，首幀不依賴額外的載入 action**：`BuyLedgerApp` 讀出的設定快照與 App 版本直接傳入 `RootFeature.State`；設定頁推入時由 `MoreFeature` 以偏好與辨識類型的投影建立 `SettingsFeature.State`。

### Reducer 與 State

- **Feature 過大、需要拆檔時依 `tca-architecture.md` 的拆分順序**：`Path`／`Destination` 移到 `<Name>+Path.swift`／`<Name>+Destination.swift` → 可獨立的流程抽成子 Feature 以 `Scope` 組合。
  - 沒有自己 View 的子 Feature 不設 `view` 分組，由父層轉送 (如 `QuoteRateFeature`、`PaymentMethodCorrectionFeature`、`OrdersPresentationFeature`、`RootLaunchFeature`)。
- **重複的計算或讀寫分派收進同域輔助型別**：
  - 純計算放無 case 的 enum，只放 `static func`，以 `inout State` 與明確參數溝通 (如 `OrdersFilterOperations`)。
  - 需要依賴的讀寫分派放持有依賴值的 struct，由 reducer 以自己的 `@Dependency` 建立 (如 `LookupItemOperations`)。
  - 需要 reducer 解析後的時間與行事曆的操作放持有這兩個值的 struct，由 reducer 以注入的 `date.now`、`calendar` 建立 (如 `RootNavigationOperations`)。
  - 輔助型別不宣告 `@Dependency`，也不呼叫 `Date()`／`UUID()`／`Calendar.current`，由 reducer 解析後傳入；被它跨檔呼叫的 State 方法或靜態工廠要是 internal。
  - 投影擁有者 (含 `OrdersFeature`、`CampaignFeature`) 的主檔以外不接收 `inout` 容器 State，也不外傳可寫的共享引用：輔助型別讀值快照並回傳計畫，由容器 reducer 套用，避免繞過投影與共享寫入守門。
- **主 switch 維持窮舉、零預設分支**：`TestSuiteIntegrityTests` 守門，不得改寫成 `default:` 換行再 `return .none` 等規避形式。
  - 因型別檢查逾時拆成多段 `Reduce` 時，段間以明列的 case 清單交出，不用預設分支；每段抽成具名方法，以 `Reduce(段名)` 組合。
- **草稿型別標 `@ObservableState`**：只標 `Equatable` 會退化成整張表單重繪；非同步載入的欄位不參與草稿相等比較，另以旗標追蹤。

### 錯誤與診斷訊息

- **自訂錯誤型別以 `underlying` 保留原始錯誤，不遵循 `Equatable`**：帶底層失敗的 case 宣告 `underlying: any Error & Sendable`，純分類 case (如 `APIError.http(statusCode:)`) 維持原形狀。
  - 框架錯誤 (SwiftData、Foundation、EventKit、URL loading、`DecodingError`) 一律 `error as NSError` 橋接：typed catch 拿到的是 `any Error`，`as NSError` 是唯一無條件成立且保留 domain、code、userInfo 的轉換。
  - App 自己定義的錯誤原樣承載、不橋接 (目前只有 `RecordDecodingError`)：橋接會把結構化欄位壓成字串，呼叫端與測試就無法 pattern-match。
  - App 自己判斷出的狀況不偽造 `NSURLErrorDomain` 等框架 domain，需要可辨識的診斷碼時用自有 domain (如 `com.leoho.BuyLedger.networking`)。
  - 只有真的顯示給使用者的錯誤型別才遵循 `LocalizedError` (目前只有 `PersistenceRecoveryError`，經 `PersistenceFailureFeature` 以無型別 catch 取 `localizedDescription`)。
- **使用者可見訊息與診斷輸出不內插完整 URL 或 `URLRequest`** (含 `absoluteString`／`description` 等攤平存取)：避免憑證外洩；`TestSuiteIntegrityTests` 以子字串比對守門，改名後再內插等迂迴寫法仍要人工複核。

### 寫法

- **Reducer body 內呼叫 State 上的 instance method 走 `store.state.method(...)`**，不透過 `@dynamicMemberLookup` 的 `store.method(...)`。
- **不用 `switch`／`if` 運算式賦值** (`let x = switch …`)：先宣告 `let x: T` 再於各分支賦值；在 `@ViewBuilder` 內與 result builder 衝突時抽成 helper。
- **不為補註解新增顯式 `init`**：能用合成的 memberwise init 就用；只有需要 `@ViewBuilder` trailing closure、無標籤的語意化參數、驗證、轉換或相依注入時才寫。

## 環境相依性與依賴注入

### Service、Client 與 Store

- **TCA 相依一律以 `DependencyValues` 的 key path 取用** (如 `\.orderService`、`\.buyLedgerDatabase`)：Feature 與 App 組合根取用 Service，Service 的 `liveValue` 以相同方式取得 Database、Client、Store 等技術相依。
- **Feature 的業務操作由 `Sendable` Service struct 提供，每個操作一個 closure**：`liveValue` 必須是 computed property 並以 key path 注入相依，不用 `static let` 固定第一次解析到的依賴。
  - Client 與 Store 只提供技術操作：`HTTPClient` 負責 HTTP 傳輸，`UserDefaultsStore` 只讀寫偏好值，`AppConfigurationStore` 只讀取並正規化 Info.plist 設定；設定 key 與快照組裝留在 `SettingsService`，API key 名稱留在使用端 (`ExchangeRateEndpoint`、`AISummaryService`)。
  - 只有會失敗的操作才用 typed throws，不為符合型別樣板加 `throws` (如 `UserDefaultsStore`、`AppConfigurationStore`、`SettingsService.load`／`save`)。
  - effect 內把 Service 錯誤傳進 `Result<_, PersistenceError>` 時寫 `do throws(PersistenceError) { … } catch { … }`：一般 `do`／`catch` 的 `error` 是 `any Error`，編不過。
- **Feature 專屬 Service 只被所屬 Feature 引用**：Feature 之間的資料經父層投影或 delegate 交給，不直接取用他人的 Service。
- **每個 Feature 至多一個以資料庫為下層的 Service** (`Features/<Feature>/Data/` 內取用 `buyLedgerDatabase` 者)：同一交易要同時改主檔與訂單時，寫入必須在擁有者 Service 的同一次 `database.write` 內 (如 `LookupService.renameItem`、`CampaignService.renameCampaign`)。
  - 系統 framework 的 Service (`CalendarReminderService`、`OpenSettingsService`、`PhotoService`) 不以資料庫為下層，不計入。
  - 以上兩條與訂單端只讀主檔目錄 (見 `ios-data-layer.md`) 由 `BuyLedgerTests/Guards/ServiceOwnership/ServiceOwnershipScanTests.swift` 掃描 production 程式碼守門；`Core/` 的共用 Service 與 `App/` 組合根 (含 `App/Testing/`) 不受限。

### SwiftData 容器與範例資料

- **Production 的 SwiftData 容器只由 `BuyLedgerDatabaseKey.liveValue` 從 `PersistenceContainer.bootstrap` 建立**：多個容器會讓同一 process 的資料狀態不一致 (即使 SQLite 同名)。
  - Service 透過 `@Dependency(\.buyLedgerDatabase)` 共用該 Database，不另建容器或存取全域單例；工廠函式 (`make`、`makeBootstrap`) 維持 `private`。
- **Production `liveValue` 不載入範例資料**，首次啟動是真正的空狀態；`LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback`、`FxRates` 只用於 Preview 與測試。
  - 不以 Database 為下層的 Service 由各自的 `previewValue` 提供固定假資料。
  - 以 Database 為下層的 Service 共用一個記憶體 Database，只 seed 一次 `LedgerOrder.sampleOrders` 與 `CurrencyCode.defaults` (幣別快取標成永不過期，Preview 不發網路請求)；其 `previewValue` 通過環境 assert 後回傳 `liveValue`。

### 時間、地區與識別碼

- **production code 走 `@Dependency`，不直接呼叫 `Date()`／`UUID()`／`Locale.current`／`TimeZone.current`／`Calendar.current`** (dependency 註冊處除外)。
  - Reducer 在 `// MARK: - Dependencies` 宣告 `@Dependency(\.date) private var date`，以 `date.now`、`uuid()` 取值。
  - 遵循 `View` 的型別 (含以 extension 遵循者) 本體不宣告 `@Dependency`，production 不引用 `Calendar.current`／`Calendar.autoupdatingCurrent`；由 `DependencyConventionScanTests` 的畫面規則掃描守門。
- **需要現在時間的衍生資料由 reducer 把注入值寫進 State 的 `dateContext`**，State 的 computed property 與畫面據此推導，不呼叫 `Date()`。
  - `OrderListFeature`、`CampaignListFeature` 在 `view(.task)` 與 `view(.retryTapped)` 寫入後再請容器載入，不能被載入去重略過；`OrderMergeFeature` 建立時帶入清單的 `dateContext`，缺少時由容器以注入值建立。
  - `DashboardFeature`、`InsightsFeature` 同樣在 `view(.task)` 與 `view(.retryTapped)` 覆寫後送 `delegate(.refresh)`；統計與 `screenState` 以記錄的日期推導，尚未記錄時顯示載入骨架。
  - App 回到前景 (`AppLockFeature` 的 `delegate(.didBecomeActive)`) 與系統重大時間變更 (`RootLaunchFeature` 於 `view(.task)` 起監聽 `SignificantTimeChangeService`，以 `delegate(.significantTimeChanged)` 交 Root) 時，Root 以注入的 `date.now`、`calendar` 呼叫開團、訂單容器、首頁與分析頁的 `refreshDateContext` 重寫。

### 測試的相依

- **測試的相依預設值必須讓漏接設定立即失敗**：Service 的 `testValue` 每個 closure 都用 `unimplemented(...)`，有回傳值時給中性 `placeholder`，回傳 stream 時給立即結束的 stream。
  - Feature 測試只覆寫會呼叫到的 closure；直接測 Service 的 `liveValue` 時，明確注入所需 Client、Store 與 Database。
  - Client、Store、Database 不宣告 `testValue`，測試以 `withDependencies` 注入替身，避免誤連正式網路或資料庫。
- **測試固定注入的時間與曆法**：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；Calendar 相關測試固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)`。
  - 例外：驗證「依注入的時區或曆法格式化」的測試，注入值要與執行環境不同才分得出注入值與裝置值 (如 `DateSectionFormattingTests` 的 `Pacific/Kiritimati` 與民國曆)，不套用固定值。

## ios-dev-kit 規範與專案差異

- **程式風格、排版、MARK 分區與新檔樣板一律依 `/ios-dev-kit`**：分區見 `references/formatting.md`，TCA Feature 型別見 `references/tca-architecture.md`，新檔從 `assets/templates/` 複製 (樣板選擇表見 `references/file-templates.md`)。
  - 改到的檔整檔對齊，不因只改一行延後；未改到的檔不順手重排。
  - 以下是本專案與 kit 不同或 kit 未涵蓋的規則。

### Feature 目錄

- **Feature 依 kit 分 `Presentation/`、`Domain/`、`Data/`，沒有內容的層不建資料夾**：根畫面放 `Presentation/Root/`。
  - 無畫面的子 Feature 也各自一個資料夾，資料夾名等於型別前綴 (如 `Presentation/CampaignLoad/`)。
  - 只給單一畫面用的子 View 放該畫面資料夾；跨畫面共用的放 `Presentation/Components/`；`<Feature>Formatters` 與狀態樣式放 `Presentation/Formatting/`。
  - 檔案多的畫面資料夾再依用途分 `Views/`、`Operations/`、`Queries/`、`Models/`、`Requests/`、`Plans/` 等子資料夾，Feature 本體留在畫面資料夾最上層 (如 `Orders/Presentation/OrderEdit/`)。
  - `Data/` 只平放 Service 主檔，有多個 Service 也不分子資料夾；Service 的錯誤型別與交給 Presentation 的值型別放 `Domain/` (如 `OrderError`、`CampaignReminderLink`)，只給 Service 內部用的傳輸型別留在 `Data/` (如 `OllamaChatRequest`)。

### 測試

- **UI 測試以 `-BLUITest` 加一組 `-BLUITest<名稱>` 啟動參數指定資料與情境**，不用 kit 的 `-uiTesting` 加 `launchEnvironment["UITEST_SCENARIO"]`：參數由 `LaunchOptions` 組出、App 端 `BLUITestConfiguration` 解析，沒有 `-BLUITest` 時整套測試掛鉤都不生效。
  - 新增情境時在 `LaunchOptions` 與 `BLUITestConfiguration` 各加對應欄位，不改走環境變數；UIKit 本身認得的系統參數 (如 `-UIPreferredContentSizeCategoryName`) 只加在 `LaunchOptions`。

### 既有架構 (新程式碼沿用現行寫法)

- **`MoreFeature` 是 App 殼層的分頁宿主**，沒有自己的領域資料；它的 `Path` 引用其他 Feature 模組的 Feature 型別，視為 kit「跨 Feature 模組導航只在 App 層」的殼層例外，目錄暫留 `Features/More/`，依第 10 步調整。
- **設定寫入維持 reducer 內同步呼叫**：讓連續輸入依序保存，避免非同步效果重排快照。

### 依 kit、例外先個案討論

- **`@Shared` 依 kit 規範，要用 `.inMemory` key 時先與使用者個案討論**：現行的 `.inMemory` key 有主檔目錄 `.lookupCatalog` 與幣別清單 `.currencyCodes`；另有容器內的無鍵共享資料，寫入責任見 `ios-data-layer.md`。
  - `OrdersFeature` 持有無鍵共享訂單，建立時把同一引用交給子層；只有 `OrdersLoadFeature` 與 `OrderWritesFeature` 在 reducer 內以 `withLock` 更新，容器不寫，清單與詳情只拿 `SharedReader`；載入狀態也由 `OrdersLoadFeature` 共享給容器與清單。
  - `CampaignFeature` 以無鍵 `@Shared` 持有開團、訂單投影、提醒連結與只看未收款；`MoreFeature.State.orders` 是客戶頁讀取的訂單投影。開團與「更多」的訂單投影僅由 Root 更新，不能與 Orders 的資料來源混用。
  - `OrdersFeature.State.campaigns` 是無鍵 `@Shared` 開團投影，清單以同一份 `SharedReader` 讀取；容器可寫，但只有 Root 在 reducer 內以 `orders.$campaigns.withLock` 同步，`ProjectionWriteBoundaryTests` 守門訂單範圍的寫入、可寫引用外傳與重綁。
  - Root 的 `RootLaunchFeature` 載入幣別快取，非空才寫入 `.currencyCodes`；Orders 以 `@SharedReader(.currencyCodes)` 建立表單選項，讀取失敗或空結果保留原值。
- **格式化依 kit 用 `FormatStyle`，要用 `<Feature>Formatters` 靜態函式時先與使用者個案討論**：`FormatStyle` 較接近 SwiftUI 原生寫法；現有的靜態函式見下方「過渡例外」。

### 過渡例外

局部改動沿用各項的現行位置與寫法，不順手遷移，避免混用架構。

- **依第 10 步處理**：
  - 錯誤型別：Orders 的 Service 用 `OrderError`，Campaigns 與 Lookups 沿用共用的 `PersistenceError`，不另立 `<Feature>Error`。
  - Service 直接呼叫系統 framework (例如 EventKit、PhotosUI、LocalAuthentication、UIApplication)。
  - `AppLaunchConfigurator` 以參數預設值注入 `CrashDiagnosticsClient`，預設正式實作並可由呼叫端替換。
- **已決定改依 kit、尚未遷移**：
  - 格式化：現有 `BLFormatters` 與各 `<Feature>Formatters` 的靜態函式待改為 `FormatStyle`；新增的格式化依 kit 寫 `FormatStyle`。
  - 測試拆檔：現有的 `<Type>Tests+<行為>.swift`、`<Scenario>+<X>Cases.swift` 跨檔 extension 待另開 change 拆成獨立測試型別 (`<TypeUnderTest><行為>Tests`)；新寫的測試直接用獨立型別，style 閘門不對既有分檔逐檔判違規。

## 已裁定的產品決策

- **App 沒有資料匯出或備份出口，store 維持系統預設檔案保護等級 (裝置首次解鎖後可讀)**：store 含客戶姓名、備註與照片，此取捨由使用者裁定並接受，不是疏漏。
  - 未記錄的省略不得僅因無人反對就視為已接受，本條即是該項記錄。
  - store 開不起來時的救援是 `PersistenceFailureFeature` 把檔案搬到隔離備份目錄，不依賴匯出功能。
