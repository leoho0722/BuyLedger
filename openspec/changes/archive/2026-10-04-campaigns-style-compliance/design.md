## Context

開團功能 (`apps/ios/BuyLedger/Features/Campaigns/`) 是 ios-dev-kit 修正順序的第 5 步。第 3 步 (`small-features-style-compliance`) 定型了 TCA 範本，第 4 步 (`lookups-style-compliance`) 示範了沒有 View 的子 Feature、單一 `Destination` 與「表單關閉後才顯示 alert」，第 4.5 步 (`service-database-layer-alignment`) 把依賴改成 Service 並整檔修過開團檔案的寫法與排版。

現況 (2026-10-01 實測)：

- `CampaignFeature.swift` 1,350 行，同時處理列表、詳情、編輯儲存、狀態、結團、刪除、提醒；`body` 是兩段 inline `Reduce` 閉包；6 個 `@Presents`；`extension CampaignFeature.State` 有 183 個非空行的日期分組方法；`import SwiftUI` 只為了 `LocalizedStringKey` 型別的通知文案。
- `CampaignDetailView` 以 `campaignID` 參數加共用 store 呈現詳情，畫面內算 `CampaignSummary`、挑選「只看未收款」的列、決定收款切換的下一個狀態；`CampaignListView` 以 `@Dependency(\.date)`／`calendar` 取現在時間並呼叫 `state.dateSections(...)` 與 `CampaignSummary.batch`；詳情以 `selectedCampaignID` 驅動的 `[String]` 導覽路徑推入。
- `CampaignEditFeature` 的 `saveTapped` 由父層攔截做重名檢查；`RootFeature` 攔截開團內部 action `.campaignRenamed`、`.campaignDeleted`，並直接寫 `campaigns.orders` (投影) 與 `campaigns.selectedCampaignID` (深連結)。
- 開團資料只在列表出現時載入；`OrdersFeature`／`OrderEditFeature` 另外注入 `CampaignService` 自行讀取，`OrdersFeature` 還有一份與開團逐行相同的結單日自動轉狀態寫入。

使用者裁決：

- 2026-10-01：Y (訂單端的開團依賴與重複自動轉狀態留第 6 步)；P (現在時間由 reducer 寫進 State)；疑似缺陷「首頁開團卡冷啟動空白」本步只實測、第 6 步修。
- 2026-10-02 (Codex 第一輪審查後)：方案 A (單一 Feature) 主檔估計仍有 400 到 470 行，改為**方案 B，本步就拆成列表與詳情**，以 **`@Shared`** 共用資料；原訂的第 8.5 步取消。
- Codex 第二輪 (2026-10-02) 指出詳情自帶寫入與提示會和容器的表單、提示搶著呈現，深連結也可能打斷詳情的寫入；本版改為詳情不做寫入、不呈現任何提示，寫入集中到沒有 View 的 `CampaignWritesFeature`，提示一律由容器呈現 (見 Decisions 前兩節)。
- 2026-10-03 (開團部分 task 0.1 至 7.7 全部完成後)：使用者裁決擴大範圍，B 組整合點改為整檔合規，並把第 8 步的 App 殼層重構提前到本步。方案由主對話依程式碼盤點提出，以下只記錄裁決 (編號沿用方案，本文件以「4.n」「Dn」引用)：
    - B 組：4.1／4.2 由殼層方案取代 (不做 `RootFeature+MoreRoute.swift`)；4.3 `ProjectionWriteBoundaryTests` 補第三條規則；4.4 Root `Action` 依送出者分組、父層不再攔截子層內部 action，`CombineReducers` 保留並在 doc 寫明原因；4.5 `ContrastComplianceTests` 為配合改名改一行，後經使用者裁決改為本步整檔合規 (task 8.9)；4.6 `CampaignDetailScreen` 拆 3 檔、`BLAccessibilityID` 拆 8 檔且主檔保留共用方法；4.7 `guard` 的 else 先記錄警告再 return 不算違規，檢查腳本放寬；4.8 `Array` 擴充檔用功能段名，檢查腳本放寬 (後經使用者指正：功能段名只限 `<Type>+Extensions.swift`，`<Type>+<Feature>.swift` 用一般區名，`Array` 擴充的兩個方法改為 static 方法、刪除該檔)；4.9 `LocalizationCatalogTests` 第一條拆 5 條、已驗收英文值參數化；4.10 `BLUITestDependencyOverrides.swift` 改名 `DependencyValues+BLUITestOverrides.swift`；4.11 `// Given: 說明` 統一為單獨的 `// Given`；4.12 `CampaignsScreen`、`CampaignEditScreen` 本步整檔；4.13 新輔助型別不另寫單元測試，靠既有測試加變異驗證。
    - 殼層：D1 抽 `MoreFeature` 持有 `StackState` (M2)；D2 `MoreFeature` 視為 App 殼層、目錄不動；D3a 至 D3d 匯率、報價、主檔管理、設定都放 `Path` (接受輸入重設、報價每次進入多打一次匯率 API、主檔每次重讀與返回取消回應)；D4「更多」列用 `Button` 加尾端箭頭、保留系統列按壓高亮；D5 偏好由 Root 持有、設定頁以 delegate 回報；D6 啟用驗證移入 `SettingsFeature` (L1)，`BiometricAuthService` 本步搬到 `Core/Dependencies/`、不列過渡例外；D7 `AppLockFormatters`；D8 冷啟動解鎖改由 `onChange(of: scenePhase, initial: true)`；D9 回到前景由殼層集中重寫現在時間；D10 監聽系統重大時間變更 (新 Service)；D11 導覽輔助型別因 D10 改 struct 形式；D12 本步修冷啟動月目標；D13 `Features/App` 其餘檔本步整檔合規；D14 保留 `persistenceFailure`；D15 頂層 `AppScenePhase`；D16 改名 `AppFeature` 留第 10 步；D17 `OrdersFeature.swift`、`LayerBoundaryTests.swift`、`SnapshotTests+Lookups.swift` 只查 diff；D18 移除不再使用的 xcstrings key；D19 回到前景不重新評估開團自動結束；D20 Orders 新委派的測試放新檔；D21 客戶頁以 `SharedReader` 讀訂單投影。
    - 同日兩條現行規則：TCA `State` 本體順序為 stored → 非 private computed → init → nested types → 方法；多重 trailing closure 一律多行。

殼層現況 (2026-10-03 盤點，行數為不含檔頭與空行的非空行數實測)：

- `RootFeature.swift` 413 行：`State` 持有 `orders`／`customers`／`campaigns`／`dashboard`／`insights`／`fx`／`quote`／`settings`／四份 `lookupManagements`、`morePath: [MoreRoute]`、`persistenceFailure`；`Action` 是只為 `morePath` 的 `BindableAction`，`task`／`tabSelected`／`sidebarTabSelected`／`startNewOrder`／`smartGroupSelected`／`customerSelected`／`categorySelected`／`campaignSelected` 平放。
- `AppLockFeature` 巢狀在 `SettingsFeature.State.appLock`；`BuyLedgerApp` 經 `AppScenePhaseCoordinator` 送 `.settings(.appLock(...))`；冷啟動由 Root `task` 送 `.settings(.appLock(.appDidBecomeActive))`；`SettingsFeature` 攔截 `.appLock(.enableAuthenticationFinished(.success))`、`.appLock(.enableToggled(false))` 存檔；`ActionGroupingScanTests` 唯一的 allowlist 是 `SettingsView` 送 `.appLock(`。
- 語言由 `RootView` 讀 `store.settings.language`；月目標以 `onChange(of: \.settings.monthlyProfitGoalTWD)` 投影到總覽，但 `RootFeature.State.init` 沒有同步，`DashboardFeature.State` 預設 80,000，冷啟動首頁因此顯示 80,000 直到在設定頁改過 (程式碼推論，未實測)；預設幣別沒有讀取端 (新訂單一律 TWD，第 6 步)。
- `BiometricAuthService` 在 `Features/App/Data/`，引用者為 `AppLockFeature`、`App/Testing/` 的替身與覆寫、`AppLockFeatureTests`、`BiometricAuthServiceTests`。
- 把現在時間寫進 State 的只有 `CampaignListFeature.State.dateContext`；`OrdersView`／`OrdersCompactView`／`OrderMergeCandidateSheet`／`DashboardView`／`InsightsView` 仍在畫面讀時間 (第 6、7 步過渡例外)。
- `CampaignFeature.swift` 294 行；`RootSidebarLayout.swift` 344 行；`SettingsFeatureTests.swift` 348 行。

約束 (本步必須遵守的既有守門與規則)：

- `ProjectionWriteBoundaryTests`：`CampaignFeature` 的投影 `orders` 主檔為 `Features/Campaigns/CampaignFeature.swift`；`RootFeature.swift` 是唯一合法寫入者；主檔以外出現 `inout CampaignFeature.State` 即違規。目前只在擁有者區塊偵測 `state.orders =` 與變異方法呼叫，偵測不到 `withLock`，也偵測不到以值傳遞的 State 寫入共享引用。
- `ActionGroupingScanTests`：已遷移的 View 只能送 `.view(...)`；reducer 規則掃描整個 `Features/`，任何 `.<小寫識別字>(.view(` 都算父層碰子層 view action。
- `LocalizationCatalogTests` 寫死 `CampaignListView.swift` 路徑 (navigationTitle 掃描) 與 `CampaignDetailView.swift` 路徑及字面 `Text(LocalizedStringKey(order.paymentReceiptStatus.title))`。
- `apps/ios/CLAUDE.md`：Feature 除 `Data/` 外維持扁平、目錄調整在第 10 步；格式化用 `CampaignFormatters` 等靜態函式；一檔一個頂層型別；`Reduce(core)`；主 switch 不用預設分支；沒有自己 View 的子 Feature 由父層轉送。`.claude/rules/ios-data-layer.md`：`@Shared` 目前只用在主檔目錄，「擴用前先確認真的有多個 feature 讀寫同一份資料」。
- ios-dev-kit `tca-architecture.md`：Stack 由根 Feature 的 `Path` 管理、子畫面以 `delegate` 交回；一個畫面只有一個 `destination`；`@Shared` 只用於父子 Feature 的記憶體內共享。
- TCA 官方 `SharingState.md` (本機 TCA 1.26.2、swift-sharing 2.9.1)：父層以無鍵 `@Shared` 持有來源，建立子層 State 時傳引用；唯讀用 `SharedReader`；寫入一律 `withLock`；TestStore 以 `$0.$x.withLock { ... }` 斷言。
- 規格：`campaign-management` 規定「只看未收款」以專用 action 更新且跨導覽保留；`campaign-calendar-reminder` 規定提醒以注入的 calendar 計算、重建先建新事件再刪舊事件、提醒不經獨立 sheet；`campaign-write-ordering` 規定重名拒絕在任何寫入前、寫入成功才更新畫面、刪除後才移除行事曆事件、載入失敗不與一次性失敗共用欄位；`app-layer-boundaries` 規定每個請求一個回應 case、重試是獨立的使用者操作、投影由 root 單向同步且唯讀；`gesture-and-target-affordance` 規定詳情的刪除與長按刪除使用同一份確認。
- 殼層相關的既有守門與規則 (2026-10-03 擴大範圍適用)：`LayerBoundaryTests.rootStoreDeclarationsMatchTheNavigationHostWhitelist` 鎖住四個根 store 宿主 (`RootView`／`RootTabLayout`／`RootSidebarLayout`／`MoreView`) (本 change 縮為三個宿主，測試改名為 `filesDeclaringRootStore_功能目錄_僅由三個根導覽宿主持有`)；`ProjectionWriteBoundaryTests.rootFeatureRelativePath` 是 `Features/App/RootFeature.swift`，現行規則偵測不到別檔以 `inout RootFeature.State` 寫 `state.dashboard.orders` 這類投影；`.claude/rules/ios-navigation.md` 記載「更多」路徑非空時改 `selectedTab` 會讓 iPad 的 `NavigationSplitView` assertion 崩潰；`apps/ios/CLAUDE.md` 規定子層啟動所需資料在建立 State 時帶齊、純計算放無 case enum、需要依賴值的分派放持有依賴值的 struct、輔助型別不宣告 `@Dependency`。

## Goals / Non-Goals

**Goals:**

- 開團的每個 production 檔與測試檔各自不超過 300 行 (不含檔頭與空行)；每個 Feature 的 Action 依送出者分組，`body` 只組合。
- 列表與詳情各自是有 View 的 Feature，衍生資料 (日期區段、列彙總、詳情內容、收款切換) 由 Feature 狀態提供，畫面只呈現。
- 父子只經 delegate 溝通；容器是開團操作確認與寫入失敗提示的唯一呈現者 (編輯表單自身的捨棄確認保留在表單內)，所有關閉路徑與並行失敗都有確定的呈現順序。
- `findings.md` 377 筆全部有結論，判讀級問題依本文件處置。
- 使用者可觀察的行為不變，例外只有 Implementation Contract「行為」列出的差異 (開團原有的本地化修正與日期標題更新時機，加上 2026-10-03 擴大範圍確認的殼層差異)。
- App 殼層 (2026-10-03 擴大範圍)：`RootFeature.swift` 不超過 300 行；Root `Action` 依 `view` 與子層分組，父層只對子層 delegate 反應，`ActionGroupingScanTests` 的 allowlist 清空；「更多」以 `MoreFeature` 的 `StackState` 驅動；App 鎖定常駐殼層、啟用驗證在設定頁；開團列表的現在時間在回到前景與跨日時更新；冷啟動首幀即使用已儲存的偏好。
- 原 B 組 15 檔與殼層改到的檔依整檔標準合規 (只為接線而改的三個檔例外，見 Implementation Contract「檢查分組」)。

**Non-Goals:**

- 不改 `OrdersFeature`／`OrderEditFeature` 對 `CampaignService` 的注入與訂單端的自動轉狀態，不設計 App 啟動時的開團載入，不修首頁開團卡冷啟動空白 (第 6 步)。
- 不改 Dashboard、Insights 的程式碼 (第 7 步)；它們引用的 `CampaignSummary` 只換檔案位置，`CampaignFormatters.twd` 的呼叫點不動。
- 不改 `CampaignService`、`CampaignReminderService`、`CalendarReminderService` 的介面與錯誤型別 (`PersistenceError` 沿用)。
- 不調整目錄層級 (除了既有慣例的 `Data/`、`Components/`)、不改 `FormatStyle` (第 10 步)。
- 不改 SwiftData schema；不改自動轉狀態的評估時機 (目前只在首次載入評估，回到前景也不重新評估，D19)。
- `Features/Orders/` 只改 `OrdersFeature` 的「前往開啟 AI 設定」改送 `delegate(.aiSettingsRequested)` (B 組只查 diff)。
- 第 6 步承接，本步只登記、不開 task：`OrderEditView` 6 個選擇列使用 `.buttonStyle(.plain)` 而失去系統列按壓高亮；預設幣別設定沒有讀取端 (新訂單一律 TWD)；Root 送進 `OrdersFeature` 的三種內部 action (`.orders(.task)`、`.orders(.receiptStatusChanged)`、`.orders(.paymentMethodFlagsApplied)`) 留待 Orders 有正式入口。
- 不把 `RootFeature` 改名 `AppFeature`、不搬 `Features/More/` 目錄 (第 10 步，D16、D2)；`ProjectionWriteBoundaryTests`、`LayerBoundaryTests`、`DesignSystemSourceScanTests` 三份同型的 `stripCommentsAndStrings` 不抽共用 (第 10 步)。

## Decisions

### 拆成 CampaignFeature、CampaignListFeature、CampaignDetailFeature 與兩個無 View 子 Feature

| Feature | View | 職責 |
|---|---|---|
| `CampaignFeature` | `CampaignView` (新檔，開團分頁的根容器：`NavigationStack`、編輯表單 sheet、容器 alert 的掛載) | `@Shared` 的來源、導覽堆疊、**操作確認與失敗提示的唯一呈現者** (編輯表單、刪除與結團確認、全部失敗提示；表單自身的捨棄確認除外) 與表單生命週期、把列表與詳情的請求轉給子 Feature、對 `RootFeature` 的 delegate |
| `CampaignListFeature` | `CampaignListView` (列表內容與列表 toolbar) | 載入與重試、結單日自動轉狀態 (含寫入)、篩選、分組、日期區段、列彙總、現在時間 |
| `CampaignDetailFeature` | `CampaignDetailView` | 詳情內容、「只看未收款」；**不做寫入、不呈現提示、沒有非同步 effect**，其餘操作都以 delegate 交給 `CampaignFeature` |
| `CampaignWritesFeature` | 無 | 儲存、改名連動、刪除、狀態變更、結團的寫入與成功後更新共用開團 (見「寫入集中到 CampaignWritesFeature」) |
| `CampaignReminderFeature` | 無 | 行事曆提醒 (見「提醒流程抽成 CampaignReminderFeature」) |
| `CampaignEditFeature` | `CampaignEditView` | 編輯表單 (見「父層以最新開團清單驗證重名」) |

`RootFeature` 的 `Scope(state: \.campaigns, ...)` 仍指向 `CampaignFeature`，`RootTabLayout` 與 `RootSidebarLayout` 的開團分頁改呈現 `CampaignView(store:language:)`。所有 Feature 與編輯表單依現行登記留在 `Features/Campaigns/` 平面。

**行數預算** (估計值，以第 4 步 `LookupManagementFeature` 實測校準：State 42、Action 68、`core` 加 helper 150 個非空行，全檔 290；`CampaignWritesFeature` 在 task 2.5、`CampaignListFeature` 在 3.2、`CampaignDetailFeature` 與 `CampaignFeature` 在 3.3 結束時量測，超過 300 行就停下回報，不自行登記例外或再抽結構)：

| 檔案 | State | Action | Dependencies＋body | `core`＋helper | 固定開銷 (import、頂層宣告、MARK、extension) | 合計 |
|---|---|---|---|---|---|---|
| `CampaignFeature.swift` | 約 45 (11 個成員、`init`) | 約 65 (7 個子層／導覽 case、2 個 view、3 個 delegate) | 約 27 (4 個依賴、3 個 `Scope`、`.forEach`、`.ifLet`) | 約 145 (約 20 個分支，多數一行轉送；helper：處理請求、開表單、處理送出、`showDetail`) | 約 9 | 約 290 (餘裕小，task 3.3 實測) |
| `CampaignListFeature.swift` | 約 50 (8 個成員、3 個 computed) | 約 60 | 約 15 | 約 85 | 約 9 | 約 220 |
| `CampaignDetailFeature.swift` | 約 35 (5 個成員、1 個 computed) | 約 45 | 約 8 | 約 40 | 約 9 | 約 140 |
| `CampaignWritesFeature.swift` | 約 8 | 約 75 (4 個請求、5 個回應、4 個 delegate) | 約 12 | 約 115 | 約 9 | 約 220 |

為了讓 `CampaignFeature` 留在預算內，以下純計算與值型別放在主檔以外 (不帶 `inout CampaignFeature.State`)：表單生命週期與暫存 (`CampaignPresentationQueue`)、儲存計畫的組裝 (`CampaignSavePlan`)、重名判斷 (`CampaignSavePlan.conflicts(...)`)、所有 `AlertState` 建構 (`CampaignFeature+Destination.swift`)、預設提醒時間 (`CampaignReminderRequest.defaultTimestamp`)。

替代方案：方案 A 估計 400 到 470 行 (使用者放棄)；詳情自帶寫入與提示 (前一版) 需要兩個呈現者協調，且深連結換掉詳情時會丟棄進行中的寫入回應；所有寫入留在容器時估計約 400 行。

### 以 @Shared 共用開團、訂單投影、提醒連結與只看未收款

`CampaignFeature.State` 是來源，以無鍵 `@Shared` 持有四份資料，無參數的 `init()` 先以明確型別建立區域引用 (例如 `Shared<[Campaign]>(value: [])`) 再同時指派給 `_x` 與子層 State，不提前讀 `self`；`RootFeature.State()` 與測試的建構方式不變，資料設定改用 `withLock`。

| 資料 | `CampaignFeature` | `CampaignListFeature` | `CampaignDetailFeature` | `CampaignWritesFeature` | `CampaignReminderFeature` | 寫入者 |
|---|---|---|---|---|---|---|
| `campaigns: [Campaign]` | `@Shared` (來源) | `@Shared` | `@SharedReader` | `@Shared` | 無 | 列表 (載入結果、自動轉狀態)、`CampaignWritesFeature` (寫入成功後)；自動轉狀態維持現況「先更新顯示再寫入」 |
| `orders: [LedgerOrder]` (投影) | `@Shared` (來源) | `@SharedReader` | `@SharedReader` | 無 | 無 | 只有 `RootFeature` (`state.campaigns.$orders.withLock { $0 = ... }`) |
| `reminderLinks: [Campaign.ID: CampaignReminderLink]` | `@Shared` (來源) | 無 | `@SharedReader` | 無 | `@Shared` | 只有 `CampaignReminderFeature` |
| `showsUnpaidOnly: Bool` | `@Shared` (來源) | 無 | `@Shared` | 無 | 無 | 只有詳情的 `view(.unpaidOnlyToggled)` (跨導覽保留由共用達成) |

- 子層 `init` 對唯讀資料只接 `SharedReader<Value>` (由父層以 `SharedReader(_ base: Shared<Value>)` 轉換後傳入)，不先收 `Shared` 再自行轉換；`SharedReader` 沒有 setter 與 `withLock`，列表與詳情在編譯期就無法寫入投影與連結。
- `RootFeature` 的 `onChange(of: \.campaigns.campaigns)` 與三份副本同步不變 (前後取得的是陣列值，可觀察 reducer 內的 `withLock`；本機 TCA `OnChangeReducerTests` 有對應案例)；共享寫入不得移到 effect 裡再回送。
- 文件改寫：`.claude/rules/ios-data-layer.md`「`@Shared` 只用在主檔目錄」改為主檔目錄 (`.lookupCatalog` 鍵) 與開團 (由 `CampaignFeature` 持有、無鍵的父子共享) 兩處；`apps/ios/CLAUDE.md` 專案差異的 `@Shared` 條目同步。
- 測試：初始資料以 `withLock` 設定後再建 `TestStore`；斷言用 `$0.$campaigns.withLock { ... }`；effect 鏈上的共享變更寫在第一個觀察到它的斷言點 (TCA `SharingState.md` Tests 節)。

替代方案：父層以 `onChange` 把副本寫回列表與堆疊裡的每個詳情 (使用者未採用)。

### 詳情不寫入也不呈現，提示一律由容器呈現

詳情的使用者操作只有兩種結果：改共用的 `showsUnpaidOnly`，或以 `delegate(.requested(CampaignRequest))` 請 `CampaignFeature` 處理。因此詳情沒有非同步 effect，堆疊元素被換掉或移除時不會有遺留的回應；同一時間的呈現只有容器一個來源，不需跨畫面協調。

- `CampaignRequest` (列表與詳情共用的請求型別)：`showDetail(Campaign.ID)`、`create`、`edit(Campaign.ID)`、`delete(Campaign.ID)`、`settle(Campaign.ID)`、`changeStatus(id: Campaign.ID, status: CampaignStatus)`、`toggleReceipt(orderID: LedgerOrder.ID, status: PaymentReceiptStatus)`。`CampaignFeature` 以單一 helper 處理兩個來源的請求。
- 刪除 (列表長按與詳情選單)、結團都先由容器顯示確認 alert，確認後轉給 `CampaignWritesFeature`；兩條刪除路徑共用同一份確認內容與同一段寫入。
- 收款切換的下一個狀態由詳情 reducer 依 `orders` 決定 (`received` 切 `pending`、其他切 `received`；找不到訂單不送出)，容器把 `toggleReceipt` 轉成自己的 `delegate(.receiptStatusToggled)`。
- ios-dev-kit「一個畫面只有一個 `destination`」：詳情畫面不需要任何呈現，所以沒有 `destination`；容器是開團操作確認與寫入失敗提示的唯一呈現者。編輯表單自身的捨棄確認 (`CampaignEditFeature.discardConfirmation`) 保留在表單內，屬於表單開啟期間，外部失敗照樣暫存到表單完全關閉。
- 詳情沒有非同步 effect 是本設計的前提：收款切換回傳的同步 `.send(.delegate)` 不留等待中的回應；日後若在詳情加入 `.run` 或延遲，要重新檢查深連結換掉詳情時的遺留回應。

### 詳情以 StackState 推入，列表點擊與深連結共用同一入口

- `CampaignFeature+Path.swift`：`@Reducer enum Path { case detail(CampaignDetailFeature) }`；`State.path = StackState<Path.State>()`；`body` 以 `.forEach(\.path, action: \.path)` 組合；`Path.State` 的 `Equatable` 遵循寫在 `extension CampaignFeature.Path.State` (比照 `Destination.State` 的巨集例外)。
- 推入入口只有 `CampaignFeature.State.showDetail(campaignID:)` (State 本體內的 `mutating func`)：找到該開團時在同一次更新內 `path.removeAll()` 再 `append(.detail(...))` (不重建整個 `StackState`，保留其掛載紀錄)，找不到則不動。列表的 `requested(.showDetail)` 與 Root 的開團深連結 (以名稱找到 id 後；原為 `RootFeature.campaignSelected(name)`，2026-10-03 起由 `RootNavigationOperations.showCampaign(named:state:)` 承接，見「Root 導覽操作與 Action 分組」) 都呼叫它，`selectedCampaignID` 移除。
- `RootFeature` 直接呼叫這個 State 方法而不經 `CampaignFeature` 的 reducer：詳情沒有非同步 effect，被換掉的元素不會有遺留回應，`.forEach` 下一次處理 action 時即完成掛載紀錄的同步。測試：詳情 A 經實際的列表請求流程推入 (不是在初始 State 手動放入)，再以深連結換成 B，斷言堆疊只剩 B、沒有 missing element 的 issue；接著對 B 送出一次操作 (例如收款切換) 並返回列表，確認 delegate 轉送、pop 與掛載同步都正常。
- 刪除成功時從 `path` 移除該開團的詳情；iPad 的 `RootSidebarLayout` 呈現同一個 `CampaignView`。

### Action 依送出者分組，每個請求一個回應

每個 Feature 的 `Action` 依 `view` → `delegate` → 子層／導覽 → 請求 (沒有 View 的子 Feature) → 內部回應 (字母序) 排列；成功與失敗合併成一個 `...Response(Result<_, PersistenceError>)`。`PersistenceError` 不遵循 `Equatable`，開團各 Feature 的 `Action` 都不遵循 `Equatable` (`RootFeature.Action` 第 3 步起已不遵循)。

| Feature | `view` | `delegate` | 子層、導覽與請求 | 內部回應 |
|---|---|---|---|---|
| `CampaignFeature` | `task` (轉送提醒連結載入)、`formSheetDismissed` | `campaignDeleted(name:)`、`campaignRenamed(from:to:)`、`receiptStatusToggled(orderID:status:)` | `path`、`destination`、`list`、`reminder`、`writes` | 無 |
| `CampaignListFeature` | `task`、`retryTapped`、`campaignTapped(Campaign.ID)`、`statusFilterSelected(CampaignStatus?)`、`groupingSelected(CampaignGrouping)`、`newCampaignTapped`、`editCampaignTapped(Campaign.ID)`、`deleteCampaignTapped(Campaign.ID)` | `requested(CampaignRequest)`、`autoCloseFailed` | 無 | `autoCloseResponse(Result<Void, PersistenceError>)`、`campaignsResponse(Result<[Campaign], PersistenceError>)` |
| `CampaignDetailFeature` | `editTapped`、`settleTapped`、`statusChanged(CampaignStatus)`、`deleteTapped`、`receiptToggleTapped(LedgerOrder.ID)`、`unpaidOnlyToggled(Bool)` | `requested(CampaignRequest)` | 無 | 無 |
| `CampaignWritesFeature` | 無 | `failed(Failure)`、`saved(CampaignReminderRequest?)`、`renamed(from:to:)`、`deleted(Deletion)` | 請求：`saveRequested(CampaignSavePlan)`、`deleteRequested(id:name:)`、`settleRequested(Campaign.ID)`、`statusChangeRequested(id: Campaign.ID, status: CampaignStatus)` | `deleteResponse`、`renameResponse`、`saveResponse`、`settleResponse`、`statusResponse` |

- 多個 associated value 的 case 一律加標籤 (ios-dev-kit；使用者 2026-10-03 在 style 閘門裁決，簽章已依此改寫)。
- `retryTapped` 與 `task` 走同一段載入，但 `retryTapped` 是獨立的使用者操作 (`app-layer-boundaries`「A retry is its own user interaction」)，載入失敗畫面的重試鍵改送它。載入失敗寫入 `errorMessage` (持續顯示於列表)，不進任何 alert。
- `CampaignFeature.body`：`Scope(list)` → `Scope(reminder)` → `Scope(writes)` → `Reduce(core)` → `.forEach(\.path)` → `.ifLet(\.$destination)`。只對子層的 delegate 反應：列表與詳情的 `requested`、列表的 `autoCloseFailed`、表單的 `saveRequested`、寫入與提醒的 delegate。
- 移除的舊 case：`campaignsLoaded`、`campaignsFailed`、`campaignStatusSaved`、`campaignSettled`、`campaignSaved`、`campaignDeleted`、`campaignRenamed`、`campaignWriteFailed`、`settleConfirmed`、`campaignDeleteRequested`、六個 `reminder*`、`campaignSelected`、`noticeAlert`、`detailNoticeAlert`、`deletionConfirmation`、`detailDeletionConfirmation`、`settleConfirmation`、`editCampaign`，以及 `selectedCampaignID`、`reminderLinks` 等舊欄位。

### 父層以最新開團清單驗證重名

`CampaignEditFeature` 的 Action 改為 `binding`、`view(.saveButtonTapped／.cancelButtonTapped)`、`delegate(.saveRequested(SaveRequest))`、`discardConfirmation`；`CampaignEditView` 只送 `.view(...)`；`State` 不新增 stored 欄位，另有便利 `init(original:link:id:now:calendar:)` (見「提醒流程抽成 CampaignReminderFeature」) 與可寫的 computed property `draftName`：名稱欄位綁定 `$store.draftName`，reducer 以 `.binding(\.draftName)` 清除過期的重名訊息 (綁 `$store.draft.name` 時 SwiftUI 會寫回整個 `draft`，送出的 key path 是 `\.draft`，`.binding(\.draft.name)` 永遠不成立；verify 後修正，測試以 `@Bindable` 走真正的綁定路徑)。

- 子層只處理不需要父層資料的檢查：名稱去頭尾空白後為空就不送出。其餘送出 `delegate(.saveRequested(SaveRequest))`，`SaveRequest` (巢狀型別) 帶 `original: Campaign?`、已去空白的 `name`、`draft: CampaignDraft`；表單不自行關閉。
- `CampaignFeature` 收到後，在關閉表單、任何寫入與提醒調解**之前**，以當下最新的 `campaigns` 呼叫 `CampaignSavePlan.conflicts(name:originalName:editingID:campaigns:)`：名稱與原名不同、且有其他 id 的開團去空白後同名 → 把「已有其他開團使用這個名稱，請改用不同名稱。」寫回 `destination` 內表單的 `nameConflictMessage`，表單維持開啟，零寫入；否則關閉表單並轉給寫入子 Feature。原名未變直接放行 (即使資料裡已有同名的其他開團)。
- 檢查一律用送出當下的清單，所以「列表載入中開表單、載入後才出現同名」也會被擋。符合 `.claude/rules/ios-navigation.md`「需要父層資料的驗證由父層決定是否關閉，拒絕時把原因寫回子層 State」，`CampaignEditFeature` 仍是該條的例子。
- 測試輸入要能殺死變異：原名例外用「兩個不同 id 都叫『重複團』、編輯其中一個且不改名 → 儲存成功」；重名拒絕用「表單先開啟，之後列表載入回應帶入同名開團，再送出 → 拒絕且 `saveCampaign`／行事曆替身零呼叫」。

`CampaignDraft` 移到自己的檔案。

### 表單以任何方式關閉時都等關好才顯示提示

`CampaignFeature+Destination.swift`：`@Reducer enum Destination { case edit(CampaignEditFeature); @ReducerCaseIgnored case alert(AlertState<Alert>) }`，明寫 `Destination.Action` (`alert(Alert)`、`edit(CampaignEditFeature.Action)`)，`Alert` 為 `confirmDelete(Campaign.ID)`、`confirmSettle(Campaign.ID)`、`openSettings`；所有 `AlertState` 建構寫在 `extension CampaignFeature.Destination.State` (比照 `LookupManagementFeature+Destination.swift`)。`CampaignView` 只宣告一個 `.sheet(item:onDismiss:)`，並把容器唯一的 alert 綁定掛在目前最上層的畫面 (堆疊為空時是列表根內容，推入詳情時是詳情；另一處給 `.constant(nil)`，原因見 Risks 的 iPad 項)；`CampaignListView`、`CampaignDetailView` 自身不宣告任何呈現。

表單生命週期與暫存放在 `CampaignPresentationQueue` (State 成員，值型別，獨立檔案；方法以 `inout CampaignFeature.Destination.State?` 溝通，不碰整份 State)：

| 狀態 | 進入條件 | 提示到達時 |
|---|---|---|
| 表單開啟 | `destination` 為 `.edit` | 存入暫存，不取代表單 |
| 關閉中 | 父層接受儲存並把 `destination` 設為 `nil`；或 `core` 收到 `.destination(.dismiss)` 且當下仍是 `.edit` (取消無變更、確認捨棄、下滑關閉都會走到這裡；base reducer 在 `destination` 清空前執行) | 存入暫存 |
| 已關閉 | `view(.formSheetDismissed)` (由 `.sheet` 的 `onDismiss` 送出)：清除旗標，暫存有值就設進 `destination` 並清空 | 直接設進 `destination` (另一個 alert 顯示中時取代它；alert 之間的切換沒有 sheet 關閉動畫的問題，第 4 步已實測) |

- 暫存只保留最新的一則 (與現況同一欄位覆寫一致；規格 delta 明列)，移出後為 `nil`；提示關閉後 `destination` 為 `nil`，不留下「狀態宣稱顯示、畫面沒顯示」的通知。
- 表單內的「捨棄變更」確認選「繼續編輯」時表單維持開啟，暫存保留到表單真正關閉。
- 測試涵蓋：儲存後關閉中到達、取消無變更與確認捨棄的關閉中到達、開啟中到達後選繼續編輯再取消、關閉中連續兩則只顯示後一則、儲存成功但改名與提醒都失敗、詳情發起的狀態變更失敗在表單開啟中到達、移出後暫存為 `nil`、提示關閉後 `destination` 為 `nil`；`CampaignPresentationQueue` 另有直接的單元測試。

### 寫入集中到 CampaignWritesFeature

沒有 View、不設 `view` 分組、由 `CampaignFeature` 轉送 (比照 `PaymentMethodCorrectionFeature`)。State 以 `@Shared var campaigns` 持有開團；依賴 `campaignService`、`orderService`、`date`。

| 請求 | 行為 |
|---|---|
| `saveRequested(CampaignSavePlan)` | `saveCampaign` → `saveResponse`；成功時 upsert 進共用開團 (依開團日期由新到舊排序)，有改名則 `renameOrderCampaign` → `renameResponse` (成功送 `delegate(.renamed)`，失敗送 `delegate(.failed(.rename))`)，最後送 `delegate(.saved(plan.reminder))` (改名失敗仍繼續，與現況順序相同：儲存 → 改名 → 提醒)；儲存失敗送 `delegate(.failed(.save))`，不改共用資料、不送 `saved` |
| `deleteRequested(id:name:)` | `removeCampaign` → `deleteResponse`；成功時從共用開團移除並送 `delegate(.deleted(Deletion))` (`id`、`name`、被刪連結的事件 id)；失敗送 `delegate(.failed(.delete))` |
| `settleRequested(Campaign.ID)` | 找不到或已結團就不動；以 `date.now` 寫入結算日 → `settleResponse`；成功只套用 `settledDate`；失敗送 `delegate(.failed(.settle))` |
| `statusChangeRequested(id: Campaign.ID, status: CampaignStatus)` | 找不到或狀態相同就不動 → `statusResponse`；成功只套用 `status`；失敗送 `delegate(.failed(.status))` |

`CampaignFeature` 處理寫入的 delegate：`saved(request?)` 有請求時轉送 `.reminder(.reconcileRequested)`；`renamed` 轉成自己的 `delegate(.campaignRenamed)`；`deleted` 從 `path` 移除該詳情，再依序送自己的 `delegate(.campaignDeleted(name:))` 與 `.reminder(.campaignRemoved(...))`；`failed` 經 `CampaignPresentationQueue` 呈現。

`CampaignSavePlan` (純值型別，獨立檔案)：`campaign` (新開團用父層以 `uuid()` 產生的 id、備註去空白、沿用原 `settledDate`)、`rename: Rename?` (原名存在且不同)、`reminder: CampaignReminderRequest?`；`static func make(request:existingLink:newID:calendar:)` 與 `static func conflicts(name:originalName:editingID:campaigns:)`。`orderService.renameOrderCampaign` 是開團跨 Feature 改寫訂單表的既有路徑，登記為過渡例外、第 6 步隨 `OrderService` 處理。

### 提醒流程抽成 CampaignReminderFeature

沒有 View、不設 `view` 分組、由 `CampaignFeature` 轉送。

- State：`@Shared var links: [Campaign.ID: CampaignReminderLink]`、`hasLoadedLinks: Bool`。
- 父層轉送的請求：`linksRequested` (`CampaignFeature` 的 `view(.task)`，已載入就略過)、`reconcileRequested(CampaignReminderRequest)` (寫入子 Feature 回報 `saved` 且有請求時)、`campaignRemoved(campaignID: Campaign.ID, eventIdentifier: String?)` (刪除成功後)。收到 `campaignRemoved` 時先以 `withLock` 清除 `links[campaignID]`，沒有事件 id 或事件移除失敗也維持清除；此路徑不呼叫 `removeLink` (本機交易已刪除持久化連結)，有事件 id 才移除行事曆事件，失敗回報 `eventRemovalAfterDeleteFailed`。
- `CampaignReminderRequest` 欄位：`campaignID`、`reconcile: CampaignReminderReconcile`、`title`、`eventDate` (時間戳當天起始)、`alarmOffset` (自當天 00:00 起算的秒數)、`timestamp`。`CampaignReminderReconcile` 為 `create`、`remove(eventIdentifier: String)`、`rebuild(oldEventIdentifier: String)`；判定由純函式 `CampaignReminderReconcile.decide(wantsReminder:existingLink:originalTitle:newTitle:chosenTimestamp:) -> CampaignReminderReconcile?` 負責，規則搬自現況：要提醒且無連結 → `create`；要提醒、有連結且標題或時間戳變更 → `rebuild`；要提醒、有連結且未變 → `nil`；不要提醒且有連結 → `remove`；不要提醒且無連結 → `nil`。不需調解時 `CampaignSavePlan.reminder` 為 `nil`。
- 回應：`linksResponse(Result<[Campaign.ID: CampaignReminderLink], PersistenceError>)` (失敗維持現況靜默、連結維持空)、`createResponse(campaignID: Campaign.ID, oldEventIdentifier: String?, result: Result<CampaignReminderLink, Failure>)`、`linkRemovalResponse(campaignID: Campaign.ID, result: Result<Void, PersistenceError>)`、`oldEventRemovalResponse(Result<Void, CalendarReminderError>)`、`eventRemovalResponse(Result<Void, CalendarReminderError>)`。
- `delegate(.failed(Failure))`：`Failure` (遵循 `Error`) 為 `accessDenied`、`accessRestricted`、`creationFailed`、`calendarUnavailable`、`linkRemovalFailed`、`oldEventRemovalFailed`、`eventRemovalAfterDeleteFailed`；`CampaignFeature` 對應成提示 (文案表見 Implementation Contract)，`accessDenied` 附「前往設定」(`Alert.openSettings`)。
- 行為逐條沿用：權限只在建立與重建時請求 (移除提醒不請求，與現況相同)，三態分開呈現；`noWritableCalendar` 對應 `calendarUnavailable`，其餘建立失敗與連結寫入失敗對應 `creationFailed`；移除提醒時行事曆事件移除失敗可忽略、仍移除連結；重建先建新事件並寫入新連結，成功後才刪舊事件，刪舊失敗回報 `oldEventRemovalFailed` 且不回滾；新事件建立失敗時連結維持指向舊事件、不刪舊事件 (`campaign-calendar-reminder` delta 統一了重建順序)。
- `CampaignReminderRequest.defaultTimestamp(closeDate:now:calendar:)` 是純計算 (結單日或今天的 09:00)；由 `CampaignEditFeature.State` 的便利 `init(original:link:id:now:calendar:)` 在內部呼叫並決定提醒開關 (有連結就開、時間取連結的時間戳)；`CampaignFeature` 開啟表單時只傳入注入的 `date.now` 與 `calendar`，不使用列表的 `dateContext` (使用者 2026-10-02 在 task 3.3 為壓低 `CampaignFeature` 行數所做的裁決)。

### 列表與詳情的衍生資料由 State 提供

computed property 寫在各自 `State` 本體 (不另開 `extension ...State`)；衍生值一律 computed、不存 stored 欄位：

- `CampaignListFeature.State`：`loadState`；`dateSections: [CampaignDateSection]` (`dateContext` 為 `nil` 時回空陣列，否則呼叫 `CampaignDateSectionBuilder.sections(for:statusFilter:grouping:calendar:)`)；`rowSummaries: [String: CampaignSummary]` (以 `dateSections` 內的開團名稱呼叫 `CampaignSummary.batch`)。
- `CampaignDetailFeature.State`：`content: CampaignDetailContent?`，由 `CampaignDetailContent.make(campaignID:campaigns:orders:links:showsUnpaidOnly:)` 組出開團、彙總、可見分貨列 (「只看未收款」時取 `unpaidDistribution`，否則取 `distribution`) 與提醒連結；開團不存在時為 `nil`，畫面顯示「開團不存在」。
- 排序規則逐字沿用：區段與子群組依日期由新到舊；開團依 `openDate` 由新到舊，`openDate` **完全相同**時依名稱 `localizedStandardCompare` 遞增 (同一天不同時間仍依時間)。
- `CampaignDateSection.title` 與 `CampaignSubgroup.title` 改為 `CampaignSectionTitle` (`.day(Date)`、`.yearMonth(Date)`、`.year(Date)`、`.month(Date)`)。畫面以 `CampaignFormatters.sectionTitle(_:context:locale:)` 取得文字：`.day` 沿用 `OrderFormatters.daySectionTitle`，相對日期回傳本地化 key「今天」「昨天」(不論 locale)、其餘日期依 locale 格式化 (同年為月、日與縮寫星期，跨年為年月日)；翻譯由畫面的 `LocalizedStringKey` 完成。App 語言依 `app-layer-boundaries` 以建構參數傳遞，不放進 State。
- 本地化修正 (明列)：月分組的子標題目前以 `Text(String)` 呈現，「今天／昨天」不會翻譯；改為與頂層標題相同的 `LocalizedStringKey` 包裝。中文畫面不變，英文畫面改顯示 Today／Yesterday (catalog 已有)。
- 三個 Feature 都不寫 `orders`。

### 現在時間由 reducer 寫進 State

`CampaignListFeature.State` 加 `var dateContext: CampaignDateContext?` (`now`、`calendar`)。`view(.task)` 與 `view(.retryTapped)` 一進來就以注入的 `date.now`、`calendar` 寫入，**寫在「已載入就略過」的判斷之前**，所以已載入後每次 `.task` 執行仍會更新。`CampaignListView` 拿掉 `@Dependency(\.date)`／`calendar`，`.task` 掛在列表畫面本身 (堆疊根內容)。

`dateContext` 另由殼層在 App 回到前景與系統回報重大時間變更 (例如停在前景跨午夜) 時重寫 (2026-10-03 擴大範圍，見「scenePhase、回到前景與跨日」；原本「列表停在畫面上跨午夜要等 `.task` 再執行、第 8 步補回到前景更新」的已知差異由該節取代)。從詳情返回時是否重跑 `.task` 由 SwiftUI 生命週期決定，本步不依賴。第 6、7 步的 `OrdersView`、`OrdersCompactView`、`OrderMergeCandidateSheet`、`DashboardView`、`InsightsView` 照此做法處理。

`apps/ios/CLAUDE.md`「SwiftUI View 也可以同樣宣告」「State 的 computed property 改成 `func foo(referenceDate:)` 由 reducer 或 view 傳入」改寫為：需要現在時間的衍生資料由 reducer 把注入值寫進 State，畫面不宣告 `@Dependency`；尚未遷移的五個畫面列為第 6、7 步的過渡例外。

### 改名、刪除與收款切換經 delegate 通知 RootFeature

- `RootFeature`：`.campaigns(.delegate(.campaignRenamed))`、`.campaigns(.delegate(.campaignDeleted))`、`.campaigns(.delegate(.receiptStatusToggled))` 三個 case 沿用現有的訂單副本改寫與轉送邏輯 (2026-10-03 起改寫主體移到 `RootCascadeOperations`)，其餘 `case .campaigns: return .none`；開團深連結切到開團分頁並呼叫 `state.campaigns.showDetail(campaignID:)` (原 `campaignSelected(name)`，2026-10-03 起由 `RootNavigationOperations.showCampaign(named:state:)` 承接)；`onChange(of: \.orders.orders)` 對開團改為 `withLock`。

### CampaignService 搬進開團 Data，訂單端依賴留第 6 步

以 `git mv` 把 `CampaignService.swift`、`CampaignService+Dependency.swift`、`CampaignService+Preview.swift` 搬到 `Features/Campaigns/Data/`，型別、key path、錯誤型別不變 (`DependencyConventionScanTests` 的 `featureOutsideData` 只豁免第三層正好是 `Data` 的路徑，搬後仍合規)。`apps/ios/CLAUDE.md` 過渡例外改寫：Campaign 已搬；新增「`OrdersFeature`、`OrderEditFeature` 跨 Feature 取用 `CampaignService`，`OrdersFeature` 另有一份結單日自動轉狀態寫入，依第 6 步處理」與「`CampaignWritesFeature` 經 `OrderService.renameOrderCampaign` 改寫訂單的開團名稱，依第 6 步處理」。`CampaignService` 沿用 `PersistenceError`，「`XxxPersistenceError` 改為 `<Feature>Error`」的規則不適用 (`persistence-error-contract` 也以它為例)。

### CampaignSummary 搬到 Core/Domain

`CampaignSummary` 與 `CampaignDistributionRow` 只依賴 `LedgerOrder`，被開團、Dashboard、Insights 使用；依 `app-layer-boundaries`「A type used across features that depends on nothing from any feature SHALL live in the shared layer」搬到 `Core/Domain/` (比照 `OrderSummary`)，一檔一型別。`LayerBoundaryTests` 只禁止 Core 引用 Features，搬後不引用任何 Feature 型別。

### 目錄、格式化與命名沿用現行登記

- 開團目錄只新增既有慣例的 `Components/`；各 Feature 與編輯表單不另開資料夾，目錄調整留第 10 步。
- 格式化維持 `CampaignFormatters` 靜態函式，新增的 `sectionTitle` 同樣是靜態函式；`CampaignStatusStyle` 移到自己的檔案。
- View action 以「發生了什麼」命名，沿用既有名稱 (`newCampaignTapped`、`settleTapped` 等)，新增的依同一慣例 (`retryTapped`、`editTapped`、`receiptToggleTapped`)；`CampaignEditFeature` 的 `saveTapped`／`cancelTapped` 改為 `saveButtonTapped`／`cancelButtonTapped`。
- 測試命名用三段式中文 `<方法>_<情境>_<預期>`：A 組 (見 Implementation Contract「檢查分組」) 的測試檔整檔改名；B 組只改本步觸碰的測試方法。

### 畫面元件拆檔

- `CampaignView`：`NavigationStack`、詳情目的地、編輯表單 sheet、alert、`.task`。
- `CampaignListView`：根標題 (`rootNavigationTitle`)、toolbar (篩選選單、新增鍵)、載入狀態切換、`.task`；區段清單抽成 `Components/CampaignSectionList.swift`，開團列移到 `Components/CampaignRow.swift`。
- `CampaignDetailView`：`List` 與 toolbar 選單；資訊、結算、分貨三區段抽成 `Components/CampaignDetailInfoSection.swift`、`CampaignDetailSettlementSection.swift`、`CampaignDetailDistributionSection.swift`。
- 元件以傳入值與 closure 溝通，或接收所屬 Feature 的 store 且只送 `.view(...)`；`ActionGroupingScanTests` 兩種都掃得到。
- `LocalizationCatalogTests` 的開團收款字面檢查改指向實際含 `Text(LocalizedStringKey(order.paymentReceiptStatus.title))` 的元件檔，字面不變；navigationTitle 掃描的 `CampaignListView.swift` 路徑不變。
- 每個 View 與元件不超過 300 行；accessibility identifier、合併朗讀、contextMenu、44pt 點擊範圍逐一保留。
- Preview 與 snapshot 的列表、詳情以等價的 `NavigationStack` 宿主渲染 (含標題與 toolbar)，宿主遷移不重錄基準圖。

### reducer 不 import SwiftUI

`CampaignFeature.swift`、`CampaignFeature+Destination.swift`、`CampaignFeature+Path.swift`、`CampaignListFeature.swift`、`CampaignDetailFeature.swift`、`CampaignWritesFeature.swift`、`CampaignReminderFeature.swift` 與純計算型別只 `import ComposableArchitecture`／`Foundation`。提示文案以字面值 (含插值) 直接寫在 `TextState(...)` 內，失敗以 enum 傳遞，不先組成 `String` 再傳入 (swift-navigation 的 `TextState` 另有會走 verbatim 的 `StringProtocol` 初始化器)。驗證比照第 4 步：以 `nm -u` 加 `swift demangle` 正向確認這些目的檔引用的是 `TextState.init(_: LocalizedStringResource)`，且沒有 `LocalizedStringKey` 與 `StringProtocol` 版本。文案逐字不變，`Localizable.xcstrings` 不新增 key。

### 改動前先錄開團 snapshot 與 UI 測試

開團畫面目前沒有任何 snapshot。task 0.4 在任何 production 改動之前新增 `SnapshotTests+Campaigns.swift` (`extension SnapshotTests`，讓 CI 的 `-skip-testing:BuyLedgerTests/SnapshotTests` 一併排除) 並錄製基準圖，完工後不得重錄 (例外：`campaignEditView_編輯既有開團_符合基準圖` 經使用者 2026-10-04 裁決重錄 (模擬器重開後系統 compact `DatePicker` 的日期格式改變，正式程式碼未動，原基準圖兩個日期欄格式不一致；經過見 task 10.5 補記))：

| 測試 | 內容 |
|---|---|
| `campaignListView_依日分組含今天與昨天_符合基準圖` | 固定現在時間，開團日期為今天、昨天與同年更早 |
| `campaignListView_依月分組_符合基準圖` | 月分組，子標題含今天與昨天 (守本地化修正後中文不變) |
| `campaignListView_依年分組_符合基準圖` | 年分組，列上顯示開團日期 |
| `campaignListView_載入失敗_符合基準圖` | 載入失敗畫面與重試鍵 |
| `campaignDetailView_一般開團含提醒_符合基準圖` | 資訊、結算、分貨與提醒時間 |
| `campaignDetailView_只看未收款_符合基準圖` | 開啟「只看未收款」 |
| `campaignEditView_編輯既有開團_符合基準圖` | 編輯表單含提醒 |

每條包在 `TestDependencies.withFixedNow`，store 用 `EmptyReducer()`，淺色外觀錄製。改動後列表與詳情改用新 Feature 的 State (含 `dateContext` 與共享資料) 建構，宿主維持等價的 `NavigationStack`；只改測試的建構，不改圖。本地化修正落地後 (task 3.2) 另新增 `campaignListView_英文月分組_符合基準圖` (en locale) 守住 Today／Yesterday，這張是修正後才錄的新基準，不屬於改動前基準。

task 0.5 只加測試掛鉤與 identifier (不改行為)，並新增 `BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift` 五條 UI 測試，改動前後都必須綠燈：

| 測試 | seed 與啟動參數 | 斷言 |
|---|---|---|
| `testRetryTapped_每次載入皆失敗_仍顯示失敗畫面與重試鍵` | `campaignsWithOrders`、`-BLUITestLoadFailure campaigns` | 進開團分頁出現載入失敗與重試鍵；點重試後仍顯示載入失敗 (每次讀取都失敗) 且 App 不卡住 |
| `testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示` | `empty`、`-BLUITestCampaignWriteFailure` | 新增「失敗開團」並儲存：表單關閉後出現「操作失敗」alert，訊息含「開團儲存失敗」，關閉後列表沒有該列 (`campaign-write-ordering` delta 範例) |
| `testConfirmDelete_詳情確認刪除_返回列表並移除該列` | `campaignsWithOrders` | 詳情選單刪除、確認後回到列表且該列消失 |
| `testReceiptToggleTapped_未收款訂單切換兩次_已收更新後還原` | `campaignsWithOrders` | 已收 `$11,800` → 點未收款訂單的收款鍵 → `$16,780` → 再點一次 → `$11,800` (應收維持 `$16,780`) |
| `testUnpaidOnlyToggled_返回列表再進詳情_保留開關與篩選` | `campaignsWithOrders` | 開啟「只看未收款」後全部已收款的客戶列消失、未收款客戶仍在；返回列表再進同一詳情，開關仍開啟且篩選仍生效 |

- 「點重試後載入成功」的 UI 測試無法在本步寫：首頁出現時 `OrdersFeature` 會先以同一個 `CampaignService` 讀開團 (Y 留到第 6 步)，只失敗第一次讀取的閘門會被它消耗；重試後重新載入由單元測試守住，成功情境的 UI 測試排第 6 步。重試鍵是否真的送出重試事件，在本步只有單元層級的保證 (見 Risks)。
- 測試支援：`-BLUITestCampaignWriteFailure` (`BLUITestConfiguration.shouldFailCampaignWrites`、`LaunchOptions` 對應旗標，開團的 `saveCampaign`、`removeCampaign` 拋 `PersistenceError.saveFailed`，讀取不受影響；用 `empty` seed 避免載入時的自動轉狀態寫入觸發提示)；`BLAccessibilityID.Campaigns.detailDistributionRow(customerName:)` 與 `detailReceiptToggle(orderID:)`。現有 `campaignsWithOrders` seed 已有已收與未收混合 (應收 `$16,780`、已收 `$11,800`)，不新增 seed。
- `testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示` 等待空狀態或新增入口出現，不使用只等待有資料列表的 `CampaignsScreen.waitUntilReady`。權限的 `restricted` 狀態 harness 無法模擬，由單元測試覆蓋。

### 冷啟動首頁開團卡的實測

疑似缺陷 (程式碼推論)：首頁「進行中開團」卡與 Insights 開團排行的資料只來自開團 Feature，而開團只在列表出現時載入，冷啟動後未進過開團分頁時兩處可能是空的；既有 `InsightsTests.testRevenueAttributionMatchesAcrossViews` 會先繞開團分頁再讀排行。task 0.3 以 `xcodebuildmcp ui-automation` 實測：`campaignsWithOrders` seed 冷啟動停在首頁，`snapshot-ui` 檢查進行中開團卡是否列出 seed 的進行中開團；再切到開團分頁後回首頁重查；Insights 同樣檢查。結果寫在 task 下方並回報，成立就由主對話登記到第 6 步；本步不改任何程式碼、不提交會轉紅的測試。

### 測試拆檔與寫法

- `CampaignFeatureTests` (2,056 行) 依 Feature 與職責拆成 `CampaignFeatureTests` 與其 `+<職責>.swift` (請求處理、導覽與深連結、編輯開啟與重名、表單生命週期與提示、寫入與提醒的整合、寫入失敗後重新載入)、`CampaignListFeatureTests` (載入與自動轉狀態、重試、篩選與分組、日期區段與現在時間)、`CampaignDetailFeatureTests` (詳情內容、只看未收款、請求與收款切換)、`CampaignWritesFeatureTests` (四種寫入的成功、失敗與只套用單一欄位)；每檔不超過 300 行。五條「寫入失敗後重新載入」的複合測試保留情境，以 `CampaignFeature` 的 store 走「列表／詳情請求 → 容器確認 → 寫入子 Feature → 重新載入」的完整流程，不改成只測單一子 Feature。兩條放錯檔的 `CampaignEditFeature` binding 測試移到 `CampaignEditFeatureTests`。
- `CampaignReminderFailureTests` 的 11 條去向：權限三條 (拒絕、受限、無可寫入行事曆)、建立失敗三條 (事件寫入失敗、無識別碼、連結寫入失敗)、移除與重建順序四條 → `CampaignReminderFeatureTests` 直接測子 Feature；`noticeAlert_點選開啟設定_開啟系統設定` → `CampaignFeatureTests` (容器 alert 的「前往設定」呼叫 `openSettingsService`)。
- `CampaignFeatureTests` 既有的正向提醒測試 (`reminderLinksLoaded`、新增時建立、清除時移除、改名重建、時間重建) 的日期、提示位移、標題、連結與呼叫順序斷言保留：流程本身移到 `CampaignReminderFeatureTests`，`CampaignFeature` 另以三條整合測試確認「儲存成功後轉送的 `CampaignReminderRequest` 內容正確 (建立與重建參數化)」「子層 `failed` 依表單生命週期呈現」「刪除成功後轉送 `campaignRemoved` 帶事件 id」。
- 新增 `CampaignDateSectionBuilderTests`：日、月、年分組與子群組、狀態篩選、`openDate` 完全相同時依名稱排序 (名稱倒序變異以完全相同的時間戳輸入)、同一天不同時間仍依時間、UTC 與 UTC+8 分桶不同；`CampaignFormatters.sectionTitle` 在 zh-Hant 下相對日期回傳「今天」「昨天」key、同年為月日星期、跨年為年月日 (`campaign-management` delta 範例的數值，預期值寫成字面，先在測試模擬器以現行 `OrderFormatters.daySectionTitle` 的實際輸出確認格式，例如「5月8日週五」)。英文 Today／Yesterday 由畫面層的英文月分組 snapshot 守住，不在 formatter 層斷言。
- 新增 `CampaignDetailContentTests`、`CampaignReminderReconcileTests` (含預設提醒時間)、`CampaignSavePlanTests` (組裝與重名判斷)、`CampaignPresentationQueueTests`。
- 新增 reducer 測試：列表 `view(.task)` 在已載入時仍更新 `dateContext`、`retryTapped` 重新載入、篩選與分組切換、`campaignTapped` 送出 `requested(.showDetail)`；詳情 `receiptToggleTapped` 兩個方向與找不到訂單、`unpaidOnlyToggled` 寫入共用值、其餘操作送出對應 `requested`；`CampaignFeature` 的 `showDetail` 建立正確的詳情 State、深連結與列表點擊得到相同堆疊、詳情 A 顯示中深連結換成 B、刪除時移除對應詳情。
- `CampaignIntegrationTests` 與 `RootFeatureTests` 的開團測試 (改名、刪除、載入、兩條深連結、收款切換與 `setOrdersAndProjections`) 改經開團的 `view` 與 Service 替身走完整流程，斷言 `RootFeature` 收到 delegate 後的訂單副本與投影；`OrdersFeatureTests` 的同名 `.campaignsLoaded` 屬 `OrdersFeature`，不得改到。
- A 組測試檔：三段式中文命名、`///`、Given／When／Then、case key path `receive`、完整狀態斷言、替身用 `LockIsolated`，整檔適用；B 組 (見 Implementation Contract「檢查分組」；2026-10-03 起 `RootFeatureTests` 改列 A 組) 只對本步觸碰的測試方法適用。輸入要能分辨正確與錯誤實作 (`test-guard-effectiveness`)。

### 守門涵蓋開團的 View、withLock 與投影

- `ActionGroupingScanTests.migratedViewPaths` 加 `Features/Campaigns/CampaignView.swift`、`CampaignListView.swift`、`CampaignDetailView.swift`、`CampaignEditView.swift`；`migratedComponentDirectories` 加 `Features/Campaigns/Components` (目錄建立後才加)；不新增 allowlist。
- `ProjectionWriteBoundaryTests`：
  - 新增規則：`$orders.withLock` 只能出現在 `RootFeature.swift` (不論前綴與所在型別，包含 `state.campaigns.$orders.withLock` 這類完整路徑與以值傳入 `CampaignFeature.State` 的外部 helper)。
  - 新增規則：`Features/Campaigns/` 內投影的可寫引用 `$orders` 只能作為 `SharedReader(` 的引數出現，不得以 `Shared` 傳出。
  - 自我測試情境補上：外部 helper 以值接收 State 後 `state.$orders.withLock`、完整路徑寫入、把 `$orders` 當 `Shared` 傳給子層，三者都要被判為違規；`RootFeature.swift` 內的同步寫入判為合法。
- 變異驗證：在開團 View 暫加非 `.view` 送出、在 `CampaignFeature` 暫加 `.edit(.view(` 比對、在 `CampaignFeature` 暫加 `state.$orders.withLock`、在 `CampaignFeature.core` 暫加可編譯的引用外傳 `let leakedOrders = state.$orders`，各自讓對應規則轉紅。

### B 組整檔合規

原 B 組 13 檔加 `CampaignsScreen.swift`、`CampaignEditScreen.swift` 改依 A 組整檔標準修正 (4.12)。只為接線而改的大型既有檔 `OrdersFeature.swift`、`SnapshotTests+Lookups.swift` (整檔 28 筆) 維持只查 diff (D17)；`LayerBoundaryTests.swift` (540 行、整檔 91 筆) 原列 D17，後經使用者 2026-10-03 裁決本步整檔合規並拆檔 (比照 `ProjectionWriteBoundaryTests`)。`ContrastComplianceTests.swift` 除了配合 `SidebarSmartGroup` 改名，經使用者 2026-10-03 裁決本步整檔合規 (整檔標準下 101 筆，2026-10-03 實測；task 8.9)。

| 檔案 (不含檔頭與空行的行數，實測) | 做法 |
|---|---|
| `BLAccessibilityID.swift` (612) | 依 `<Name>+<Domain>.swift` 拆成主檔 (`enum BLAccessibilityID {}` 與共用的 `option`／`row`／`indexed`) 加 `+Common` (`Common`、`OptionPicker`)、`+App` (`PersistenceFailure`、`AppLock`、`Root`)、`+Dashboard`、`+Orders` (`Orders`、`OrderEdit`、`OrderMerge`、`PhotoViewer`、`AISummary`)、`+Campaigns` (`Campaigns`、`CampaignEdit`)、`+Insights`、`+More` (`More`、`Customers`、`Fx`、`Quote`、`Settings`、`LookupManagement`)；每個 `+` 檔只有一個 `// MARK: - Nested Types` extension，巢狀名稱與呼叫端不變 |
| `BLUITestConfiguration.swift` | 5 個列舉各一檔 (`BLUITestLanguage`、`BLUITestCalendarAccess`、`BLUITestBiometricScenario`、`BLUITestLoadFailure`、`BLUITestPersistenceMode`，比照 `BLUITestLoadSource.swift` 的形狀)；主檔修 `DOCBL`、`DateComponents(` 斷行等機械項；`guard` 的 else 先 `warn(...)` 再 `return` 依 4.7 保留 |
| `BLUITestDependencyOverrides.swift` | 以 `git mv` 改名 `DependencyValues+BLUITestOverrides.swift` (formatting.md 外部型別擴充的檔名)，同步 `.claude/rules/ios-ui-tests.md` 的引用 (4.10) |
| `BLUITestConfigurationTests.swift` | 整檔去掉 `#if DEBUG` 內的 4 格縮排 (比照 kit 範本)、三段式命名、`///`、Given／When／Then；一條測試含多個 When 的改 `@Test(arguments:)`；無效值、重複旗標與缺值的退回拆到 `+InvalidValues.swift` |
| `LaunchOptions.swift` | 本體只留 `// MARK: - Properties` (`static let default` 在前)，`launchArguments` 移到 `Nested Types` 之後的 `// MARK: - Computed Properties` extension |
| `CampaignDetailScreen.swift` (378) | 主檔只放宣告、`app` 與 `rootIdentifier`；`+Content.swift` 放結團膠囊、結算、已收金額、分貨列、展開、收款切換、只看未收款與它們共用的 reveal helper；`+Toolbar.swift` 放更多選單、編輯／結團／刪除、兩組確認 alert 與返回 |
| `CampaignsScreen.swift`、`CampaignEditScreen.swift` | 整檔修 MARK 段名、本體的 computed property 與 `CALL1` (各 6 筆，實測) |
| `RootSidebarLayout.swift` (344) | `SmartGroup` 抽成頂層 `SidebarSmartGroup.swift` (本體放 case 與 `orderBrowsingCases`，另有 `Computed Properties`、`Internal Method`、`Identifiable` 分區)；`SidebarSelection` 留在 `Nested Types`；`selectionBinding` 改多重 trailing closure 多行；`currentSelection` 的 `if case .status(let status) = …` 移到第一個條件 (同時消除腳本把逗號結尾的條件誤判為多 pattern 的 44 筆 `CASECONT`)；移除 `navRow` 未使用的 `palette` 參數。列 View 不抽出：抽出的列若宣告根 store 會違反宿主白名單，`LocalizationCatalogTests` 也以本檔路徑檢查智慧分組列的朗讀字串 |
| `ActionGroupingScanTests.swift` | 五條測試改三段式中文名、補 `///`；`// Given: 說明` 統一為單獨的 `// Given`，說明移到 `///` (4.11) |
| `RootFeatureTests.swift` (1,603) | 先純搬移成主檔加 `+OrderFilters`、`+PaymentMethodCorrection`、`+LookupRename`、`+LookupSync`、`+Campaigns`、`+DeepLinks`、`+Fixtures` (跨檔共用 helper 放 `+Fixtures` 的 `// MARK: - Internal Method`，只被單一檔使用的維持 private)，條數與通過數不變；之後才隨殼層改寫 (見「殼層守門、測試與文件同步」) |
| `ProjectionWriteBoundaryTests.swift` (656) | 拆主檔加 `+Scanner`、`+Patterns`、`+SourceStripping`；`try! NSRegularExpression` 改 typed throws 一路傳到呼叫端 (鐵則只允許 IBOutlet 與字面值 `static let` 的強制解包)；舊式命名改三段式；`SharedOrderScenario` 改 internal |
| `LocalizationCatalogTests.swift` (940) | 拆主檔加 `+AppLanguage`、`+SourceGuards`、`+LiteralScan` 與外部型別擴充 `String+SourceLiteralScan.swift` (一般區名)、自有掃描型別 `SourceTextScanner.swift` (以 `Array(source.utf16)` 走訪，取代原 `NSString` 擴充，另補 `SourceTextScannerTests.swift`；原 `Array` 受限擴充的兩個方法改為 `String`／`String.SourceLineRange` 的 static 方法，4.8 更正)；第一條測試拆成 5 條 (程式字面值都已收錄、已驗收英文值、中文來源不得與英文相同、每個需翻譯條目中英文非空、`sourceLanguage` 為 `zh-Hant`)；`documentedEnglishValues` 改參數化，每組 key 一個案例 (單元總數預估增加約 30，以實測為準)；12 個條件的 `guard` 抽成回傳 `Bool` 的 private helper；寫死的原始檔路徑不變 |

- 檢查腳本 `reference/style_checks.py` 同步：`B_GROUP` 改為上述 3 檔；`EXISTING_OVER_LIMIT` 移除 `RootFeature.swift`、`RootFeatureTests.swift`、`BLUITestDependencyOverrides.swift`、`SettingsFeatureTests.swift`；`GUARDX` 放寬為允許 else 內「一個警告或 log 呼叫後接單一 return／throw」(4.7)；外部型別的綜合擴充檔 (`<Type>+Extensions.swift`，`Type` 為 `Array`、`String`、`NSString`、`Dictionary`、`Set`、`DependencyValues`) 允許以功能命名的 MARK 段名；拆成 `<Type>+<Feature>.swift` 後一檔一個關注點，用一般區名 (4.8 依 formatting.md「為非自己的型別加功能」更正)；B 組只查 diff 時忽略純空白變動 (拿掉 `#if` 包裝造成的整檔減少縮排不算改動)。放寬只認這些形狀，其他寫法照舊判違規。
- `findings.md`：腳本更新後先整檔掃描本次擴大範圍的既有檔 (原 B 組 15 檔與殼層會改寫的既有檔)，逐筆寫入、結論待填；各 task 修完填結論，刪除或改名的檔寫明落在哪個新檔。
- 新的同域輔助型別 (`RootNavigationOperations`、`RootCascadeOperations`、`SidebarSmartGroup`) 不另寫單元測試，行為由 `RootFeatureTests` 的深連結與 cascade 測試涵蓋，以變異驗證確認會轉紅 (4.13)。
- 2026-10-03 的兩條現行規則適用於本次所有新增與改寫：TCA `State` 本體順序 stored → 非 private computed → init → nested types → 方法；多重 trailing closure 一律多行 (`Binding {` / 本體 / `} set: {` / 本體 / `}`)。
- 拆出的新檔放進既有資料夾即自動編入對應 target：`BuyLedger`、`BuyLedgerTests`、`BuyLedgerUITests`、`BuyLedgerAccessibilityIDs` 都是 `PBXFileSystemSynchronizedRootGroup` (`BuyLedgerAccessibilityIDs` 同時編入 App 與 UITests，唯一的 exception set 只排除 `Resources/` 的設定檔)，不改 `project.pbxproj`。

替代方案：B 組維持只查 diff (使用者放棄)；`RootFeature` 只外移 `MoreRoute` 與兩個輔助型別 (方案 A，草稿實算約 295 行、結構性違規仍留第 8 步，由「Root 導覽操作與 Action 分組」取代)；`Private Method` 整段移到 `RootFeature+Core.swift` (等於以跨檔 extension 規避 300 行上限，formatting.md 不放寬上限)；`BLUITestDependencyOverrides.swift` 不改名 (使用者選照 kit)；`GUARDX` 改寫成 `if` 區塊 (使用者裁定原寫法不算違規)。

### Root 導覽操作與 Action 分組

**Supersedes**: campaigns-style-compliance / 改名、刪除與收款切換經 delegate 通知 RootFeature

**Supersedes**: campaigns-style-compliance / 詳情以 StackState 推入，列表點擊與深連結共用同一入口

(兩者只被取代「Root 以根層 action `campaignSelected(name)` 切到開團分頁並呼叫 `showDetail`」這一點：根層 `campaignSelected` 移除，深連結改由 `RootNavigationOperations.showCampaign(named:state:)` 呼叫同一個 `CampaignFeature.State.showDetail(campaignID:)`；三個開團 delegate、訂單副本改寫行為與 `showDetail` 單一入口都不變，改寫主體移到 `RootCascadeOperations`)

`RootFeature` 依 tca-architecture.md 的 Action 分組與 TCA `Performance.md`「以方法共用邏輯，不送多餘 action」改寫，主檔目標不超過 300 行。

- **State** (stored → init)：`@Presents var persistenceFailure`、`selectedTab`、`preferences: SettingsSnapshot`、`appLock: AppLockFeature.State`、`orders`、`campaigns`、`dashboard`、`insights`、`more: MoreFeature.State`；`init(persistenceStatus:preferences:appVersion:)`，參數沿用現行做法提供預設值，既有的 `RootFeature.State()` 呼叫端 (production 與測試合計 34 處，2026-10-03 grep 實測) 不必為此改寫。`customers`／`fx`／`quote`／`settings`／`lookupManagements`／`morePath` 改由 `MoreFeature` 承接 (9.3 完成，之前的過渡見 Migration Plan)。
- **Action** (`view` → 導覽 → 其他依字母)：`view(View)` 只有 `task`、`tabSelected(RootTab)`、`sidebarTabSelected(RootTab)`、`smartGroupSelected(OrderStatus)` (送出者只有 `RootView`／`RootTabLayout`／`RootSidebarLayout`)；沒有 `delegate` (沒有父層)；導覽槽 `persistenceFailure(PresentationAction<…>)` (D14)；子層 `appLock`、`campaigns`、`dashboard`、`insights`、`more`、`orders`；內部 action `significantTimeChanged` (見「scenePhase、回到前景與跨日」)。刪除 `binding` (`BindableAction`／`BindingReducer`；分頁改 `$store.selectedTab.sending(\.view.tabSelected)`) 與 `startNewOrder`／`customerSelected`／`categorySelected`／`campaignSelected`。
- **Body**：`CombineReducers { Scope(appLock) Scope(orders) Scope(campaigns) Scope(dashboard) Scope(insights) Scope(more) Reduce(core).ifLet(\.$persistenceFailure) }` 後接投影的 `onChange`；`.ifLet` 接在 `Reduce(core)` 之後 (kit 組合順序)；`CombineReducers` 保留，`///` 寫明「尾端 `onChange` 要看到子層造成的變更才能同步投影」(4.4)。投影：`\.orders.orders` (開團與 More 以 `withLock`、總覽、分析)、`\.campaigns.campaigns`、`\.orders.loadState`、`\.preferences` (`appLock.isBiometricUnlockEnabled`、`dashboard.monthlyProfitGoalTwd`、`more.preferences`)、`\.appLock.biometryType` (`more.biometryType`)。
- **`RootNavigationOperations`** (新檔，struct，D11)：stored `referenceDate: Date`、`calendar: Calendar`，由 Root 以 private computed property 從注入的 `date.now`、`calendar` 建立 (輔助型別不宣告 `@Dependency`、不呼叫 `Date()`)；方法 `showOrders(status:state:)`、`showOrders(customer:state:)`、`showOrders(category:state:)`、`showCampaign(named:state:)`，參數 `state: inout RootFeature.State`；保留「客戶深連結清除殘留類別篩選」「類別用精準篩選避免搜尋誤中」的註解。選 struct 是因為 D10 加入監聽後，enum 形式 (每次呼叫多傳時間與行事曆兩個參數) 估計會讓 Root 超過 300 行；`apps/ios/CLAUDE.md` 的拆分規則補「持有 reducer 解析後的時間與行事曆值的 struct」這個情境。
- **`RootCascadeOperations`** (新檔，無 case enum)：`campaignDeleted(_:in:)`、`campaignRenamed(from:to:in:)`、`lookupItemRenamed(_:kind:in:)`，參數 `in orders: inout [LedgerOrder]` (不傳整個 Root State)；去空白與「兩端非空且不同」的判斷放 `Private Method`。
- **根層導覽改寫** (每列都在同一次狀態更新內完成)：

| 原 action | 觸發來源 | 改寫後 |
|---|---|---|
| `tabSelected` | iPhone 分頁列 | `.view(.tabSelected(tab))`：只改 `selectedTab`，保留「更多」堆疊 |
| `sidebarTabSelected` | iPad 側邊欄分頁列 | `.view(.sidebarTabSelected(tab))`：先 `state.more.popToRoot()` 再改 `selectedTab` |
| `smartGroupSelected` | iPad 側邊欄智慧分組 | `.view(.smartGroupSelected(status))`：`popToRoot()` 後 `showOrders(status:state:)` |
| `customerSelected` | 「更多」堆疊內的客戶頁 | `CustomersFeature.delegate(.customerSelected)` → `MoreFeature` 先清空自己的 path 再送 `.delegate(.customerSelected)` → Root `showOrders(customer:state:)`；切分頁時路徑已空 |
| `categorySelected` | 分析頁類別長條 | `.insights(.delegate(.categoryTapped))` → `showOrders(category:state:)`；不清「更多」堆疊 (iPad 在分析頁時堆疊必為空，iPhone 維持保留) |
| `campaignSelected` | 總覽開團卡、分析開團排行 | `.dashboard`／`.insights(.delegate(.campaignTapped))` → `showCampaign(named:state:)` → `state.campaigns.showDetail(campaignID:)` |
| `startNewOrder` | 總覽「新增訂單」 | `.dashboard(.delegate(.newOrderTapped))` 內同一次更新設 `selectedTab = .orders` 與空白 `orders.editOrder` (需要 `uuid()`，留在 `core`；從其他分頁直接設 sheet 時 `OrdersView` 不在階層的理由保留) |
| `viewAllOrdersTapped` 的轉送 | 總覽「檢視全部訂單」 | 直接 `selectedTab = .orders`，不再 `.send(.tabSelected)` |
| AI 未開啟提示「前往開啟」 | 訂單頁 alert | `OrdersFeature` 改送 `.delegate(.aiSettingsRequested)` → Root `selectedTab = .more` 並 `state.more.showSettings()` |

- **iPad `NavigationSplitView` 路徑雷**：Root 主動切離「更多」的兩個 view action (`sidebarTabSelected`、`smartGroupSelected`) 一律先 `popToRoot()`；從「更多」堆疊內交出的跨分頁意圖 (目前只有客戶) 由 `MoreFeature` 先清自己的 path 再送 delegate。新增會切離「更多」的推入點都要走這兩條之一，寫進 `.claude/rules/ios-navigation.md`。
- **父層攔截清單** (4.4)：刪除 Root `task` 送 `.settings(.appLock(.appDidBecomeActive))` (改由 `scenePhase` 的 `initial: true`)；`.orders(.aiDisabledAlert(.presented(.goToAISettings)))` 改比對 `.orders(.delegate(.aiSettingsRequested))`；`.customers`／`.lookupManagements` 的 delegate 改由 `MoreFeature` 轉送、Root 只比對 `.more(.delegate(…))`；`dashboard`／`insights` 的委派改呼叫導覽操作、不再以 `.send(.campaignSelected)` 等轉發；`SettingsFeature` 攔截 `.appLock(...)` 與 `SettingsView` 送 `.appLock(.enableToggled(...))` 由「偏好與 App 鎖定分工」消除。`OrdersFeature` 的改動只有新增 `delegate(.aiSettingsRequested)`、`goToAISettings` 改送它與兩處分段 `Reduce` 的明列 case 補 `.delegate` (B 組只查 diff)。Root 送進 Orders 的 `.orders(.task)`、`.orders(.receiptStatusChanged)`、`.orders(.paymentMethodFlagsApplied)` 是送出不是攔截，留第 6 步 (Non-Goals)。
- **`ProjectionWriteBoundaryTests` 第三條規則** (4.3)：`RootFeature.swift` 以外不得寫 `state.<Root 子層 key>.<該擁有者的投影屬性>` (賦值與變異方法)，對照表由 `projectionOwners` 加 Root State key 推出：`dashboard`、`insights` 各自的投影、`appLock.isBiometricUnlockEnabled`、`more.preferences`／`more.biometryType`；`campaigns.campaigns` 與 `orders.*` 不是投影，不得誤判。自我測試：`Features/App/RootNavigationOperations.swift` 寫 `state.dashboard.orders = []` 判 1 筆、寫 `state.campaigns.campaigns = []` 判 0 筆、寫 `state.more.preferences = .default` 判 1 筆 (`MoreFeature` 存在後加入)；`Features/App/RootCascadeOperations.swift` 出現 `$orders.withLock` 判 1 筆。`rootFeatureRelativePath` 不變 (`onChange` 與 `withLock` 都留在 `RootFeature.swift`)。
- **行數** (估計，方案以同一算法對草稿實算)：enum 形式約 287 行；struct 形式約 276 行，加跨日監聽約 14 行後約 290 行。9.1、9.2 完成時 Root 仍持有常駐子層，會暫時超過 300；9.3 與 9.4 結束時量測，超過 300 就停下回報，不自行再抽結構 (下一層備案是把 `dashboard`／`insights` 相同的 `refresh` 與 `campaignTapped` 轉送各併成一個多 pattern case，代價是偏離「case 順序與 Action 一致」，需使用者同意)。
- **`Features/App` 其餘檔** (D13)：`PersistenceFailureFeature` 的 Action 改為 `view(.recoveryTapped)`、`destination` (取代 `confirmation`)、單一 `recoveryResponse` (取代 `recoverySucceeded`／`recoveryFailed`)，`body` 改 `Reduce(core)`；`PersistenceFailureView`、`RootTab`、`SidebarBadgeCounts`、`AppLockView`、`RootView` 修 MARK 分區與機械項，第 8 步的殼層因此在本步整步結案。

替代方案：方案 A (見「B 組整檔合規」)；enum 形式的導覽輔助型別 (D11 原建議，D10 採用監聽後改 struct)；`RootFeature` 改名 `AppFeature` (D16：其他模組根也都未用 `<Feature>RootFeature`，單獨改殼層反而不一致，留第 10 步)；以 `@Presents var destination` 承載持久化失敗 (D14：kit 的 Destination 規則針對 sheet／alert，這是替換整個內容的阻斷畫面，且 Root 只有這一個呈現)。

### 偏好與 App 鎖定分工

- **偏好的唯一記憶體來源是 `RootFeature.State.preferences`** (D5)：語言要給 `RootView` 設 `\.locale`、月目標要投影到總覽、鎖定啟用要投影到 `AppLockFeature`，三者都在殼層。`BuyLedgerApp` 讀一次 `settingsService.load()` 直接傳入 `RootFeature.State(persistenceStatus:preferences:appVersion:)`；init 同時設 `appLock` (`isBiometricUnlockEnabled` 與冷啟動的 `isLocked`)、`dashboard.monthlyProfitGoalTwd` (D12，修冷啟動首頁顯示預設 80,000) 與 `more.preferences` (投影只由 Root 寫)。
- **設定頁仍是持久層唯一寫入者** (`app-settings`)：每次寫入後送 `.delegate(.preferencesChanged(snapshot))`，`MoreFeature` 原樣轉送，Root 更新 `preferences`，`onChange(of: \.preferences)` 再同步三份投影。不用 `@Shared` 共用偏好 (kit：能用 delegate 回傳就不用 `@Shared`，並避免跨 Feature 模組共享)。語言由 `RootView` 讀 `store.preferences.language` 設 locale，並以建構參數傳給兩種 layout 與 `MoreView`。9.2 完成時設定仍是 Root 的常駐子層，委派由 Root 直接處理；9.3 起改經 `MoreFeature` 轉送。
- **App 鎖定拆分** (D6，L1)：`AppLockFeature` 只負責「離開前景上鎖、回到前景或冷啟動驗證解鎖」，上移為 Root 的常駐子層；啟用前的驗證移入 `SettingsFeature`。理由：開關與失敗說明在設定頁 (iPad 中掛在堆疊外層的 alert 蓋不到推入頁)，鎖定狀態必須常駐殼層，兩者生命週期不同。
    - `AppLockFeature`：State `isBiometricUnlockEnabled` (Root 寫的投影)、`isLocked`、`unlockDidFail`、`isUnlocking`、`biometryType`；Action `view(.retryUnlockTapped／.scenePhaseChanged(AppScenePhase))`、`delegate(.didBecomeActive)`、`unlockResponse(BiometricAuthService.AuthenticationResult)`；`body` 為 `Reduce(core)`；刪除啟用流程、`enableFailureAlert` 與 `import SwiftUI`。
    - `SettingsFeature`：State 刪 `appLock`，新增 `isBiometricUnlockEnabled`、`let biometryType` (建構時帶入，首幀即正確命名 Face ID 或 Touch ID)、`@Presents var destination` 與非 private computed `snapshot` (寫入與委派共用)；`init(snapshot:appVersion:biometryType:)`；Action `view` 加 `appLockToggled(Bool)`，新增 `delegate(.preferencesChanged(SettingsSnapshot))`、`destination(PresentationAction<Destination.Action>)`、`appLockAuthenticationResponse(BiometricAuthService.AuthenticationResult)`，刪除 `appLock` 與其 `Scope`；依賴加 `biometricAuthService`。
    - 「啟用前先驗證一次」原樣搬移：`appLockToggled(true)` 時 `isAvailable()` 為假直接顯示裝置不支援的 alert；否則驗證，`.success` 才設 `isBiometricUnlockEnabled = true`、寫入並送委派，`.failure`／`.cancelled` 只顯示 alert，開關因自訂 binding (get 讀已生效的值) 自動彈回。`appLockToggled(false)` 直接設 false、寫入並送委派。關閉只可能在已解鎖、設定頁可見時發生，`isLocked`／`unlockDidFail` 必為 false，不另清 (由單元測試斷言這個前提)。
    - `SettingsFeature+Destination.swift` (新檔)：`@Reducer enum Destination { case alert(AlertState<Alert>) }` 與 `extension SettingsFeature.Destination.State` 的兩個 alert 建構方法 (字面值逐字搬自 `AppLockFeature`) 與 `Equatable`。
    - `SettingsView` 的開關 binding 改送 `.view(.appLockToggled($0))` (多重 trailing closure 多行)，alert 綁 `$store.scope(state: \.destination?.alert, action: \.destination.alert)`；`ActionGroupingScanTests` 的唯一 allowlist 因此移除。
- **`BiometricAuthService` 搬到 `Core/Dependencies/`** (D6)：取用者變成 `AppLockFeature` 與 `SettingsFeature` 兩個 Feature，不再是殼層專屬 (`apps/ios/CLAUDE.md`：Feature 專屬 Service 才放該 Feature 的 `Data/`)。以 `git mv` 搬三檔，型別、巢狀型別 (`AuthenticationResult`、`BiometryKind`) 與 key path 不變；它只依賴 `LocalAuthentication`，不引用 Feature 型別 (`LayerBoundaryTests` 守門)。不列過渡例外。
- **`AppLockFormatters`** (新檔，無 case enum，D7)：`unlockTitle(for:)`、`protectionDescription(for:)` 回傳 `LocalizedStringKey`，字面值原樣搬自 `AppLockFeature.State` 的兩個 computed property；讓 `AppLockFeature`、`SettingsFeature` 兩個 reducer 不 import SwiftUI (比照開團「reducer 不 import SwiftUI」)，`AppLockView` 與 `SettingsView` 呼叫它。

替代方案：設定常駐「更多」、Root 讀 `more.settings.language`；Root 與設定以無鍵 `@Shared` 共用偏好；L2 (啟用流程留 `AppLockFeature`、設定頁經 Root 轉送：父層要送子層非 delegate action、alert 掛不到推入的設定頁、存檔權不在設定頁，違反單一寫入者)；`BiometricAuthService` 留在 `Features/App/Data/` 並列過渡例外 (使用者選現在搬)；兩個 State 各自保留文案 computed property (設定頁要 import SwiftUI，且同一 switch 重複兩份)。

### App 殼層：MoreFeature 與 StackState

- **結構** (D1，M2)：`MoreFeature` 是 Root 以 `Scope` 組合的常駐子層，持有 `StackState<Path.State>`，依 kit「Stack：根畫面的 Path」(`@Reducer enum Path`、`case path(StackActionOf<Path>)`、`.forEach`、`NavigationStack(path:)` 只寫在該模組根 View)。
- **State** (stored → init → 方法)：`var path = StackState<Path.State>()`；`@Shared var orders: [LedgerOrder]` (客戶頁的訂單投影來源，只由 Root 以 `withLock` 寫入；推入客戶頁時以 `SharedReader(state.$orders)` 傳入，比照開團詳情)；`var preferences: SettingsSnapshot = .default`、`var biometryType: BiometricAuthService.BiometryKind = .unavailable` (建立設定頁 State 用的投影，只由 Root 寫；宣告處給預設值、init 不寫，避免 `ProjectionWriteBoundaryTests` 把 init 判為寫入)；`let appVersion: String` (外部注入、不給宣告處預設值)；`init(appVersion:)` 以 `Shared(value: [])` 建立訂單來源；`mutating func showSettings()` (同一次更新內 `path.removeAll()` 再推入設定，列點擊與 AI 深連結共用；navigation-path-integrity「單一路徑、先清空再推入」)；`mutating func popToRoot()`。
- **Action**：`view(.entryTapped(Entry))`；`delegate`：`ordersLoadRequested`、`customerSelected(String)`、`lookupItemRenamed(kind: LookupKind, rename: LookupItemRename)`、`paymentMethodEdited(PaymentMethodEditPlan)`、`preferencesChanged(SettingsSnapshot)`；`path(StackActionOf<Path>)`。`body`：`Reduce(core).forEach(\.path, action: \.path)`。
- **Nested Types**：`@Reducer enum Path { customers(CustomersFeature)、fx(FxFeature)、lookupManagement(LookupManagementFeature)、quote(QuoteFeature)、settings(SettingsFeature) }`；`enum Entry` (取代 `RootFeature.MoreRoute`，8 個 case，順序與 `BLAccessibilityID.More.Row` 一致)；`// MARK: - Equatable` 的 `extension MoreFeature.Path.State: Equatable {}`。
- **`core`**：`entryTapped` 依 Entry 推入對應 State (設定走 `showSettings()`，以 `preferences`、`appVersion`、`biometryType` 建立；四種主檔都推 `.lookupManagement(LookupManagementFeature.State(kind:))`)；客戶頁 `ordersLoadRequested` 原樣轉送；客戶頁 `customerSelected` **先 `state.path.removeAll()` 再**轉送 (kit 動詞對應 finish：清空 path 再向父層送 delegate；iPad 切分頁前路徑必須為空)；主檔頁 `itemRenamed` 以 `state.path[id:case:]` 取種類後送 `lookupItemRenamed(kind:rename:)` (不改 `LookupManagementFeature` 的 delegate 形狀)；`paymentMethodEdited`、設定頁 `preferencesChanged` 原樣轉送。
- **定位** (D2)：`MoreFeature` 沒有自己的領域資料，是 App 殼層的分頁宿主 (現行 `MoreView` 也因此列在根導覽宿主白名單)；它的 `Path` 引用其他 Feature 模組的 Feature 型別，視為 kit「跨 Feature 模組導航只在 App 層」的殼層例外，`apps/ios/CLAUDE.md` 記為專案差異；目錄維持 `Features/More/`，調整留第 10 步。
- **五個目的地都放 `Path`，返回即釋放** (D3a 至 D3d，與現行常駐的差異見 Implementation Contract「行為」)：匯率工具與報價試算每次進入重設輸入 (報價每次進入多打一次匯率 API)，同時消除「載入中返回後永久載入中」的推論缺陷 (現行 `.finish()` 綁 View 生命週期，取消後 `isLoading` 停在 `true`，`guard !state.isLoading` 擋住之後的載入與重試；UI 測試替身瞬間回應，未實測)；主檔管理每次進入重讀，返回時 TCA 取消該元素所有 effect (`StackReducer` 移除元素時自動取消子 effect)；設定實質不變；客戶頁以 `SharedReader` 讀投影 (D21，TCA `SharingState.md` 的堆疊元素共享寫法)，推入當下就有資料、停在頁面上時隨訂單更新。「更多」堆疊本身常駐：iPhone 切分頁保留、iPad 側邊欄與深連結先清空，與現行相同。
- **`MoreView`**：`@Bindable var store: StoreOf<MoreFeature>` 與 `let language: AppLanguage`；`NavigationStack(path: $store.scope(state: \.path, action: \.path)) { … } destination: { switch store.case … }`；列改為 `Button` 送 `.view(.entryTapped(entry))`，尾端加 SF Symbol `chevron.right` (`accessibilityHidden`，符合 assistive-announcement-hygiene「列按鈕的尾端箭頭不朗讀」)，**保留 List 預設按鈕樣式讓系統提供列按壓高亮，只把文字色改回主色，不用 `.buttonStyle(.plain)`** (D4)；accessibility identifier 不變；刪除 `lookupManagementDestination` 的 `ContentUnavailableView` 備援 (Path 元素自帶 State，不會找不到 store) 與其 snapshot、基準圖，並從 `Localizable.xcstrings` 移除「無法載入主檔管理頁面，請稍後再試。」(D18：程式已無使用處，留著是死翻譯，Xcode build 也會把它標成 stale)。不用 `NavigationLink(state:)`：kit 避免在 View 內直接以它跳到其他 Feature 模組。
- **`CustomersFeature`**：`orders` 改 `@SharedReader var orders: [LedgerOrder]`，`init(orders: SharedReader<[LedgerOrder]>)`；`CustomersView` 只改 Preview 的建構。
- **守門**：`LayerBoundaryTests` 的根 store 宿主白名單由四個改為三個 (刪 `MoreView`)；`ActionGroupingScanTests.migratedViewPaths` 加 `RootView`、`RootTabLayout`、`RootSidebarLayout`、`AppLockView`、`MoreView` (`PersistenceFailureView` 於 D13 整理後加入)。
- **Root 側**：`RootTabLayout` 與 `RootSidebarLayout` 以 `MoreView(store: store.scope(state: \.more, action: \.more), language:)` 呈現「更多」；`onChange(of: \.orders.orders)` 加 `more.$orders.withLock`。

替代方案：M1 (Root 直接持有 `StackState`，資料流較短但 Root 估計約 320 行)；匯率、報價、主檔、設定常駐 (以無 payload 的 Path case 指向常駐 State，非 TCA 典型寫法)；`NavigationLink(state:)`；Root 的 `onChange` 逐一改寫堆疊內的客戶頁元素。

### scenePhase、回到前景與跨日

**Supersedes**: campaigns-style-compliance / 現在時間由 reducer 寫進 State

(只取代其中的已知行為差異「列表停在畫面上跨午夜要等 `.task` 再執行才更新、第 8 步補回到前景更新」，以及 Non-Goal「不處理 scenePhase (第 8 步)」；`dateContext` 由 reducer 寫進 State、畫面不宣告 `@Dependency` 的決策不變)

- **接線** (D8、D15)：刪除 `AppScenePhaseCoordinator` 與其測試。`BuyLedgerApp.body` 改為 `.onChange(of: scenePhase, initial: true)`，把 `SwiftUI.ScenePhase` 經 `AppScenePhase(_:)` 轉成自訂列舉，送 `store.scope(state: \.appLock, action: \.appLock)` 的 `.view(.scenePhaseChanged(...))`；上鎖、解鎖與是否通知殼層一律由 reducer 決定。`AppScenePhase` 是 `Features/App/` 的頂層列舉 (`active`／`inactive`／`background`，`@unknown default` 對應 `.inactive`，維持現行「不送任何事件」)，`import SwiftUI` 只在這裡。`BuyLedgerApp` 在 `App/`，不在 reducer 掃描範圍，且送的是子層 store 自己的 `view` action。
- **冷啟動解鎖**改由 `initial: true` 觸發，刪除 Root `task` 送 `.settings(.appLock(.appDidBecomeActive))`：初始值是 `.active` 時立即送，不是時之後轉為 `.active` 照樣送。
- **`AppLockFeature.core`**：`.scenePhaseChanged(.background)` 已啟用才 `isLocked = true`；`.scenePhaseChanged(.active)` 更新 `biometryType`、一律送 `.delegate(.didBecomeActive)`，已啟用且鎖定中再合併解鎖 effect；`.scenePhaseChanged(.inactive)` 不動；`retryUnlockTapped`、`unlockResponse` 照舊。
- **回到前景** (D9)：Root 收到 `.appLock(.delegate(.didBecomeActive))` 時以注入的 `date.now`、`calendar` 建立 `CampaignDateContext`，呼叫開團模組根的 `CampaignFeature.State.refreshDateContext(_:)` (新增的 `mutating func`，只寫 `list.dateContext`；Root 只呼叫開團模組根的 State 方法)。列表未出現過時也寫入，無可見影響 (列表 `.task` 出現時會再寫一次)。
- **停在前景跨日** (D10)：新增 App 殼層專屬的 `SignificantTimeChangeService` (`Features/App/Data/` 三檔，依 Service 樣板)：closure 型別以 typealias 宣告；`liveValue` 以 `NotificationCenter` 監聽 `UIApplication.significantTimeChangeNotification`，產生 `AsyncStream<Void>`；`testValue` 每個 closure 用 `unimplemented`，stream 的 placeholder 立即結束；`+Preview` 回傳立即結束的 stream。Apple 文件：此通知在跨日、電信校時與日光節約時間變更時發出，App 暫停時排入、回到前景送達。Root 的 `view(.task)` 以 `.merge` 加入一個 `.run`，`for await` 該 stream 時送內部 action `significantTimeChanged`，收到時同樣呼叫 `refreshDateContext`；這個 effect 隨 `RootView` 的 `.task` (`await store.send(.view(.task)).finish()`) 結束而取消 (kit「AsyncStream 監聽綁在 `.view(.task)`」)。直接使用 `UIApplication` 的通知屬 `apps/ios/CLAUDE.md` 已登記的「Service 直接呼叫系統 framework，依第 10 步處理」。
- **範圍**：只有已把現在時間寫進 State 的 `CampaignListFeature.State.dateContext`；`OrdersView`、`OrdersCompactView`、`OrderMergeCandidateSheet` (第 6 步)、`DashboardView`、`InsightsView` (第 7 步) 遷移時在同兩個 Root case 各加一行，寫進 `apps/ios/CLAUDE.md`「現在時間」條目。自動結束開團只在列表載入時評估，回到前景不重新評估 (D19，維持 Non-Goal)。
- **測試**：`AppScenePhaseCoordinatorTests` 的三條改寫為 `AppLockFeatureTests` 的 TestStore 測試 (`scenePhaseChanged_進入背景且保護已啟用_鎖定內容`、`…_進入背景且保護未啟用_維持未鎖定`、`…_回到前景且鎖定中驗證成功_解除鎖定並送出回前景委派(biometryType:)`、`…_回到前景且鎖定中驗證失敗_維持鎖定並標示失敗`、`…_回到前景且未鎖定_只更新辨識類型並送出回前景委派`、`…_轉為非作用中_狀態不變也不送委派`)，另新增 `AppScenePhaseTests` (三種系統場景階段對應自訂列舉；`SwiftUI.ScenePhase` 是否 `Sendable` 決定能否參數化，實作時確認)。跨午夜以 Root TestStore 守 (固定 `date` 為隔日 00:30、列表先記錄前一天)，不以 UI 實測。Service 的 `liveValue` 由 `SignificantTimeChangeServiceTests` 對 `NotificationCenter.default` 發出該通知、確認 stream 收到一次 (`.claude/rules/ios-navigation.md`：系統事件到動作的接線都要有測試)。Root 測試送 `.view(.task)` 時一律覆寫該 Service 為會結束的 stream。

替代方案：保留 Root `task` 觸發冷啟動解鎖 (需要父層送子層 action)；各列表畫面自己觀察 `scenePhase` 送 `.view(.scenePhaseChanged)` (分散，多個訊號來源)；只做 scenePhase (App 一直停在前景跨午夜時不更新)；`AppScenePhase` 做成 `AppLockFeature` 的巢狀型別 (`BuyLedgerApp` 也要用)。

### 殼層守門、測試與文件同步

**守門測試**

| 測試 | 變更 | task |
|---|---|---|
| `ProjectionWriteBoundaryTests` | 第三條規則與自我測試 (見「Root 導覽操作與 Action 分組」)；`projectionOwners` 新增 `AppLockFeature` (`isBiometricUnlockEnabled`) 與 `MoreFeature` (`preferences`、`biometryType`，home `Features/More/MoreFeature.swift`)；`CustomersFeature.orders` 條目保留 (改 `SharedReader` 後編譯期已不可寫，條目仍描述現存主體)；`$orders` 只能作為 `SharedReader(` 引數的規則由 `Features/Campaigns/` 擴大到 `Features/More/`，自我測試加 `Features/More/MoreFeature.swift` 出現 `state.$orders.withLock` 判 1 筆、`let leaked = state.$orders` 判 1 筆 | 9.1、9.2、9.3 |
| `LayerBoundaryTests` | 根 store 宿主四個改三個 | 9.3 |
| `ActionGroupingScanTests` | `actionAllowlist` 改為空陣列；兩條 allowlist 自我測試 (改名前為 `matchingAllowlistEntryIsUsed`、`unusedAllowlistEntryFailsTheScan`，task 8.5 會改為三段式名稱) 改用測試內自建的合成條目 (現行都直接取 `actionAllowlist[0]`，清單變空會越界)；`migratedViewPaths` 加殼層 View、`MoreView`、`PersistenceFailureView` (spec「adopted 清單只增不減」成立) | 9.2、9.3、9.5 |
| `TestSuiteIntegrityTests` | 不改；新 `core` 一律明列 case、零 `default` | 全部 |
| `LocalizationCatalogTests` | 寫死的 `MoreView.swift`、`SettingsView.swift`、`RootSidebarLayout.swift` 路徑都不搬；App 鎖定的 alert 與標題字面值搬到 `SettingsFeature+Destination.swift`／`AppLockFormatters.swift`，字面不變 | 9.2、9.3 |
| `DependencyConventionScanTests` | 不改；`SettingsFeature` 取用 `biometricAuthService` 是 Service，`SignificantTimeChangeService` 照 Service 樣板 | 9.2、9.4 |
| `SnapshotTests+Lookups` | 刪 `moreViewMissingLookupManagementShowsUnavailableBaseline` 與其基準圖 | 9.3 |

**測試遷移** (每個 task 內遷移全部呼叫端)

| 原測試 | 改寫 | task |
|---|---|---|
| `smartGroupSelected_*` (3 條)、`sidebarTabSelected_更多路徑非空_清空路徑並切換分頁`、`tabSelected_更多路徑非空_保留路徑` | 改送 `.view(...)`；`MoreFeature` 存在後初始堆疊改 `more.path`，斷言 `more.path` | 9.1、9.3 |
| `categorySelected_*` (2 條) | 改名 `insights_點選分類_…`，送 `.insights(.delegate(.categoryTapped))`，不再 receive `\.categorySelected` | 9.1 |
| `dashboard_點選新增訂單…`、`dashboard_點選檢視全部訂單…`、`dashboard_點選總覽開團…`、`insights_點選洞察開團…`、`insights_點選洞察分類…` 與 `assertCampaignDeepLink` | 刪除對 `\.startNewOrder`／`\.tabSelected`／`\.categorySelected`／`\.campaignSelected` 的 receive，狀態改在 `send` 的 closure 斷言 | 9.1 |
| `CampaignIntegrationTests+Navigation` 的 `campaignSelected_詳情A顯示中深連結到B_堆疊只剩B` | 改名 `dashboard_詳情A顯示中點選開團卡B_堆疊只剩B`，改送 `.dashboard(.delegate(.campaignTapped("乙團")))` | 9.1 |
| `orders_前往開啟人工智慧設定_更多路徑只留設定頁(initialPath:)` | 改 receive `\.orders.delegate.aiSettingsRequested`；`MoreFeature` 存在後依 `ios-unit-tests.md` (會推入堆疊的參數化測試要拆開) 拆成「更多頁為空時推入設定」與「更多頁已有頁面時只留設定頁」兩條 | 9.1、9.3 |
| `init_生物辨識解鎖設定_鎖定狀態與設定一致`、`init_注入已保存設定_初始狀態同步設定` | 以 `RootFeature.State(preferences:)` 建構、斷言 `appLock.isLocked`；後者拆成 `init_注入已保存設定_殼層與更多頁持有偏好與版本` 與 `init_已保存月目標_總覽首幀使用該目標` | 9.2 |
| `task_啟動根功能_以七天期限刷新幣別快取` | 送 `.view(.task)`、不再 receive `\.settings.appLock.appDidBecomeActive`、拿掉 `biometricAuthService` 覆寫；9.4 起覆寫 `SignificantTimeChangeService` 為立即結束的 stream | 9.2、9.4 |
| `AppLockFeatureTests` 10 條 | 啟用三條 (含參數化) 移到 `SettingsFeatureTests+AppLock`；其餘依「scenePhase、回到前景與跨日」的測試列表改名改寫 | 9.2 |
| `SettingsFeatureTests` 12 條 (348 行) | 拆主檔與 `+AppLock.swift`；所有會寫入的測試補 receive `\.delegate.preferencesChanged`；`appLock_*` 三條改 `appLockToggled_*` 並與搬來的啟用測試合併 | 9.2 |
| `AppScenePhaseCoordinatorTests` | 刪除，改 `AppScenePhaseTests` | 9.2 |
| `customerSelected_有殘留類別篩選_清除類別篩選`、`customers_點選客戶_切換分頁前清空更多路徑`、`customers_載入客戶清單_送出訂單載入動作` | 改名 `more_客戶頁點選客戶_清空堆疊並清除殘留類別篩選`、`more_客戶頁要求載入訂單_送出訂單載入`；經 `\.more.path[id:].customers` 送出，receive 客戶委派再 receive More 委派 | 9.3 |
| `lookupManagements_*` (改名 4、付款方式更正 3、分類同步 3) 與 `orders_訂單編輯中新增分類_同步至查詢管理` | 改名 `more_*`；初始 State 先推入對應主檔頁；receive 鏈加 `\.more.path[id:].lookupManagement.delegate.itemRenamed` → `\.more.delegate.lookupItemRenamed`；新增分類測試改讀 `more.path[id:case:]` 的 `items` | 9.3 |
| `campaigns_*` 與 `setOrdersAndProjections`、`CampaignIntegrationTests` 的客戶投影 | `customers.orders` 改 `more.$orders`／`more.orders` (共享寫入在 `send` 的 closure 斷言) | 9.3 |
| `CustomersFeatureTests` 4 條 | State 改以 `SharedReader(value:)` 建構；整檔合規 (2026-10-03 實測 11 筆) | 9.3 |
| `PersistenceFailureFeatureTests` | 依 `view`／`destination`／`recoveryResponse` 改名與改 receive | 9.5 |

**新增測試**

| 檔案 | 測試 | task |
|---|---|---|
| `OrdersFeatureTests+AIDisabledAlert.swift` (D20，不碰 2,911 行的主檔) | `aiDisabledAlert_點選前往設定_送出開啟設定委派` | 9.1 |
| `SettingsFeatureTests+AppLock.swift` | `appLockToggled_驗證成功_啟用儲存並回報偏好`、`appLockToggled_驗證失敗或取消_維持關閉並顯示提示(result:)`、`appLockToggled_裝置不支援_維持關閉並顯示提示`、`appLockToggled_關閉_立即儲存並回報偏好` | 9.2 |
| `AppScenePhaseTests.swift` | `init_系統場景階段_對應自訂列舉` (三種) | 9.2 |
| `MoreFeatureTests.swift` | `entryTapped_` 推入匯率頁、客戶頁 (讀訂單投影)、四種主檔頁 (各一條或共用 helper，不參數化)、報價頁、設定頁 (帶入偏好、版本與辨識類型) | 9.3 |
| `MoreFeatureTests+Relays.swift` | `path_客戶頁要求載入訂單_轉送委派`、`path_客戶頁選取客戶_清空堆疊並轉送委派`、`path_主檔改名_帶種類轉送委派`、`path_付款方式更正完成_轉送委派`、`path_設定變更_轉送偏好委派` | 9.3 |
| `RootFeatureTests+AppShell.swift` | `appLock_回到前景_更多頁辨識類型同步`、`more_設定改語言_殼層偏好與更多頁投影同步`、`more_設定關閉App鎖定_鎖定投影同步為關閉`、`more_設定改月目標_總覽目標同步`、`orders_訂單更新_已推入的客戶頁讀到新訂單` (9.3)；`appLock_跨午夜後回到前景_開團日期脈絡改為新的一天`、`significantTimeChanged_停在前景跨日_開團日期脈絡改為新的一天` (9.4) | 9.3、9.4 |
| `SignificantTimeChangeServiceTests.swift` | `liveValue_系統發出重大時間變更通知_串流收到一次` | 9.4 |

單元總數會因拆測試、參數化與新增而增加 (`RootFeatureTests` 預估 37 → 約 45 條，估計)；回歸以「失敗清單是 0.2 基準的子集」判定，各 task 記錄新總數。本次不新增 UI 測試，UI 主回歸仍是 0.2 基準加 5。

**變異驗證** (每項確認執行數大於 0、轉紅後還原轉綠)

1. Root `sidebarTabSelected` 拿掉 `popToRoot()` → `sidebarTabSelected_更多路徑非空_清空路徑並切換分頁` 紅。
2. `MoreFeature` 客戶轉送不清 path → `path_客戶頁選取客戶_清空堆疊並轉送委派` 紅。
3. Root `onChange(of: \.orders.orders)` 拿掉 `more.$orders.withLock` → `orders_訂單更新_已推入的客戶頁讀到新訂單` 紅。
4. 在 `MoreFeature` 加 `state.$orders.withLock { $0 = [] }` → `ProjectionWriteBoundaryTests` 紅。
5. 在 `RootNavigationOperations` 加 `state.more.preferences = .default` → 第三條規則紅。
6. `AppLockFeature` 回到前景不送 `didBecomeActive` → `AppLockFeatureTests` 對應條紅 (9.4 起 `appLock_跨午夜後回到前景_…` 也紅)。
7. `AppLockFeature` 進背景不看是否啟用 → `scenePhaseChanged_進入背景且保護未啟用_維持未鎖定` 紅。
8. `SettingsFeature` 啟用不經驗證直接設 true → `appLockToggled_驗證失敗或取消_…` 紅。
9. `SettingsFeature` 寫入後不送委派 → 補了委派 receive 的 `binding_持久化欄位改變_…` 紅。
10. Root 不處理 `.more(.delegate(.preferencesChanged))` → `more_設定改語言_…` 紅。
11. `OrdersFeature` 前往設定不送委派 → `aiDisabledAlert_點選前往設定_…` 與 Root 的 AI 深連結測試紅。
12. Root init 拿掉月目標同步 → `init_已保存月目標_總覽首幀使用該目標` 紅。
13. `AppScenePhase.init` 對調 `.background`／`.inactive` → `AppScenePhaseTests` 紅。
14. `MoreView` 改宣告 `StoreOf<RootFeature>` → `LayerBoundaryTests` 白名單紅。
15. `MoreView` 暫加 `store.send(.path(.popFrom(id: …)))` → `ActionGroupingScanTests` 紅。
16. `BuyLedgerApp` 拿掉 `initial: true` → iPhone 跑 `AppLockTests` 的冷啟動測試；未轉紅代表冷啟動時 scenePhase 初始值不是 `.active`、後續變更已足以觸發，記為 findings 而非守門 (UI 層，單元測試守不到)。
17. Root 送出側：智慧分組不先清「更多」路徑 → `smartGroupSelected_從更多頁選取智慧分組_清空更多路徑` 紅；客戶深連結不清殘留類別 → `customerSelected_有殘留類別篩選_清除類別篩選` (9.3 起為 `more_客戶頁點選客戶_…`) 紅；`RootCascadeOperations.campaignRenamed` 不去空白 → `campaigns_開團改名_同步更新多開團訂單` 紅；`lookupItemRenamed` 不比對種類 → `lookupManagements_分類改名_透過委派改寫訂單` 紅；`RootNavigationOperations` 寫 `state.dashboard.orders = []` → 第三條規則紅。
18. Root 收到 `didBecomeActive` 不刷新 → `appLock_跨午夜後回到前景_…` 紅。
19. Root `view(.task)` 不監聽 Service → `significantTimeChanged_停在前景跨日_…` 紅。
20. Root 收到 `significantTimeChanged` 不刷新 → `significantTimeChanged_停在前景跨日_…` 紅。
21. `SignificantTimeChangeService.liveValue` 改監聽其他通知名 → `SignificantTimeChangeServiceTests` 紅。

**`mobilebuildmcp ui-automation` 實測** (每項記 `snapshot-ui` 或截圖摘要；iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929` 以 `campaignsWithOrders` seed，iPad Air 11-inch (M4) `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`；導航後重新 `snapshot-ui`，分頁列用 `touch --down --up`)

iPhone：

1. 「更多」逐一推入匯率工具、客戶名單、報價試算、四種主檔、設定，各自 `snapshot-ui` 確認目的地根 identifier，返回回到「更多」清單。
2. 匯率工具改金額、報價試算輸入本金後返回再進入，確認輸入已重設 (D3a、D3b)。
3. 推入客戶名單 → 切到訂單分頁 → 切回「更多」，客戶名單仍在 (iPhone 保留堆疊)。
4. 客戶深連結：客戶名單點客戶 → 切到訂單頁且搜尋為該客戶；切回「更多」為清單根。
5. AI 設定深連結 (不帶 `-BLUITestAiSummary` 啟動)：訂單頁 AI 總結 → 提示「前往開啟」→「更多」推入設定，返回一次回到清單根；先手動推入設定再切到訂單頁觸發一次，仍只有一份設定。
6. 語言：設定頁改 English → 分頁列、設定標題、「More」標題立即變英文；返回後再進入維持英文；`simulator launch-app` 重開仍為英文。
7. 月目標：以 `-BLUITestMonthlyGoal 50000` 冷啟動，總覽首幀顯示 50,000 的目標進度 (D12)；設定頁改目標後回總覽同步。
8. App 鎖定 (`-BLUITestBiometricScenario success`、未啟用)：設定頁打開開關維持開啟 → `ui-automation button` 按 home → `simulator launch-app` 回前景，`wait-for-ui` 依序看到鎖定畫面與自動解鎖；關閉開關後再背景與前景，不出現鎖定畫面；以 `failure` 情境打開開關，出現啟用失敗 alert 且開關彈回。
9. 「更多」列外觀 (D4)：`ui-automation touch --down` 按住任一列後 `ui-automation screenshot`，確認系統列按壓高亮，再 `touch --up` 完成推入；另截未按壓的清單，確認尾端 `chevron.right` 與主色文字。
10. 深連結 (9.1)：首頁開團卡推入該團詳情、分析頁開團排行推入詳情、分析頁類別長條切到訂單並只套用類別篩選、首頁「新增訂單」開啟空白表單。

iPad：

1. 側邊欄「更多」逐一推入五類目的地並返回。
2. 從「更多」推入客戶名單後點側邊欄「訂單」→ 不崩潰；回「更多」為清單根。
3. 從「更多」推入設定後點側邊欄智慧分組 → 不崩潰、訂單套用狀態篩選、側邊欄只高亮一列。
4. 客戶深連結：「更多」→ 客戶名單 → 點客戶 → 不崩潰、訂單頁搜尋為該客戶。
5. AI 設定深連結：側邊欄改選「更多」、設定已推入；返回正常。
6. 設定頁以 `failure` 情境打開 App 鎖定，alert 顯示在推入的設定頁之上 (iPad `NavigationSplitView` alert 雷)。
7. 語言切換後側邊欄標籤即時變英文。
8. 主檔改名：「更多」→ 商品類別 → 改名 → 返回 → 訂單頁該訂單類別已換新名 (cascade 經 More 轉送)。
9. home 鍵背景與前景的鎖定與解鎖 (同 iPhone 第 8 項)。
10. 「更多」列外觀 (同 iPhone 第 9 項)。
11. 智慧分組 (8.4)：點側邊欄智慧分組切到訂單並只高亮一列，再點分頁列切回。

**文件同步** (以內容定位)

- `.claude/rules/ios-navigation.md`：「跨頁觸發新訂單用 `RootFeature.Action.startNewOrder`」改為 Root 在總覽 `newOrderTapped` 委派的同一次更新內切到 `.orders` 並設空白草稿 (保留 sheet 掛不上的理由)；「以 `RootFeature.MoreRoute` 值導向堆疊驅動」改為 `MoreFeature.State.path` 的 `StackState<Path.State>`，列點擊與深連結只呼叫 `showSettings()` 這類 State 方法；「切分頁前先 `state.morePath.removeAll()`」改為 Root 的 `sidebarTabSelected`／`smartGroupSelected` 先 `state.more.popToRoot()`、從「更多」堆疊交出的跨分頁意圖由 `MoreFeature` 先清空再送 delegate，iPhone `tabSelected` 保留堆疊；「App 鎖定」節改為 `onChange(of: scenePhase, initial: true)` 經 `AppScenePhase(_:)` 送 `AppLockFeature` 的 `.view(.scenePhaseChanged)`、冷啟動靠 `initial: true`、接線測試改 `AppScenePhaseTests` 加 `AppLockFeatureTests`、回到前景由 `delegate(.didBecomeActive)` 交殼層更新現在時間；「啟用帳本保護前先通過一次驗證」改為 `SettingsFeature.view(.appLockToggled(true))`，成功才設 `isBiometricUnlockEnabled` (取代過時的 `isProtectionEnabled`)、寫入並送 `preferencesChanged`。
- `.claude/rules/ios-data-layer.md`：frontmatter `paths` 的 `Features/App/RootFeature.swift` 改為涵蓋 `RootFeature`、`RootCascadeOperations`、`RootNavigationOperations`，`Features/{…}` 加 `More`；主檔改名 cascade 改為經 `MoreFeature` 轉送 `.delegate(.lookupItemRenamed(kind:rename:))`、Root 以 `RootCascadeOperations.lookupItemRenamed` 分派；「`RootFeature.State.lookupManagements` 的初始陣列與 `MoreRoute`」改為 `MoreFeature.Entry` 與其推入對照、`BLAccessibilityID.More.Row`；`@Shared` 使用範圍加 `MoreFeature.State.orders` (客戶頁讀取)，`$orders` 只能作為 `SharedReader(` 引數的範圍加 `Features/More/`；付款方式資料流加入「`MoreFeature` 轉送」一環。
- `.claude/rules/ios-ui-tests.md`：`BLUITestDependencyOverrides` 兩處改 `DependencyValues+BLUITestOverrides` (8.2)；「常數集中在 `BuyLedgerAccessibilityIDs/BLAccessibilityID.swift`」改為 `BuyLedgerAccessibilityIDs/` 的 `BLAccessibilityID` 依區域分 `+<區域>.swift`。
- `apps/ios/CLAUDE.md`：根 store 宿主四個改三個 (`RootView`／`RootTabLayout`／`RootSidebarLayout`)；投影監看補 `MoreFeature` 的訂單、偏好、辨識類型與 `AppLockFeature` 的啟用狀態；「`BuyLedgerApp` 讀出的設定快照與 App 版本直接傳入 `SettingsFeature.State`」改為傳入 `RootFeature.State`、設定頁推入時由 `MoreFeature` 以投影建立；「現在時間」條目補回到前景與重大時間變更由 Root 呼叫 `CampaignFeature.State.refreshDateContext`；「未修改的既有 Feature 檔留到第 6 至 8 步」與 `extension <Feature>.State` 的「第 6 至 8 步」改為「第 6、7 步」；拆分規則補「持有 reducer 解析後的時間與行事曆值的 struct (如 `RootNavigationOperations`)」；過渡例外補 Root 送進 `OrdersFeature` 的三種內部 action (第 6 步)；專案差異補 `MoreFeature` 是 App 殼層的分頁宿主、可引用其他 Feature 模組的 Feature 型別，`@Shared` 條目加 More 的訂單投影。
- `apps/ios/README.md`：專案結構的 `Features/App/` 改列 `RootFeature` (殼層)、`RootNavigationOperations`／`RootCascadeOperations` (同域輔助型別)、`SidebarSmartGroup`、`AppLockFeature`／`AppLockView`／`AppScenePhase`／`AppLockFormatters`，`Data/` 改列 `SignificantTimeChangeService`、`PersistenceRecoveryService`，刪 `AppScenePhaseCoordinator`；`Core/Dependencies/` 補 `BiometricAuthService`；`More/` 改為「`MoreFeature` 以 `StackState` 推入匯率、客戶、報價、主檔管理、設定」；`Settings/` 補 App 鎖定的啟用驗證；`App/Testing/` 補 5 個啟動參數列舉與 `DependencyValues+BLUITestOverrides`；UI 測試段落的 `BLAccessibilityID` 描述同步分檔；「更多」堆疊、主檔改名資料流與帳本保護三個 bullet 改寫 (App 鎖定在殼層、設定頁負責啟用驗證、`AppScenePhase` 取代 Coordinator)。
- `.claude/rules/ios-unit-tests.md` 不需改 (`RootFeatureTests.makeIsolatedRootState` 名稱保留在 `+Fixtures`；`StackElementID` 規則已涵蓋 More 與開團兩個堆疊)。

### 判讀級問題的處置

| 問題 | 處置 |
|---|---|
| `CampaignFeature` 超過 300 行、inline `Reduce`、詳情共用列表 store | 拆成 CampaignFeature、CampaignListFeature、CampaignDetailFeature 與兩個無 View 子 Feature；各自 `Reduce(core)` |
| Action 未分組、成功與失敗拆成兩個 case、重試鍵送 `.task` | Action 依送出者分組，每個請求一個回應 |
| 父層攔截表單 `saveTapped` | 父層以最新開團清單驗證重名 |
| `RootFeature` 攔截開團內部 action、直接寫 `selectedCampaignID` | 改名、刪除與收款切換經 delegate 通知 RootFeature；詳情以 StackState 推入，列表點擊與深連結共用同一入口 |
| 6 個 `@Presents`、兩個畫面各宣告多個 `.alert` | 詳情不寫入也不呈現，提示一律由容器呈現；表單以任何方式關閉時都等關好才顯示提示 |
| 寫入散在一個 Feature 的兩段 `Reduce` | 寫入集中到 CampaignWritesFeature |
| View 內計算彙總、篩選、收款切換、日期區段 | 列表與詳情的衍生資料由 State 提供 |
| View 持有 `@Dependency(\.date)`／`calendar` | 現在時間由 reducer 寫進 State |
| `extension CampaignFeature.State` (MKNX) | 成員回到各 `State` 本體；日期分組搬到 `CampaignDateSectionBuilder` |
| 一檔多型別 (4 檔) | 目錄、格式化與命名沿用現行登記；`CampaignDraft`、`CampaignStatusStyle`、`CampaignDistributionRow`、`CampaignRow` 各自成檔 |
| 兩個 View 超過 300 行、`CampaignDetailView` 持有 `campaignID` | 畫面元件拆檔；詳情改讀自己 Feature 的 `content` |
| reducer `import SwiftUI` | reducer 不 import SwiftUI |
| `CampaignService` 在 Core | CampaignService 搬進開團 Data，訂單端依賴留第 6 步 |
| `CampaignSummary` 跨 Feature 放在開團目錄 | CampaignSummary 搬到 Core/Domain |
| 月分組子標題不本地化 | 列表與詳情的衍生資料由 State 提供 (明列的本地化修正) |
| 日期分組、篩選、分組零測試；開團零 snapshot | 測試拆檔與寫法；改動前先錄開團 snapshot 與 UI 測試 |
| 提醒規格的重建順序自相矛盾 | 提醒流程抽成 CampaignReminderFeature (`campaign-calendar-reminder` delta) |
| 投影改共享引用後守門偵測不到 `withLock` | 守門涵蓋開團的 View、withLock 與投影 |
| B 組 15 檔整檔違規 (超長、一檔多型別、命名、Given／When／Then、MARK) | B 組整檔合規 |
| `RootFeature` 413 行、Root Action 未分組、平行的根層導覽 action、父層攔截子層內部 action | Root 導覽操作與 Action 分組 |
| 「更多」以 `MoreRoute` 陣列與五個常駐子層驅動、`MoreView` 是根 store 宿主 | App 殼層：MoreFeature 與 StackState |
| App 鎖定巢狀在設定頁、`SettingsFeature` 攔截 `.appLock(...)`、allowlist 豁免、冷啟動月目標未同步 | 偏好與 App 鎖定分工 |
| `AppScenePhaseCoordinator` 經巢狀子層送事件、`dateContext` 不在回到前景與跨日更新 | scenePhase、回到前景與跨日 |

## Implementation Contract

**行為**：使用者在開團列表、詳情、編輯表單看到與操作的內容不變 (以 snapshot 基準圖與 UI 測試守住)。開團的操作確認與失敗提示只由容器呈現 (表單自身的捨棄確認除外)，表單與其捨棄確認存在期間外部失敗會暫存；寫入失敗一律以可關閉的 alert 呈現；表單開啟或關閉中到達的失敗在表單關好後出現 (最新的一則)。以下是本 change 確認的全部可觀察差異，其餘行為不變：

| 差異 | 內容 | 來源 |
|---|---|---|
| 開團日期標題 | 列表的「今天／昨天」在列表 `.task` 執行、App 回到前景、系統回報重大時間變更 (含停在前景跨午夜) 時更新，只在這些事件之間不變；取代 P 原本「列表停在畫面上跨午夜要等 `.task` 再執行」的差異 | P、D9、D10 |
| 英文月分組子標題 | 英文介面改顯示 Today／Yesterday (中文不變) | 本地化修正 |
| 匯率工具 | 每次從「更多」進入都重設為預設的來源幣別與金額 (`FxFeature.State` 預設 KRW、150,000)，沒有快照時先顯示載入中再抓；返回後再進入不再保留輸入；載入中返回造成的永久載入中 (推論缺陷，未實測) 不再可能發生 | D3a |
| 報價試算 | 每次進入重設本金、運費、費率、目標毛利與來源幣別；每次進入都呼叫一次匯率 API (現行快照存在就不重抓，一個 App 生命週期只呼叫一次) | D3b |
| 主檔管理 | 每次進入重讀該種類 (結果相同)；若在表單關閉後、寫入完成前按返回，寫入已落盤但改名或付款方式的連動不送出，記憶體內訂單維持舊名直到下次載入訂單 (本機寫入為毫秒級，推論，未實測) | D3c |
| 設定 | 由殼層偏好建立，顯示值相同；可用幣別清單每次從預設清單開始、`.task` 回應後更新，鍵盤焦點重設 | D3d |
| 冷啟動解鎖 | 持久層降級且已啟用 App 鎖定時，冷啟動就要求驗證 (現行要等第一次回到前景) | D8 |
| 首頁月目標 | 冷啟動首幀即顯示已儲存的月目標 (現行顯示預設 80,000 直到在設定頁改過；程式碼推論，task 9.2 以 UI Automation 實測) | D12 |
| 「更多」列外觀 | 列改為按鈕加尾端 `chevron.right` (朗讀隱藏)，保留系統列按壓高亮、文字為主色；箭頭與系統導覽箭頭接近但非完全相同 | D4 |
| 「更多」主檔備援畫面 | 「無法載入主檔管理頁面，請稍後再試。」畫面與其翻譯移除 (Path 元素自帶 State，這個畫面已不可能出現) | D18 |

**介面**：

- 各 Feature 的 Action、`CampaignRequest`、`Destination`、`Path` 如 Decisions 各節所列。
- `CampaignFeature.Action.Delegate`：`campaignDeleted(name:)`、`campaignRenamed(from:to:)`、`receiptStatusToggled(orderID:status:)`；`RootFeature` 只對這三個 delegate 反應。
- `CampaignFeature.State`：無參數 `init()`；`@Shared` 的 `campaigns`、`orders`、`reminderLinks`、`showsUnpaidOnly`；`mutating func showDetail(campaignID:)`。
- `CampaignDateSection`／`CampaignSubgroup` 的 `title` 型別改為 `CampaignSectionTitle`／`CampaignSectionTitle?`。
- `CampaignService` 的 closure、`DependencyValues.campaignService` key path 與 `PersistenceError` 不變，只換檔案位置。
- `RootFeature.State`：`init(persistenceStatus:preferences:appVersion:)`；`preferences: SettingsSnapshot`、`appLock`、`more`。`RootFeature.Action`：`view(.task／.tabSelected／.sidebarTabSelected／.smartGroupSelected)`、`persistenceFailure`、子層 `appLock`／`campaigns`／`dashboard`／`insights`／`more`／`orders`、內部 `significantTimeChanged`；不再是 `BindableAction`。
- `RootNavigationOperations` (struct) 與 `RootCascadeOperations` (無 case enum) 的方法如「Root 導覽操作與 Action 分組」。
- `MoreFeature` 的 State、Action、`Path`、`Entry`、`showSettings()`、`popToRoot()` 如「App 殼層：MoreFeature 與 StackState」；`MoreView(store:language:)`。
- `AppLockFeature.Action`：`view(.retryUnlockTapped／.scenePhaseChanged(AppScenePhase))`、`delegate(.didBecomeActive)`、`unlockResponse`；`AppScenePhase`：`active`／`inactive`／`background` 與 `init(_: ScenePhase)`；`AppLockFormatters.unlockTitle(for:)`、`protectionDescription(for:)`。
- `SettingsFeature.State`：`init(snapshot:appVersion:biometryType:)`、`snapshot`；`SettingsFeature.Action` 加 `view(.appLockToggled(Bool))`、`delegate(.preferencesChanged(SettingsSnapshot))`、`destination`、`appLockAuthenticationResponse`。
- `OrdersFeature.Action.Delegate.aiSettingsRequested`；`CampaignFeature.State.refreshDateContext(_ context: CampaignDateContext)`；`CustomersFeature.State.init(orders: SharedReader<[LedgerOrder]>)`。
- `SignificantTimeChangeService`：回傳 `AsyncStream<Void>` 的 closure 與 `DependencyValues.significantTimeChangeService`；`BiometricAuthService` 的型別、巢狀型別與 `DependencyValues.biometricAuthService` 不變，只換到 `Core/Dependencies/`。

**失敗呈現與文案** (全部由 `CampaignView` 的 alert 呈現，列表載入失敗除外；逐字沿用，標題預設「操作失敗」、按鈕「知道了」)：

| 來源 | 訊息 |
|---|---|
| 列表載入失敗 (列表內持續顯示，不進 alert) | 開團載入失敗，請稍後再試。 |
| 列表 `autoCloseFailed` | 開團狀態自動更新失敗，請稍後再試。 |
| 寫入 `failed(.save)` | 開團儲存失敗，請稍後再試。 |
| 寫入 `failed(.rename)` | 開團已儲存，但歸屬訂單的開團名稱更新失敗，請稍後再試。 |
| 寫入 `failed(.delete)` | 開團刪除失敗，請稍後再試。 |
| 寫入 `failed(.status)` | 開團狀態更新失敗，請稍後再試。 |
| 寫入 `failed(.settle)` | 結團失敗，請稍後再試。 |
| 提醒 `eventRemovalAfterDeleteFailed` | 開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。 |
| 提醒 `linkRemovalFailed` | 提醒連結移除失敗，請稍後再試。 |
| 提醒 `oldEventRemovalFailed` | 提醒已更新，但舊的行事曆事件移除失敗，請自行到行事曆刪除。 |
| 提醒 `accessDenied` | 標題「需要行事曆權限」，訊息「請到「設定」開啟行事曆存取權限，才能新增或移除訂購提醒。」，按鈕「前往設定」與「知道了」 |
| 提醒 `accessRestricted` | 標題「無法使用行事曆」，訊息「這台裝置的行事曆存取受政策限制，暫時無法新增或移除訂購提醒。」 |
| 提醒 `creationFailed` | 標題「無法建立訂購提醒」，訊息「訂購提醒建立失敗，請稍後再試。」 |
| 提醒 `calendarUnavailable` | 標題「找不到可寫入的行事曆」，訊息「找不到可寫入的行事曆，請新增或啟用一個可寫入的行事曆後再試。」 |
| 刪除確認 (列表長按與詳情選單共用) | 標題「刪除開團」，訊息「刪除「<名稱>」後無法復原。歸屬此開團的訂單會保留，但會變回未歸團。」，按鈕「刪除」「取消」 |
| 結團確認 | 標題「結團結算」，訊息「結算「<名稱>」後就無法再改回進行中。確定要結團嗎？」，按鈕「結團」「取消」 |

App 鎖定啟用失敗與裝置不支援的兩個 alert 改由 `SettingsFeature` 的 `destination` 呈現 (推入的設定頁之上)，字面值逐字搬自 `AppLockFeature`；`Localizable.xcstrings` 除 D18 移除的一個 key 外不增減。

**測試環境**：iPhone 17 (iOS 26.5) `DDAA3311-B464-4DD3-96B8-360B26AF1929`、iPad Air 11-inch (M4) (iOS 26.5) `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5` (2026-10-01 以 `xcodebuildmcp simulator list` 確認存在)；單元測試與 UI 測試用同一台 iPhone，iPad 回歸固定同一台；跑 snapshot 前鎖淺色外觀；iPad UI 回歸前確認軟體鍵盤可顯示。

**檢查分組** (2026-10-03 起適用；開團部分 task 0.1 至 7.7 依當時分組驗收完成)：

- A 組 (整檔適用所有規範，不超過 300 行)：開團責任檔 (`Features/Campaigns/**`、`Core/Domain/CampaignSummary.swift`、`Core/Domain/CampaignDistributionRow.swift`、`Campaign*Tests.swift` 與本步新增的開團測試、`SnapshotTests+Campaigns.swift`、`CampaignFlowTests.swift`)；原 B 組 15 檔與其拆出、改名的新檔 (見「B 組整檔合規」)、`ContrastComplianceTests.swift` 與其拆出檔；App 殼層 (`Features/App/**`、`Features/More/**`、本步改到的 `Features/Settings/**` 與 `Features/Customers/**`、`App/BuyLedgerApp.swift`、`Core/Dependencies/BiometricAuthService*.swift`)；本步新增或改寫的其他測試檔 (`AppLockFeatureTests`、`SettingsFeatureTests*`、`CustomersFeatureTests`、`PersistenceFailureFeatureTests`、`MoreFeatureTests*`、`AppScenePhaseTests`、`SignificantTimeChangeServiceTests`、`OrdersFeatureTests+AIDisabledAlert`)。
- B 組 (只審本步 diff 改到的行與觸碰的方法，既有違規與行數留給各自負責的步驟)：`Features/Orders/OrdersFeature.swift`、`BuyLedgerTests/SnapshotTests+Lookups.swift` (D17)；與 `reference/style_checks.py` 的 `B_GROUP` 一致。機械檢查、測試命名與 Given／When／Then、獨立 style 審查一律照此分組。
- `EXISTING_OVER_LIMIT` 已移除開團三檔與 `RootFeature.swift`、`RootFeatureTests.swift`、`BLUITestDependencyOverrides.swift`、`SettingsFeatureTests.swift`，這些檔 (含改名或拆檔後) 超過 300 行一律算失敗。

**驗收條件**：

1. `reference/style_checks.py` 對本 change 全部新增與修改的 Swift 檔檢查，除不計失敗的 `WSTR`、`WCL`、`WSIG`、`LENX` (只剩不屬本步的既有超長檔) 外為 0 筆；`git diff --check HEAD` 與未追蹤檔逐一 `grep -nE '[[:space:]]+$'` 無輸出。
2. A 組每個檔不超過 300 行 (不含檔頭與空行)，含 `RootFeature.swift`、`CampaignFeature.swift`、`MoreFeature.swift`。
3. 獨立 style agent 依 `/ios-dev-kit` 原文逐檔逐條審查 (不抽查)：A 組整檔、B 組只審本步改到的方法與必要區塊；處置為 0 或逐筆附使用者裁決。
4. 殘留名稱：開團部分 `grep -rn` 限 `apps/ios/BuyLedger/Features/Campaigns`、`Features/App/RootFeature.swift` 與本步改到的測試檔，`campaignsLoaded`、`campaignsFailed`、`campaignStatusSaved`、`campaignSettled`、`campaignSaved`、`campaignWriteFailed`、`settleConfirmed`、`campaignDeleteRequested`、`reminderStored`、`reminderLinksLoaded`、`selectedCampaignID` 以及舊呈現欄位的 key path `\.noticeAlert`、`\.detailNoticeAlert`、`\.deletionConfirmation`、`\.detailDeletionConfirmation`、`\.settleConfirmation`、`\.editCampaign` 無輸出 (新的 alert 建構方法不得沿用這些名稱；`OrdersFeature` 自己的 `campaignsLoaded` 不在範圍)；`Features/Campaigns/` 內 `import SwiftUI` 只出現在 View、`Components/`、`CampaignFormatters.swift`、`CampaignStatusStyle.swift`。殼層部分 `grep -rn` 在 `apps/ios` 中 `MoreRoute`、`morePath`、`appDidResignActive`、`appDidBecomeActive`、`enableToggled`、`enableAuthenticationFinished`、`unlockAuthenticationFinished`、`startNewOrder`、`AppScenePhaseCoordinator`、`BLUITestDependencyOverrides` 無輸出；`campaignSelected`、`categorySelected`、`case customerSelected` 在 `Features/App/*.swift`、`RootFeatureTests*.swift`、`CampaignIntegrationTests*.swift` 無輸出 (與其他 Feature 的同名 action 重疊，限定範圍)；`RootFeature`、`RootNavigationOperations`、`RootCascadeOperations`、`AppLockFeature`、`SettingsFeature*`、`MoreFeature` 不 import SwiftUI。
5. `findings.md` 無「結論：待填」。
6. 完整單元回歸：xcresult 時間晚於最後一次 Swift 寫入，失敗清單是 task 0.2 基準的子集；`ActionGroupingScanTests`、`ProjectionWriteBoundaryTests`、`LayerBoundaryTests`、`DependencyConventionScanTests`、`LocalizationCatalogTests`、`TestSuiteIntegrityTests`、`AppScenePhaseTests`、`MoreFeatureTests`、`SignificantTimeChangeServiceTests` 與開團 8 條 snapshot (改動前基準 7 條中 6 條未重錄、1 條依裁決重錄，另 1 條英文新基準)、`persistenceFailureView_持久化錯誤_符合基準圖` (未重錄) 全綠。
7. iPhone 與 iPad 各一次 `BuyLedgerUITests` 主回歸：`totalTestCount` 等於基準加 5 (2026-10-03 擴大範圍不新增 UI 測試)，失敗清單是基準的子集，`CampaignFlowTests` 五條與既有開團 UI 測試全綠。
8. `spectra validate campaigns-style-compliance` 通過，`git status --porcelain` 的變動都在範圍邊界內。
9. 「殼層守門、測試與文件同步」列出的 `mobilebuildmcp ui-automation` 實測項目全部完成並記在對應 task 下方；實測不成立視為缺陷回報，不降級為推論。

**範圍邊界**：

- 範圍內：proposal「Impact」列出的檔案。2026-10-03 起新增的範圍目錄為 `Features/App/**`、`Features/More/**`，以及 `Features/Settings/`、`Features/Customers/` 中 Impact 列出的檔、`App/BuyLedgerApp.swift`、`App/Testing/` 的拆檔與改名、`BuyLedgerAccessibilityIDs/` 的拆檔、`BuyLedgerUITests/Screens/` 與 `Support/` 的整檔修正；`project.pbxproj` 只允許 `CURRENT_PROJECT_VERSION` 遞增 (專案用 synchronized group，搬檔、拆檔與改名都不改 pbxproj)；`Localizable.xcstrings` 只允許移除「無法載入主檔管理頁面，請稍後再試。」這一個 key (D18)，Xcode build 產生的其他結構變更要還原；`Core/Dependencies/` 只新增由 `Features/App/Data/` 搬入的 `BiometricAuthService` 三檔；`Features/App/Data/` 只新增 `SignificantTimeChangeService` 三檔；`Features/Orders/` 只有 `OrdersFeature.swift` 的 `delegate(.aiSettingsRequested)` (B 組)。
- 範圍內 (使用者 2026-10-04 裁決)：`BuyLedgerTests/` 與 `BuyLedgerUITests/` 全部測試檔移除 `// MARK: - Tests` 分區；本 change 其他部分沒動到的測試檔，diff 只允許刪除這一行與其後空行。
- 範圍外：`Features/Orders/` 其餘程式碼 (含 Root 送進 Orders 的三種內部 action、`OrderEditView` 選擇列的按壓高亮、預設幣別的讀取端，皆第 6 步)；`Features/Dashboard/`、`Features/Insights/` 的程式碼 (Root 只寫總覽的月目標投影)；`CampaignService`／`CampaignReminderService`／`CalendarReminderService` 與 `BiometricAuthService` 的介面；SwiftData schema；首頁開團卡冷啟動空白的修正；回到前景重新評估自動結束；`RootFeature` 改名 `AppFeature` 與目錄調整 (第 10 步)；三份 `stripCommentsAndStrings` 的共用化 (第 10 步)。

## Risks / Trade-offs

- [行數預算是估計] → 每個 Feature 在完成它的 task (2.5、3.2、3.3) 結束時量測，超過 300 行就停下回報。
- [`@Shared` 在 TestStore 的斷言時機] → 共享變更寫在第一個觀察到它的斷言點；初始資料在建 store 前以 `withLock` 設定；遇到「兩處都報 state mismatch」先檢查斷言點，不放寬窮舉。
- [`ProjectionWriteBoundaryTests` 對 `withLock` 與以值傳遞的 State 原本是盲點] → 本步補兩條規則與自我測試，並以變異驗證。
- [SwiftUI 在 sheet 關閉動畫中丟棄 alert] → 表單生命週期涵蓋所有關閉路徑，加 UI 測試 `testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示` 與 reducer 測試。
- [後到的提示覆蓋先到的] → 與現況同一欄位覆寫一致，規格明列；儲存成功但改名與提醒都失敗時只看到最後一則。
- [iPad 的 `NavigationSplitView` 中，掛在 NavigationStack 外層的 `.alert` 無法顯示在推入的詳情之上 (`.sheet` 可以；task 5.2 在 iPad 實測，iPhone 不受影響)] → alert 的狀態仍只有容器的 `destination`，`CampaignView` 把同一個 alert 綁定掛在目前最上層的畫面：堆疊為空時掛在列表根內容，推入詳情時掛在詳情 (另一處給 `.constant(nil)`，同一個綁定同時掛兩處會破壞 iPhone)；sheet 維持掛在容器 (使用者 2026-10-02 裁決)。
- [詳情的操作都要經容器處理] → 多一次 delegate 轉送，換來詳情沒有非同步 effect、深連結換掉詳情時沒有遺留回應、單一呈現者；詳情的寫入失敗也在容器呈現。
- [重試鍵接線沒有 UI 層級的保證] → `ActionGroupingScanTests` 只保證送的是 `.view(...)`，`retryTapped` 的重新載入由單元測試守住；成功情境的 UI 測試排第 6 步，屆時一併守住接線。
- [`dateContext` 只在列表 `.task`、回到前景與系統重大時間變更時更新] → 涵蓋使用者能察覺的跨日情境 (2026-10-03 起取代 P 原本的延後更新)；其他時間點不更新是設計，spec 明列。
- [提醒流程與寫入拆成子 Feature 後 action 順序改變，`receive` 序列全部要重寫] → 逐條對應原 11 個失敗情境與 5 個正向情境，並以變異驗證確認轉紅。
- [搬檔讓第 4.5 步登記的路徑與文件過時] → 文件同步 task 逐列對照 `git status --short`。
- [iPad `NavigationSplitView` 在「更多」路徑非空時改 `selectedTab` 會 assertion 崩潰] → Root 主動切離的 view action 先 `popToRoot()`、`MoreFeature` 交出的跨分頁意圖先清 path；變異 1、2 與 iPad 實測第 2 至 5 項守住。
- [主檔管理放 `Path` 後返回會取消進行中寫入的回應 (D3c)] → 只在表單關閉後、毫秒級寫入完成前按返回才發生，使用者已接受；下次載入訂單即一致。
- [報價每次進入多打一次匯率 API (D3b)] → 使用者已接受配額影響；若日後配額不足，改回常駐並另修載入中返回的卡住缺陷。
- [`RootFeature` 與 `CampaignFeature` 的行數是估計] → `RootFeature` 在 task 9.3、9.4 結束時量測 (方案估計約 290 行)；`CampaignFeature` 2026-10-03 實測 294 行，加 `refreshDateContext` 估計約 300 行，在 9.4 量測；超過就停下回報，`CampaignFeature` 的備案 (Root 直接呼叫 `state.campaigns.list` 的方法) 需使用者同意。
- [Root 的 `view(.task)` 加入長時間 effect 後，Root 測試要處理未結束的 effect] → 測試一律覆寫 `SignificantTimeChangeService` 為會結束的 stream，不放寬窮舉。
- [`initial: true` 的冷啟動行為取決於 SwiftUI 給的初始值] → 變異 16 以 UI 測試確認；未轉紅時記 findings。
- [殼層重構跨 9.1 至 9.4，中間狀態 Root 暫時超過 300 行] → 每個 task 結束都能 build 並通過相關測試 (Migration Plan)；行數只在 9.3、9.4 驗收。
- [檢查腳本的兩條放寬過寬而漏判] → 放寬只認「警告或 log 呼叫後接單一 return／throw」與 `<Type>+Extensions.swift` 檔名，task 7.8 以樣本檔確認其他寫法仍判違規 (後依使用者指正，功能段名只限綜合擴充檔)。
- [Xcode build 會改寫 `Localizable.xcstrings` 的結構] → 範圍檢查只允許移除 D18 的一個 key，其餘變更還原。

## Migration Plan

無資料或 schema 遷移。每個 task 結束時 App target 與測試 target 都能編譯、相關測試綠燈 (task 0.4、0.5 的基準在所有行為重構之前)；刪除或改名 API 的 task 在同一個 task 內遷移全部呼叫端 (含 Preview、snapshot、`RootFeatureTests`、`CampaignIntegrationTests`)。回滾即還原本 change 的 commit。

2026-10-03 擴大範圍依 expand → migrate → contract 進行：B 組各檔的拆檔與改名 (task 8.x) 不改行為，各自 build 並通過測試；殼層依 9.1 (Root 內部重構與 `OrdersFeature` 委派，此時 Root 仍持有 `morePath` 與五個常駐子層) → 9.2 (App 鎖定上移、偏好進 Root、設定接手啟用驗證，此時設定仍是 Root 常駐子層、委派由 Root 直接處理) → 9.3 (`MoreFeature` 接手「更多」，移除 Root 的常駐子層與 `binding`) → 9.4 (回到前景與跨日刷新) → 9.5 (`Features/App` 其餘檔) 依序進行，每個 task 內遷移全部呼叫端與測試，結束時 App 與測試 target 可編譯、相關測試全綠。`BiometricAuthService` 與 `BLUITestDependencyOverrides.swift` 以 `git mv` 搬移或改名，保留歷史。無資料或 schema 遷移。

## Open Questions

- 開團部分無未決事項 (疑似缺陷「首頁開團卡冷啟動空白」已於 task 0.3 實測成立，登記第 6 步)。
