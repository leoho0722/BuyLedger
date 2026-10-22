## Summary

把 `apps/ios/BuyLedger/Features/Campaigns/` 與對應單元測試對齊 `/ios-dev-kit`：1,350 行的 `CampaignFeature` 拆成管導覽與呈現的 `CampaignFeature`、列表畫面 `CampaignListFeature`、詳情畫面 `CampaignDetailFeature`，以及沒有 View 的寫入子 Feature `CampaignWritesFeature` 與提醒子 Feature `CampaignReminderFeature`，以 `@Shared` 共用開團、訂單投影、提醒連結與「只看未收款」，並把畫面上即時計算的彙總、篩選、日期分組與收款切換規則移進 Feature 狀態。這是 ios-dev-kit 修正順序十步計劃的第 5 步；範圍與裁決由使用者 2026-10-01 討論、2026-10-02 依 Codex 兩輪審查結果改定。

2026-10-03 使用者裁決擴大範圍 (開團部分 0.1 至 7.7 已全部完成)：原本只查 diff 的整合點 (B 組) 改為整檔合規，並把第 8 步的 App 殼層重構 (`RootFeature`、「更多」分頁、App 鎖定、場景階段與偏好) 提前到本步一起完成。

## Motivation

2026-10-01 以第 4.5 步的檢查腳本重掃本步範圍，13 個檔案共 **377 筆**機械問題 (實測，明細見 `findings.md`)；2026-09-14 審查的「8／39」已過時，因為第 4.5 步整檔修過這些檔的寫法與排版。腳本抓不到的結構問題才是本步主體 (行數為 2026-10-01 `wc -l` 實測)：

1. **`CampaignFeature.swift` 1,350 行** (上限 300，不含檔頭與空行)：列表、詳情、結團、刪除、行事曆提醒全在一個 Feature，詳情畫面共用列表的 store，`body` 是兩段 inline `Reduce` 閉包，6 個 `@Presents`，State 的日期分組方法 183 個非空行。
2. **Action 沒有分組**：約 30 個 case 平放，成功與失敗拆成 `campaignStatusSaved`／`campaignSettled`／`campaignSaved` 加共用的 `campaignWriteFailed(String)`，違反 `app-layer-boundaries`「one request's success and failure SHALL be a single response case」；載入失敗的重試鍵送的是 `.task` 而非重試事件。
3. **父層碰子層的非 delegate action**：`CampaignFeature` 攔截編輯表單的 `.saveTapped`，`RootFeature` 攔截開團的內部 action `.campaignRenamed` 與 `.campaignDeleted`。
4. **畫面自己計算**：`CampaignListView` 每次渲染呼叫 `CampaignSummary.batch`，並以 `@Dependency(\.date)`／`calendar` 計算日期區段；`CampaignDetailView` 在畫面裡算彙總、挑選「只看未收款」的列、決定收款鍵切換成哪個狀態。
5. **檔案與型別配置**：`CampaignListView` 406 行、`CampaignDetailView` 404 行；四個檔各放了兩個頂層型別；`CampaignService` 仍在 `Core/Dependencies/` (第 4.5 步登記的過渡例外)；Dashboard 與 Insights 使用的 `CampaignSummary` 放在開團目錄。
6. **測試**：`CampaignFeatureTests` 2,056 行、`CampaignReminderFailureTests` 655 行；25 個測試仍是單段命名且缺 Given／When／Then；日期分組、狀態篩選與分組切換零測試；開團畫面沒有 snapshot。
7. **規格自相矛盾**：`campaign-calendar-reminder` 一處寫重建提醒「remove then recreate」，另一處要求先建新事件再刪舊事件；程式採後者。

討論時選的方案 A (維持單一 Feature) 經 Codex 審查指出主檔壓不到 300 行；以第 4 步達標的 `LookupManagementFeature` (290 行) 校準，估計仍有 400 到 470 行。使用者 2026-10-02 改為本步就拆成列表與詳情 (方案 B)，並選擇以 `@Shared` 共用資料。

**範圍擴大 (2026-10-03)**

8. **B 組整合點只查 diff 會留下半套合規**：B 組 13 個檔以整檔標準掃描合計 526 筆 (實測；扣掉腳本誤判 44 筆與不計失敗 3 筆，實際待修約 480 筆)，另有 `CampaignsScreen.swift`、`CampaignEditScreen.swift` 各 6 筆 (實測)。其中 `RootFeature.swift` 413 行、`BLAccessibilityID.swift` 612 行、`RootFeatureTests.swift` 1,603 行、`LocalizationCatalogTests.swift` 940 行等超過 300 行 (皆為不含檔頭與空行的非空行數，2026-10-03 實測)。
9. **`RootFeature` 不改殼層結構就降不到 300 行**：只外移輔助型別的方案 A 草稿實算約 295 行、餘裕約 5 行，且 Root `Action` 未依送出者分組、父層攔截子層內部 action (`.orders(.aiDisabledAlert(.presented(.goToAISettings)))`、`SettingsFeature` 攔截 `.appLock(...)`)、`ActionGroupingScanTests` 仍留一條「第 8 步補 delegate」的豁免，這些結構性違規都要等第 8 步。
10. **殼層的既有缺口**：「更多」分頁以 `RootFeature.MoreRoute` 陣列加五個常駐子層驅動；App 鎖定巢狀在設定頁內，由 `AppScenePhaseCoordinator` 轉送場景事件；開團列表的現在時間只在列表 `.task` 更新 (使用者裁決 P 的已知缺口)；冷啟動時 `RootFeature.State.init` 沒有把已儲存的月目標同步到總覽，首頁一律顯示預設 80,000 (程式碼推論，未實測)。

使用者因此決定 B 組改整檔合規，並把第 8 步的殼層重構提前到本步 (方案與裁決見 design「Context」的 2026-10-03 裁決)。

## Proposed Solution

**拆分 (使用者裁決：方案 B、`@Shared`)**

- `CampaignFeature` 管導覽堆疊 (`StackState`，詳情為 `Path.detail`)、開團操作確認與寫入失敗提示的**唯一呈現者** (編輯表單、刪除與結團確認、所有失敗提示，單一 `Destination`；表單自身的捨棄確認保留在表單內)，並持有 `@Shared` 的開團、訂單投影、提醒連結與「只看未收款」。
- `CampaignListFeature` 管載入、結單日自動轉狀態、篩選、分組與日期區段；`CampaignDetailFeature` 只管詳情內容與「只看未收款」，不做寫入、不呈現提示，其餘操作以 delegate 交給 `CampaignFeature`。兩者以 `SharedReader` 唯讀訂單投影與提醒連結。
- 儲存、改名連動、刪除、狀態變更、結團集中到沒有 View 的 `CampaignWritesFeature`；行事曆提醒流程抽成沒有 View 的 `CampaignReminderFeature`。
- `RootFeature` 改以 `withLock` 同步訂單投影，深連結與列表點擊走同一個推入詳情的入口。

**資料流**

- 每個 Feature 的 Action 依 `view` → `delegate` → 子層／導覽 → 內部回應分組；每個請求一個 `...Response(Result<_, PersistenceError>)`；重試改送 `.view(.retryTapped)`。
- 編輯表單以 `delegate(.saveRequested)` 交給父層；父層在關閉表單與任何寫入之前，以最新的開團清單檢查重名，拒絕時把原因寫回表單。
- 改名、刪除、收款切換以 `CampaignFeature.Action.Delegate` 通知 `RootFeature`。
- 表單以任何方式關閉 (儲存、取消、確認捨棄、下滑) 時，期間到達的失敗提示都等表單關好才顯示。
- **現在時間由 reducer 寫進 State (使用者裁決 P)**：列表的 `.task` 每次執行時記錄 `date.now` 與 `calendar`，畫面不再持有 `@Dependency`。2026-10-03 起殼層另在 App 回到前景與系統回報重大時間變更 (例如跨日) 時重寫，列表停在前景跨午夜也會更新 (取代原本「要等 `.task` 再執行」的已知缺口)。

**配置**

- `CampaignService` 三個檔搬進 `Features/Campaigns/Data/`；`OrdersFeature`、`OrderEditFeature` 對它的注入、訂單端重複的結單日自動轉狀態，以及 `CampaignWritesFeature` 經 `OrderService` 改寫訂單的開團名稱，登記為過渡例外、第 6 步處理 (使用者裁決 Y)。
- `CampaignSummary` 與 `CampaignDistributionRow` 搬到 `Core/Domain/` (比照 `OrderSummary`；跨 Feature 使用且不依賴任何 Feature)。
- 一檔一個頂層型別；畫面區塊抽成 `Features/Campaigns/Components/` 的獨立 View；所有 production 與測試檔各自不超過 300 行。
- 依 `apps/ios/CLAUDE.md` 現行登記：開團目錄除 `Data/`、`Components/` 外維持扁平 (各 Feature 與編輯表單不另開資料夾)，格式化維持 `CampaignFormatters` 靜態函式。

**守門與驗證**

- 改動任何行為前先新增開團列表、詳情與編輯表單的 snapshot 並錄製基準圖，再新增 5 條開團 UI 測試與一個寫入失敗啟動參數 (task 0.5 只加測試掛鉤與 identifier)；完工後維持綠燈且基準圖不重錄 (例外：`campaignEditView_編輯既有開團_符合基準圖` 經使用者 2026-10-04 裁決重錄 (模擬器重開後系統 compact `DatePicker` 的日期格式改變，正式程式碼未動，原基準圖兩個日期欄格式不一致；經過見 task 10.5 補記))。
- task 0.3 以 UI Automation 實測「首頁進行中開團卡在冷啟動後是空的」這個疑似缺陷；成立就登記，**修正留第 6 步** (使用者裁決)。
- `ActionGroupingScanTests` 納入開團的四個 View 與 `Components/`；`ProjectionWriteBoundaryTests` 補上對 `withLock` 寫入與可寫引用外傳的偵測；新增日期分組、詳情內容、提醒調解、儲存計畫、表單生命週期的單元測試。

**測試跟著改**：`CampaignFeatureTests` 依各 Feature 與職責拆檔，提醒失敗測試改測子 Feature；開團責任檔 (A 組) 的測試整檔改用三段式中文命名並補 Given／When／Then；`RootFeatureTests` 與 `CampaignIntegrationTests` 直接送開團內部 action 的測試改走 view 與 delegate 的完整流程。2026-10-03 起 `RootFeatureTests` 等原 B 組檔也改整檔合規 (見下方範圍擴大)。

**範圍擴大：B 組整檔合規 (2026-10-03)**

- 原 B 組 13 檔加 `CampaignsScreen.swift`、`CampaignEditScreen.swift` 改依整檔標準修正：`BLAccessibilityID` 依區域拆 8 檔、`BLUITestConfiguration` 的 5 個列舉各自成檔、`BLUITestDependencyOverrides.swift` 依 kit 改名 `DependencyValues+BLUITestOverrides.swift`、`CampaignDetailScreen` 拆 3 檔、`RootSidebarLayout` 的智慧分組抽成 `SidebarSmartGroup`、`RootFeatureTests`／`ProjectionWriteBoundaryTests`／`LocalizationCatalogTests` 拆檔與整檔改寫 (後者第一條測試拆成 5 條、已驗收英文值參數化)。
- 只為接線而改的大型既有檔 (`OrdersFeature.swift`、`SnapshotTests+Lookups.swift`) 維持只查 diff；`ContrastComplianceTests.swift`、`LayerBoundaryTests.swift` 經使用者裁決整檔合規 (後者拆檔)。
- 檢查腳本放寬兩條使用者裁決：`guard` 的 else 先記錄警告再 return 不算違規；外部型別的 `<Type>+Extensions.swift` 綜合擴充檔用功能段名 (拆成 `<Type>+<Feature>.swift` 後用一般區名)。

**範圍擴大：提前第 8 步 App 殼層 (2026-10-03)**

- `RootFeature` 降到 300 行內：Action 依 `view` 與子層分組，`startNewOrder`／`customerSelected`／`categorySelected`／`campaignSelected` 改為共用的導覽操作 (`RootNavigationOperations`)，訂單改名連動外移到 `RootCascadeOperations`；父層不再攔截子層內部 action，`OrdersFeature` 改以 `delegate(.aiSettingsRequested)` 請 Root 開啟設定；`ActionGroupingScanTests` 的豁免清空。
- 「更多」分頁抽成 `MoreFeature`，以 `StackState<Path.State>` 推入客戶、匯率、主檔管理、報價、設定 (返回即釋放)；客戶頁以 `SharedReader` 讀訂單投影；列改為按鈕加尾端箭頭並保留系統列按壓高亮。
- 使用者偏好由 Root 持有 (啟動時讀一次)，設定頁每次寫入後以 delegate 回報；App 鎖定上移為殼層常駐子層，只管上鎖與解鎖，啟用前的驗證移到設定頁；`BiometricAuthService` 搬到 `Core/Dependencies/`。
- `BuyLedgerApp` 以 `onChange(of: scenePhase, initial: true)` 經自訂列舉 `AppScenePhase` 送 App 鎖定，刪除 `AppScenePhaseCoordinator`；回到前景與系統重大時間變更 (新 Service) 時由 Root 重寫開團列表的現在時間；冷啟動首幀即使用已儲存的月目標。
- `Features/App` 其餘檔 (`PersistenceFailureFeature`／`View`、`RootTab`、`SidebarBadgeCounts`、`AppLockView`、`RootView`) 一併整檔合規。

## Non-Goals

見 design.md 的 Goals / Non-Goals。

## Alternatives Considered

- **方案 A：維持單一 `CampaignFeature`，以子 Feature 與輔助型別拆分**：受 `ProjectionWriteBoundaryTests` 限制 (修改整份開團 State 的方法只能留主檔)，主檔估計仍有 400 到 470 行；使用者 2026-10-02 改選 B。
- **詳情自帶寫入與提示** (第二輪前的設計)：需要容器與詳情兩個呈現者協調，深連結換掉詳情時也會丟棄進行中的寫入回應；改為詳情只送請求、寫入與呈現集中。
- **方案 B 但父層複製同步資料**：列表與詳情各持副本，由 `CampaignFeature` 在資料變動時寫回；同步程式碼多、漏一條就顯示舊資料，且要放寬「投影由 `RootFeature` 同步」的規格；使用者選 `@Shared`。
- **方案 X：本步一併移除訂單端的開團依賴與重複自動轉狀態**：要先決定「App 啟動時由誰載入開團」，與第 6 步「`.orders(.task)` 被多個父層觸發」是同一個設計問題；使用者選 Y 留到第 6 步。
- **方案 Q：保留畫面以 `@Dependency(\.date)` 取現在時間並登記例外**：使用者選 P。
- **`CampaignSummary` 搬到 `Features/Campaigns/Domain/`、編輯表單另開資料夾、格式化改 `FormatStyle`** (討論時提出)：與 `apps/ios/CLAUDE.md` 登記的「Feature 其他檔案維持扁平，依第 10 步決定目錄調整」「格式化用靜態函式，不是 `FormatStyle`」衝突，依現行登記處理。
- **`RootFeature` 只外移 `MoreRoute` 與兩個輔助型別 (B 組方案 A)**：主檔草稿實算約 295 行、餘裕約 5 行，結構性違規仍留第 8 步；使用者 2026-10-03 改為提前第 8 步殼層。
- **Root 直接持有「更多」的 `StackState` (M1)**：資料流較短，但 Root 估計約 320 行，需要再抽一層；使用者選抽出 `MoreFeature` (M2)。
- **啟用驗證留在 `AppLockFeature`、設定頁經 Root 轉送 (L2)**：需要父層送子層非 delegate action，失敗提示也蓋不到 iPad 推入的設定頁；使用者選 L1。
- **只以 scenePhase 更新現在時間**：App 一直停在前景跨午夜時不會更新；使用者選加監聽系統重大時間變更。

## Impact

- Affected specs: campaign-management, campaign-write-ordering, campaign-calendar-reminder, app-layer-boundaries, app-settings
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift (2026-10-03 起另加 `refreshDateContext(_:)`)
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignGrouping.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDateSection.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignSubgroup.swift
    - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService.swift (只修 1 筆機械問題)
    - apps/ios/BuyLedger/Features/App/RootFeature.swift (訂單投影改 `withLock`、深連結改推入詳情、開團 delegate；2026-10-03 起整檔：殼層重構)
    - apps/ios/BuyLedger/Features/App/RootTabLayout.swift (開團分頁改呈現 `CampaignView`；2026-10-03 起改送 `.view(...)`、「更多」改呈現 `MoreView(store:language:)`)
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift (同上，另抽出 `SidebarSmartGroup`)
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedger/Features/App/RootTab.swift
    - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
    - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
    - apps/ios/BuyLedger/Features/App/AppLockView.swift
    - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
    - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift (只改 Preview 的 State 建構)
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift (只加 `delegate(.aiSettingsRequested)`，B 組只查 diff)
    - apps/ios/BuyLedger/App/BuyLedgerApp.swift
    - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift (只加開團寫入失敗旗標；2026-10-03 起整檔：拆出 5 個列舉)
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings (只移除「無法載入主檔管理頁面，請稍後再試。」一個 key)
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift (只加詳情分貨列與收款鍵 identifier；2026-10-03 起整檔：依區域拆檔)
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
    - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift (與其 `+<職責>.swift`；2026-10-03 起客戶投影斷言改讀 `more.orders`)
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift (只改開團相關的 5 條與 `setOrdersAndProjections` helper；2026-10-03 起整檔：拆檔與殼層遷移)
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
    - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift (補 `withLock` 寫入與可寫引用外傳的偵測；2026-10-03 起整檔：拆檔、第三條規則)
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift (只同步開團 View 搬檔後的路徑；2026-10-03 起整檔：拆檔與改寫)
    - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift (只加新旗標的解析測試；2026-10-03 起整檔)
    - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
    - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
    - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
    - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
    - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift (根 store 宿主白名單縮為三個；使用者 2026-10-03 裁決整檔合規並拆檔)
    - apps/ios/BuyLedgerTests/** 與 apps/ios/BuyLedgerUITests/** 的全部測試檔：移除 `// MARK: - Tests` 分區 (使用者 2026-10-04 裁決；本 change 其他部分沒動到的測試檔只刪這一行與其後空行)
    - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift (只刪除「更多」備援畫面的 snapshot，B 組只查 diff)
    - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift (配合 `SidebarSmartGroup` 改名並整檔合規，task 8.9)
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift (只加新旗標；2026-10-03 起整檔)
    - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift (只加收款與分貨列的操作；2026-10-03 起整檔：拆 3 檔)
    - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift (2026-10-03 起整檔)
    - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift (2026-10-03 起整檔)
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift、CampaignCrudTests.swift (配合開團畫面拆分、詳情與表單流程改寫的 UI 測試，task 3.1 至 8.3)
    - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift、Tests/Orders/OrderDetailTests.swift、Tests/Orders/AISummaryTests.swift (配合殼層、App 鎖定與深連結改動的 UI 測試，task 8.2、9.1 至 9.3)
    - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift (只改呼叫端：配合 `BLUITestConfiguration.shouldResetPersistentStore` 改名)
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift (2026-10-04 起整檔：使用者裁決，task 11.5)
    - apps/ios/BuyLedgerTests/FxFeatureTests.swift (新增匯率傳輸失敗測試，task 11.3)
    - apps/ios/BuyLedgerTests/CampaignServiceTests.swift 與其 `+Decoding`、`+Delete`、`+DeleteFailure`、`+SaveFailure` (task 7.3 style 閘門：A 組開團測試整檔合規、改用 `Campaign.fixture`)
    - apps/ios/BuyLedgerTests/CampaignReminderServiceTests.swift (同上)
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
    - .claude/rules/ios-accessibility-localization.md (`LocalizationCatalogTests` 拆檔後同步規則檔的載入路徑與引用檔名)
    - .claude/rules/ios-data-layer.md
    - .claude/rules/ios-integrations.md
    - .claude/rules/ios-navigation.md
    - .claude/rules/ios-unit-tests.md
    - .claude/rules/ios-ui-tests.md
    - openspec/changes/campaigns-style-compliance/reference/style_checks.py (2026-10-03 起 `B_GROUP`、`EXISTING_OVER_LIMIT`、`GUARDX`、`Array` 擴充段名；2026-10-04 起測試檔不允許 `// MARK: - Tests`)
  - New:
    - apps/ios/BuyLedger/Features/Campaigns/CampaignView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature+Destination.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature+Path.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderReconcile.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderRequest.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignWritesFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignRequest.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationQueue.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignSavePlan.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDateSectionBuilder.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignSectionTitle.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDateContext.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailContent.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDraft.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignStatusStyle.swift
    - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignSectionList.swift
    - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignRow.swift
    - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailInfoSection.swift
    - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailSettlementSection.swift
    - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailDistributionSection.swift
    - apps/ios/BuyLedger/Core/Domain/CampaignSummary.swift (由 Features/Campaigns 搬入)
    - apps/ios/BuyLedger/Core/Domain/CampaignDistributionRow.swift
    - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService.swift (由 Core/Dependencies 搬入)
    - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Dependency.swift (由 Core/Dependencies 搬入)
    - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Preview.swift (由 Core/Dependencies 搬入)
    - apps/ios/BuyLedger/Features/App/RootNavigationOperations.swift
    - apps/ios/BuyLedger/Features/App/RootCascadeOperations.swift
    - apps/ios/BuyLedger/Features/App/SidebarSmartGroup.swift
    - apps/ios/BuyLedger/Features/App/AppScenePhase.swift
    - apps/ios/BuyLedger/Features/App/AppLockFormatters.swift
    - apps/ios/BuyLedger/Features/App/Data/SignificantTimeChangeService.swift、`+Dependency.swift`、`+Preview.swift`
    - apps/ios/BuyLedger/Features/More/MoreFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature+Destination.swift
    - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthService.swift、`+Dependency.swift`、`+Preview.swift` (由 Features/App/Data 搬入)
    - apps/ios/BuyLedger/App/Testing/BLUITestLanguage.swift、BLUITestCalendarAccess.swift、BLUITestBiometricScenario.swift、BLUITestLoadFailure.swift、BLUITestPersistenceMode.swift (由 BLUITestConfiguration 拆出)
    - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestOverrides.swift (由 BLUITestDependencyOverrides.swift 改名)
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift、`+App`、`+Dashboard`、`+Orders`、`+Campaigns`、`+Insights`、`+More` (由 BLAccessibilityID 拆出)
    - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen+Content.swift、CampaignDetailScreen+Toolbar.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests+<職責>.swift (由 CampaignFeatureTests 拆出，職責見 design「測試拆檔與寫法」)
    - apps/ios/BuyLedgerTests/CampaignListFeatureTests.swift (超過 300 行時以 `+<職責>.swift` 再拆)
    - apps/ios/BuyLedgerTests/CampaignDetailFeatureTests.swift (同上)
    - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests.swift (取代 CampaignReminderFailureTests；同上)
    - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests.swift (超過 300 行時以 `+<職責>.swift` 再拆)
    - apps/ios/BuyLedgerTests/CampaignReminderReconcileTests.swift
    - apps/ios/BuyLedgerTests/CampaignSavePlanTests.swift
    - apps/ios/BuyLedgerTests/CampaignPresentationQueueTests.swift
    - apps/ios/BuyLedgerTests/CampaignDetailContentTests.swift
    - apps/ios/BuyLedgerTests/CampaignDateSectionBuilderTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+Campaigns.swift
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Campaigns/ 下的開團基準圖 (七張於 task 0.4 改動前錄製，英文月分組一張於本地化修正後錄製)
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift 與 `__Snapshots__/SnapshotTests+CampaignDetail/` 下的三張改動前基準圖 (task 0.4 錄製；詳情兩條與編輯表單一條)
    - apps/ios/BuyLedgerTests/SnapshotTests+CampaignFixtures.swift (開團 snapshot 共用的訂單資料)
    - apps/ios/BuyLedgerTests/CampaignIntegrationTests+<職責>.swift、CampaignSummaryTests+<職責>.swift、CampaignDateSectionBuilderTests+<職責>.swift、CampaignEditFeatureTests+Init.swift、CampaignEditFeatureTests+Binding.swift、CampaignSavePlanTests+Conflicts.swift (拆檔)
    - apps/ios/BuyLedgerTests/CampaignReminderRequestTests.swift
    - apps/ios/BuyLedgerTests/Campaign+Fixture.swift (開團測試共用 fixture，task 7.3 使用者裁決)
    - apps/ios/BuyLedgerTests/TestDependencies+Calendar.swift (測試共用的 UTC 曆法)
    - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift、`+PaymentMethodCorrection`、`+LookupRename`、`+LookupSync`、`+Campaigns`、`+DeepLinks`、`+Fixtures`、`+AppShell`、`+Sidebar` (由 RootFeatureTests 拆出與新增)
    - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift、`+Patterns`、`+SourceStripping`、`+RootProjections`
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift、`+Scenarios` (由 ActionGroupingScanTests 拆出，2026-10-03 整檔合規)
    - apps/ios/BuyLedgerTests/AppLockFeatureTests+Formatters.swift (由 AppLockFeatureTests 拆出，搭配 `AppLockFormatters`)
    - apps/ios/BuyLedgerTests/LayerBoundaryTests+Scanner.swift、`+Patterns`、`+SourceStripping`、`+FileScan` (由 LayerBoundaryTests 拆出)
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests+AppLanguage.swift、`+SourceGuards`、`+LiteralScan`，以及 String+SourceLiteralScan.swift、SourceTextScanner.swift、SourceTextScannerTests.swift
    - apps/ios/BuyLedgerTests/BLUITestConfigurationTests+InvalidValues.swift
    - apps/ios/BuyLedgerTests/MoreFeatureTests.swift、MoreFeatureTests+Relays.swift
    - apps/ios/BuyLedgerTests/SettingsFeatureTests+AppLock.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests+AIDisabledAlert.swift
    - apps/ios/BuyLedgerTests/AppScenePhaseTests.swift
    - apps/ios/BuyLedgerTests/SignificantTimeChangeServiceTests.swift
    - openspec/changes/campaigns-style-compliance/reference/style_checks.py
  - Removed:
    - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
    - apps/ios/BuyLedger/Core/Dependencies/CampaignService.swift
    - apps/ios/BuyLedger/Core/Dependencies/CampaignService+Dependency.swift
    - apps/ios/BuyLedger/Core/Dependencies/CampaignService+Preview.swift
    - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
    - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
    - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
    - apps/ios/BuyLedger/Features/App/Data/BiometricAuthService.swift、`+Dependency.swift`、`+Preview.swift` (搬到 Core/Dependencies)
    - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift (改名)
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/moreViewMissingLookupManagementShowsUnavailableBaseline.1.png (備援畫面已不存在)
