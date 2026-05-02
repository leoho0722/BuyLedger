<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `/spectra-*` skills when:

- A discussion needs structure before coding → `/spectra-discuss`
- User wants to plan, propose, or design a change → `/spectra-propose`
- Tasks are ready to implement → `/spectra-apply`
- There's an in-progress change to continue → `/spectra-ingest`
- User asks about specs or how something works → `/spectra-ask`
- Implementation is done → `/spectra-archive`
- Commit only files related to a specific change → `/spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra-apply` and `/spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# 儲存庫指引

## 專案結構與模組組織

此儲存庫已建立 Xcode Multiplatform 專案，目標平台為 iOS、iPadOS 與 macOS。專案主要技術棧為 Swift 6 + SwiftUI、TCA（Swift Composable Architecture）、SwiftData + CloudKit 與 Swift Charts。Xcode 專案檔位於 `BuyLedger/BuyLedger.xcodeproj`，scheme 名稱為 `BuyLedger`。

目前主要結構如下：

- `BuyLedger/BuyLedger.xcodeproj/`：Xcode 專案檔。`project.pbxproj` 應納入版本控制，`xcuserdata/` 不應提交。
- `BuyLedger/BuyLedger/App/`：App 進入點 (`BuyLedgerApp.swift`)、`WindowGroup`、macOS `Settings { }` scene、`CommandGroup` 選單與跨平台 `FocusedValue` 等全域啟動設定。
- `BuyLedger/BuyLedger/Core/`：跨 feature 共用的依賴、SwiftData/CloudKit 持久化、基礎服務與工具；含 `Domain/`（`LedgerOrder` 等 model、`LedgerOrder+Samples.swift`、`FxRateSnapshot.swift`）、`Persistence/`（`OrderPersistence`（`@ModelActor`）、`PersistenceContainer`）、`Dependencies/`（`OrderRepository`、`HTTPClient`、`APIKeyProvider`）。
- `BuyLedger/BuyLedger/Features/`：依功能切分的 TCA feature；現有 feature 包含 `App/`（`RootFeature` + `RootView` + 平台導覽 `RootSidebarLayout` / `RootTabLayout`）、`Customers/`、`Dashboard/`、`FX/`（`FxFeature`、`FxView`、`ExchangeRateClient`、`FxRates`）、`Insights/`、`More/`、`Orders/`（含 `OrdersView` 平台分流、`OrdersCompactView`、`OrdersMacView`、`OrderEditFeature` 與 `Components/`）、`Quote/`、`Settings/`（`SettingsFeature` + iOS `SettingsView` + macOS `SettingsScene_macOS`）。feature 變大時再拆 `Models/`、`Components/` 等子目錄。
- `BuyLedger/BuyLedger/Shared/`：跨 feature 共用的設計系統、SwiftUI 元件、Swift Charts 呈現元件、extensions 與可重用 helper。
- `BuyLedger/BuyLedger/Shared/DesignSystem/Foundations/`：設計系統基礎 token，例如：語意色彩、語意狀態、尺寸、間距、陰影與文字層級。
- `BuyLedger/BuyLedger/Shared/DesignSystem/Components/`：設計系統 UI 元件。請依元件類別建立子資料夾，例如：`Avatar/`、`Badges/`、`Buttons/`、`Cards/`、`Charts/`、`TextFields/`。
- `BuyLedger/BuyLedger/Resources/`：App icon、顏色、圖片資產、`Info.plist`、`BuyLedger.entitlements`、`Config.xcconfig`（gitignored、放本機 API key）與 `Config.example.xcconfig`（committed template）等資源或設定檔。
- `BuyLedger/BuyLedgerTests/`：單元測試與 swift-snapshot-testing baseline（`__Snapshots__/`）。
- `BuyLedger/BuyLedgerUITests/`：UI 測試與啟動畫面測試。
- `Package.swift`：只有在導入共用 Swift package，或採用 package-first 佈局時才需要加入。

Xcode project 使用 file system synchronized groups；新增或搬移檔案時優先調整實體資料夾，再用 build 驗證目標是否仍正確包含來源與資源。請勿將建置輸出、本機 Xcode 狀態、密鑰、簽署憑證或 provisioning profile 納入 Git。若未來建立 shared scheme，應提交 `xcshareddata/xcschemes/`。

## 主要技術棧

- Swift 6 + SwiftUI：新程式碼以 Swift 6 strict concurrency 檢查為準。專案層級 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`（不是 `MainActor`）；改成 `MainActor` 會讓 SwiftData `@Model` 與 `@ModelActor` 編不過。需要 main actor 才安全的型別請對個別宣告加 `@MainActor`。
- TCA（Swift Composable Architecture）：功能狀態、商業邏輯、副作用與依賴注入放在 reducer 與 `@Dependency` 中；SwiftUI View 保持宣告式與輕量。Reducer body 使用顯式 `some Reducer<State, Action>`（`some ReducerOf<Self>` 會 circular reference）。
- SwiftData + CloudKit：SwiftData model 是本機持久化核心；目前 `PersistenceContainer.makeForApp()` 只開純本機，``CloudKitOption.privateContainer(...)`` 介面已預留待 Apple Developer 帳號 provision 後接上。
- Swift Charts：圖表 View 只負責呈現，資料彙總、分組、排序與格式化放在可測試的 feature/domain 層（如 `InsightsView` 對應的 stats 計算）。

## 文件查證準則

使用任何框架或套件開發前，無論是 Apple 原生框架或第三方套件，都必須先使用 Context7 查詢最新官方文件與建議用法，再依查證結果進行設計與實作。不應只依賴記憶、既有範例或過去專案習慣。

涉及 Apple 原生框架、平台 API 或 Xcode 工具鏈時，例如 SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode build/test 與平台能力，除了 Context7 之外，還必須使用 Apple docs MCP 查詢 Apple 官方文件。實作前請比對 Context7 與 Apple 官方文件的內容；若兩者有差異，不得自行決定採用哪一方，必須先整理差異、影響與建議選項並詢問使用者，由使用者決策後再繼續實作。

查證後的實作應遵循目前文件推薦的模式。例如 TCA 應優先使用目前版本推薦的 `@Reducer`、`@ObservableState`、`@Bindable var store`、`$store.property.sending(...)`、`Store.scope(state:action:)` 與 `TestStore` 測試模式；若因編譯器、平台限制或專案限制需要偏離文件建議，請在回覆或變更說明中明確說明原因。

## 建置、測試與開發指令

優先使用 `xcodebuildmcp` MCP server 或 CLI（依全域指南判斷分流）。原始 `xcodebuild` 仍可作為 fallback；`xcrun` 與 `simctl` 不應直接呼叫。

常用 MCP 工具（互動式 build/run/test、結構化結果、UI 自動化）：

- `mcp__XcodeBuildMCP__list_schemes`、`mcp__XcodeBuildMCP__list_sims`：檢查 schemes 與可用 simulator。
- `mcp__XcodeBuildMCP__build_sim` / `mcp__XcodeBuildMCP__build_run_sim`：iOS / iPadOS simulator 建置或一鍵 build + install + launch。
- `mcp__XcodeBuildMCP__build_run_macos`（或 CLI `xcodebuildmcp macos build-and-run`）：macOS build + run。
- `mcp__XcodeBuildMCP__test_sim`：執行測試套件。

常用 CLI（可複現指令、CI、批次、log 過濾）：

- `xcodebuildmcp simulator build-and-run --project-path BuyLedger/BuyLedger.xcodeproj --scheme BuyLedger --simulator-name "iPhone 17"`
- `xcodebuildmcp simulator build-and-run --project-path BuyLedger/BuyLedger.xcodeproj --scheme BuyLedger --simulator-name "iPad Pro 13-inch (M5)"`（注意：simulator 名稱是 `iPad Pro 13-inch (M5)`，沒有把 `13-inch` 包在括號內）
- `xcodebuildmcp macos build-and-run --project-path BuyLedger/BuyLedger.xcodeproj --scheme BuyLedger`
- `xcodebuildmcp simulator test --project-path BuyLedger/BuyLedger.xcodeproj --scheme BuyLedger --simulator-name "iPhone 17"`
- 如需詳細 build error，CLI 預設只回 trailing `BUILD FAILED`；改用 `xcodebuildmcp --log-level error <subcommand> ...` 取得實際 diagnostic。

注意：三個 platform 的 simulator/macOS build 共用同一份 `DerivedData/.../XCBuildData/build.db`，不能並行跑 build；請序列化（`cmd1 && cmd2 && cmd3`）以避免 `database is locked` 失敗。

提交前請先執行 `git status --short`，確認只包含本次變更需要的檔案。

## App 進入點與平台導覽

`BuyLedgerApp.swift` 同時宣告 `WindowGroup` 與（macOS）`Settings { ... }` scene。注意：`#if os(macOS)` 不可同時包住 `WindowGroup` 的 modifier 與另一個 top-level `Scene`——必須切成兩個獨立 `#if os(macOS)` 區塊（否則 result builder 會 parse fail）。

`RootFeature.State.selectedTab` 驅動三種 layout：

- macOS：`RootSidebarLayout` 用 `NavigationSplitView` + sidebar + 訂單頁的 `.inspector(...)`。
- iPad（regular size class）：`RootSidebarLayout` 同 macOS 的 split 結構但無 inspector。
- iPhone（compact）：`RootTabLayout` 用 `TabView`。

`OrdersView` 是平台分流入口（`#if os(macOS)` → `OrdersMacView`、否則依 `horizontalSizeClass` 切 `OrdersCompactView` / `regularSplitContent`），`.sheet(item: $store.scope(state: \.editOrder, action: \.editOrder))` 一律掛在 `OrdersView` 外層，三平台共用。

跨頁觸發新訂單請使用 `RootFeature.Action.startNewOrder`：reducer 會同時把 `selectedTab` 切到 `.orders` 並把 `OrdersFeature.State.editOrder` 設成空白草稿，避免「Dashboard 按按鈕但 sheet 不彈」這類 view-not-in-hierarchy 的 race。

macOS 偏好設定改用標準的 `Settings { ... }` scene（⌘,），實作在 `Features/Settings/SettingsScene_macOS.swift`，採 `TabView` + `Form` + `.formStyle(.grouped)`。iOS / iPadOS 沿用 `SettingsView`（`Form` + `Section`）由 `MoreView` push 進入。`MoreView` 同時提供兩種佈局：iOS 為 grouped `List`、macOS 為 `LazyVGrid` 卡片網格（`#if os(macOS)`），且 macOS 版本不顯示「設定」入口。

## 資料層與 Dependency 注入

`OrderRepository`（`Core/Dependencies/OrderRepository.swift`）為訂單資料的 dependency 介面，背後接 `OrderPersistence`（`@ModelActor`）操作 SwiftData。

- `liveValue` 不會自動 seed sample 資料——使用者首次啟動會看到真正的空狀態（Dashboard 顯示 `onboardingHero`、Insights 顯示空狀態 `ContentUnavailableView`、Orders 顯示 `沒有符合條件的訂單`）。
- `previewValue` 使用 in-memory container 並傳 `seedSampleOrdersIfEmpty: true`，讓 SwiftUI Preview 與快照測試看得到內容。
- `LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback` **僅供 Preview / 單元測試 / `previewValue` 使用**，runtime path 不應讀取。
- macOS 沙盒 SwiftData store 在 `~/Library/Containers/com.leoho.BuyLedger/Data/Library/Application Support/BuyLedger.store{,-shm,-wal}`；要回到真正空狀態時可手動刪除（先停 app 再刪以釋放檔案 lock）。

`@ModelActor` 自動產生的 init 帶 main actor 隔離，所以 actor 實例必須在 `async` context 才能建立；參考 `OrderRepository.makePersistence(container:)` 用 `MainActor.run { ... }` 跳上 main 取得 actor 後再回到原 task。

TCA scope 透過 `Scope(state: \.orders, action: \.orders) { OrdersFeature() }` 等串起；feature view 端用 `store.scope(state: \.fx, action: \.fx)` 取子 store。Reducer body 內呼叫 State 上的 instance method 必須走 `store.state.method(...)`（不能透過 `@dynamicMemberLookup` 的 `store.method(...)`）。

## 外部 API 與 Fallback 政策

`ExchangeRateClient`（`Features/FX/ExchangeRateClient.swift`）封裝 ExchangeRate-API v6 的 `latest/{base}` endpoint。`fetchLatest(.twd)` 為唯一 runtime API call；歷史 endpoint 已移除（屬選用）。

API key 注入流程：

1. `BuyLedger/Resources/Config.xcconfig`（gitignored）放實際 key：`EXCHANGE_RATE_API_KEY = ...`。
2. `BuyLedger/Resources/Config.example.xcconfig`（committed）為範本。
3. `Config.xcconfig` 在 pbxproj 內以 `baseConfigurationReference` 掛到 app target 的 Debug + Release config（透過 `PBXFileReference` + `SOURCE_ROOT` path）。
4. `Info.plist` 內 `EXCHANGE_RATE_API_KEY` key 引用 `$(EXCHANGE_RATE_API_KEY)` build setting，build 時被注入。
5. `APIKeyProvider.liveValue` 從 `Bundle.main.infoDictionary` 讀回，nil/空字串時回傳 nil。

**runtime 不再使用 hardcoded fallback 匯率**——`FxFeature.State.rate / convertedTwd / displayRate(for:)` 全為 `Decimal?`，無 snapshot 時為 nil；`FxView` 顯示「—」並以 banner 提示錯誤。`QuoteFeature` 也自有 `ExchangeRateClient` 依賴，`.task` 載入失敗時 `rate = 0` cascade 歸零，view 顯示「尚無可用匯率資料」橫幅。`InsightsView` 訂單為空時整頁改成「尚未有足夠可用於分析的資料」`ContentUnavailableView`，不顯示空圖表。

Fallback 原則：UI 寧可顯示空狀態也不顯示假資料，避免讓使用者誤信。`FxRates` / `FxRateSnapshot.fallback` / `LedgerOrder.sampleOrders` 都已加 doc comment 標註「僅供 Preview / Tests」。

## 程式風格與命名慣例

Swift 程式碼請遵循 Swift API Design Guidelines。型別名稱使用 `UpperCamelCase`，屬性與函式使用 `lowerCamelCase`，測試方法名稱應清楚描述情境與預期結果。

命名請具體表達責任，例如 `TransactionListView`、`LedgerRepository`、`CurrencyFormatterService`。Swift 縮排使用四個空格。SwiftUI View 應保持小而聚焦，重複使用的 UI 請拆成獨立元件。

跨平台 UI 應優先使用 SwiftUI 條件編譯與平台慣用容器，例如 `#if os(macOS)`、`NavigationSplitView` 與 iOS/iPadOS 的 toolbar placement。TCA feature 應以 `Feature`、`State`、`Action`、`Reducer`、`Dependency` 清楚切分，避免把商業邏輯放在 SwiftUI View 中。SwiftData schema 或持久化行為變更時，應同步檢查 migration、preview 與測試資料。

避免提交本機 IDE 設定、產生的 archive、環境設定檔或任何只屬於開發機器的狀態檔。

## Design System 準則

Design System 應放在 `BuyLedger/BuyLedger/Shared/DesignSystem/`，並區分 `Foundations/` 與 `Components/`。`Foundations/` 放跨元件共用的 token、modifier 與語意模型；`Components/` 放可視 UI 元件，並依類別建立子資料夾。

每個主要元件或資料型別原則上各自一個 Swift 檔案，檔名必須對應主要型別名稱，例如 `BLBarChart.swift`、`BLDonutChart.swift`、`BLSparkline.swift`、`BLSearchField.swift`、`BLAmountField.swift`。避免建立 `BLCharts.swift`、`BLTextFields.swift` 這類同時涵括多種元件的大檔。若小型 enum 或 extension 只服務單一元件，可以與該元件同檔；若開始跨元件重用或變大，請拆出獨立檔案。

Design System Swift 檔案 header 使用 Xcode 預設格式：

```swift
//
//  FileName.swift
//  BuyLedger
//
//  Created by Leo Ho on yyyy/m/d.
//
```

註解請使用正體中文撰寫，語氣接近 Apple 官方文件風格。公開或內部共用的型別、屬性、`init`、`body`、helper method 與 preview sample 都應有清楚用途。不要為了補註解而新增不必要的顯式 `init`；能使用 Swift 合成 memberwise initializer 時請優先使用。只有在需要 `@ViewBuilder` trailing closure、無標籤參數的語意化 API、驗證、轉換或相依注入時才新增顯式 `init`。

`struct`、`enum`、`extension`、`final class` 等型別宣告後第一行要空一行。Design System 檔案請使用一致的 `MARK` 區段，例如：

- `// MARK: - View Properties`
- `// MARK: - Init`
- `// MARK: - View Body`
- `// MARK: - ViewBuilder`
- `// MARK: - Private Method`
- `// MARK: - Preview`

非 View 型別可依語意使用 `Cases`、`Data Properties`、`Identifiable Properties`、`Static Properties`、`View Method` 等段落。`#Preview` 放在檔案最後，前方加上 `// MARK: - Preview`。每個可視 Design System 元件都應提供自己的 `#Preview`；需要 binding 時使用 `.constant(...)`，需要圖表或狀態資料時用小型 sample data。

調整 Design System 結構或元件後，請至少執行 macOS 與 iOS Simulator build，確認 file system synchronized groups 正確拾取新增、搬移或刪除的 Swift 檔案。

## 測試準則

單元測試放在 `BuyLedger/BuyLedgerTests/`，UI 流程測試放在 `BuyLedger/BuyLedgerUITests/`。測試檔名應對應被測試的型別或功能，例如 `LedgerRepositoryTests.swift` 或 `AddTransactionFlowTests.swift`。

影響帳本餘額、資料持久化、CloudKit 同步、金額格式化、圖表資料彙總、跨平台 UI 行為與主要使用者流程的變更都應加入測試。TCA reducer 應使用 `TestStore` 驗證 action flow、state mutation 與 effects；SwiftData 測試應優先使用 in-memory container；CloudKit 相關邏輯應透過 dependency 抽象，避免單元測試直接依賴真實 iCloud 狀態。開啟 pull request 前，請執行完整測試指令並在 PR 說明中列出結果。

### Snapshot 測試（swift-snapshot-testing）

Snapshot baseline 放在 `BuyLedger/BuyLedgerTests/__Snapshots__/`，使用 `pointfreeco/swift-snapshot-testing` 套件，套件已在 BuyLedgerTests target 的 packageProductDependencies。第一次跑會 record baseline 並回報 fail（屬正常行為），確認視覺正確後 commit baseline；之後 view 變更若與 baseline 不符會 fail。`SnapshotTests.swift` 以 `#if canImport(SnapshotTesting) && os(iOS)` 包住，目前僅 iOS 393×852 baseline。設計大改時請刪掉對應 baseline 讓下一次跑自動重建。

## Commit 與 Pull Request 準則

請使用簡潔的 Conventional Commit 風格訊息，例如 `feat: add transaction list` 或 `docs: update contributor guide`。

Pull request 應包含簡短摘要、測試結果、相關 issue 連結，以及可見 UI 變更的截圖或 simulator 錄影。每個 PR 應聚焦在單一功能或修正。

## 安全性與設定注意事項

絕對不要提交 `.env`、`Config.xcconfig`（含實際 API key）、私鑰、provisioning profile、簽署憑證或其他敏感資料。`Config.example.xcconfig` 為提交版本的範本，實際 `Config.xcconfig` 已列入 `.gitignore`。

`BuyLedger.entitlements` 必須透過 pbxproj 的 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;` build setting 才會被 codesign 拿去簽；若忘了掛，binary 上只會出現 Xcode 自動加的 sandbox key，runtime 會抓不到設定的 entitlements 並出現難以診斷的錯誤（例如 macOS sandbox 阻擋 DNS 造成 NSURLErrorDomain Code -1003）。

macOS 沙盒下要打外部 API 必須加 `com.apple.security.network.client = true`。CloudKit container、`aps-environment` 等 entitlement key 等 Apple Developer 帳號實際 provision 後再加；未 provision 時加上會讓 codesign 失敗。CloudKit container、iCloud capability 與 entitlements 的變更需要在 PR 中明確說明。請提交 `Package.resolved` 等 lock file，讓 TCA 等相依套件解析結果可重現。

## Commit 風格

使用正體中文撰寫 Conventional Commits：`<type>(<scope>): <描述>`

常用 type：`feat`（新功能）、`fix`（修正）、`refactor`（重構）、`docs`（文件）、`chore`（雜項）、`ci`（CI/CD）、`test`（測試）、`style`（排版）。

由 Claude 建立或 amend 的 commit，commit message 最後須加入帶模型名的 Co-Authored-By trailer（display name 含當次實際使用的模型名，email 用 Claude Code 預設）：

```text
Co-Authored-By: Claude <model-name> <noreply@anthropic.com>
```

例如本次工作使用 Claude Opus 4.7 (1M Context)：

```text
Co-Authored-By: Claude Opus 4.7 (1M Context) <noreply@anthropic.com>
```

description（body）使用列點格式，例如：

```text
refactor(settings-view): 設定頁面 Cupertino → Material 3 重構

- 移除所有 Cupertino 元件
- 統一採用 Material 3 Card.filled + ListTile 呈現
```
