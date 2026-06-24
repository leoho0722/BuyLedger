# Apple 平台指引 (iOS / iPadOS / macOS)

本檔記錄 Apple 平台 (apps/apple) 的硬規則與隱性 gotcha；跨平台通用規範 (產品政策、標點、註解、Commit 風格等) 見 repo 根目錄的 [`CLAUDE.md`](../../CLAUDE.md)，產品介紹與 monorepo 結構見根目錄 [`README.md`](../../README.md)，平台環境設定與 build / test 見本目錄 [`README.md`](README.md)。

## 主要技術棧

- **Swift 6 strict concurrency**：專案層級 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` (不是 `MainActor`)。改成 `MainActor` 會讓 SwiftData `@Model` 與 `@ModelActor` 編不過。需要 main actor 才安全的型別請對個別宣告加 `@MainActor`。
- **TCA Reducer body** 使用顯式 `some Reducer<State, Action>`，不可用 `some ReducerOf<Self>` (會 circular reference)。

## 文件查證準則

- Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 除了 Context7 之外，另外用 **Apple docs MCP** 對照；兩邊文件矛盾時不可自決，先列差異與建議選項問使用者。

## 建置、測試與開發指令

本平台必守鐵則：

- 絕不退回原生 `xcodebuild` / `xcrun` / `simctl`。
- **任何 build 前先把 build number +1**——凡 build / build-and-run (不論 simulator / macOS / device、不論 MCP 工具或 CLI)，執行前必須先跑 `cd apps/apple && agvtool next-version -all`，將 `CURRENT_PROJECT_VERSION` (即 CFBundleVersion，相當於 Android 的 versionCode) 遞增 1；**跑 test 不遞增** (test binary 不會被安裝或散佈，遞增只製造 pbxproj 雜訊)。`agvtool` 是上一條「絕不退回原生工具」的明文例外 (版本管理不在 XcodeBuildMCP 能力範圍)。同一輪驗證中以 `&&` 串接的多平台 build 視為一次、只遞增一次；遞增產生的 pbxproj 變更隨當次工作一併 commit，不可丟棄。
- 三平台 simulator/macOS build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不能並行**——請序列化 (`cmd1 && cmd2 && cmd3`)，否則 `database is locked`。
- 詳細 build error 要加 `xcodebuildmcp --log-level error <subcommand> ...`，否則 CLI 只回 trailing `BUILD FAILED`。
- simulator 名稱不要寫死，跑 build-and-run 前先 `xcodebuildmcp simulator list-sims` 查當前可用名稱。
- macOS rebuild-and-launch 前先 `xcodebuildmcp macos stop --app-name BuyLedger` 關掉前一個 App (XcodeBuildMCP 預設只啟 simulator 工具集，macOS 走 CLI)，否則新 binary 不會被載入。
- 模擬器跑 App 用 `build-and-run`，不要先 `build` 再 `build-and-run`。

## App 進入點與平台導覽

動到這層程式碼時請遵守：

- **`BuyLedgerApp.swift` 的 `#if os(macOS)`**：不可同時包住 `WindowGroup` 的 modifier 與另一個 top-level `Scene`——必須切成兩個獨立 `#if os(macOS)` 區塊，否則 result builder 會 parse fail。
- **啟動時的服務初始化集中在 `AppLaunchConfigurator.configure()`** (Firebase Analytics / Crashlytics / Performance / Firestore)——三平台分流的 `AppDelegate` 都只在 `didFinishLaunching` 呼叫它，新增啟動設定請加在這裡，不要散落各平台進入點。Firebase 依賴 pbxproj 的 `OTHER_LDFLAGS = "-ObjC"`，不可移除。
- **跨頁觸發新訂單**請使用 `RootFeature.Action.startNewOrder`：reducer 會同時把 `selectedTab` 切到 `.orders` 並把 `OrdersFeature.State.editOrder` 設成空白草稿。從非 `.orders` 分頁直接設 sheet state 會發生 view-not-in-hierarchy 的 race——`.sheet(...)` 修飾子掛在 `OrdersView` 上，當下不在 hierarchy 就不會 mount。
- **`OrdersView` 的 `.sheet(item: $store.scope(state: \.editOrder, action: \.editOrder))`** 一律掛在 `OrdersView` 外層，三平台共用——不可移到平台分流後的子 view 裡。
- **點空白處收鍵盤用 `dismissKeyboardOnTap()`** (`Shared/Keyboard/`)：iOS / iPadOS 以 **window 級** `UITapGestureRecognizer` 實作，靠 `blocksKeyboardDismissTap` 沿 superview 逐層過濾互動 (`UIControl` / `UITextInput`)、文字編輯與系統選單 view——**不可改成對所有 touch 都收鍵盤** (會誤觸貼上／選取等系統 action)。macOS 無軟體鍵盤，為 no-op。
- **iPhone (compact) 的 NavigationStack 不要用 `.toolbar` 的 `.bottomBar`**：compact 走 `RootTabLayout` 的 `TabView`，底部 tab bar 會蓋掉 `.bottomBar`，工具列項目 (如多選的批次操作) 在實機上看不到。批次／選取類操作改放 `.primaryAction` 等頂部 placement，筆數等資訊可放 `navigationTitle`。iPad (regular) / macOS 走 `RootSidebarLayout` 無底部 tab bar，`.bottomBar` 才安全 (`OrdersView.regularSplitContent` 仍用之)。

## 資料層與 Dependency 注入

- **`liveValue` 不自動 seed sample 資料**——使用者首次啟動是真正的空狀態 (Dashboard 顯示 `onboardingHero`、Insights 顯示空狀態 `ContentUnavailableView`、Orders 顯示「沒有符合條件的訂單」)。
- **`previewValue`** 使用 in-memory container 並傳 `seedSampleOrdersIfEmpty: true`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- **`LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback` 與 `FxRates`** 僅供 Preview / 單元測試 / `previewValue` 使用，runtime path **不應讀取**。
- **`@ModelActor` init 帶 main actor 隔離**——actor 實例必須在 `async` context 才能建立。參考 `OrderRepository.makePersistence(container:)` 用 `MainActor.run { ... }` 跳上 main 取得 actor 後再回到原 task。
- **多個 repository 共用單一 `ModelContainer`**——`Core/Dependencies/` 下所有 `*Repository` 的 `liveValue` 一律走 `PersistenceContainer.shared`，**不可各自呼叫 `makeForApp()`**；同一 process 內並存多個 container (即使底層 SQLite 同名) 會造成 SwiftData 內部狀態錯亂。
- **Repository 一律以 type-based `@Dependency(SomeRepository.self)` 注入**——新 repo 不再新增 `DependencyValues` keyPath；reducer 在 `// MARK: - Dependency Properties` 宣告 `@Dependency(OrderRepository.self) private var orderRepository`。
- **主檔 (訂單來源／商品類別／付款方式) CRUD 走 `LookupManagementFeature`** (以 `LookupKind` 分流共用同一份 reducer/view)，它只負責寫各自的 DB 主檔表。**cascade 到 `OrdersFeature.State` 的 in-memory master 副本 (`orderSourceMaster` / `categoryMaster` / `paymentMethodMaster`) 與訂單表的 rename，由 `RootFeature` 攔截 `renameRequested` / `addConfirmed` / `deleteRequested` 處理**——新增主檔型別或動到 cascade 時這兩處都要顧。
- **`LedgerOrder` 是 immutable struct**——cascade rename 等要改任一欄位時必須用 memberwise init 重建整筆 (參考 `RootFeature.rebuildOrder`)，不可就地 mutate。
- **Reducer body 內呼叫 State 上的 instance method** 必須走 `store.state.method(...)`，不可透過 `@dynamicMemberLookup` 的 `store.method(...)`。

## 生成式 Data Model (Core/Domain/Generated/)

`Core/Domain/` 的資料形狀由 `shared/data-model` 的 `datamodel-gen` 產生器產出 (跨平台 schema → Swift)，**不再手寫**。跨平台規範見 root [`CLAUDE.md`](../../CLAUDE.md) 的「跨平台 Data Model」；Apple 端 gotcha：

- **生成檔在 `Core/Domain/Generated/<Type>.generated.swift`**——含型別主宣告 (stored properties / cases、由 trait 對應的 conformances + 全域 `Sendable`、必要時的顯式 init)。**不可手動編輯**；要改形狀請改 `shared/data-model/schema/` 後 `cd shared/data-model/generator && bun run generate`。
- **生成檔在磁碟上預設唯讀** (`generate` 會 chmod `0o444`)——Xcode 編譯只讀取、不受影響；重生成直接再跑 `bun run generate` 即可 (會自動解鎖重寫)，真要手動檢視才 `bun run unlock`。若 IDE 提示檔案唯讀無法存檔，代表你正試圖手改生成檔——應改 schema 重生成。
- **手寫邏輯放同名 extension 檔**——例如 `LedgerOrder.swift` 只含 `extension LedgerOrder { ... }` 的 computed properties、display title、static 集合、自訂 `Codable`；無剩餘手寫邏輯的型別 (如 `Money`、`LedgerCustomer`、`PaymentMethodInfo`) 沒有手寫檔，由生成檔完整提供。
- **全型別補 `Sendable`**——emitter 對所有生成 struct / enum 無條件加 `Sendable` (補上編譯器本已合成、舊源碼漏標的標註)；`sendable` 不是 schema trait，不要寫進 schema。
- **`serialization: custom` 的型別** (`CurrencyCode`、`LedgerOrderItem`) 生成宣告不含 `Codable`，自訂 `Codable` 留在手寫 extension，保住既有編碼形狀 (如 `LedgerOrderItem` 刻意不寫出 `id`)。
- **提交前跑 `bun run check`** (於 `shared/data-model/generator`) 確認生成檔與 schema 同步 (exit 0)；生成檔與 schema 一起 commit。
- **新增／刪除 Domain 型別後以三平台 build 驗證**——`Core/Domain/` 是 file system synchronized group，新檔 (含 `Generated/` 子資料夾) 自動納入；務必 iOS + iPadOS + macOS 各 build 一次確認拾取正確。

## SwiftData Schema 與 Migration

Schema 採版本化 `VersionedSchema`，設有 migration floor (floor 以下的版本已移除)，floor 到 target 之間的中間版本凍結為影子，遷移由 `BuyLedgerMigrationPlan` (`SchemaMigrationPlan`) 串接，全部定義在 `Core/Persistence/BuyLedgerSchema.swift`。

- **只有最新版本引用 top-level `@Model` 型別**——target 版本的 `models` 指向 `OrderRecord` 等 top-level 定義；**floor 以外的每個保留舊版本必須把當時的 `@Model` 凍結成內嵌於該 enum 的 shadow 型別**，保住當時的 attribute fingerprint，否則改動 top-level 型別會連帶破壞舊 schema 指紋導致 migration 失敗 (floor 本身的 `OrderRecord` 也已是凍結影子)。
- **加欄位／加表 → `.lightweight`；改型別 → `.custom`**——新增帶 default 的欄位或全新 model 走 lightweight；改變既有欄位型別必須走 `.custom` 的 dump-and-restore (歷史案例與 pattern 細節見 `/swiftdata-schema-migration` skill)。
- **改 schema 時，invoke `/swiftdata-schema-migration` 取得逐步操作指引** (新增版本 enum、凍結舊版 shadow、append migration stage、更新 `PersistenceContainer.make`)。
- **移除舊版本是單向操作**——遷移為 forward-only，plan 只需「最舊仍存在的 store 版本 (floor) → target」之間連續的 stage 鏈。移除舊版會把 floor 往上抬；任何停在低於新 floor 的 on-disk store 將失去遷移路徑，開啟時 `ModelContainer` init 拋錯、進而觸發 `makeForApp()` 砍檔。**只有確定沒有任何已安裝 store 停在被移除的版本 (或更早) 時才可移除**；上架後此前提幾乎不成立，務必保留能回溯到最舊可能 store 的完整版本鏈。
- **「已在最新版就安全」僅限單機**——「已在 target 的 store 不觸發遷移、移除舊版不受影響」是 per-device 結論。目前 CloudKit 為 `.disabled` (code 與 entitlements 皆關) 故成立；一旦啟用 sync，離線停在舊版的第二台裝置升級後同樣會觸發砍檔，且刪除可能透過 sync 傳播——啟用 sync 前必須重新評估版本移除策略。
- `PersistenceContainer.makeForApp()` 在 container 建立失敗時會「清掉舊 store 重建、再退回 in-memory」——這是**開發期 fallback**，要保留使用者資料時請補正確的 migration stage，不要依賴這段砍檔邏輯。

## 外部 API 實作

- 幣別清單經 `CurrencyMetadataRepository.refreshIfStale(604_800)` 打 `/codes` 並 cache 7 天 (動態載入、不可 hardcode 的政策見 root `CLAUDE.md`)。

## 程式風格 Apple 補充

通用標點、註解語言與 Commit 風格見 root `CLAUDE.md`；以下是 Swift / SwiftUI / TCA 專屬規則。

### 結構與命名

- **商業邏輯／資料計算** (彙總、分組、排序、格式化) 一律放 reducer 或可測試的 feature helper；SwiftUI View (含 Swift Charts) 只負責呈現，不要把計算 inline 在 view body。
- **TCA feature** 內部用 `// MARK: - State / Action / Dependency Properties / Reducer Body` 等清楚切分 (順序見「MARK 區段與排版」一節的對照表)。
- **不用 `switch`／`if` 運算式賦值**：避免 `let x = switch … { … }` / `let x = if … { … }` 這種運算式寫法；改用傳統陳述式 (先宣告 `let x: T`，再於各分支賦值)。若該計算寫在 `@ViewBuilder` body 內會與 result builder 衝突，請抽成獨立 helper 回傳該值，view body 只呼叫 helper。

### 註解

- 不要為了補註解而新增不必要的顯式 `init`；能使用 Swift 合成 memberwise initializer 時請優先使用。只有在需要 `@ViewBuilder` trailing closure、無標籤參數的語意化 API、驗證、轉換或相依注入時才新增顯式 `init`。

### MARK 區段與排版

- `struct` / `enum` / `extension` / `final class` 等型別宣告後第一行要空一行。
- 所有型別共用同一套「由上到下」的區段順序。View 型別用完整版；非 View 型別沿用**相同順序**，只是把 View 專屬段落換成語意對應段名、或在無內容時直接略過。**沒有對應成員的段落不要寫**——不留空 `// MARK:`、不留空 `extension` (例如沒有任何 `@ViewBuilder` 方法時，不保留 `// MARK: - ViewBuilder`)。

  | # | 位置語意             | View                   | TCA Reducer             | 其他型別 (enum / struct / class)                                                     |
  |---|----------------------|------------------------|-------------------------|--------------------------------------------------------------------------------------|
  | 1 | 內容定義 (狀態／屬性) | `View Properties`      | `State`、`Action`        | `Cases` (enum) → `Identifiable Properties` → `Data Properties` → `Static Properties` |
  | 2 | 初始化               | `Init`                 | (少見)                  | `Init`                                                                               |
  | 3 | 相依注入             | 併入 `View Properties` | `Dependency Properties` | `Dependency Properties` (若有)                                                       |
  | 4 | 主體／核心計算        | `View Body`            | `Reducer Body`          | `Computed Properties`／主要對外計算 (可用語意名，如 `Display Properties`)              |
  | 5 | 巢狀型別             | `Nested Types`         | `Nested Types`          | `Nested Types`                                                                       |
  | 6 | ViewBuilder          | `ViewBuilder`          | —                       | —                                                                                    |
  | 7 | 方法                 | `Private Method`       | `Private Method`        | `Private Method` (靜態成員可另立 `Static Method`)                                    |
  | 8 | 預覽                 | `Preview`              | —                       | `Preview` (僅 Design System 元件等可預覽型別)                                        |

- **第 5～8 區段一律寫在型別主體外**，讓主體專注在「它是什麼」與「主要計算」。其中 Nested Types 視該巢狀型別是否需被外部 (其他檔／測試) 引用，用 `extension` 或 `private extension` 切分 (型別本身的 access level 也據此決定)；ViewBuilder 與 Private Method 一律 `private extension`；Preview 則是檔尾的 `#Preview`。
- **`ViewBuilder` 段的成員 (`func` 或 `var` 回傳 `some View`) 一律標註 `@ViewBuilder`**——即使只回傳單一 view 也要標，全專案統一這一種寫法，不採「不標 `@ViewBuilder`、改用 `return` 回傳單一 view」的另一種。理由：`@ViewBuilder` 對單一 view 同樣合法，且日後加 `if`／`switch` 分支或並列多個 view 時不必改寫。此規定僅適用於「組合 view 內容」的 helper；下列不在此列：協定的 `body`／`makeBody`／`ViewModifier.body(content:)` (已隱含 builder)、以及 `View` 擴充上「套一層 modifier 就回傳」的 API (如 `blCardShadow()`／`blTextStyle()`，歸 `// MARK: - View Method`)。
- **方法一律收在 `// MARK: - Private Method`**：不要用 `Formatting`、`Layout Helper`、`Aggregation` 等 purpose 名稱另立方法段；需要分小類時，在同一個 `private extension` 內用無破折號的 `// MARK: <子分類>` 細分 (靜態成員可另立 `// MARK: - Static Method`)。property／計算類語意名 (如 `Display Properties`) 仍可用，放第 1 或第 4 區段。
- **`ViewModifier` 型別**比照 View 排序 (其 `body(content:)` 即第 4 區段「主體」，由協定隱含 `@ViewBuilder` 故毋須標)；若是某檔的次要型別，段首以 `// MARK: - ViewModifier` 標示 (而非 `ViewBuilder`)。Design System 中可重用的 ViewModifier 各自獨立一檔，集中放 `Shared/DesignSystem/Foundations/ViewModifiers/`。
- `#Preview` 放在檔案最後，前方加上 `// MARK: - Preview`。

建立新 Swift 檔案時，invoke `/swift-file-template` 取得檔案 header 格式與 View / 非 View 型別 / TCA Reducer 的具體程式碼範本。

## Design System 準則

- Design System 放在 `apps/apple/BuyLedger/Shared/DesignSystem/`，並區分 `Foundations/` 與 `Components/`。`Foundations/` 放跨元件共用的 token、modifier 與語意模型；`Components/` 放可視 UI 元件，並依類別建立子資料夾。
- 每個主要元件或資料型別原則上各自一個 Swift 檔案，檔名必須對應主要型別名稱 (例如 `BLBarChart.swift`、`BLDonutChart.swift`、`BLSparkline.swift`、`BLSearchField.swift`、`BLAmountField.swift`)。避免建立 `BLCharts.swift`、`BLTextFields.swift` 這類同時涵括多種元件的大檔。若小型 enum 或 extension 只服務單一元件，可以與該元件同檔；若開始跨元件重用或變大，請拆出獨立檔案。
- 每個可視 Design System 元件都應提供自己的 `#Preview`；需要 binding 時使用 `.constant(...)`，需要圖表或狀態資料時用小型 sample data。
- 調整 Design System 結構或元件後，請至少執行 macOS 與 iOS Simulator build，確認 file system synchronized groups 正確拾取新增、搬移或刪除的 Swift 檔案。

## 測試準則

單元測試放在 `apps/apple/BuyLedgerTests/`，UI 流程測試放在 `apps/apple/BuyLedgerUITests/`。測試檔名對應被測試的型別或功能 (例如 `OrdersFeatureTests.swift`、`OrderPersistenceTests.swift`)。

### Snapshot 測試 (swift-snapshot-testing)

Baseline 在 `BuyLedgerTests/__Snapshots__/`；`SnapshotTests.swift` 以 `#if canImport(SnapshotTesting) && os(iOS)` 包住，目前僅 iOS 393×852 baseline。record / commit 流程與設計大改重建見 [README.md › 執行測試](README.md#3-執行測試) 與本目錄 README 的 Troubleshooting。

**硬規則**：每個 snapshot test 必須用 `TestDependencies.withFixedNow { ... }` (`BuyLedgerTests/TestDependencies.swift`) 包住 view 建構與 `assertSnapshot`，注入固定 `\.date` (2026-04-30 UTC)；不要在測試裡直接 `Date()`。

## 環境相依性與依賴注入

root `CLAUDE.md` 的注入原則在本平台的具體落地：production code **一律走 `@Dependency`，不可直接呼叫 `Date()` / `UUID()` / `Locale.current` / `TimeZone.current` / `Calendar.current`** (除了 dependency 註冊處本身)。

具體規則：

- TCA Reducer：在 `// MARK: - Dependency Properties` 區塊加 `@Dependency(\.date) private var date` 等；reducer body 中以 `date.now`、`uuid()` 取值。
- SwiftUI View：同樣可加 `@Dependency(\.date) private var date`，在 view body 或 helper method 中以 `date()` / `date.now` 取值。
- State 上的 computed property 不可內部呼叫 `Date()`——改成 `func foo(referenceDate: Date) -> ...` 由 caller (reducer 或 view) 以注入後的 date 傳入。

測試端：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；snapshot test 用 `TestDependencies.withFixedNow { ... }`。Calendar 相關測試需要固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)` 確保跨機器一致。

## 安全性與設定注意事項

`BuyLedger.entitlements` 必須透過 pbxproj 的 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;` build setting 才會被 codesign 拿去簽；若忘了掛，binary 上只會出現 Xcode 自動加的 sandbox key，runtime 會抓不到設定的 entitlements 並出現難以診斷的錯誤。

macOS 沙盒下要打外部 API 必須加 `com.apple.security.network.client = true`。CloudKit container、`aps-environment` 等 entitlement key 等 Apple Developer 帳號實際 provision 後再加；未 provision 時加上會讓 codesign 失敗。CloudKit container、iCloud capability 與 entitlements 的變更需要在 PR 中明確說明。

## 跨裝置同步 (opt-in、離線優先)

跨裝置同步 (change `enable-cross-device-sync`，承接 `firebase-auth-multiuser-sync`) 已**真正啟用**：同帳號任意兩平台 (iOS↔web) 經後端 (Postgres 為 SoT) + per-user Firestore 投影 (即時讀) 傳播 Order/Campaign。iOS 採**離線優先**——SwiftData (`PersistenceContainer.shared`、CloudKit 仍 `.disabled`) 維持唯一本機 SoT、離線可完整新增/編輯/刪除；同步為 **opt-in 預設關閉**，總開關為 `App/CloudSyncFeatureFlag.swift` 的 `CloudSyncFeatureFlag.isEnabled` (預設 `false`)。flag 關閉時不實例化任何 `CloudSyncEngine` / `BackendAPIClient` / listener、不顯示登入、不存取 Firestore，行為純本機。owner 為後端持久化概念，**iOS 領域模型不帶 ownerUid** (Option B)。

- **flag OFF 時 schema 仍升 V12 並建空 sidecar 表**——`CloudSyncFeatureFlag.isEnabled == false` 只關掉「同步行為」，**不關掉 schema migration**：`BuyLedgerSchemaV12` (lightweight) 一律生效，即使從不開同步的 store 開啟時也會建立空的 `SyncMeta` / `SyncQueueItem` sidecar 表。flag-gate 的範圍是「不跑同步引擎」，不是「儲存層完全無痕」；不要誤以為關閉同步就不會動 on-disk schema。
- **HLC client** (`Core/Sync/Hlc.swift` / `HlcClient.swift`)：物理毫秒一律經 `@Dependency(\.date)` 取得 (`HlcClient.live` 內 `date.now`，引擎本身不直接讀系統時鐘，對齊環境相依注入鐵則)；`writerId` 採此安裝的 **Firebase Installation ID (FID)** (`Installations.installations().installationID()`、於 `CloudSyncEngine.start()` 取得快取)——FCM device token 因需 APNs / `aps-environment` (未 provision) 否決，FID 免 APNs 且非自產 UUID；`lastIssued` HLC 持久化在 `SyncMeta` (生成/receive 經 `SyncMetaPersistence` 在 `@ModelActor` 內單次「載入→逐欄處理→存回」原子推進，避免 `await` 點交錯導致時鐘重複或回退)。
- **`CloudSyncEngine`** (`Features/App/CloudSyncEngine.swift`)：以 `cloudSync.ordersCollection().addSnapshotListener` 訂閱 orders 投影、逐欄合併進 SwiftData——遠端欄位套用 iff `remoteClock > localClock` 且該欄位非本機 DIRTY；**保護 DIRTY 但不丟棄較高時鐘**，被略過的較高遠端值記入 `SyncMeta.pendingRemote` (有別於 `lastPulledVersion`)、不靜默丟棄。DIRTY 只在 push-ack 時清除：依 PATCH 回應的 `appliedFieldClocks` + 回傳的 order DTO **逐欄對帳** (`appliedFieldClocks[X] == myPushedClock` → 本機勝、寫 clock 清 DIRTY；`>` → 採伺服器權威值 + clock 清 DIRTY；清除後 `pendingRemote[X]` 較高則補套)，不靠「HTTP 送達」當「我方勝出」。刪除為帶時鐘 tombstone + 非破壞性復活 (Option A，`p→c→w` 統一比較器、不為刪除另開特例)。拉取後以 `onOrdersMerged` 觸發 `OrdersFeature.reloadFromStore` (繞過 `.task` 的 `hasLoaded` 防重載) 讓 TCA 畫面即時重讀。`deinit` 須移除 listener 與 NotificationCenter observer (需 `@preconcurrency import FirebaseFirestore`)。
- **待送佇列** (`Core/Sync/SyncQueueItem.swift` / `SyncQueuePersistence.swift`)：寫入失敗 retry **3 次** (backoff) 後該筆 `SyncQueueItem` 留在本機持久化佇列；`CloudSyncEngine.drainQueue()` 於 **app 啟動**與 `NetworkPathMonitor` (`Core/Sync/NetworkPathMonitor.swift`，包 `NWPathMonitor` 為可注入 `AsyncStream<Bool>`) **重連時** drain 重送；逐 id 的「待同步 / 失敗」狀態 (`pending` / `failed`) 與 `retryCount` 存 `SyncMeta`。重送以 UUID upsert 冪等。
- **照片走 Firebase Storage `photoRefs`**——Firestore 投影以 `photoRefs` 鍵承載 Storage 路徑參照 (絕不放 base64)；拉取端 (`Core/Sync/PhotoRefResolver.swift`，`@preconcurrency import FirebaseStorage`) 在任何欄位合併前先把 `photoRefs` 下載解析回 `[Data]`，個別參照失敗時略過該張、不阻斷整筆合併；client 絕不上傳 Storage (後端維持 Storage 唯一寫入方)。
- **同步 metadata 全放本機專屬 sidecar、不入領域/生成型別**——每欄位時鐘、DIRTY 集、tombstone、`pending`/`failed`、`lastIssued` HLC、`pendingRemote`、`photoRefs` 一律存 `SyncMeta` / `SyncQueueItem` (本機專屬 `@Model`)，**不寫進 `OrderRecord` 或 `Core/Domain/Generated/` 生成型別** (避免污染 mapping、觸發屬性指紋 migration、誘使違規改 shared schema)。

### Firebase 套件與登入

- **目前 target link 了 `FirebaseCore` / `FirebaseFirestore` / `FirebaseAnalytics` / `FirebaseInstallations` / `FirebaseStorage`**，`GoogleService-Info.plist` 已放在 `BuyLedger/Resources/`。
- **要做 Firebase Auth (Google / Apple) 登入須先在 Xcode 對 target 加 `FirebaseAuth` (同 firebase-ios-sdk 套件、已解析) 與 GoogleSignIn-iOS 套件的 `GoogleSignIn` (`GIDSignIn` 登入流程) + `GoogleSignInSwift` (官方 SwiftUI 按鈕) 產品**——加 SPM 產品請用 Xcode 操作、勿手改 pbxproj。登入畫面的 Google 按鈕一律用 `GoogleSignInSwift` 的 `GoogleSignInButton`、不自製。Apple 登入走內建 `AuthenticationServices` + Firebase `OAuthProvider("apple.com")`。
- **Google 登入必須在 `Info.plist` 的 `CFBundleURLTypes` 註冊 `GoogleService-Info.plist` 的 `REVERSED_CLIENT_ID` (即 `com.googleusercontent.apps.<…>`) 為 URL scheme**——少了它，點 Google 登入按鈕時 `GIDSignIn` 會拋 ObjC `NSException` (「missing URL schemes」)，且該例外非 Swift `Error`、`do-catch` 攔不到，會直接閃退 (本檔 `Info.plist` 又設 `NSApplicationCrashOnExceptions`)。換 Firebase 專案 / client ID 時要同步更新此 scheme。
- **後端 base URL 走 `AppConfiguration` 從 `Info.plist` 讀回** (`BACKEND_API_BASE_URL`，非機密直接定義；`BackendAPIClient.baseURL` 不寫死)，網路層收斂到 `HTTPClient`。
- 啟用流程：登入取得 Firebase ID token → 各 API 請求夾帶 `Authorization: Bearer` → 寫入走後端 `applyFieldWrites` 欄位級合併、讀自己的 `users/{uid}/…` Firestore 投影即時同步。
