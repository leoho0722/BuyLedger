# 7.1 第二輪紀錄 (2026-10-09)

第一輪後有改動的 222 檔分 14 組唯讀重審 (未改動的 61 檔沿用第一輪結論，經比對沒有未修的第一輪違規)。行號為審查當下位置，修正時以符號名稱為準。

## 判定原則補充
- 開團整合測試 (`CampaignIntegrationTests*`) 名稱本身描述入口流程 (列表刪除、列表編輯、深連結後操作) 時，沿真實入口建立前置屬受測流程的一部分，不算違規。
- 單一本地化 key 帶插值 (`Text("訂單照片 (\(n)/\(max))")`) 是呈現，不算畫面組字；有條件判斷或字串拼接才要移出。
- 註解裡指稱程式碼中實際存在的變數或成員 (例如測試的 `store` 變數) 加反引號屬正確。
- `} ?? x`、`}?.x` 接在多行 closure 後屬允許。`throws(any Error)` 在測試 helper 不算違規。

## 必修 (依組)
- g11 `RootFeatureTests+DefaultCurrency`：`orders_改預設幣別時已開草稿_維持原幣別` 第一段改 `more_`；`orders_預設改為日圓後開新訂單_…` 的 Given send 改直設 (`makeIsolatedRootState { RootFeature.State(preferences:) }`)；`orders_預設日圓合併確認韓圓訂單_保留韓圓` 的 Given 三段無作用 send 鏈移除。
- g11 `RootFeatureTests+LookupSync`：Then 段 receive 與 `#expect` 之間的空行。
- g06 `CampaignIntegrationTests+Fixtures`：`rebuilt` 的摘要「預期訂單副本」改為與用途一致 (Given 輸入)。
- g10 `OrdersSearchCancellationTests`：`static let orders` 改 `private`。
- g10 `ProjectionWriteBoundaryTests+Patterns`／`+Scanner`：`property`、`owner` 若是程式碼識別字才加反引號 (實作者讀上下文判斷)。
- g10 `RootFeatureTests+Campaigns`：`campaigns_開團改名_同步更新多開團訂單` 的 Given 改直設編輯表單 (不送開表單 action，改名走 `\.draftName` 或直接設草稿)；`campaigns_切換開團收款狀態_更新所有頁面的訂單` 的推入詳情改 `showDetail(campaignID:)` 直設。
- g03 `OrderDraft+WriteResult`：Private Method 區 static 方法排在 instance 方法之前。
- g03 `OrderEditView`：`@FocusState private var focusedField` 排在 store 之後。
- g03 `OrderEditFeature`／`OrderEditDraftOperations`：`apply(_ action: Action, state:)` 收整個 Action 再 switch，改為依 case 傳具體 payload (binding、photos、pickers 各自的處理方法)，`core` 不變。
- g03 `OrderEditPhotosFeature`：`photosImported(PhotoImportResult)` 改 `photoImportResponse(PhotoImportResult)` (內部回應命名)，同步測試。
- g14 `ProjectionWriteBoundaryTests+Orders`：`ordersProjectionScenarios` 改 `private static var`，移入 Private Method 的 `private extension`。
- g14 `RootFeatureTests+AISummaryProjection`：`orders_偏好改動時已開啟的摘要_保留原模型` 第一段改 `more_`；`orders_偏好改動後重新開啟摘要_使用新模型` Given 裡關閉表單的 send (`.destination(.dismiss)`、`.view(.formSheetDismissed)`) 改直設。
- g12 `OrdersCompactListContent`：註解 `maxHeight` 加反引號。`String+SourceLiteralScan`：`SourceLineRange.contains(_:)` 改 `private`；註解 `braceDepth` 加反引號。
- g12 `BuyLedgerUITests/Screens/DashboardScreen`：`loadFailureDismissed(timeout:)` 改動詞式 (如 `waitForLoadFailureDismissal(timeout:)`)，同步 `DashboardLaunchLoadingTests` 呼叫端。
- g13 `OrderFilterFeatureTests`：兩個 `nonisolated static func makeState` 的 doc 補 `- Note` 說明 nonisolated 理由 (同 `OrderListFeatureTests` 既有寫法)。`OrderFormattersTests`：`static let locale` 改 `private`。
- g08 `OrderEditFeatureTests+Merge`：`- Note` 一則一事拆開。`OrderMergeFeatureTests.makeOrder`：參數說明不只複述名稱。`OrderEditFeatureTests` 的 `MergeEditCase` doc「預期值」改為「要寫入的值」。
- 主對話 (build 判定)：同檔已 `import SwiftUI` 又 `import Foundation` 的檔 (g13 V3、g08 V1 等) 移除 `Foundation`，以 build 驗證，編譯失敗的補回。
- g09 `OrdersFeaturePerformanceTests`：`makeOrders` 排在 `assertNoRegression` 之前 (依第一次被呼叫順序)。
- g09 `OrdersFeatureTests+FailureTiming`：`formSheetDismissed_關閉中連續兩則通知_只呈現最新一則` 的第一則通知改在 Given 直設，受測的第二則 `orderWriteFailed` 留在 When。
- g09 `OrdersFeatureTests+OptionWrites`：`list_新增後關閉表單再重開_只更新目錄不改新表單` 的開啟表單 A 改直設 (`initial.destination = .edit(formA)`)，新增選項與 dismiss 的效果鏈保留。
- g02 `OrderDetailCostView`、`OrderDetailSummaryView`、`OrderEditItemsSection`、`OrderFilterPreviewState`、`OrderMergeCandidateSheet`：View 建構函式與 `makeState` 的摘要改動詞開頭 (如「顯示…」「建立…」)。`OrderDetailView`：兩個 Preview 的 `store: Store(initialState: …(` 改由外而內斷行。`OrderMergeCandidateSheet`：註解 `locale` 加反引號。
- g02 `OrderDetailCostView`：圓餅圖 `components.map` 組 `BLDonutSegment` (Decimal 轉 Double 與 `valueDescription` 組字) 移到 `OrderCostBreakdown` 或 `OrderDetailFeature.State`，畫面只讀結果，輸出逐字相同、snapshot 不重錄 (production 改動，需補單元測試與變異)。
- g07 `CurrencyMetadataServiceTests+Refresh`：`#expect(after == before)` 的 `before` 改字面值 (`[CurrencyCode(rawValue: "TWD"), .usd]` 依實際資料)；`didRefresh` 改 `isRefreshed`。
- g07 `OrderDraftTests+Customer`、`+Photos`、`OrderEditCampaignOptionsTests`：最後一個 closure 參數改 trailing closure (7 處)。
- g07 `LocalizationCatalogTests` 的 `examples` 摘要改為描述整組；`ContrastComplianceTests` 第 139 行摘要刪掉「審查報告點名」等過程紀錄。
- g07 Q-5：`ContrastComplianceTests`、`LocalizationCatalogTests`、`+SourceGuards`、`OrderEditFeatureTests+Campaigns` 共 20 條測試名，逐條核對第一段是否對應 When 呼叫的方法、屬性或 action，不一致的改名。
- g01 `RootFeature`：core switch 次序與 Action 宣告一致 (`.persistenceFailure`、`.significantTimeChanged` 的位置)。
- g01 `CampaignFeature`：Action 依 view → delegate → destination／path → 其他排列並同步 switch；`.path`／`.list` case 本體超過十行抽 Private Method (超過 300 行依 kit 拆分)。`CampaignLoadFeature`：`.loadRequested` case 本體抽方法。`CampaignRequestPlan`：檔頭後連續空行。
- g01 `DashboardView` (4 處)、`InsightsView` (3 處)：`.fill` 在 `.frame` 之前，改 `.frame` 後接 `.foregroundStyle` (同 7.5 做法，snapshot 不重錄)。
- g01 `OrderDetailContentView`：`hasCardlessAdjustments`、`hasCostBreakdown` 移到 `OrderDetailFeature.State` (與 `hasNotes` 一致)。
- g04 `OrderListInteraction`：連續空行。`OrderMergeFeature`：State 的 private computed `filteredCandidates` 移到 init 之前。`OrderWritesFeature`：`.statusResponse(.success)` 拆出、switch 依宣告次序；四個超過十行的 case 抽 Private Method。`OrdersContainerPlan`：`requiresDateContext` 排在 `requiresFormID` 之前 (呼叫者在前)。`OrdersEditorOptions`：`make` 排在前，`orderSources`、`reconciliationStatuses` 只本檔使用改 private。`OrderSummaryPrompt`：`itemsDigest` 改 private (測試若直接呼叫，改驗證 `summaryPrompt`)。
- g04 `OrdersFeature`：body 內 `.onChange(of: \.hasLoaded)` 的多段邏輯抽 Private Method。`OrdersCompactView`、`OrdersView`：`typealias AlertAction` 改用全名。`OrderMergeFeature` 註解 `SwiftUI` 加反引號。
- g07／g02 `OrderEditStatusSection`：幣別名稱列的 `.lineLimit(1)` 依無障礙規則移除 (snapshot 若改變則還原並回報)。

## 不算違規
- g06 V-1～V-5 (整合測試入口)；g06 P-1 (`private extension` 放 nested type)、P-3 (`O1` 字面值反引號)。
- g14 V1／P5 (`reloadedOrders` 是測試替身記錄的回應，非受測程式產生；實際側正規化、預期為 Given 輸入)、P1 (Given fixture 的 `.id`)、P3 (第一段為被測 computed `filteredOrders`)、P4 (型別初始化式以 Given 變數為引數)。
- g12 V1 (`"篩選: \(summary)"` 單一本地化 key 插值)、P1 (分隔線屬版面)、P2 (含尾隨逗號 101 字元，維持斷行)、P3 (UI 前置檢查)、P4 (import 已由 7.14 build 判定)。
- g13 P1 (字面符號反引號)、P2 (單側正規化，預期為 Given 輸入)；g08 PJ2 (測試 doc 的架構用語)、PJ4 (六條點擊測試各自對應命名，不併參數化)、PJ5 (換算來回視為一個動作)。
- g09 V7-1 (`Decimal(string:) ?? 0`：浮點字面值會失準、強制解包被腳本擋)、V9-1 (`FormSheet` 是參數化測試的參數型別)、V9-2 (三種表單關閉判定為受測點)、V11-1／V12-2 (以初始化式建預期子 State)、V11-2 (合併確認的實際入口)、P1 (無編譯警告)、P2 (實作者已說明效果時序理由)。
- g02 P2 (單一本地化 key 插值)、P3 (`palette.secondaryLabel`，留給結案後的色盤重構)；g07 Q-1 (測試 Throws 用語)、Q-2 (值的反引號)、Q-4 (`if` 內帶標籤 closure)。
- g01 V-08 (單一本地化 key 插值)、P-01 (`Bool?` 在第 7 步的 `InsightsStats`)、P-02／P-03 (modifier 歸組維持)、P-05、P-06 (首頁分析頁畫面計算依 design 屬第 7 步)、P-07；g04 P1 (寫入 closure typealias)、P2 (輔助方法與 action 一一對應的命名)、P3 (git mv 改名檔)、P4、P5 (功能專屬 `StackState` 擴充)、P10 (超過十行規則抽出的方法)。
- g11 P-2、P-3；g10 V6 (`store` 指測試變數)、P-1 (載入次數守門)、P-2 (When 前等待讀取開始)、P-3、P-4；g03 V-04 (單一本地化 key 插值)、P-01、P-04。

## 使用者裁決 (第二輪)

1. `OrdersFeature` 容器在本 change 重做：`core` 依 Action 宣告順序 switch，每個 case 呼叫計畫型別的純計算方法 (計畫型別不再有吃整個 Action 的 `make`)；呈現佇列、合併轉場與 `destination` 開關時序抽成無 View 子 Feature 以 `Scope` 組合，主檔回到 300 行內。
2. 內部回應保留具體錯誤型別 (`Result<…, PersistenceError>` 等，與 Service 的 typed throws 一致)，登記為 kit 差異；不必改 `any Error`。
3. 命名類違規全部在本 change 改，連帶的檔一併整檔對齊：`shows…` Bool (`showsDate`、`showsUnpaidOnly`；篩選 picker 旗標若仍在也改)、縮寫 `Twd` → `TWD` (`monthlyProfitGoalTwd`、`minusTwd`／`plusTwd`／`signedTwd`)、`OrderEditStatusSection` 的 `.lineLimit(1)` 依無障礙規則移除 (snapshot 改變則回報)。
4. 訂單容器依 `reference/716-design.md` 抽兩個無 View 子 Feature (呈現、詳情導覽)，容器主檔硬性 300 行內；同一次更新內必須完成的呈現與導覽用子 State 的 `mutating` 方法，一次性通知維持 action。
5. 7.17 修正後超過 300 行的 `CampaignFeature`、`RootFeature` 在本 change 抽子 Feature：開團比照訂單抽呈現子 Feature (7.22)；Root 先出唯讀設計再實作 (7.23)。
6. 訂單容器實作後實測 359 行 (設計估 304)：登記有邊界的例外，只限 `OrdersFeature`、上限 359 行，6c 移走新增主檔選項的轉送後重量，回到 300 行內即撤銷；兩個子 Feature 與其他規則照舊 (`findings.md`「行數例外」、`apps/ios/CLAUDE.md` 由 7.21 登記)。

