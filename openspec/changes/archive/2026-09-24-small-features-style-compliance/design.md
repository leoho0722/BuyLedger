## Context

第 3 步範圍是 `apps/ios/BuyLedger/Features/` 下六個區域的 17 個 production Swift 檔：`FX/` (2 檔)、`Quote/` (2 檔)、`Settings/` (5 檔)、`AISummary/` (4 檔)、`Customers/` (3 檔)、`More/` (1 檔)，加上跟著改的 6 個單元測試檔 (`FxFeatureTests`、`QuoteFeatureTests`、`SettingsFeatureTests`、`AISummaryFeatureTests`、`CustomersFeatureTests`、`OllamaClientTests`)。2026-09-14 全庫審查在這 23 檔記錄 491 筆待修項 (實測值，由報告資料集篩出，已排除尾隨空白)，逐筆明細在本目錄的 `findings.md`。

前兩步已把 Core、codegen 與 Shared／Design System 對齊並結案 (commit `30791e3`、`44e7799`)。本步的畫面依賴的錯誤型別、`CurrencyDisplayName`、`BLFormatters` 與 `OptionPickerSheet` 形狀已穩定。

**三種範圍要分清楚**：

- **審查基準**：上面 23 個檔案、491 筆，是 `findings.md` 逐筆要有結論的對象。
- **實作範圍**：proposal Impact 清單列出的全部檔案 (含連帶改名的 App、Core、Shared、Orders 檔與新增的元件、測試、文件)，也就是「範圍邊界」的 allowlist。
- **檢查範圍分兩組** (以完工時 `git status --porcelain` 列出的 Swift 檔為準)：
    - **A 組，整檔合規**：審查基準的 23 檔 (含改名後的 `SettingsStore.swift` 與搬到 `Core/Networking/` 的三個 Ollama 檔) 加上本步新增的全部 Swift 檔。驗收條件 1 至 3 的每一項對整個檔案檢查。
    - **B 組，只管改到的地方**：其餘連帶改動的既有檔 (`RootFeature`、`OrdersFeature`、`OrderFormatters`、`BuyLedgerApp`、`BLUITestDependencyOverrides`、`FxRateSnapshot`、`BLFormatters`、`Bundle+Extensions`、`OrdersFeatureTests`、`RootFeatureTests`、`SnapshotTests`、`BLFormattersTests`)。驗收條件 1 至 3 只對本步新增或修改的行、宣告與測試檢查 (以 `git diff` 的 hunk 判定)，檔案其餘既有違規屬各自的步驟，不在本步修。這與第 2 步的做法相同；實測 `OrdersFeature` 有 9 行、`BLUITestDependencyOverrides` 有 15 行超過 100 字元，整檔套用會把第 6、8 步的工作提前拉進來。

**本步是 TCA 寫法的範本**。後面第 4 至 8 步 (Lookups、Campaigns、Orders、Dashboard／Insights、App 殼層) 都要做同樣的 Action 分組、父子溝通與 View 瘦身，這裡的決策會被照抄，所以每條決策都寫到「換一個 Feature 也能照做」的程度。

**現況的四個結構問題** (已逐一讀過原始碼確認)：

- 五個 reducer (`FxFeature`、`QuoteFeature`、`SettingsFeature`、`AISummaryFeature`、`CustomersFeature`) 的 `Action` 全部平放；`body` 直接寫 `Reduce { state, action in ... }` 閉包；`@Dependency` 與 `private var` 同行，或在 reducer 分支內就地宣告 (`AISummaryFeature`)。
- `RootFeature` 在 `.task` 送 `.settings(.task)` 與 `.settings(.appLock(.appDidBecomeActive))`、在 `.dashboard(.delegate(.refresh))` 再送一次 `.settings(.task)`，並直接攔截 `.customers(.task)` 轉成 `.orders(.task)`。`CustomersView` 直接送 `.delegate(.customerTapped(...))`。目前沒有任何測試擋得住這些寫法。
- `FxView` 393 行、`QuoteView` 444 行 (2026-09-21 實測，不含前 7 行檔頭與空行；`findings.md` 的 398／448 是 2026-09-14 報告當時的數字，之後第 2 步改過這兩檔)，超過 `formatting.md` 的 300 行上限；兩者與 `CustomersView` 都在 View 內寫格式化方法或業務判斷。
- 設定的讀取 (`SettingsStorage.load()`) 在 reducer 內同步呼叫；月度目標的讀取用 `UserDefaults.double(forKey:)`，key 不存在時回 0，與註解及三處預設值 80,000 矛盾。已確認全專案沒有 `register(defaults:)`。

**限制與既有登記差異** (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」，本步沿用)：

- Reducer body 寫 `some Reducer<State, Action>`，不寫 `some ReducerOf<Self>` (後者 circular reference)。
- struct-of-closures Client 與 repository 宣告 `testValue` (`SettingsStore`、`OllamaClient` 屬此類)。
- 金額、百分比、日期格式化用 `BLFormatters`／`OrderFormatters`／`CampaignFormatters` 這類靜態函式，不是 `FormatStyle`。
- 檔頭日期一律不補零 `YYYY/M/D`。
- `Feature.State` 上顯式標註的 `Sendable` 是編譯期契約，不可刪除 (`SettingsFeature`／`FxFeature`／`QuoteFeature` 屬此類)。
- SwiftUI View 超過 300 行優先抽獨立 View 型別，不以跨檔 extension 拆分 (跨檔 extension 讀不到 `private @State`／`@Environment`)。

## Goals / Non-Goals

**Goals:**

- 23 個檔案符合 `/ios-dev-kit` 的 `tca-architecture.md`、`formatting.md`、`coding-style.md` 與 `file-templates.md`，除了上面的既有登記差異與本 design 明列的例外。
- 定型 TCA 範本：Feature 型別的分區、`Action` 分組、`core(state:action:)`、Effect 抽方法、`Destination`、父子溝通規則。
- 所有 View 的 `body` 只放大框架，View 內不再寫格式化方法或業務判斷，每個 View 檔不超過 300 行。
- 修正月度目標的預設值讀取，新安裝的使用者拿到 80,000。
- 新增可轉紅的守門，擋住「View 送出 `.view` 以外的 action」與「reducer 送出或攔截子層的 `.view`」。
- 六個測試檔依規範補齊 doc comment、Given／When／Then、case key path `receive` 與參數化，修掉一條無法區分行為的假測試。

**Non-Goals:**

- **App 鎖定相關項目留給第 8 步**。`SettingsFeature` 以 `Scope` 組合 `AppLockFeature`、攔截 `.appLock(.enableAuthenticationFinished(.success))` 與 `.appLock(.enableToggled(false))` 決定存檔、`SettingsView` 以自訂 `Binding` 送 `.appLock(.enableToggled(_:))`、`RootFeature` 在啟動時送 `.settings(.appLock(.appDidBecomeActive))`，本步全部不動。`AppLockFeature` 屬 App 殼層，第 8 步落實 2026-09-14 裁決 4 (刪 `AppScenePhaseCoordinator`、改收 `.view(.scenePhaseChanged)`) 時一併補 delegate 並移除這些攔截。
- **`RootFeature` 只做本 design 明列的連帶改動**：State 建構參數、刪兩處 `.settings(.task)`、客戶 delegate 轉發、`onChange` 的屬性改名、`Action` 移除 `Equatable`。`morePath` 改 `StackState` 等其餘結構留給第 8 步。
- **`MoreView` 持有根 store 與 `morePath` 的導覽結構不動** (第 8 步)，本步只改它自己的分區、body 與重複定義。
- **`OrdersFeature` 直接讀 `SettingsStore` 判斷 AI 總結開關的跨 Feature 讀取不動** (第 6 步)，本步只改型別與欄位名稱。
- **`DashboardFeature.State.monthlyProfitGoalTwd` 不改名** (第 7 步)；`BLUITestConfiguration` 與 UI 測試 `LaunchOptions` 自己的 `monthlyProfitGoalTwd`／`useAiSummary` 欄位不改名 (第 8、9 步)。
- **Fx 與 Quote 的 `userMessage(for:)` 不合併**：兩組文案措辭不同，各自是字串目錄中的獨立 key，合併要改動本地化目錄與英文翻譯。
- **`CustomersFeature.State.customers` 維持 computed property**：`tca-architecture.md` 的 State 一節要求可由其他狀態算出的值寫成 computed property；改成 stored 需要第二個寫入者同步它，違反投影只有 `RootFeature` 一個寫入者。
- **`ExchangeRateClient` 的冗餘 `nonisolated` 不動**：它屬第 1 步已結案範圍，本步只清搬進 `Core/Networking/` 的 `OllamaClient`。
- **不改任何使用者可見字串與本地化 key、不改任何 `BLAccessibilityID`、不改 UI 測試檔 (第 9 步)、不重錄 snapshot 基準圖**。
- **不改測試方法名稱的命名格式**：使用者 2026-09-21 裁決維持單段 lowerCamel。

## Decisions

### TCA Feature 型別的分區與 Action 分組範本

五個 reducer 一律套 `tca-architecture.md` 的骨架，型別本體固定四區 `State` → `Action` → `Dependencies` → `Body`，本體外依序是 `Nested Types` extension、`// MARK: - Equatable` 與 `// MARK: - Sendable` 的空 extension (有 `Destination` 時)、`Private Method` 的 `private extension`，其第一個方法固定是 `core(state:action:)`。

- 既有分區名 `Dependency Properties` 改 `Dependencies`、`Reducer Body` 改 `Body`、`Cancel ID` 與 `Nested Types` (在本體內) 一律移到本體外的 `Nested Types` extension。
- `@Dependency(...)` 與 `private var name` 維持同一行 (使用者裁決，與全庫既有 65 處一致)；`AISummaryFeature` 在分支內就地宣告的 `OllamaClient`、`appConfiguration`、`continuousClock`、`dismiss` 全部移到 `Dependencies` 區。
- `body` 組合順序 `BindingReducer()` (有才寫) → `Scope` → `Reduce(core)` → `.ifLet(...)`。`body` 型別維持 `some Reducer<State, Action>` (既有登記差異)。
- `core` 的 `switch` case 順序與 `Action` 宣告順序一致，case 之間不空行；`.delegate` 與 `.destination` 一律 `return .none`。超過十行的分支抽成動詞開頭、回傳 `Effect<Action>` 的 Private Method，排在 `core` 之後。
- **State 的衍生值留在 State 內**：`tca-architecture.md` 要求 computed property「放同一個 `State` 內、stored property 之後」，這是 TCA State 對 `formatting.md`「型別本體只放 stored properties」的特例。State 內不加 MARK，stored 在前、computed 在後。`findings.md` 對 State 內 computed property 與內嵌 `// MARK: - Computed Properties` 的 `MK4`／`MK5`，處置是刪掉內嵌 MARK、成員留原處。State 內的巢狀型別 (如 `AISummaryFeature.State.Phase`) 則移到 Feature 的 `Nested Types` extension。

五個 reducer 的 `Action` 定案如下 (排列即宣告順序；`View` 與 `Delegate` 是 `@CasePathable` nested enum)：

| Feature | binding | view | delegate | 子層與目的地 | 內部回應 |
|---|---|---|---|---|---|
| `FxFeature` | `binding` | `task`、`retryTapped`、`quickAmountTapped(Decimal)`、`currencyPickerTapped`、`currencySelected(String)` | 無 | `destination` | `currencyCodesResponse`、`ratesResponse` |
| `QuoteFeature` | `binding` | `task`、`retryTapped`、`currencyPickerTapped`、`currencySelected(String)` | 無 | `rateSource` | 無 |
| `QuoteRateFeature` | 無 | 無 (沒有自己的 View) | 無 | `destination` | `task`、`refreshRequested`、`pickerTapped`、`currencySelected(String)`、`currencyCodesResponse`、`ratesResponse` |
| `SettingsFeature` | `binding` | `task`、`defaultCurrencySelected(String)`、`aiSummaryModelSelected(String)` | 無 | `appLock` (第 8 步前維持) | `currencyCodesResponse` |
| `AISummaryFeature` | 無 | `task`、`retryTapped`、`closeTapped` | 無 | 無 | `chunkReceived(String)`、`streamFailed(LocalizedStringResource)`、`streamFinished`、`streamTimedOut` |
| `CustomersFeature` | 無 | `task`、`customerTapped(String)` | `ordersLoadRequested`、`customerSelected(String)` | 無 | 無 |

- `FxView` 的重試改送 `.view(.retryTapped)`，不再借用 `.task`；它與 `.view(.task)` 共用同一個載入 Effect，行為與現況相同 (重新載入匯率與幣別清單)。`QuoteFeature` 的 `rateRefreshRequested` 改名 `.view(.retryTapped)`，維持只重載匯率。
- `fromCurrencySelected(String)` 改名 `currencySelected(String)`，字串轉 `CurrencyCode` 留在 reducer；View 不做型別轉換 (選擇器以 ISO 代碼字串溝通)。
- **`QuoteRateFeature` 於第 10 批由 `QuoteFeature` 抽出** (`tca-architecture.md` 拆分順序第 2 步)，以 `Scope` 組合，`QuoteFeature.State` 持有 `var rateSource`。它**刻意不設 `view` 分組**：沒有自己的 View，四個使用者意圖由 `QuoteFeature` 的 `core` 轉送成一般內部 case，父層轉送的因此不是子層 `.view`，不觸犯 `ActionGroupingScanTests` 規則二。
- 無 case 的使用者操作 View 送 `store.send(.view(...))`；焦點與表單值一律用 `$store.xxx` 綁定或 `store.xxx = value` 寫入，不再手組 `.binding(.set(\.xxx, value))`。

**替代方案**：沿用現有平放寫法、只補 doc 與 MARK。否決理由是 Action 分組是本步存在的主要目的，第 4 至 8 步要照抄。

### 父層不送子層 action，設定在建立 State 時帶齊

使用者 2026-09-21 裁決採用本做法。`view` 只能由對應 View 送出、父層只處理子層的 `delegate`，所以父層需要子層「先有資料」時，資料在建立子層 State 時就帶齊，而不是事後送子層 action。

**設定頁**：

- `SettingsFeature.State` 新增 `appVersion: String` 與寫在型別本體 (stored properties 之後) 的 `init(snapshot: SettingsSnapshot = .default, appVersion: String = "—")`，把快照的六個欄位、`appLock.isBiometricUnlockEnabled` 與 `appVersion` 一次設好。兩個參數都有預設值，既有的 `SettingsFeature.State()` 呼叫 (測試、Preview、`RootFeature.State` 的預設值) 不必改；已確認 `SettingsSnapshot.default` 六個欄位與 State 現有的 stored 預設值逐一相同，所以 `SettingsFeature.State()` 的內容不變。這是 `apps/ios/CLAUDE.md`「需要轉換時才寫 init」允許的情形。
- `RootFeature.State.init(persistenceStatus:isBiometricUnlockEnabled:)` 改為 `init(persistenceStatus:settings:)`，第二個參數型別 `SettingsFeature.State`，預設 `SettingsFeature.State()`。**App 鎖定兩個欄位的初始化責任**：`SettingsFeature.State(snapshot:appVersion:)` 只設 `appLock.isBiometricUnlockEnabled` (它是設定值)，不碰 `appLock.isLocked`；`RootFeature.State.init` 在存入 `settings` 後設 `self.settings.appLock.isLocked = settings.appLock.isBiometricUnlockEnabled` (它是啟動時的執行狀態，只有 App 啟動才需要先鎖上)。這與現況 `RootFeature.State.init` 同時設兩個值的結果相同。`RootFeatureTests` 現有的「啟用鎖定時啟動即上鎖」測試改用新參數後維持原斷言。
- `BuyLedgerApp.init` 原本就讀一次 `SettingsStore.load()` 取鎖定設定，改為把整份快照與 `Bundle.appVersion` 交給 `SettingsFeature.State(snapshot:appVersion:)`。UI 測試的設定覆寫早於這一行 (`AppLaunchConfigurator.prepareUITestHarnessIfNeeded()` 在 store 建立前)，所以覆寫值會被讀到。
- `RootFeature` 的 `.task` 刪掉 `.send(.settings(.task))`，只剩 `.send(.settings(.appLock(.appDidBecomeActive)))` 與幣別主檔背景更新；`.dashboard(.delegate(.refresh))` 刪掉 `.send(.settings(.task))`，只轉發 `.send(.orders(.task))`。記憶體內的設定 State 是唯一寫入者 (只有 `SettingsFeature` 會寫 `SettingsStore`)，重讀 UserDefaults 不會帶來新資料。
- `SettingsFeature` 的 `.view(.task)` 只負責載入幣別清單，不再讀設定快照。

**客戶頁**：`.view(.task)` 回 `.send(.delegate(.ordersLoadRequested))`，`.view(.customerTapped(name))` 回 `.send(.delegate(.customerSelected(name)))`。`RootFeature` 改攔截 `.customers(.delegate(.ordersLoadRequested))` 轉 `.send(.orders(.task))`、`.customers(.delegate(.customerSelected(name)))` 轉既有的 `.send(.customerSelected(name))`，不新增平行的根 action (符合 `app-layer-boundaries` 既有條文)。`.orders(.task)` 在第 6 步前仍是 `OrdersFeature` 的平放 case，本步不動。

**App 版本字串**：`SettingsView.appVersion` 目前在 Private Method 直接讀 `Bundle.main.infoDictionary`，違反「Private Method 的輸入只來自 View 已持有的值」。改為 `Shared/Extensions/Bundle+Extensions.swift` 新增 `appVersion`，由 `BuyLedgerApp` 讀一次存進 `SettingsFeature.State.appVersion`。

**缺值時整串以「—」呈現 (使用者裁決)**：短版號與建置號任一讀不到，整個版本字串就是「—」，不做逐段替代。理由是半串的 `1.7.0 (—)` 讀起來像建置號真的叫「—」，整串破折號才與 App 其他空狀態一致。

| `CFBundleShortVersionString` | `CFBundleVersion` | 輸出 |
|---|---|---|
| `1.7.0` | `312` | `1.7.0 (312)` |
| 不存在 | `312` | `—` |
| `1.7.0` | 不存在 | `—` |
| 不存在 | 不存在 | `—` |

**不抽出 `appVersion(from:)` 純函式 (使用者裁決)**：邏輯只被上方這一個 computed property 使用，直接寫在 property 內，不為了可測性多開一層。連帶不保留 `BundleExtensionsTests.swift`：它唯一的測試對象就是那個純函式，改成對 `Bundle.main` 斷言只會變成假測試。

**替代方案一**：父層改送子層的 `.view(.task)`。否決理由是違反「view 只由對應 View 送出」，使用者裁決不採。
**替代方案二**：子層另設 `case parent(Parent)` 分組收父層指令。否決理由同上，需要登記新的專案差異。

### 設定寫入維持同步

`SettingsFeature` 的存檔 (`persist(_:)` 呼叫 `SettingsStore.save`) 維持在 reducer 內同步執行，登記為本步唯一新增的例外。

理由是**寫入順序**：月度目標欄位每按一個鍵就送一次 binding，每次都存整份快照。移到 `.run` 後每次存檔是各自的 Task，執行順序不保證，較舊的快照可能在較新的之後寫入，把使用者最後輸入的值蓋掉。`SettingsStore.save` 是 `UserDefaults` 的同步寫入，不會實質阻塞 reducer。讀取則已經依上一節移出 reducer。

**替代方案**：`.run` 加 `.cancellable(id:cancelInFlight: true)`。否決理由是取消只能阻止尚未開始的寫入，已開始執行的同步 `save` 無法中斷，兩個 Task 的先後仍不保證。

### 幣別選擇 sheet 改由 Destination 驅動

`FxFeature` 與 `QuoteFeature` 的 `showsCurrencySheet: Bool` 改為 `@Presents var destination: Destination.State?`，`Destination` 是 `Nested Types` 內的 `@Reducer enum Destination { case currencyPicker }`。報價側於第 10 批抽出 `QuoteRateFeature` 後，`destination` 與 `Destination` 隨匯率來源一起搬到該子 Feature，`QuoteView` 改以 `$store.scope(state: \.rateSource.$destination, action: \.rateSource.destination)` 綁定。

- 這是無關聯值的 case，TCA 1.25 起支援 (官方 `MigratingTo1.25` 文件的 `case help` 範例)，不需要為一個無狀態的選擇器新增 reducer；專案目前是 1.26.2。
- `Action` 加 `case destination(PresentationAction<Destination.Action>)`，`body` 在 `Reduce(core)` 後接 `.ifLet(\.$destination, action: \.destination)`。
- 補 `extension FxFeature.Destination.State: Equatable {}` 與 `Sendable` (因為 `FxFeature.State` 顯式標 `Sendable`，這是編譯期契約)，放 `// MARK: - Equatable` 與 `// MARK: - Sendable`。
- View 以 `.sheet(isPresented: Binding($store.scope(state: \.$destination, action: \.destination).currencyPicker))` 綁定，`.sheet` 從 `currencyPicker` Private View 移到 `body` 的導航與呈現組。
- `.view(.currencyPickerTapped)` 設 `state.destination = .currencyPicker`；`.view(.currencySelected(code))` 設定幣別並清空 `destination`，讓關閉由 reducer 決定、TestStore 可斷言 (`OptionPickerSheet` 選取後呼叫的 `dismiss()` 因此成為無作用)。

**替代方案**：保留布林並登記例外。否決理由是 `tca-architecture.md` 的 Tree 導航一節明文要求 sheet 走 `Destination`，而 TCA 已原生支援無狀態的 case，沒有技術障礙。

### 同一次請求的結果合併成 Result

- `ratesLoaded(FxRateSnapshot)` 與 `ratesFailed(LocalizedStringResource)` 合併為 `ratesResponse(Result<FxRateSnapshot, APIError>)`，錯誤轉文案 (`userMessage(for:)`) 移到 reducer 的 failure 分支。`ExchangeRateClient.fetchLatest` 是 `throws(APIError)`，Effect 用單一 `catch` 包成 `.failure(error)`。
- 幣別清單的 `availableCurrenciesLoaded([CurrencyCode])` 改為 `currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataRepositoryError>)`。「失敗或空清單時保留目前清單」原本寫在 Effect 的空 `catch` 與 `if !codes.isEmpty` 內，改由 reducer 決定，可以用 TestStore 驗證。Fx、Quote、Settings 三處都這樣改。
- **`Action` 的 `Equatable` 只在必要處移除**：`APIError` 與 `CurrencyMetadataRepositoryError` 依第 1 步不遵循 `Equatable`，所以 `FxFeature.Action`、`QuoteFeature.Action`、`SettingsFeature.Action` 移除 `Equatable`，`RootFeature.Action` 因為含這三者跟著移除 (只改這一個遵循)。`AISummaryFeature.Action` 與 `CustomersFeature.Action` 保留 `Equatable`：前者被 `OrdersFeature.Action` 以 `PresentationAction` 持有，移除會連帶改動第 6 步的檔案。`tca-architecture.md` 不要求 `Action` 遵循 `Equatable`，測試一律用 case key path `receive`。
- `RootFeatureTests` 以值比對的 `receive` 共三處：`receive(.settings(.task))` 依上一節刪除；另兩處是多行寫法的 `.lookupManagements(.element(...))` (付款方式編輯失敗、類別刪除成功)，改成帶值的 case key path (`\.lookupManagements[id:].<case>` 加上預期值)，守門力不變。其餘都是 case key path。

### View 的 MARK 分區依 TCA 樣板，沒有 Computed Properties

`tca-architecture.md` 的 View 一節與 `file-templates.md` 的 `presentation/View.swift` 一節都把 View 分區寫死為 **Properties → (Init) → Body → Private Views → Nested Types → Private Method → Preview**，樣板檔 `tca/FeatureView.swift` 的插槽亦同；`formatting.md` 的通用六區 (含 `Computed Properties`) 只適用非 View 型別。

- 色盤、格線欄位、預設金額這類純 UI 計算一律放 `Private Method`，即使宣告形式是 computed property；`Private Method` 的收納規則本就是「輸入只來自 View 已持有的值、輸出給 modifier 或版面用、沒有副作用」。
- 第 2 步的 design 把通用六區與 View 專屬順序混用，訂出含 `Computed Properties` 的 View 順序，本步 (第 11 批) 依使用者裁決改回樣板；`Shared/DesignSystem/` 下 10 個同型檔屬第 2 步已提交範圍，留給第 10 步。
- 規則已登記於 `apps/ios/CLAUDE.md`。

### reducer 的 body 只組合，分支主體抽成 core

`body` 不寫 `Reduce { state, action in }` 閉包，分支主體抽成 `Private Method` 的第一個方法 `core(state:action:)`，`body` 寫 `Reduce(core)`。本步第 11 批把 `RootFeature` 195 行的 inline 閉包一併抽出 (原屬第 8 步)，範圍內 7 個 Feature 因此全部一致。

**`OrdersFeature` 的三段 `Reduce` 不在本步處理**：三段各自綁不同的 `.ifLet`／`.forEach`，TCA 的執行順序是「父1 → 子1 → 父2 → 子2 → 父3 → 子3」，併成單一 `Reduce(core)` 會讓 `.editOrder(.presented(.saveTapped))` 的攔截相對於 `OrderEditFeature` 的順序改變，而該路徑是 `ios-data-layer.md` 標註「撞號會退回靜默覆寫」之處。正解是依 `tca-architecture.md` 拆分順序第 2 步抽子 Feature，屬第 6 步。

### 一個檔只放一個頂層型別

同檔多個頂層型別會讓檔案層級的固定區名 (`Internal Method` 等) 重複出現，Xcode jump bar 分不出歸屬。第 11 批依此把 `OrdersFeature.swift` 內 `OrdersFeature.State` 的 extension 併入既有的 `OrdersFeature+StateQuery.swift`，`OrderDateSection` 獨立為 `OrderDateSection.swift` (同目錄的 `OrderDatePeriod`、`OrderStatusFilter`、`OrderDraft` 都是一型一檔)；只搬位置、不改邏輯。

### View 以獨立 View 型別拆檔，格式化移出 View

**拆檔**：`FxView`、`QuoteView` 與 `CustomersView` 超過 300 行，依 `apps/ios/CLAUDE.md` 抽成獨立 View 型別，放各自的 `Components/` 子目錄 (比照 `Features/Orders/Components/`)，只接收原始值與 closure，不持有 store：

| 新型別 | 內容 | 輸入 |
|---|---|---|
| `FxStatusBanner` | 載入中、錯誤加重試、已連線三種橫幅 | 是否載入中、錯誤訊息、快照時間、重試 closure |
| `FxRatesList` | 即時匯率標題與各幣別列 | 要顯示的幣別、各幣別匯率、快照時間 |
| `QuoteStatusBanner` | 載入中、匯率不可用加重試、毛利過高三種橫幅 | 是否載入中、不可用原因、毛利是否低於 100%、重試 closure |
| `QuoteBreakdownCard` | 成本拆解卡與無匯率時的空狀態 | 是否有可用匯率、各項金額、總成本 |
| `QuoteInputsCard` | 來源幣別列與七個數值輸入欄 | 幣別代碼、七個 `Binding<Decimal>`、焦點 binding、開啟選擇器 closure |
| `CustomerTopCard` | Top 客戶卡片與名次膠囊 | 名次、客戶資料 |
| `CustomerListRow` | 客戶列的姓名、分級、累計消費與最近訂單日期 | 客戶資料 |

後三個於第 10 批因 300 行上限補抽；`CustomersView` 的列間分隔線縮排改由 `CustomerListRow.dividerInset(avatarSize:)` 推導，不再由外層手算內層版面。

各元件需要的 `@Environment(\.locale)` 與 `@ScaledMetric` 由元件自己宣告。拆出後各檔都不超過 300 行 (含本步新增的多狀態 `#Preview`)，驗收以不含檔頭與空行的行數計算。

**格式化移出 View**：

- `CustomersView.formatDate(_:)` 與 `OrderFormatters.shortDate(_:locale:)` 是同一條「月日短日期」規則的兩份實作。新增 `BLFormatters.shortDate(_:locale:)` 作為唯一入口，`OrderFormatters.shortDate` 改為一行轉呼叫 (簽章不變，Orders 其餘呼叫端不動)，`CustomersView` 直接呼叫 `BLFormatters.shortDate`。
- `FxView` 的 `rateDisplay(for:)`、`snapshotDateText`、`rateSourceSubtitle` 內的時間格式與 `presetLabel(_:)` 收進新增的 `Features/FX/FxFormatters.swift` (`rate(_:locale:)` 四位小數、無資料回「—」；`snapshotTimestamp(_:locale:)` 月日時分；`presetAmount(_:locale:)` 整數)。兩份相同的時間樣式因此只剩一份。
- `FxView.ratesListCurrencies` 的「排除新台幣」移到 `FxFeature.State.ratesListCurrencies`；`rateSourceSubtitle` 內 `.twd` 的分支因清單已排除新台幣而永遠不會執行，刪除。
- `QuoteView.heroPriceText` 的判斷移到 `QuoteFeature.State.displayedSuggestedTWD: Decimal?` (無可用匯率或無法計算時為 `nil`)，View 以 `BLFormatters.twd(_:locale:)` 的 Optional 多載呈現 (`nil` 顯示「—」)。hero 卡下方三選一的提示改由 `QuoteFeature.State.heroMessage` 決定，型別是 `Nested Types` 內的 `enum HeroMessage` (`rateUnavailable`、`estimate(profitTWD:marginPercent:)`、`marginTooHigh`)。
- 成本拆解的三元素 tuple 陣列改為 `QuoteBreakdownCard` 的 nested `struct BreakdownItem`。

**其餘 View 規則** (六個 View 與新元件一體適用)：

- `body` 只放容器、子 View 呼叫與套在整個畫面的 modifier；鍵盤工具列抽成 `keyboardToolbar`，`SettingsView` 的六個 Section 各抽成 Private View。
- `body` 內的 `let palette = BLPalette()` 改為 `private var palette: BLPalette` computed property，與第 2 步相同。
- Properties 順序：`@Environment` → `@FocusState`／`@ScaledMetric` (同組依名稱字母序) → `store`。
- modifier 依版面 → 外觀 → 行為 → 導航與呈現四組排列，只做跨組移動、同組內相對順序不動。`AISummaryView.aiDisclaimerCapsule` 的 `frame(maxWidth:alignment:)` 必須留在 `background(_:in:)` 之外，否則膠囊會撐滿整列，保留位置並加一行理由註解。
- 無參數的 Private View 用 `var`；有多種狀態的畫面各加一個具名 `#Preview` (FX：初始、載入中、錯誤、已連線；Quote：可試算、匯率不可用、毛利達 100%；AISummary：串流中、失敗、逾時截斷；Customers：有資料、空狀態)。Preview 不覆寫依賴，TCA 會自動使用 `previewValue`。

**替代方案**：以 `<Name>+<Domain>.swift` 跨檔 extension 拆 View。否決理由見 `apps/ios/CLAUDE.md`：跨檔 extension 讀不到 `private` 的 `@Environment`／`@FocusState`，為了編譯降成 internal 會破壞封裝。

### 匯率換算收斂到 FxRateSnapshot

`FxFeature.State.displayRate(for:)` 與 `QuoteFeature.State.rate` 是同一段「快照換算成 1 單位 = X TWD」的兩份實作。在 `Core/Domain/FxRateSnapshot.swift` 新增 `func twdRate(for currency: CurrencyCode) -> Decimal?`：新台幣回 1；快照以新台幣為基準且該幣別匯率大於 0 時回倒數；快照以該幣別為基準時回其新台幣匯率；其餘回 `nil`。

- `FxFeature.State.displayRate(for:)` 保留 (View 與測試使用)，改為：新台幣回 1，否則回 `snapshot?.twdRate(for:)`。
- `QuoteFeature.State.rate` 改為：新台幣回 1，否則回 `snapshot?.twdRate(for: fromCurrency) ?? 0`，維持無資料時為 0 的既有語意。
- 新增 `FxRateSnapshotTests.swift` 涵蓋四種分支，預期值寫死數字。

### OllamaClient 搬到 Core/Networking

`OllamaClient` 是遠端服務的技術入口，依 `apps/ios/CLAUDE.md`「Core 需要的 API client 放 `Core/Networking/`」搬到 `Core/Networking/OllamaClient.swift`，與 `ExchangeRateClient` 同層；它只引用 `HTTPClient`、`URLRequestBuilder`、`APIError`，不認得任何 Feature 型別，`LayerBoundaryTests` 不受影響。

- `OllamaDTO.swift` 的 `ChatRequest`／`ChatResponse` 改名 `OllamaChatRequest`／`OllamaChatResponse`，比照第 1 步拆出 `ExchangeRateLatestResponse` 的做法各自一檔。原名在 App target 全域沒有指出是 Ollama 格式，日後接其他聊天 API 會撞名。
- `liveValue` 內 `guard let url = URL(string: "https://ollama.com/api/chat") else { throw ... NSURLErrorDomain ... }` 改為 `static let chatURL = URL(string: "https://ollama.com/api/chat")!` 加「字面值常數」註解 (`coding-style.md` 唯一允許的 `!`)，刪掉偽造 `NSURLErrorDomain` 的不可達分支 (`apps/ios/CLAUDE.md` 禁止為 App 自己判斷的狀況偽造框架 domain)。
- `testValue` 改用與 `ExchangeRateClient.testValue` 相同的自有 domain `com.leoho.BuyLedger.networking` 與「依賴未注入」代碼，不再偽造 `NSURLErrorUnknown`。
- 串流 Task 的三個 `catch` 子句 (`CancellationError`、`APIError`、其他) 改為單一 `catch` 內判斷。
- 冗餘的 `nonisolated` 移除 (專案預設隔離已是 `nonisolated`)；若移除後編譯不過，保留並加一行理由註解。

### AISummary 的金鑰檢查移進 Effect

`AISummaryFeature` 目前在 reducer 內同步呼叫 `appConfiguration.ollamaAPIKey()` 並直接寫 log，違反「Reduce 內不直接呼叫依賴」。

- `.view(.task)` 與 `.view(.retryTapped)` 共用 `startStream(state:)`：同步清空 `summaryText`、`errorMessage`、`truncationMessage` 並設 `phase = .streaming`，回傳的 Effect 內先讀金鑰；缺金鑰時寫 log 並送 `.streamFailed("AI 總結尚未完成設定，目前無法使用。")`，文案與 log 內容與現況相同。
- 畫面行為不變：`phase` 為 `.idle` 與 `.streaming` 且尚無內容時畫面相同 (都顯示「AI 正在分析商品明細…」)，所以缺金鑰時仍是「轉圈後顯示失敗」。
- `StreamResult` 與 `CancelID` 移到 `Nested Types` extension (private)；串流與逾時競速的 `withTaskGroup` 整段移到 `startStream(state:)`，其兩個 `catch` 各改為單一 `catch`。
- `extension APIError { var summaryFailureMessage }` 是在 Feature 檔擴充 Core 型別，讓所有模組都看得到這個 Feature 的文案。改為 `AISummaryFeature` 的 private `static func summaryFailureMessage(for:)`，文案逐字不變。

### 客戶名單的 CustomerRow 獨立成檔

`CustomerRow` 與其 `aggregate(orders:)` 搬到 `Features/Customers/CustomerRow.swift`。`id` 是手寫的 `Identifiable` 實作，移到 `// MARK: - Identifiable` extension；`Dictionary(grouping:by:)` 改 trailing closure、`compactMap` 移除明寫的回傳型別。彙總結果與排序不變，由新的 `CustomerRowTests.swift` 守 (從 `CustomersFeatureTests` 搬出兩條直接測 `aggregate` 的測試)。

### 更多頁以 MoreRoute 為唯一來源

`MoreView.ToolItem` 的七個 case 與 `RootFeature.MoreRoute` 一一對應，新增目的地要改兩處。刪除 `ToolItem`，改由 `MoreView` 的 Private Method 以 `MoreRoute` 為輸入提供標題、圖示與色彩 (純呈現對應，符合 View Private Method 規則)。現況是七個工具列加一個設定列，共八個 route；**八個全部改走 `func routeLink(_ route: RootFeature.MoreRoute) -> some View`**。設定列的標題「設定」、圖示 `gear`、色彩 `secondaryLabel`，字型與工具列相同 (`BLTypographyStyle.body` 加 `.medium`)，所以改走同一套後視覺不變 (由 task 0.4／8.5 的截圖比對確認)。三個 Section 的分組與列的順序不變。

- `ToolItem.subtitle` 全庫無人讀取，隨 `ToolItem` 刪除。
- 在 View 檔對 `RootFeature.MoreRoute` 擴充 `accessibilityKey`，改為 `MoreView` 的 private 方法 `accessibilityRow(for:)`，回傳值不變。
- `lookupManagementDestination(for:)` 的失敗分支是一個 closure 為空的 `BLLoadFailureView`，重試鍵按了沒反應。改為不帶按鈕的 `ContentUnavailableView`，以既有字串「無法載入主檔管理頁面，請稍後再試。」作為標籤，不新增本地化 key。這條分支只在 `lookupManagements` 缺少某種主檔時出現，正常流程不會觸發。

### 設定儲存改名 SettingsStore 並修正月度目標預設

- `SettingsStorage` 改名 `SettingsStore` (`coding-style.md` 的已定義角色後綴；職責是本機偏好儲存)，檔案改名 `SettingsStore.swift`，**留在 `Features/Settings/`**：它引用 `AISummaryModelCatalog.defaultModel`，搬進 Core 會讓 Core 認得 Feature 型別。
- 讀寫邏輯抽成兩個 internal 純函式 `static func snapshot(from defaults: UserDefaults) -> SettingsSnapshot` 與 `static func save(_ snapshot: SettingsSnapshot, to defaults: UserDefaults)`，`liveValue` 傳 `.standard`。測試以 `UserDefaults(suiteName:)` 建立獨立網域驗證，測後清除。
- **月度目標讀取修正 (使用者裁決)**：先判斷 `defaults.object(forKey:) == nil`，是就回 `SettingsSnapshot.default` 的月度目標 (80,000)；不是就照現況以 `defaults.double(forKey:)` 讀值再轉 `Decimal`，寫入方式也維持現況的 `Double`。已寫入的值照舊尊重，包含使用者刻意設的 0。
- 本節與 task 2.1 的欄位名稱沿用改名前的 `monthlyProfitGoalTwd`，改名由 task 2.2 統一處理 (見「命名改正與 UserDefaults key 不變」)。
- nested `SettingsStorageKeys` 改名 `Keys` (不重複外層名)，維持 private。
- `SettingsSnapshot.testDefault` 與 `default` 內容完全相同，刪除；`testValue` 與 `previewValue` 改讀 `.default`。
- `testValue` 維持宣告，屬既有登記差異。

### 命名改正與 UserDefaults key 不變

| 現名 | 新名 | 連帶改動 (只改名稱) |
|---|---|---|
| `SettingsFeature.State.monthlyProfitGoalTwd`、`SettingsSnapshot.monthlyProfitGoalTwd` | `monthlyProfitGoalTWD` | `RootFeature` 的 `onChange(of: \.settings.monthlyProfitGoalTwd)` 與賦值右側；`BLUITestDependencyOverrides` 的快照賦值 |
| `SettingsFeature.State.useAiSummary`、`SettingsSnapshot.useAiSummary` | `isAISummaryEnabled` | `OrdersFeature` 讀取處與其 doc；`OrdersFeatureTests` 兩處；`BLUITestDependencyOverrides` 的快照賦值 |
| `SettingsStorage` | `SettingsStore` | `BuyLedgerApp`、`OrdersFeature`、`BLUITestDependencyOverrides`、`OrdersFeatureTests`、`RootFeatureTests` |
| `FxFeature.State.convertedTwd` | `convertedTWD` | `FxView`、`FxFeatureTests` |
| `QuoteFeature.State` 的 `internationalShippingTwd`、`itemTwd`、`domesticTwd`、`cardFeeTwd`、`paymentFeeTwd`、`platformFeeTwd`、`costTwd`、`suggestedTwd`、`estimatedProfitTwd` | 結尾改 `TWD` | `QuoteView` 與元件、`QuoteFeatureTests`、`SnapshotTests` 的 `QuoteFeature.State(...)` 參數標籤 |

**UserDefaults 的 key 字串一律不變** (`settings.monthlyProfitGoalTwd`、`settings.useAiSummary` 等六個)：只改 Swift 常數名稱，不改字串值。改了字串會讓既有使用者的設定讀不到、全部回到預設值。

`DashboardFeature.State.monthlyProfitGoalTwd`、`BLUITestConfiguration` 與 `LaunchOptions` 自己的同名欄位不在本表 (見 Non-Goals)。

### 測試定型：Given／When／Then、case key path、LockIsolated 與 fixture

- **測試方法名稱維持單段 lowerCamel (使用者 2026-09-21 裁決)**，與第 1 步已提交的做法一致；`findings.md` 的六筆命名項目預填「不修」。這條差異由 task 7.1 寫進 `apps/ios/CLAUDE.md`。
- 每個 `@Test` 有 `///`，本體有 `// Given`、`// When`、`// Then` 三段。**標記底下必須有對應的程式碼**：第 1 步曾有 136 處裸標記直接接 `}`，驗收要看每個 When／Then 標記底下第一個非空行不是 `}` 或另一個標記；`file-templates.md` 允許空的 `// Given` (保留標記並留空行)。
- 型別的 doc comment 放在 `@MainActor` 之上；`@testable import` 前空一行。
- `receive` 一律用 case key path (`store.receive(\.ratesResponse.success)`)；`TestStore` 不關 exhaustivity。窮舉 `receive` 之後重複斷言同一欄位的 `#expect` 刪除。
- 同一邏輯多組輸入改 `@Test(arguments:)`：`OllamaClientTests` 的空行與壞格式、`QuoteFeatureTests` 的毛利公式三組與 100%／150%／80% 三組、`SettingsFeatureTests` 的語言儲存值 (搬到 `AppLanguageTests`) 與「會存檔的 binding 欄位都會存檔」。會存檔的 binding 欄位只有三個：`language`、`isAISummaryEnabled`、`monthlyProfitGoalTWD` (預設幣別與 AI 模型走 view action)；`isGoalFieldFocused` 是焦點，依現況不存檔，另寫一條測試斷言它不觸發存檔。
- 測試替身：`AISummaryFeatureTests` 的頂層 `CancellationRecorder` actor、`SettingsFeatureTests` 的 `SnapshotBox` 改用 `LockIsolated`；`QuoteFeatureTests` 的 `QuoteRateClientStub` 移進 `Nested Types`。`AISummaryFeatureTests` 關閉 sheet 的測試移除 `Task.yield()` 輪詢，改在 `send(.view(.closeTapped))` 後 `await store.finish()`。
- 新增 `LedgerOrder+Fixture.swift`，提供全參數有預設值的 `static func fixture(...)` (固定日期與識別值，不含隨機值或目前時間)；本步只讓 `CustomersFeatureTests` 與 `QuoteFeatureTests` 改用它，其他測試檔留給各自的步驟。
- `SettingsFeatureTests` 裡測 `AppLanguage` 的四條搬到新的 `AppLanguageTests.swift`，`CustomersFeatureTests` 裡直接測 `CustomerRow.aggregate` 的兩條搬到 `CustomerRowTests.swift`。
- **修掉一條假測試**：`FxFeatureTests.fromCurrencySelectedRecomputesRateFromSnapshot` 注入的是 `FxRateSnapshot.fallback`，實作改讀 fallback 也會通過，預期值又用與實作相同的算式算出。改為注入與 fallback 不同的自訂快照，預期匯率與換算金額寫死數字。
- `RootFeatureTests` 只改受本步影響的測試：State 建構參數、啟動 `.task` 與總覽重整不再收到設定載入、客戶 delegate 的轉發；需要改寫主檔目錄的測試仍用既有的 `makeIsolatedRootState`。

### 新增 Action 分組守門

新增 `apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift`，兩條原始碼掃描，比照既有掃描測試 (`LayerBoundaryTests`、`DesignSystemSourceScanTests`) 先剝除註解與字串字面值再比對。比對對象是剝除後的**整份檔案文字** (不是逐行)，所以跨行呼叫與任意空白都會被看到：

1. **已遷移 Feature 的 View 只送 view action**：掃描清單內每個 View 檔 (`FxView`、`FX/Components/`、`QuoteView`、`Quote/Components/`、`SettingsView`、`AISummaryView`、`CustomersView`)。以正規表示式 `store\s*\.\s*send\s*\(\s*` 找出每個送出點，取其後的文字，必須以 `.view(` 開頭 (允許 `.` 與 `view` 之間有空白)，否則記為違規並回報檔案相對路徑與該段文字。`await store.send(.view(.task)).finish()` 這種前有 `await`、後接 `.finish()` 的寫法自然通過。清單以 Feature 目錄明列，第 4 至 8 步遷移時各自加入。
   - **allowlist 形狀**：每筆是 `(相對路徑, 送出內容的開頭, 理由, 移除步驟)`，例如 `("Features/Settings/SettingsView.swift", ".appLock(", "AppLockFeature 屬 App 殼層，第 8 步補 delegate", "第 8 步")`。只豁免開頭完全相符的送出點；allowlist 的條目若在掃描中一次都沒被用到，測試同樣失敗 (避免條目過期後留著變成後門)。
2. **reducer 不送也不攔截子層的 view action**：掃描 `apps/ios/BuyLedger/Features/` 全部 Swift 檔，以正規表示式 `\.\s*(?!send\b|view\b)[a-z]\w*\s*\(\s*\.\s*view\s*\(` 找「某個子層 case 直接包著 `.view(`」的寫法，例如 `.send(.settings(.view(.task)))`、`case .customers(.view(.task)):`、`.destination(.presented(.edit(.view(...))))` 中的 `.edit(.view(`。排除 `send` 是為了放過 Feature 自己的 `.send(.view(...))`，排除 `view` 是為了放過 `.view(.view(` 這種不會出現的巢狀以免誤判。未遷移的 Feature 沒有 `.view` case，不會誤報。
3. **掃描器自我測試**：同檔另加一條參數化測試，把下表的原始碼片段直接餵給兩個比對函式，確認判斷正確，避免正規表示式寫錯導致守門空跑：

   | 片段 | 規則 | 預期 |
   |---|---|---|
   | `store.send(.view(.task))` | 1 | 通過 |
   | `await store.send(.view(.task)).finish()` | 1 | 通過 |
   | `store.send(\n    .view(.retryTapped)\n)` (跨行) | 1 | 通過 |
   | `store.send(.binding(.set(\.isFocused, false)))` | 1 | 違規 |
   | `store.send(.delegate(.customerSelected(name)))` | 1 | 違規 |
   | `// store.send(.task)` (註解內) | 1 | 通過 (剝除後不存在) |
   | `return .send(.view(.task))` (Feature 自己送) | 2 | 通過 |
   | `case .view(.task):` (Feature 自己的分支) | 2 | 通過 |
   | `.send(.settings(.view(.task)))` | 2 | 違規 |
   | `case .customers(.view(.task)):` | 2 | 違規 |

   另以兩條案例驗證 allowlist：給一份含 `store.send(.appLock(.enableToggled(true)))` 的片段與對應條目，結果為通過且該條目標記為已使用；給一份不含該送出點的片段與同一條目，結果為失敗並指出未使用的條目。

兩條都要做變異驗證：在 `FxView` 暫時加一個 `store.send(.binding(...))`、在 `RootFeature` 暫時加一個 `.send(.settings(.view(.task)))`，各看到對應測試轉紅且 xcresult `totalTestCount` > 0，驗證後還原。

### ai-order-summary 規格只改用詞

`ai-order-summary` 的「AI summary setting and model configuration」條文原本直接寫程式識別字 `useAiSummary`，本步改名後會與程式碼不符，所以 delta 把它改成白話描述，並新增「改名後舊 key 仍讀得到」一個情境。其餘三個情境 (開關跨啟動保存、Debug 才能換模型、Release 固定模型) 是既有行為的原文照抄，**本步不改這些行為，也不為它們新增測試**；新情境由 `SettingsStoreTests` 以舊 key 字串寫入後讀回來驗證。

### 判讀級 findings 的逐筆處置

`findings.md` 中需要判斷才能決定修或不修的項目逐筆定案如下 (已預填進 `findings.md`)，其餘判讀項目依其「修法」欄照做：

| 位置 | 項目 | 處置 |
|---|---|---|
| `FxFeature.fromCurrencySelected(String)` | 建議改帶 `CurrencyCode` | **不修**：字串轉型留在 reducer，View 不做型別轉換 |
| `FxFeature.userMessage(for:)` | 與 Quote 同名函式重複 | **不修**：見 Non-Goals，兩組文案是不同的本地化 key |
| `QuoteFeature.State.rate` | 與 Fx 匯率換算重複 | **修**：收斂到 `FxRateSnapshot.twdRate(for:)` |
| `QuoteView` hero 提示 | View 內重複狀態判斷 | **修**：`QuoteFeature.State.heroMessage` |
| `CustomersFeature.State.customers` | 衍生值每次重算 | **不修**：見 Non-Goals |
| `SettingsFeature` 讀寫 `SettingsStorage` | reducer 內呼叫依賴 | **部分修**：讀取移到建立 State 時；寫入維持同步並登記例外 |
| `SettingsFeature` 組合 `AppLockFeature`、攔截其非 delegate action | Feature 間引用、父層只處理 delegate | **不修，第 8 步**：見 Non-Goals |
| `SettingsStorage` 位置 | 建議搬進 `Core/Dependencies/` | **不搬，只改名**：它引用 Feature 型別 `AISummaryModelCatalog` |
| `MoreView.ToolItem` | 與 `MoreRoute` 重複定義 | **修**：以 `MoreRoute` 為唯一來源 |
| `MoreView` 空的重試 closure | 按鈕按了沒反應 | **修**：改不帶按鈕的 `ContentUnavailableView` |
| `AISummaryView.aiDisclaimerCapsule` | modifier 順序 | **部分修**：`frame` 必須在 `background` 外層，加註解保留 |
| `CustomersView` 分隔線內縮、三個 View 的 `currencyDisplayText` | 尺寸與幣別顯示 | **第 2 步已修**，確認後標記 |

## Implementation Contract

**行為**：

- **改變 (使用者裁決)**：從未寫入過月度目標的使用者，讀到的目標由 0 變 80,000，總覽 hero 卡因此出現進度條。已寫入過任何值 (含 0) 的使用者不受影響。
- **改變但使用者察覺不到**：App 啟動時設定 (語言、預設幣別、月度目標) 在第一個畫面就是已儲存的值，不再先用預設值、等 `.settings(.task)` 送達後才更新；總覽下拉重整不再重讀 UserDefaults (記憶體內設定是唯一寫入者，重讀不會帶來新資料)。
- **不變**：所有畫面的版面、文字、本地化字串、`BLAccessibilityID`、可用動作與導覽；匯率換算、報價公式、客戶彙總與排序；AI 總結的串流、逾時與失敗文案；設定的 UserDefaults key 字串與存檔時機；App 鎖定的所有行為。

**對外介面變更**：

| 介面 | 改動前 | 改動後 |
|---|---|---|
| `RootFeature.State.init` | `(persistenceStatus:isBiometricUnlockEnabled:)` | `(persistenceStatus:settings: SettingsFeature.State)` |
| `SettingsFeature.State` | 只有合成 init | 本體內 `init(snapshot: = .default, appVersion: = "—")` 取代合成 init，新增 `appVersion: String` |
| 設定儲存型別 | `SettingsStorage` | `SettingsStore`，另有 `snapshot(from:)` 與 `save(_:to:)` |
| `SettingsSnapshot.testDefault` | 存在 | 刪除，改用 `.default` |
| 客戶頁 delegate | `customerTapped(String)` | `ordersLoadRequested`、`customerSelected(String)` |
| Fx／Quote 匯率回應 | `ratesLoaded`、`ratesFailed` | `ratesResponse(Result<FxRateSnapshot, APIError>)` |
| 幣別清單回應 | `availableCurrenciesLoaded([CurrencyCode])` | `currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataRepositoryError>)` |
| Fx／Quote 幣別 sheet | `showsCurrencySheet: Bool` | `@Presents var destination: Destination.State?` |
| `OllamaClient` | `Features/AISummary/`，DTO 為 `ChatRequest`／`ChatResponse` | `Core/Networking/`，DTO 為 `OllamaChatRequest`／`OllamaChatResponse` |
| `APIError.summaryFailureMessage` | Core 型別的 public 擴充 | 刪除，改為 `AISummaryFeature` 的 private static 方法 |
| 月日短日期 | `OrderFormatters.shortDate` 與 `CustomersView.formatDate` 各一份 | `BLFormatters.shortDate(_:locale:)`，`OrderFormatters.shortDate` 轉呼叫 |
| 匯率換算 | Fx、Quote 各一份 | `FxRateSnapshot.twdRate(for:)` |
| `RootFeature.Action`、`FxFeature.Action`、`QuoteFeature.Action`、`SettingsFeature.Action` | 遵循 `Equatable` | 不遵循 |

**失敗模式**：

- 幣別清單載入失敗或回傳空清單：保留目前清單、不顯示錯誤 (與現況相同，改由 reducer 決定)。
- 匯率載入失敗：顯示與現況逐字相同的錯誤文案與重試鍵。
- AI 總結缺金鑰：寫 log 並進入失敗狀態，文案與現況相同。
- `SettingsStore` 讀到無法解析的幣別或語言：沿用既有 `CurrencyCode(rawValue:)` 與 `AppLanguage(storedValue:)` 的回退，本步不改。

**驗收條件** (數字與 result bundle 路徑一律記在 `tasks.md` 對應 task 下方，只存在對話裡不算數)：

1. **機械檢查** (A 組整檔、B 組只查改到的行，見 Context「檢查範圍分兩組」)：行寬不超過 100 (以 python3 按字元計算；`formatting.md` 明文「超長字串不斷行，允許超過 100」，所以只由單一字串字面值構成而超過的行不算，逐行列在 `tasks.md` 並說明，不得為了壓行寬把字串拆行或改動測試資料)、無尾隨空白與 tab、手寫檔第 5 行完整符合 `^//  Created by Leo Ho on \d{4}/\d{1,2}/\d{1,2}\.$` (不補零)，三項各 0 筆。
2. **分區檢查** (A 組整檔；B 組只查本步新增或改動的分區)：`// MARK:` 段名都在允許清單內 (含 protocol 名與 TCA 的 `State`／`Action`／`Dependencies`／`Body`)，**頂層分區順序正確、同一分區不重複** (排除巢狀型別內與同檔多個獨立頂層型別)；modifier 跨組順序只以 `formatting.md` 表中明列的 modifier 判定。
3. **註解與測試**：A 組宣告缺 `///` 0 筆、B 組本步新增或改動的宣告缺 `///` 0 筆；六個測試檔與新測試檔的每個 `@Test`，以及 B 組測試檔中本步新增或改動的 `@Test`，都有 doc 與三段標記，When／Then 標記底下第一個非空行不是 `}` 或另一個標記。
4. **單一入口**：`grep -rn` 限 `apps/ios/**/*.swift`，`func formatDate`、`showsCurrencySheet`、`SettingsStorage` 皆無輸出；`summaryFailureMessage` 只出現在 `AISummaryFeature.swift`；`useAiSummary` 只出現在 Non-Goals 明列不改名的 `BLUITestConfiguration` 與 `LaunchOptions` (及其測試)；`month(.defaultDigits)` 只出現在 `BLFormatters.swift` (月日短日期) 與 `FxFormatters.swift` (月日時分，另一條規則)。
5. **守門轉紅**：`ActionGroupingScanTests` 兩條各做一次變異驗證，對應測試由綠轉紅、xcresult 可解析且執行數大於 0，驗證後還原；還原也算 Swift 寫入，之後的回歸必須晚於它。
6. **完整回歸**：以 `BuyLedger.xctestplan` 跑完整單元測試，先鎖模擬器淺色外觀；測試數不少於 task 0.2 基準加上本步新增數、失敗清單是 task 0.2 基準的子集。snapshot 失敗先依 `.claude/rules/ios-unit-tests.md` 判別是否為已知渲染雜訊，**不得重錄基準圖**；`quoteViewBaseline` 與 `quoteViewRateUnavailable` 必須在單獨重跑時通過。
7. **UI 回歸**：iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸，結果不得比 task 0.3 基準差。
8. **畫面比對**：FX、設定、客戶、更多、AI 總結五個畫面沒有 snapshot 守，報價只有兩條。開工前 (task 0.4) 與完工後 (task 8.5) 各用 `xcodebuildmcp ui-automation` 在淺色外觀截一次六個畫面的一般狀態，逐張確認除了本 design 宣告的改變外沒有差異，截圖路徑記在 `tasks.md`。UI 測試 harness 沒有模擬匯率失敗的選項，所以錯誤狀態改用 snapshot 守：報價的錯誤狀態已有 `quoteViewRateUnavailable`；匯率工具由 task 0.5 **在改動任何 production code 之前**新增 `fxViewBaseline` (已連線) 與 `fxViewRateFailureBaseline` (錯誤橫幅) 兩條 snapshot 測試並錄製基準圖，完工後必須維持綠燈。這是錄下改動前的現況，不屬於「重錄基準圖」。兩條測試以 `Store(initialState: state) { EmptyReducer() }` 建立 store，讓 `FxView` 出現時送出的 `.task` 不改變狀態 (真的 `FxFeature` 收到 `.task` 會把錯誤清掉、進入載入中)；狀態只用 `FxFeature.State` 的 `snapshot:` 與 `errorMessage:` 兩個建構參數，這兩個在 task 3.1 之後仍存在，測試不必跟著改。快照用 `FxRateSnapshot.fallback` (日期固定為 1970-01-01 00:00 UTC)，錯誤訊息用既有字串「網路連線異常；無法顯示即時匯率，請稍後再試。」。畫面上的時間依模擬器時區呈現，與既有 snapshot 測試一樣只在本機跑 (CI 的單元測試步驟以 `-skip-testing:BuyLedgerTests/SnapshotTests` 排除)。
9. **findings 結論**：`findings.md` 491 筆全部有結論，`待填` 0 筆，預填項目未被改掉。
10. **spectra 檢查**：`spectra validate small-features-style-compliance` 通過。

**測試環境** (基準與驗收必須用同一組，才能比較)：iPhone 用 `iPhone 17` (iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)，iPad 用 `iPad Air 11-inch (M4)` (iOS 26.5，UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`)，一律以 `--simulator-id` 指定。**不要依賴 `.xcodebuildmcp/config.yaml` 的 session 預設**：它目前指向另一台 iPhone 17 (`CA41FB26-…`)，不是上面這台。開工前以 `xcodebuildmcp simulator list` 確認兩個 UDID 仍存在；不存在就停下回報，不自行換機型。

**範圍邊界**：可改動的檔案為 proposal 的 Impact 清單加上本 change 目錄的 `tasks.md` 與 `findings.md`。**遇到清單外必須改動的檔案就停下來回報，不要自行擴張範圍** (前兩步的經驗是 allowlist 一定會估得太窄)。已確認不需要手改：`project.pbxproj` (`PBXFileSystemSynchronizedRootGroup` 按目錄同步，新增、刪除、搬移 Swift 檔與新增 `Components/` 子目錄都不必手改；唯一允許的 pbxproj 變更是 `build-and-run` 前依 `apps/ios/CLAUDE.md` 執行 `agvtool next-version` 造成的建置號遞增，只能是 `CURRENT_PROJECT_VERSION` 那幾行)、`BuyLedger.xctestplan` 與 `BuyLedgerUITests.xctestplan` (不列舉測試類別)、`Localizable.xcstrings` (不新增或改動字串)、`BLAccessibilityID.swift`。

## Risks / Trade-offs

- **[無關聯值的 `Destination` case 編不過，或 `Destination.State` 的 `Sendable` 補不上]** → TCA 1.25 文件有此用法，但專案搭配 Swift 6 嚴格併發與 `State: Sendable` 契約未實測過。實作時若巨集或 `Sendable` 遇到障礙，停下來回報，不自行改回布林或拿掉 `Sendable`。
- **[移除 `Action` 的 `Equatable` 連帶到清單外的檔]** → 已確認 `RootFeature.Action` 是唯一持有這三個 Action 的型別；`RootFeatureTests` 以值比對的 `receive` 共三處，處理方式見「同一次請求的結果合併成 Result」一節。若編譯發現其他依賴 (例如某處以 `==` 比較 action)，停下來回報。
- **[`SettingsFeature.State` 改由建立時帶齊後，啟動流程的 App 鎖定時序改變]** → 鎖定設定在 `RootFeature.State` 建立時就已設好 (與現況相同)，`.settings(.appLock(.appDidBecomeActive))` 讀到的 `isBiometricUnlockEnabled` 不再依賴先送 `.settings(.task)`。`AppLockTests` (UI) 與 `AppLockFeatureTests`、`RootFeatureTests` 的鎖定測試必須維持綠燈。
- **[改名時誤改 UserDefaults key 字串]** → 既有使用者的設定會全部讀不到。`SettingsStoreTests` 以固定字串寫入舊 key 後讀回，斷言六個欄位都讀得到，守住 key 不變。
- **[拆出元件後 `quoteViewBaseline` 像素改變]** → 報價畫面有 snapshot 守，拆檔只搬移、不改 modifier 與值。轉紅時先依已知雜訊判別法單獨重跑；單獨重跑仍紅就是真的改到畫面，要改回程式碼，不得重錄。
- **[FX、設定、客戶、更多、AI 總結沒有 snapshot，視覺回歸不會自動轉紅]** → 驗收條件 8 以開工前後的 `ui-automation` 截圖逐張比對補上；匯率工具另由 task 0.5 在改動前錄兩條 snapshot 守住一般與錯誤狀態。
- **[`OptionPickerSheet` 選取後呼叫的 `dismiss()` 與 reducer 清空 `destination` 同時發生]** → reducer 先清空，`dismiss()` 對已關閉的 sheet 無作用。TestStore 斷言 `destination` 在選取後為 `nil`，UI 回歸的幣別 picker 測試 (`CurrencyPickerTests`、`FxTests`、`QuoteTests`) 守住畫面行為。
- **[snapshot 測試在完整回歸下偶發失敗]** → 已知雜訊清單與判別法在 `.claude/rules/ios-unit-tests.md`，依規定單獨重跑 (方法層 `-only-testing` 帶 `()`、確認 `totalTestCount` ≥ 1)。
- **[`findings.md` 的預填結論被實作端照單改掉]** → 預填項目在檔頭列出並註明「不要改掉」；驗收條件 9 會檢查。
- **[實作端在沙箱內無法操作模擬器]** → 第 2 步確認 Codex 的 XcodeBuildMCP MCP server 會被沙箱擋住，派工時要求走 `xcodebuildmcp` CLI，仍禁止退回原生 `xcodebuild`／`simctl`。

## Migration Plan

無資料遷移：UserDefaults key 字串不變、SwiftData schema 不變。回滾即還原本 change 的 commit。
