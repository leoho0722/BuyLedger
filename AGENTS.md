<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `$spectra-*` skills when:

- A discussion needs structure before coding → `$spectra-discuss`
- User wants to plan, propose, or design a change → `$spectra-propose`
- Tasks are ready to implement → `$spectra-apply`
- There's an in-progress change to continue → `$spectra-ingest`
- User asks about specs or how something works → `$spectra-ask`
- Implementation is done → `$spectra-archive`
- Commit only files related to a specific change → `$spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `$spectra-apply` and `$spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# 儲存庫指引

專案概覽、目錄結構、技術棧背景與 setup 步驟見 [`README.md`](README.md)。本檔僅記錄 Codex 寫程式時必須遵守的硬規則與隱性 gotcha。

## 主要技術棧

- **Swift 6 strict concurrency**：專案層級 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` (不是 `MainActor`)。改成 `MainActor` 會讓 SwiftData `@Model` 與 `@ModelActor` 編不過。需要 main actor 才安全的型別請對個別宣告加 `@MainActor`。
- **TCA Reducer body** 使用顯式 `some Reducer<State, Action>`，不可用 `some ReducerOf<Self>` (會 circular reference)。

## 文件查證準則

- 動 Apple 框架或第三方套件前先用 **Context7** 查最新官方文件，不要憑記憶或舊範例。
- Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 另外用 **Apple docs MCP** 對照；兩邊文件矛盾時不可自決，先列差異與建議選項問使用者。

## 建置、測試與開發指令

完整指令範例見 [README.md › Build & Run](README.md#2-build--run)。

**預設用 CLI `xcodebuildmcp <subcommand>`**：build / run / test、查狀態、列舉 simulator 或 scheme、可複現指令 (CI、教學、script)、批次與管線處理 (`| grep`、`| jq`、`>` 存檔) 等都走 CLI。

**切到 MCP server `mcp__XcodeBuildMCP__*`** 的時機：

- UI 自動化 (`snapshot_ui` / `tap` / `swipe`) 與 screenshot
- 需要結構化測試結果或 coverage 報告
- 長時間操作需可控中斷或串流 log
- 讀取或設定 session defaults

**通用鐵則**：

- 絕不退回原生 `xcodebuild` / `xcrun` / `simctl`。
- 三平台 simulator/macOS build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不能並行**——請序列化 (`cmd1 && cmd2 && cmd3`)，否則 `database is locked`。
- 詳細 build error 要加 `xcodebuildmcp --log-level error <subcommand> ...`，否則 CLI 只回 trailing `BUILD FAILED`。
- simulator 名稱不要寫死，跑 build-and-run 前先 `xcodebuildmcp simulator list-sims` 查當前可用名稱。
- macOS rebuild-and-launch 前先 `xcodebuildmcp macos stop --app-name BuyLedger` 關掉前一個 App (XcodeBuildMCP 預設只啟 simulator 工具集，macOS 走 CLI)，否則新 binary 不會被載入。
- 模擬器跑 App 用 `build-and-run`，不要先 `build` 再 `build-and-run`。
- 提交前先 `git status --short` 確認只包含本次變更的檔案。

## App 進入點與平台導覽

平台 layout 分流概覽見 [README.md › App 進入點與平台導覽](README.md#app-進入點與平台導覽)。動到這層程式碼時請遵守：

- **`BuyLedgerApp.swift` 的 `#if os(macOS)`**：不可同時包住 `WindowGroup` 的 modifier 與另一個 top-level `Scene`——必須切成兩個獨立 `#if os(macOS)` 區塊，否則 result builder 會 parse fail。
- **跨頁觸發新訂單**請使用 `RootFeature.Action.startNewOrder`：reducer 會同時把 `selectedTab` 切到 `.orders` 並把 `OrdersFeature.State.editOrder` 設成空白草稿。從非 `.orders` 分頁直接設 sheet state 會發生 view-not-in-hierarchy 的 race——`.sheet(...)` 修飾子掛在 `OrdersView` 上，當下不在 hierarchy 就不會 mount。
- **`OrdersView` 的 `.sheet(item: $store.scope(state: \.editOrder, action: \.editOrder))`** 一律掛在 `OrdersView` 外層，三平台共用——不可移到平台分流後的子 view 裡。
- **點空白處收鍵盤用 `dismissKeyboardOnTap()`** (`Shared/Keyboard/`)：iOS / iPadOS 以 **window 級** `UITapGestureRecognizer` 實作，靠 `blocksKeyboardDismissTap` 沿 superview 逐層過濾互動 (`UIControl` / `UITextInput`)、文字編輯與系統選單 view——**不可改成對所有 touch 都收鍵盤** (會誤觸貼上／選取等系統 action)。macOS 無軟體鍵盤，為 no-op。

## 資料層與 Dependency 注入

- **`liveValue` 不自動 seed sample 資料**——使用者首次啟動是真正的空狀態 (Dashboard 顯示 `onboardingHero`、Insights 顯示空狀態 `ContentUnavailableView`、Orders 顯示「沒有符合條件的訂單」)。
- **`previewValue`** 使用 in-memory container 並傳 `seedSampleOrdersIfEmpty: true`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- **`LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback`** 僅供 Preview / 單元測試 / `previewValue` 使用，runtime path **不應讀取**。
- **`@ModelActor` init 帶 main actor 隔離**——actor 實例必須在 `async` context 才能建立。參考 `OrderRepository.makePersistence(container:)` 用 `MainActor.run { ... }` 跳上 main 取得 actor 後再回到原 task。
- **多個 repository 共用單一 `ModelContainer`**——`OrderRepository` / `CategoryRepository` / `PaymentMethodRepository` / `OrderSourceRepository` / `CurrencyMetadataRepository` 的 `liveValue` 一律走 `PersistenceContainer.shared`，**不可各自呼叫 `makeForApp()`**；同一 process 內並存多個 container (即使底層 SQLite 同名) 會造成 SwiftData 內部狀態錯亂。
- **Repository 一律以 type-based `@Dependency(SomeRepository.self)` 注入**——新 repo 不再新增 `DependencyValues` keyPath；reducer 在 `// MARK: - Dependency Properties` 宣告 `@Dependency(OrderRepository.self) private var orderRepository`。
- **主檔 (訂單來源／商品類別／付款方式) CRUD 走 `LookupManagementFeature`** (以 `LookupKind` 分流共用同一份 reducer/view)，它只負責寫各自的 DB 主檔表。**cascade 到 `OrdersFeature.State` 的 in-memory master 副本 (`orderSourceMaster` / `categoryMaster` / `paymentMethodMaster`) 與訂單表的 rename，由 `RootFeature` 攔截 `renameRequested` / `addConfirmed` / `deleteRequested` 處理**——新增主檔型別或動到 cascade 時這兩處都要顧。
- **`LedgerOrder` 是 immutable struct**——cascade rename 等要改任一欄位時必須用 memberwise init 重建整筆 (參考 `RootFeature.rebuildOrder`)，不可就地 mutate。
- **Reducer body 內呼叫 State 上的 instance method** 必須走 `store.state.method(...)`，不可透過 `@dynamicMemberLookup` 的 `store.method(...)`。

## SwiftData Schema 與 Migration

Schema 採版本化 `VersionedSchema` (`BuyLedgerSchemaV1`…`V5`)，遷移由 `BuyLedgerMigrationPlan` (`SchemaMigrationPlan`) 串接，全部定義在 `Core/Persistence/BuyLedgerSchema.swift`。

- **只有最新版本引用 top-level `@Model` 型別**——`BuyLedgerSchemaV5.models` 指向 `OrderRecord` 等 top-level 定義；**所有舊版本 (V1–V4) 必須把當時的 `@Model` 凍結成內嵌於該 enum 的 shadow 型別**，保住當時的 attribute fingerprint，否則改動 top-level 型別會連帶破壞舊 schema 指紋導致 migration 失敗。
- **加欄位／加表 → `.lightweight`；改型別 → `.custom`**——新增帶 default 的欄位或全新 model 走 lightweight (如 V2→V5)；改變既有欄位型別 (如 V1 `currency` 由 enum 改 `String`) 必須走 `.custom` 的 dump-and-restore (`willMigrate` 序列化進記憶體再刪舊 row、`didMigrate` 用新版影子型別重建)。
- **改 schema 的標準流程**：(1) 新增 `BuyLedgerSchemaVN` 並列出 `models`；(2) 把上一版的 `OrderRecord` (與任何受影響型別) 凍結成該舊版 enum 內的 shadow `@Model`；(3) 在 `BuyLedgerMigrationPlan.schemas` 與 `stages` append 新版與遷移階段；(4) 把 `PersistenceContainer.make` 的 `Schema(versionedSchema:)` 指向新版。
- migration 跨 `willMigrate` / `didMigrate` 的中介 snapshot 用 `nonisolated(unsafe) static` (one-shot、單執行緒，無 race)。
- `PersistenceContainer.makeForApp()` 在 container 建立失敗時會「清掉舊 store 重建、再退回 in-memory」——這是**開發期 fallback**，要保留使用者資料時請補正確的 migration stage，不要依賴這段砍檔邏輯。

## 外部 API 與 Fallback 政策

API key 注入鏈路與設定步驟見 [README.md › ExchangeRate-API 金鑰](README.md#1-exchangerate-api-金鑰)。

- **UI 寧可顯示空狀態也不顯示假資料**——API 失敗或無資料時 view 顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，不繪空圖表也不退回 hardcoded 數字。
- **幣別主檔動態載入**——`RootFeature.task` 透過 `CurrencyMetadataRepository.refreshIfStale(604_800)` 打 ExchangeRate-API `/codes` 並 cache 7 天；幣別清單不再 hardcode。`ExchangeRateClient.fetchLatest(.twd)` 仍是匯率數值的 runtime call。
- `FxRates` / `FxRateSnapshot.fallback` / `LedgerOrder.sampleOrders` 僅供 Preview / Tests，runtime path **不可讀取**。

## 程式風格與命名慣例

Swift 通用慣例 (API Design Guidelines、camel case、四空格縮排) 不重述；以下是本專案的補充。

### 結構與命名

- **商業邏輯／資料計算** (彙總、分組、排序、格式化) 一律放 reducer 或可測試的 feature helper；SwiftUI View (含 Swift Charts) 只負責呈現，不要把計算 inline 在 view body。
- **TCA feature** 內部用 `// MARK: - State / Action / Reducer Body / Dependency Properties` 等清楚切分。
- **SwiftData schema 或持久化行為變更**時，須同步檢查 migration、preview 與測試資料。

### 標點與空格

中英數混排的字串字面值與註解一律使用**半形括號** `()`，不用全形 `（）`；並依前後文在中文與半形內容之間補一個半形空格，讓兩者分開更易讀。

- **補空格**：半形括號緊貼到 CJK 字元、英數或 inline-code backtick 時，於括號外側補一個半形空格。例如 `收款金額 (NT $)`、`為空 (最寬鬆路徑) 的成本`、`` `nonisolated` (不是 `MainActor`) ``。
- **不補空格**：相鄰為空白、全形標點 (，。、；：！？「」)、字串或行邊界時不補，避免重複間距。例如 `` `…回應錯誤 (\(code))，目前無法…` `` 後接全形逗號不補、`Text("(TWD)")` 緊貼引號不補。
- **括號內側不補**：`(NT $)` 而非 `( NT $ )`。
- **Markdown 例外**：粗體結尾 `**` 前後不補空格以免破壞 `**...**` 語法——`**計算** (彙總)` 可，`**計算 **(彙總)` 不可。
- 此規則同時適用於 UI 顯示字串與正體中文註解。

### 檔案 header

所有新建 Swift 檔案的 header 一律使用 Xcode 預設格式：

```swift
//
//  FileName.swift
//  BuyLedger
//
//  Created by Leo Ho on yyyy/m/d.
//
```

### 註解

- 註解一律使用正體中文撰寫，語氣接近 Apple 官方文件風格。
- 不要為了補註解而新增不必要的顯式 `init`；能使用 Swift 合成 memberwise initializer 時請優先使用。只有在需要 `@ViewBuilder` trailing closure、無標籤參數的語意化 API、驗證、轉換或相依注入時才新增顯式 `init`。

### MARK 區段與排版

- `struct` / `enum` / `extension` / `final class` 等型別宣告後第一行要空一行。
- View 型別常用 MARK 區段：

  - `// MARK: - View Properties`
  - `// MARK: - Init`
  - `// MARK: - View Body`
  - `// MARK: - Nested Types`
  - `// MARK: - ViewBuilder`
  - `// MARK: - Private Method`
  - `// MARK: - Preview`

- 非 View 型別可依語意使用 `Cases`、`Data Properties`、`Identifiable Properties`、`Static Properties`、`View Method` 等段落。
- `#Preview` 放在檔案最後，前方加上 `// MARK: - Preview`。

## Design System 準則

- Design System 放在 `BuyLedger/BuyLedger/Shared/DesignSystem/`，並區分 `Foundations/` 與 `Components/`。`Foundations/` 放跨元件共用的 token、modifier 與語意模型；`Components/` 放可視 UI 元件，並依類別建立子資料夾。
- 每個主要元件或資料型別原則上各自一個 Swift 檔案，檔名必須對應主要型別名稱 (例如 `BLBarChart.swift`、`BLDonutChart.swift`、`BLSparkline.swift`、`BLSearchField.swift`、`BLAmountField.swift`)。避免建立 `BLCharts.swift`、`BLTextFields.swift` 這類同時涵括多種元件的大檔。若小型 enum 或 extension 只服務單一元件，可以與該元件同檔；若開始跨元件重用或變大，請拆出獨立檔案。
- 每個可視 Design System 元件都應提供自己的 `#Preview`；需要 binding 時使用 `.constant(...)`，需要圖表或狀態資料時用小型 sample data。
- 調整 Design System 結構或元件後，請至少執行 macOS 與 iOS Simulator build，確認 file system synchronized groups 正確拾取新增、搬移或刪除的 Swift 檔案。

## 測試準則

單元測試放在 `BuyLedger/BuyLedgerTests/`，UI 流程測試放在 `BuyLedger/BuyLedgerUITests/`。測試檔名對應被測試的型別或功能 (例如 `OrdersFeatureTests.swift`、`OrderPersistenceTests.swift`)。

### Snapshot 測試 (swift-snapshot-testing)

Snapshot baseline 放在 `BuyLedger/BuyLedgerTests/__Snapshots__/`。第一次跑會 record baseline 並回報 fail (屬正常行為)，確認視覺正確後 commit baseline；之後 view 變更若與 baseline 不符會 fail。`SnapshotTests.swift` 以 `#if canImport(SnapshotTesting) && os(iOS)` 包住，目前僅 iOS 393×852 baseline。設計大改時請刪掉對應 baseline 讓下一次跑自動重建。

每個 snapshot test 都必須用 `TestDependencies.withFixedNow { ... }` (位於 `BuyLedgerTests/TestDependencies.swift`) 包住 view 建構與 `assertSnapshot` 呼叫；裡面把 `\.date` 注入成 2026-04-30 UTC，避免「跨日跑出不同 baseline」這類 flake。新加 snapshot 一律走這個 helper，不要在測試裡直接 `Date()`。

## 環境相依性與依賴注入

任何讀取「現在」時間、locale、時區、UUID、隨機數的程式碼，**production code 一律走 `@Dependency`，不可直接呼叫 `Date()` / `UUID()` / `Locale.current` / `TimeZone.current` / `Calendar.current`** (除了 dependency 註冊處本身)。

具體規則：

- TCA Reducer：在 `// MARK: - Dependency Properties` 區塊加 `@Dependency(\.date) private var date` 等；reducer body 中以 `date.now`、`uuid()` 取值。
- SwiftUI View：同樣可加 `@Dependency(\.date) private var date`，在 view body 或 helper method 中以 `date()` / `date.now` 取值。
- State 上的 computed property 不可內部呼叫 `Date()`——改成 `func foo(referenceDate: Date) -> ...` 由 caller (reducer 或 view) 以注入後的 date 傳入。

測試端：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；snapshot test 用 `TestDependencies.withFixedNow { ... }`。Calendar 相關測試需要固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)` 確保跨機器一致。

## 安全性與設定注意事項

`BuyLedger.entitlements` 必須透過 pbxproj 的 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;` build setting 才會被 codesign 拿去簽；若忘了掛，binary 上只會出現 Xcode 自動加的 sandbox key，runtime 會抓不到設定的 entitlements 並出現難以診斷的錯誤。

macOS 沙盒下要打外部 API 必須加 `com.apple.security.network.client = true`。CloudKit container、`aps-environment` 等 entitlement key 等 Apple Developer 帳號實際 provision 後再加；未 provision 時加上會讓 codesign 失敗。CloudKit container、iCloud capability 與 entitlements 的變更需要在 PR 中明確說明。

## Commit 風格

使用正體中文撰寫 Conventional Commits：`<type>(<scope>): <描述>`

常用 type：`feat` (新功能)、`fix` (修正)、`refactor` (重構)、`docs` (文件)、`chore` (雜項)、`ci` (CI/CD)、`test` (測試)、`style` (排版)。

由 Codex 建立或 amend 的 commit，commit message 最後必須加入 Co-Authored-By trailer，`<model-name>` 替換為當次實際使用的模型名稱：

```text
Co-Authored-By: Codex (<model-name>) <codex@openai.com>
```

description (body) 使用列點格式，例如：

```text
refactor(time): 時間相依改走 @Dependency(\.date) 注入

- DashboardView / InsightsView / RootFeature 加 @Dependency(\.date)
- OrdersFeature.State.filteredOrders 改成 func(referenceDate:)
- 新增 TestDependencies.fixedNow 給 snapshot 與 unit test 共用
```
