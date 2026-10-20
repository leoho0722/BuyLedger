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
- **`$store.draft.name` 這類巢狀欄位綁定，SwiftUI 會寫回整個 `draft`，送出 `.set(\.draft, …)`**：TCA 的 `BindingAction ~=` 要求 key path 完全相等，reducer 的 `.binding(\.draft.name)` 永遠不成立。
    - 要對單一欄位的變更反應時，在 State 加可寫的 computed property 並讓畫面綁定它 (開團表單的 `CampaignEditFeature.State.draftName`，reducer 比對 `.binding(\.draftName)`)；其他欄位的變更走 `case .binding:`。
- **`Feature.State` 上顯式標註的 `Sendable` 是編譯期契約，不可當冗餘刪除** (`SettingsFeature`／`FxFeature`／`QuoteFeature`／`OrderEditFeature`／`CampaignEditFeature`)：刪掉後 State 混入非 Sendable 成員也不會報錯，且沒有測試會轉紅。
    - 其餘 State 尚未統一標註是刻意保留的範圍，不要以此為由移除既有標註。
- **`MemberImportVisibility` 已開啟：只 `import ComposableArchitecture` 的檔 (如 reducer，不 `import SwiftUI`) 若寫 `TextState("…")` 字面值或插值，要另外 `import Foundation`**：字面值走 `LocalizedStringResource` 初始化器，缺 import 會編譯失敗。
    - `TextState` 一律直接寫字面值 (含插值)，不先組成 `String` 再傳入：`StringProtocol` 初始化器走 verbatim，不經本地化。
- **Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 除了 Context7 也對照 Apple docs MCP**；兩邊文件矛盾時列出差異與建議選項問使用者。

## 建置與開發指令

- **不退回原生 `xcodebuild`／`xcrun`／`simctl`**，明文例外有三項：
    - `agvtool` (版本管理不在 MobileBuildMCP 能力範圍)。
    - CI (`.github/workflows/ci.yml`) 以 `npm install -g mobilebuildmcp@<釘選版本>` 安裝 CLI，之後所有 build 與 test 仍經它執行；升級 CLI 時同步更新 workflow 的釘選版本。
    - `xcrun xcresulttool get test-results summary --path <bundle>` 僅用於唯讀讀取 result bundle 摘要 (MobileBuildMCP 沒有等價指令)。
- **每次 build 或 build-and-run 前先 `cd apps/ios && agvtool next-version -all` 把 build number +1**，跑 test 不遞增 (test binary 不會安裝或散佈，遞增只製造 pbxproj 雜訊)。
    - 同一輪以 `&&` 串接的多平台 build 只遞增一次；遞增產生的 pbxproj 變更隨當次工作 commit，不丟棄。
- **改 marketing version 直接編輯 pbxproj 的 `MARKETING_VERSION`**：`agvtool new-marketing-version` 會報 Cannot find YES 且不更新 pbxproj (版號在 build settings，Info.plist 沒有版號 key)。
- **模擬器跑 App 用 `build-and-run`**，不先 `build` 再 `build-and-run`。
- **iOS 與 iPadOS simulator build 共用 `build.db`，要序列化 (`cmd1 && cmd2`)**：並行會 `database is locked`。
- **看詳細 build error 加 `mobilebuildmcp --log-level error <subcommand>`**，否則只回 `BUILD FAILED`。
- **模擬器以識別碼指定，先 `mobilebuildmcp simulator list` 查可用清單**，不寫死名稱。
    - CI 找不到符合版本的執行環境時 job 要明確失敗，不退回舊版執行環境。
- **erase 模擬器是安全的復原手段**，不影響 `DatePicker` 的日期格式。
    - 進系統設定可用 `mobilebuildmcp ui-automation` (`simulator launch-app --bundle-id com.apple.Preferences` 後 `snapshot-ui`／`tap`)，不需要 `computer-use`；但設定頁的開關與滑桿不一定能取得 ref。
- **加 SPM 產品一律在 Xcode 操作，不手改 pbxproj**。
    - 原始碼直接具名使用 TCA 傳遞相依的 API (如 `@Shared`／`SharedKey`) 時，要把該套件產品加入 `BuyLedger` 與 `BuyLedgerTests` 的連結清單：只靠 `@_exported import` 會編譯通過、連結失敗 (`Undefined symbols ... nominal type descriptor`)。
    - 加入沒有宣告 traits 的套件 (如 `swift-sharing`) 後，Xcode 可能在其 `XCRemoteSwiftPackageReference` 插入空的 `traits = ( );`，使依賴解析失敗 (`Disabled default traits ... declares no traits`)；移除該套件的這個區塊即可 (`swift-composable-architecture` 本身有宣告 traits，同樣的空區塊合法、不要動)。
- **跑 snapshot 測試前把模擬器外觀鎖淺色** (`mobilebuildmcp simulator-management set-appearance --mode light`)：自動外觀入夜切深色會讓整批 baseline 誤判失敗。
- **UI 測試 (`BuyLedgerUITests`) 走獨立 scheme，只覆蓋 iOS 26.x 模擬器**：
    - `-only-testing` 跑 UI 測試要指定 `BuyLedgerUITests` scheme；該 target 不在 `BuyLedger` scheme 的 test plan 內，指定 `--scheme BuyLedger` 會回「isn't a member of the specified test plan or scheme」。
    - 跑全功能回歸不靠 `--extra-args -testPlan` (CLI 會忽略、退回 scheme 預設的效能計畫)，改用 `--extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests`；單一類別用 `-only-testing:BuyLedgerUITests/<類別>`。
    - 執行 iPad UI 主回歸前，必須確認模擬器的軟體鍵盤可顯示，也就是硬體鍵盤連線已斷開。`mobilebuildmcp simulator-management toggle-connect-hardware-keyboard` 不可靠：它送出 `Cmd+Shift+K`，Simulator 不在前景時會無聲失效；直接寫入 `ConnectHardwareKeyboard` 偏好設定對已 booted 的裝置也無效。可靠的處置是在模擬器前端 Device Hub 的選單取消勾選 Device › Keyboard › Simulate Hardware Keyboard；模擬器重開機後該選項會恢復成勾選，每次重開機都要重新取消勾選，並先單獨跑 `KeyboardDismissTests` 確認 (判讀見下一條)。
        - Device Hub 未執行時以 `mobilebuildmcp simulator-management boot` 開機的模擬器不連接硬體鍵盤，軟體鍵盤可顯示，也同時滿足轉向測試不可開 Device Hub 的條件 (見 `.claude/rules/ios-ui-tests.md`)；完整 UI 回歸優先用這種開機方式，仍先單獨跑 `KeyboardDismissTests` 確認。
    - 若回歸出現「數字鍵盤工具列的完成鍵未能收起鍵盤」，判別方式是看失敗時可及性樹的 `Keyboard` 元素 y 起點是否大於視窗高度；修正環境後，單獨執行 `KeyboardDismissTests` 兩條測試且兩條都綠，才算確認軟體鍵盤前提成立。這類現象不要先改產品端鍵盤工具列。
    - 測試計畫：`BuyLedger.xctestplan` (單元測試，鎖 zh-Hant／TW、字母序執行)、`BuyLedgerUITests.xctestplan` (UI 主回歸，鎖 zh-Hant／TW、關閉隨機順序、排除效能測試)、`BuyLedgerUITests-Performance.xctestplan` (效能)；三份都只統計 App target 覆蓋率、不設門檻。
    - 訂單編輯表單 TextField 偶發「Activation point invalid」的 hittability 失敗屬環境雜訊：失敗的測試與元素在連續重跑間不一致即為雜訊，單獨重跑轉綠即可，不改測試碼或放寬斷言；同一條穩定重現才是真缺陷。
- **以 `mobilebuildmcp ui-automation` 驅動模擬器時不用 `type-text` 打數字**：它走 Mac 當前輸入法，注音模式會把數字轉成注音符號；`toggle-connect-hardware-keyboard` 需要未必已授權的輔助使用權限。UI 測試碼內的輸入用 `XCUIElement.typeText`。
    - 英文字母同樣會被注音轉換，中文字則直接被拒絕 (只支援美式鍵盤字元)；數字改點軟體數字鍵盤的按鍵元素。
    - `simulator launch-app` 會結束並重開 App，不會把背景中的 App 帶回前景；驗證背景與前景改按 `ui-automation button --button-type lock`，再按兩次 `home` 喚醒並解鎖裝置。畫面一閃即過時 (如自動解鎖) 用 `simulator record-video` 錄影逐格確認。
    - `--launch-args` 的純數字值會被當成數字而驗證失敗，改用 `--json '{"launchArgs":[...]}'`；`-BLUITest` 模式的設定存在記憶體，驗證「重開後仍保留設定」要以正式模式啟動。
    - 列位於分頁列範圍下方時 `touch` 會點到分頁列，先捲動讓目標露出再點。
    - sheet 內 `List` 的最後一列，`ui-automation` 的 `touch` 與 `tap` 可能回報成功卻沒有觸發，同一 sheet 的其他列正常。遇到時改以 XCUITest 驗證 (正式 UI 測試，或量完即刪的暫時測試)，不反覆重試。
    - iPad 模擬器的多工模式要維持「全螢幕 App」：「視窗 App」模式下 `snapshot-ui` 會失敗 (無法取得可及性樹)。
- **macOS BSD `sed -E` 清尾隨空白用 `[[:space:]]+$`，不用 `[ \t]`**：`[ \t]` 會匹配字面的反斜線與 `t`，把行尾的 t 一起吃掉，落在註解或字串內時編譯器不會發現。

## 架構分層

- **`Core/` 與 `Shared/` 不引用 `Features/` 下的任何型別**：依賴只能向下。Core 需要的 API client 放 `Core/Networking/`，領域層的 fallback 表放 `Core/Domain/`。
    - 組裝根例外：`App/Testing/` 的 `BLUITest*` 認得所有 feature，與 `App/AppLaunchConfigurator` 同層，不放 Core。
    - 文件註解內以反引號引用 Feature 符號不算違規，只有程式碼依賴才算。
    - `LayerBoundaryTests` 動態掃描 `Core/` 與 `Shared/` 守門；`App/` 刻意不在掃描範圍。
- **`Shared/DesignSystem/` 不得引用 `Core/Domain/` 的領域型別，也不得 import `ComposableArchitecture`**：可重用元件以 primitive 或 Design System 自有型別接收資料，架構相依由 Feature 端保留。
    - `LayerBoundaryTests` 會納入 `Core/Domain/Generated/` 的宣告名稱，並以變異驗證確認兩條守門真的會轉紅。
- **綁 store 的畫面只吃自己 feature 的 scoped store**：跨 feature 資料走根 feature 單向同步的唯讀投影，跨 feature 意圖以 delegate action 交給根 feature，由根 feature 呼叫共用的導覽操作，不新增平行的根 case；純顯示值 (如目前的 App 語言) 走建構參數。
    - 可宣告根 store 的只有三個導覽宿主 `RootView`／`RootTabLayout`／`RootSidebarLayout`，由 `LayerBoundaryTests.filesDeclaringRootStore_功能目錄_僅由三個根導覽宿主持有` 鎖住；`MoreView` 只持有 `MoreFeature` 的 scoped store。
    - 投影的變更監看集中在 `RootFeature.body` 尾端的連續 `onChange(of:)`，涵蓋訂單 (開團與「更多」的 `$orders`、總覽與分析的副本)、開團 (`orders.$campaigns`、總覽與分析的副本)、載入狀態、偏好 (`appLock.isBiometricUnlockEnabled`、`dashboard.monthlyProfitGoalTWD`、`more.preferences`、`orders.defaultCurrency`、`orders.aiSummarySettings`) 與辨識類型 (`more.biometryType`)；漏掛一條會讓畫面顯示舊資料而不易察覺。
    - **父層不送出也不攔截子層的 `.view(...)` action**：子層畫面事件只由自己的 Feature 處理，父層不得以 `.send` 或 reducer case 包裝子層 `view` action。
    - **父層要求子層載入或套用資料時，送專用請求 action，即使子層是有 View 的容器也一樣**：請求只由父層送、子層 reducer 處理，不代替使用者互動；Root 對 Orders 送 `rootRequest(OrdersRootRequest)` (`load`、`cascade`、`receiptStatusChange`、`paymentMethodFlagsApply`、`optionAdditionCompleted`)，由容器轉給載入、寫入或呈現子 Feature。需要父層處理的結果經 delegate 回報，其餘成功結果由共用資料觀察。
        - 例外：容器的無 View 呈現與導覽子 Feature (`OrdersPresentationFeature`、`OrdersDetailNavigationFeature`、`CampaignPresentationFeature`)，同一次更新內必須完成的呈現與導覽 (Root 開新訂單、寫入結果關閉表單、顯示詳情、表單關閉收尾) 由容器直接呼叫子 State 的 `mutating` 方法；寫入失敗等一次性通知仍送 `noticeRequested` action，維持下一個 action 才呈現的時序。
    - **子層啟動所需資料在建立 State 時帶齊**：`BuyLedgerApp` 讀出的設定快照與 App 版本直接傳入 `RootFeature.State`，設定頁推入時由 `MoreFeature` 以偏好與辨識類型的投影建立 `SettingsFeature.State`，首幀不依賴額外的載入 action。
    - **跨 feature 意圖由子層 reducer 以 delegate 請父層做事**：畫面只送自身 Feature 的 `view` action，由 reducer 轉成 delegate；Root 的 view case 與子層 delegate case 呼叫同一個 `RootNavigationOperations` 方法 (如 `showOrders(customer:state:)`、`showCampaign(named:state:)`)，不以 `.send` 轉成另一個根 case，也不新增平行的根 action。
- **商業邏輯與資料計算 (彙總、分組、排序、格式化) 放 reducer 或可測試的 helper**，View (含 Swift Charts) 只負責呈現。
- **Feature 超過 300 行依 `tca-architecture.md` 的拆分順序**：`Path`／`Destination` 移到 `<Name>+Path.swift`／`<Name>+Destination.swift` → 可獨立的流程抽成子 Feature 以 `Scope` 組合 (沒有自己 View 的子 Feature 不設 `view` 分組，由父層轉送，如 `QuoteRateFeature`、`PaymentMethodCorrectionFeature`、`OrdersPresentationFeature`、`RootLaunchFeature`)。重複的計算或讀寫分派收進同域輔助型別：純計算放無 case 的 enum，只放 `static func`，以 `inout State` 與明確參數溝通 (如 `OrdersFilterOperations`)；需要依賴的讀寫分派放持有依賴值的 struct，由 reducer 以自己的 `@Dependency` 建立 (如 `LookupItemOperations`)；需要 reducer 解析後的時間與行事曆的操作放持有這兩個值的 struct，由 reducer 以注入的 `date.now`、`calendar` 建立 (如 `RootNavigationOperations`)。
    - 行數例外：`OrdersFeature` 以 359 行為上限 (使用者裁決)。抽出呈現與詳情導覽子 Feature 後，剩下的 Root 介面方法與投影依寫入邊界只能留在 `OrdersFeature.swift`、`core` 依 Action 次序逐 case 轉送，再拆只會產生沒有內聚性的轉手層；行數回到 300 行內即撤銷此例外。
    - 輔助型別不宣告 `@Dependency`，也不呼叫 `Date()`／`UUID()`／`Calendar.current`，由 reducer 解析後傳入；被它跨檔呼叫的 State 方法或靜態工廠要是 internal。
    - 投影擁有者 (含 `OrdersFeature`、`CampaignFeature`) 的主檔以外不接收 `inout` 容器 State，也不外傳可寫的共享引用；輔助型別讀值快照並回傳計畫，由容器 reducer 套用，避免繞過投影與共享寫入守門。
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

- **TCA 相依一律透過 `DependencyValues` 的 key path 取用**：例如 `\.orderService`、`\.buyLedgerDatabase`。
    - Feature 與 App 組合根取用 Service；Service 的 `liveValue` 以相同方式取得 Database、Client、Store 等技術相依。
- **Production 的 SwiftData 容器只由 `BuyLedgerDatabaseKey.liveValue` 從 `PersistenceContainer.bootstrap` 建立**：Service 透過 `@Dependency(\.buyLedgerDatabase)` 共用該 Database，不另建容器或存取全域單例；多個 SwiftData 容器會造成同一 process 的資料狀態不一致 (即使 SQLite 同名)；建立 production container 的工廠函式 (`make`、`makeBootstrap`) 維持 `private`。
    - Production `liveValue` 不載入範例資料，首次啟動是真正的空狀態；不以 Database 為下層的 Service 由各自的 `previewValue` 提供固定假資料。以 Database 為下層的 Service 共用一個記憶體 Database，只 seed 一次 `LedgerOrder.sampleOrders`；其 `previewValue` 通過環境 assert 後回傳 `liveValue`。
    - `LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback`、`FxRates` 只用於 Preview 與測試，不進 production 路徑。
- **Feature 的業務操作由 `Sendable` Service struct 提供**：每個操作是一個 closure，`liveValue` 必須是 computed property，並以 key path 注入所需相依；不要用 `static let` 固定第一次解析到的依賴。
    - Client 與 Store 提供技術操作介面。`HTTPClient` 負責 HTTP 傳輸，`UserDefaultsStore` 只讀寫偏好值，`AppConfigurationStore` 只讀取並正規化 Info.plist 設定；設定 key 與快照組裝留在 `SettingsService`，API key 名稱留在使用端 (`ExchangeRateEndpoint`、`AISummaryService`)。
    - 操作本身不會失敗時不宣告 `throws`；只有會失敗的 Client、Store、Service 操作才使用 typed throws。`UserDefaultsStore`、`AppConfigurationStore` 與 `SettingsService.load`／`save` 不為符合型別樣板而加上 `throws`。
    - effect 內要把 Service 的錯誤傳進 `Result<_, PersistenceError>` 時寫 `do throws(PersistenceError) { … } catch { … }`：一般 `do`／`catch` 的 `error` 是 `any Error`，編不過。
- **Feature 專屬 Service 只被所屬 Feature 引用**：Feature 之間的資料經父層投影或 delegate 交給，不直接取用他人的 Service。
    - 守門為 `BuyLedgerTests/ServiceOwnershipScanTests.swift`，與下一條及訂單端只讀主檔目錄 (見 `ios-data-layer.md`) 共三條規則，都掃描 production 程式碼；`Core/` 的共用 Service 與 `App/` 組合根 (含 `App/Testing/`) 不受此規則限制。
- **每個 Feature 至多一個以資料庫為下層的 Service** (`Features/<Feature>/Data/` 內取用 `buyLedgerDatabase` 的 Service)。
    - 同一交易要同時改主檔與訂單時，兩者的寫入必須在擁有者 Service 的同一次 `database.write` 內 (如 `LookupService.renameItem`、`CampaignService.renameCampaign`)，這是此限制的理由。
    - 系統 framework 的 Service (`CalendarReminderService`、`OpenSettingsService`、`PhotoService`) 不以資料庫為下層，不計入此限制。
- **測試的相依預設值必須讓漏接設定立即失敗**：Service 的 `testValue` 每個 closure 都使用 `unimplemented(...)`；有回傳值時提供中性 `placeholder`，回傳 stream 時提供立即結束的 stream。
    - Feature 測試只覆寫該測試會呼叫的 Service closure。直接測 Service 的 `liveValue` 時，明確注入所需 Client、Store 與 Database。
    - Client、Store、Database 不宣告 `testValue`；測試使用它們時要以 `withDependencies` 注入替身，避免誤連正式網路或資料庫。
- **production code 走 `@Dependency`，不直接呼叫 `Date()`／`UUID()`／`Locale.current`／`TimeZone.current`／`Calendar.current`** (dependency 註冊處除外)。
    - Reducer 在 `// MARK: - Dependencies` 宣告 `@Dependency(\.date) private var date`，以 `date.now`、`uuid()` 取值；畫面不宣告 `@Dependency`。
    - 需要現在時間的衍生資料由 reducer 把注入值寫進 State，State 的 computed property 與畫面據此推導，不呼叫 `Date()`：`OrderListFeature.State.dateContext` 與 `CampaignListFeature.State.dateContext` 在 `view(.task)` 與 `view(.retryTapped)` 寫入，再請容器載入，不能被載入去重略過；`OrderMergeFeature` 建立時帶入清單的 `dateContext`，缺少時由容器以注入值建立。
    - `DashboardFeature.State.dateContext` 與 `InsightsFeature.State.dateContext` 同樣在 `view(.task)` 與 `view(.retryTapped)` 覆寫，再送 `delegate(.refresh)`；統計與 `screenState` 以記錄的日期推導，尚未記錄日期時顯示載入骨架。
    - App 回到前景 (`AppLockFeature` 的 `delegate(.didBecomeActive)`) 與系統回報重大時間變更 (`SignificantTimeChangeService`，Root 的啟動子 Feature `RootLaunchFeature` 於 `view(.task)` 起監聽，以 `delegate(.significantTimeChanged)` 交 Root) 時，Root 以注入的 `date.now`、`calendar` 呼叫開團、訂單容器、首頁與分析頁的 `refreshDateContext` 重寫。
    - 遵循 `View` 的型別 (含以 extension 遵循者) 本體不宣告 `@Dependency`，production 不引用 `Calendar.current`／`Calendar.autoupdatingCurrent`，由 `DependencyConventionScanTests` 的畫面規則掃描守門。
    - 測試：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；Calendar 相關測試固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)`。
        - 驗證「依注入的時區或曆法格式化」的測試例外：注入值必須與執行環境不同才分得出注入值與裝置值 (如 `DateSectionFormattingTests` 的 `Pacific/Kiritimati` 與民國曆)，不套用固定值。

## ios-dev-kit 規範與專案差異

- **程式風格、排版、MARK 分區與新檔樣板一律依 `/ios-dev-kit`**：分區見 `references/formatting.md`，TCA Feature 型別見 `references/tca-architecture.md`，新檔從 `assets/templates/` 複製 (樣板選擇表見 `references/file-templates.md`)。
    - 新增與修改的 Swift 檔依 `/ios-dev-kit` 的固定 MARK 分區；未修改的既有 Feature 檔留到第 6 步，不要順手重排。
    - 修改 `switch` 時整理該 switch 的全部 case，避免同一個 switch 混用排版。
    - `switch` 的 `case` 之間空一行 (`formatting.md`)。
- **註解反引號只標程式碼識別字 (型別、成員、關鍵字、檔名)**。
    - sheet、alert、reducer、store、iPad、AI、UTC 等一般概念詞不加反引號。
- **`if case` 與 `guard case` 的關聯值 pattern 一律用 `case .x(let v)`**：`file-templates.md` 已規定 switch case 使用此寫法，本專案也讓 `if case` 與 `guard case` 維持一致。
- **SwiftUI View 不以跨檔 `extension` 作為超過 300 行的第一選擇**：跨檔 extension 無法存取同一 View 的 `private @State`／`private @Environment`；為了編譯而降為 `internal` 會破壞狀態封裝。超過 300 行時優先抽成獨立 View 型別並傳入必要值與 closure；確實抽不動時才在 `findings.md` 登記行數例外，寫明原因與使用者裁決。
- **檔頭日期一律不補零 `YYYY/M/D`** (如 `2026/9/20`)，不是 `file-templates.md` 的 `YYYY/MM/DD`：Xcode 新檔樣板產生的就是不補零格式，補零等於每個新檔都要手動改一次。
    - 檔頭其餘規則仍依 `file-templates.md`：四行結構、不加版權宣告與修改紀錄、建立後不再更新日期。
- **宣告的大括號本體一律換行，不壓成單行**：`guard ... else { return x }`、`var x: T { expr }`、`func f() -> T { expr }` 都要把本體與結尾大括號各自獨立一行。`formatting.md` 的 `guard let self else { return }` 與單行 closure 範例不適用於宣告本體；作為引數傳入的 inline closure (`map { $0.id }`) 不在此限。
- **`guard … else` 內先記錄警告或 log 再 `return`／`throw` 不算違規**：kit `coding-style.md` 規定 `guard` 的 `else` 只放 `return`、`throw`，本專案解讀為不放業務邏輯，記錄診斷輸出後離開不改寫 (如 `BLUITestConfiguration` 啟動參數無法辨識時的 `warn(...)`)。
- **`@Dependency` 屬性包裝器與宣告同行**：例如 `@Dependency(\.orderService) private var orderService`；不同於 `tca-architecture.md` 的分行寫法，本專案不拆成兩行；整行超過 100 字元時才換行。
- **帶參數的函式型別 `typealias` 超過 100 字元時依參數斷行**：參數各占一行，`)` 與 effects、回傳型別同行；無參數的函式型別維持一行。
- **無參數函式宣告即使超過 100 字元也維持一行**：沒有參數可供斷行，不在 `)` 後拆行。
- **TCA `State` 本體順序為 stored properties → 非 private computed properties → init → nested types → 方法**：`formatting.md` 的巢狀型別通則把 init 排在 computed property 之前，`State` 改依 `tca-architecture.md`「computed property 放同一個 `State` 內、stored property 之後」(如 `SettingsFeature.State.snapshot` 排在 `init` 之前)。
- **測試檔不設 `// MARK: - Tests` 分區** (使用者裁決)：`@Test` 方法與 UI 測試的 `func test…()` 直接接在 Properties／Init 之後，不同於 kit 的 `tests/Tests.swift`、`tests/UITests.swift`、`tca/FeatureTests.swift` 樣板；其餘分區照樣板。
- **TCA View 除 `@Bindable var store` 外，可持有專案規則要求的 `@Environment` (`locale`、`dynamicTypeSize`、`blLayoutClass`)、`@ScaledMetric` 與 `static let` 常數**：kit `tca-architecture.md`「唯一的 stored property 是 store」不涵蓋這些無障礙與版面需求 (見 `ios-accessibility-localization.md`、`ios-design-system.md`)。
    - 屬性順序為 `static let` → `@Environment` → `@ScaledMetric` → `@Bindable var store` → `@State`／`@FocusState` → `@Binding` → 一般 `let`／`var`，同一組內依名稱字母排序。
- **由外部注入的 State 值用 `let` 且不給宣告處預設值**，只從 `init` 參數帶入 (如 `SettingsFeature.State.appVersion`)；宣告處放佔位值再於 `init` 覆寫會讓「未注入」與「注入了佔位值」無法區分。
- **小段邏輯不為單一呼叫點抽 helper**：只被一個 computed property 使用的格式化直接寫在該 property 內 (如 `Bundle.appVersion`)。有自己輸入與輸出、超過約 15 行的獨立演算法可抽成函式或 local function；一兩行可直接寫在呼叫端的邏輯仍留在原處。
- **reducer 的 `body` 只組合，不寫 `Reduce { state, action in }` 閉包**：分支主體抽成 `Private Method` 的第一個方法 `core(state:action:)`，`body` 寫 `Reduce(core)`。
    - `core` 的 `switch` 依 `Action` 宣告順序寫在 Feature 主檔，不把整個 `Action` 的分派移到輔助型別；主檔超過 300 行時依 kit 的拆分順序抽子 Feature (見「架構分層」)。
    - 因型別檢查逾時而必須分段時 (見「架構分層」的多段 `Reduce` 規則)，每段各自抽成具名方法再以 `Reduce(段名)` 組合，不保留 inline closure。
- **一個檔只放一個頂層型別**：同檔多個型別會讓檔案層級的 `// MARK: - Internal Method` 等固定區名重複出現，Xcode jump bar 分不出歸屬。獨立 model 型別各自一檔；巢狀型別 (含 TCA 的 `State`／`Action`) 依 `formatting.md` 把成員就地寫在本體，不另開 extension。
    - 例外：`@Reducer enum` 的 `Destination.State` 由巨集產生，本體無法加成員，alert 建構方法與 `Equatable` 遵循寫在 `extension <Feature>.Destination.State` (如 `LookupManagementFeature+Destination.swift`)。
- **`MockBuyLedgerDatabase` 的注入錯誤無法轉成 closure 的 typed throws 型別時保留 `preconditionFailure`**：在型別文件以 `- Note` 說明注入錯誤與 `Failure` 型別不符代表測試設定錯誤，視為程式錯誤。
- **錯誤可忽略且 catch 只有註解時，改用同一行附理由的 `try?`**：只有註解的 catch 視為空 catch；`catch { return }` 含實際敘述，不屬此例。
- **Preview seed 或 UI 測試環境無法建立時保留 `fatalError`**：在呼叫前以 `//` 說明無法繼續的原因，讓資料庫定義或測試環境問題立即失敗。
- **UI 測試以 `-BLUITest` 加一組 `-BLUITest<名稱>` 啟動參數指定資料與情境，不用 kit 的 `-uiTesting` 加 `launchEnvironment["UITEST_SCENARIO"]`**：參數由 `LaunchOptions` 組出，App 端 `BLUITestConfiguration` 解析；沒有 `-BLUITest` 時整套測試掛鉤都不生效。
    - 新增情境時在 `LaunchOptions` 與 `BLUITestConfiguration` 各加對應欄位，不改走環境變數；UIKit 本身認得的系統參數 (如 `-UIPreferredContentSizeCategoryName`) 只加在 `LaunchOptions`。
- **建構裝 closure 的相依 struct 時一律多行**：型別名稱與左括號 (例如 `Self(`) 同行，右括號 `)` 單獨一行；每個引數各占一行。即使只有一個 closure 且呼叫不超過 100 字元也照此，涵蓋 Service、Client、Store 的 dependency、preview、測試替身與覆寫。
- **多重 trailing closure 一律多行**：`Binding { } set: { }` 寫成 `Binding {`、本體、`} set: {`、本體、`}` 逐行排列，不壓成一行；kit 只規定 View builder、modifier 與 action 的 closure 一律多行，`Binding` 的 `get`／`set` 不在其列。
- **錯誤對應 helper 的 trailing closure 一律多行**：`{` 接在呼叫後，closure 本體縮排 4 格，`}` 單獨一行；包括 `PersistenceError.mapFetch`、`mapSave` 與 `wrapStorage`。
- **依賴配置的過渡例外依排程處理**：局部改動沿用各列的現行位置與取用方式，避免混用架構。
    - `BiometricAuthService` 由 `AppLockFeature` 與 `SettingsFeature` 共同取用且只依賴 `LocalAuthentication`，留在 `Core/Dependencies/`，不屬過渡例外。
    - `Core/Dependencies/` 的 ExchangeRate 與 CurrencyMetadata Service 依第 10 步決定位置。
    - 錯誤型別：Orders 的 Service 用 `OrderError`，Campaigns 與 Lookups 沿用共用的 `PersistenceError`，不另立 `<Feature>Error`。
    - Service 直接呼叫系統 framework (例如 EventKit、PhotosUI、LocalAuthentication、UIApplication)，依第 10 步處理。
    - `AppLaunchConfigurator` 以參數預設值注入 `CrashDiagnosticsClient`，預設正式實作並可由呼叫端替換，依第 10 步決定配置方式。
    - Service 的 `+Preview` 檔與 Service 放在一起，依第 10 步處理，不移至 `Preview Content`。
    - Feature 專屬 Service 放在該 Feature 的 `Data/`；Feature 其他檔案維持扁平結構，依第 10 步決定目錄調整。
- **本專案既有架構與 `/ios-dev-kit` 的差異，新程式碼沿用現行寫法**：
    - Reducer body 型別用 `some Reducer<State, Action>` (見技術棧 gotcha)，不用樣板的 `some ReducerOf<Self>`。
    - 內部回應保留具體錯誤型別：`<名詞>Response(Result<T, PersistenceError>)` 等與 Service 的 typed throws 一致，不改成 kit 樣板的 `any Error`。
    - `MoreFeature` 是 App 殼層的分頁宿主，沒有自己的領域資料；它的 `Path` 引用其他 Feature 模組的 Feature 型別，視為 kit「跨 Feature 模組導航只在 App 層」的殼層例外，目錄暫留 `Features/More/`，依第 10 步調整。
    - `@Shared` 用於主檔目錄 `@Shared(.lookupCatalog)`、幣別清單 `@Shared(.currencyCodes)` 與容器內的無鍵共享資料，寫入責任見 `ios-data-layer.md`。
        - `OrdersFeature` 持有無鍵共享訂單，建立時把同一引用交給子層；只有 `OrdersLoadFeature` 與 `OrderWritesFeature` 在 reducer 內以 `withLock` 更新，容器不寫，清單與詳情只拿 `SharedReader`；載入狀態也由 `OrdersLoadFeature` 共享給容器與清單。
        - `CampaignFeature` 以無鍵 `@Shared` 持有開團、訂單投影、提醒連結與只看未收款；`MoreFeature.State.orders` 是客戶頁讀取的訂單投影。開團與「更多」的訂單投影僅由 Root 更新，不能與 Orders 的資料來源混用。
        - `OrdersFeature.State.campaigns` 是無鍵 `@Shared` 開團投影，清單以同一份 `SharedReader` 讀取；容器可寫，但只有 Root 在 reducer 內以 `orders.$campaigns.withLock` 同步，`ProjectionWriteBoundaryTests` 守門訂單範圍的寫入、可寫引用外傳與重綁。
        - Root 的 `RootLaunchFeature` 載入幣別快取，非空才寫入 `.currencyCodes`；Orders 以 `@SharedReader(.currencyCodes)` 建立表單選項，讀取失敗或空結果保留原值。
    - `TestStore` 不設定 `exhaustivity = .off`；`TestSuiteIntegrityTests` 要求使用數量維持 0，保持未接收 action 與未預期狀態變更都能讓測試失敗。
    - 通用 extension 放 `Shared/Extensions/`，不是 `Core/Extensions/`。
    - 金額、百分比、日期格式化用 `BLFormatters`／`OrderFormatters`／`CampaignFormatters`／`DashboardFormatters`／`InsightsFormatters`／`CustomerFormatters`／`QuoteFormatters`／`FxFormatters` 的靜態函式，不是 `FormatStyle`。
    - 設定寫入維持 reducer 內同步呼叫，讓連續輸入依序保存，避免非同步效果重排快照。
    - `OrdersFeaturePerformanceTests` 維持 XCTest，其餘單元測試用 Swift Testing。

## 已裁定的產品決策

- **App 沒有資料匯出或備份出口，store 維持系統預設檔案保護等級 (裝置首次解鎖後可讀)**：store 含客戶姓名、備註與照片，此取捨由使用者裁定並接受，不是疏漏。
    - 未記錄的省略不得僅因無人反對就視為已接受，本條即是該項記錄。
    - store 開不起來時的救援是 `PersistenceFailureFeature` 把檔案搬到隔離備份目錄，不依賴匯出功能。
