# 7.22 開團呈現子 Feature 設計

Haiku 唯讀提案 (2026-10-09)，主對話審查後採用，比照 `716-design.md`。第 8 節待決事項的裁決：

- **D-1**：重名判定留在容器 (`ios-navigation.md`：需要父層資料的驗證由父層決定是否關閉表單)。
- **D-2**：一次性通知走 `noticeRequested` action (同 716 的 D3)。
- **D-3**：開系統設定由子層以 `.run` 直接呼叫，屬系統網址、非跨 Feature 導覽，不經容器。
- **D-4**：子層欄位名 `queue`，與 `OrdersPresentationFeature` 一致。
- **D-5**：容器主檔以 `style_checks.py` 實測，超過 300 停下回報，不登記例外。
- **D-6**：`CampaignView` 先用 key path 組合 `$store.scope(state: \.presentation.$destination, action: \.presentation.destination)`，build 不過再改 body 內 `@Bindable` 區域變數。
- **D-7**：測試只改路徑與補 `receive`；這些檔已於 7.13 整理，殘留違規由 7.1 第三輪處理。
- **D-8**：payload 遵循 `Equatable` 且能以字面值建立時，`receive` 帶值比對。
- **D-9**：`CampaignRequestPlan` 只改型別名。
- **D-10**：實作副本建於 7.17 整合之後。
- **分段**：先改 production (App target build 通過)，再由主對話跑測試後分批改測試路徑與補 `receive`，最後新增子 Feature 測試。


日期：2026/10/9
派工：haiku722 (task 7.22)，結構比照 openspec/changes/order-edit-style-compliance/reference/716-design.md。
本文件是唯讀設計：未修改副本或主 repo 的任何檔案。行數口徑為 reference/style_checks.py 的 LEN (檔頭 7 行之後、非空白行)。
副本路徑：/private/tmp/claude-501/-Users-leoho-Develop-BuyLedger/2dc39275-71e3-421d-9bcc-0c2f4e9e0532/scratchpad/haiku722/repo

==============================================================================
0. 摘要
==============================================================================

- 推薦方案：抽出無 View 的 CampaignPresentationFeature (新檔 Features/Campaigns/CampaignPresentationFeature.swift)，持有 destination 與 queue，以 Scope 組合於 CampaignFeature。
  Destination 型別隨之改為 CampaignPresentationFeature.Destination，檔案由 CampaignFeature+Destination.swift 改名搬移。
- 現況實測：CampaignFeature.swift 324 行，是相關檔案中唯一的 LEN 失敗。其餘 5 個相關檔 (CampaignFeature+Destination、+Path、CampaignPresentationQueue、CampaignRequestPlan、CampaignView) 通過。
- 抽離後草稿估算：容器 298 行 (上限 300，只剩 2 行餘量，見 R-1)；子 Feature 113 行；Destination 檔 187 行 (只改名)。
- 存檔的重名判定留在容器。ios-navigation.md 規定「需要父層資料的驗證 (如名稱衝突) 由父層決定是否關閉表單，拒絕時把原因寫回子層 State」。子層以同步 mutating 方法套用結果 (D3)。
- 一次性通知 (自動結單、提醒、寫入失敗) 改由 noticeRequested action 呈現 (D3)，比現況多一個 action 拍，見 R-3。
- 測試影響：新增 receive 約 35 至 40 處；destination 與 presentationQueue 路徑改寫約 185 與 57 行 (grep)；另有型別參照改名 (CampaignPresentationQueueTests 約 30 行)。
- 時序：uuid、date、calendar 的消耗次序與現況相同 (見第 6 節)；本流程不涉及 clock。
- 需主對話決定：D-1 至 D-10 (第 8 節)。

==============================================================================
1. 子 Feature 與 destination 的位置
==============================================================================

1.1 CampaignPresentationFeature (新，無 View)

- 檔案
  - Features/Campaigns/CampaignPresentationFeature.swift (主檔，新)
  - Features/Campaigns/CampaignPresentationFeature+Destination.swift (由 CampaignFeature+Destination.swift 改名搬移；內容只改型別名；檔頭第 2 行改為新檔名，建立日期保留原檔的 2026/10/2)
  - Features/Campaigns/CampaignPresentationQueue.swift (不變，只改型別參照)

- State (@ObservableState，Equatable)
  - @Presents var destination: Destination.State?
  - var queue = CampaignPresentationQueue()
    (名稱建議 queue，與 716 的 OrdersPresentationFeature.State.queue 一致，見 D-4)
  - 同步方法 (mutating，只改自己的 State，由容器在同一次更新內呼叫)：
    - present(_ destination: Destination.State)
      使用者觸發的表單或 alert，直接設定，不經佇列。與現行 handleRequest 的 .present、.edit 直接寫入等價。
    - finishFormClosing()
      var current = destination; queue.finishFormClosing(into: &current); destination = current。沿用現行的臨時變數寫法，避免 @Presents 直接以 inout 傳入時的存取重疊。
    - closeFormForSave()
      destination = nil; queue.beginFormClosing()。對應現行 save() 的兩行，順序不變。
    - showNameConflict()
      destination?.modify(\.edit) { $0.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。" }。
      訊息文字由現行容器移到子層，內容逐字相同。

- Action (沒有自己的 View，因此不設 view 分組，依 apps/ios/CLAUDE.md「沒有自己 View 的子 Feature 不設 view 分組」)
  - destination(PresentationAction<Destination.Action>)
  - noticeRequested(Destination.State)：一次性通知，經佇列呈現 (D3)。
  - delegate(Delegate)

- Delegate (Equatable)
  - saveRequested(CampaignEditFeature.SaveRequest)：表單本地驗證通過，請容器判定重名並決定是否儲存。
  - deleteConfirmed(Campaign.ID)：使用者確認刪除。
  - settleConfirmed(Campaign.ID)：使用者確認結團。

- Dependencies
  - @Dependency(\.openSettingsService) private var openSettingsService
    (D-3：建議由子層執行 .run，理由見 D-3)

- Body：Reduce(core).ifLet(\.$destination, action: \.destination)，與現行容器的組合形狀一致。

- 子層不持有 campaigns、reminderLinks、orders，也不取用 uuid、date、calendar (見 1.4)。

1.2 Destination (CampaignPresentationFeature+Destination.swift)

- extension CampaignPresentationFeature 內的 @Reducer enum Destination，case edit(CampaignEditFeature)、@ReducerCaseIgnored case alert(AlertState<Alert>)，以及 Action、Alert。內容不變，型別名改為 CampaignPresentationFeature.Destination。
- 既有的 Destination.State 靜態工廠 (autoCloseFailure、deleteConfirmation(for:)、settlementConfirmation(for:)、writeFailure(_:)、reminderFailure(_:)) 與 Equatable 擴充隨檔搬移，呼叫端改用 CampaignPresentationFeature.Destination.State.xxx。

1.3 容器 CampaignFeature (留存)

- State
  - 保留：campaigns、orders、isShowingUnpaidOnly、reminderLinks (皆 @Shared)、load、list、reminder、writes、path。
  - 新增：var presentation = CampaignPresentationFeature.State()。
  - 刪除：destination、presentationQueue、present(_ notice:)。
  - 保留方法：showDetail(campaignID:) 與 refreshDateContext(_:)。showDetail 留在主檔的理由見 R-8。
- Action (9 個)：view、delegate、path、presentation (取代 destination)、list、load、loadRequested、reminder、writes。
- Dependencies：date、calendar、uuid。openSettingsService 依 D-3 移到子層。
- Body：Scope(load)、Scope(list)、Scope(reminder)、Scope(writes)、Scope(presentation)，然後 Reduce(core).forEach(\.path, action: \.path)。
  presentation 的 Scope 放在 Reduce(core) 之前，與現行 Scope 子層的寫法一致。
  子層 core 先於子層 ifLet 執行，與現行容器的 core 先於 ifLet 相同 (R-5)。

1.4 destination 放容器或子層的取捨

- 決定：放子層 CampaignPresentationFeature。
- 理由
  - 派工目標 (7.22) 要求 destination、presentationQueue、存檔與呈現時序移到子層。
  - 表單與確認框的使用者意圖以 delegate 交給容器，比照 716 的做法。
  - 子層不持有 campaigns 與 reminderLinks，因此重名判定與提醒連結查詢留在容器，符合 ios-navigation.md 的規則 (D-1)。

==============================================================================
2. Action 次序與 core 的 case 清單
==============================================================================

2.1 容器 Action 次序 (與 core 的 case 順序一致)
  view、delegate、path、presentation、list、load、loadRequested、reminder、writes。
  (7.17 的主對話判定要求 path 排在 destination 之前；本次把 destination 換成 presentation，位置不變。)

2.2 容器 core (依 Action 宣告順序)

| 序 | Action | 處理 |
|---|---|---|
| 1 | view(.task) | .send(.reminder(.linksRequested))，不變 |
| 2 | view(.formSheetDismissed) | state.presentation.finishFormClosing()；.none (同步，不經 action) |
| 3 | delegate | .none |
| 4 | path(.element(_, .detail(.delegate(.requested(r))))) | handleRequest(r)，不變 |
| 5 | path | .none |
| 6 | presentation(.delegate(.saveRequested(r))) | save(r)，見 2.4 |
| 7 | presentation(.delegate(.deleteConfirmed(id))) | 以 state.campaigns 找名稱，找不到回 .none；找到則 .send(.writes(.deleteRequested(id:name:)))，與現行一致 |
| 8 | presentation(.delegate(.settleConfirmed(id))) | .send(.writes(.settleRequested(id)))，與現行一致 |
| 9 | presentation | .none |
| 10 | list(.delegate(.requested(r))) | handleRequest(r)，不變 |
| 11 | list(.delegate(.loadRequested)) | .send(.load(.loadRequested))，不變 |
| 12 | list | .none |
| 13 | load(.delegate(.autoCloseFailed)) | .send(.presentation(.noticeRequested(.autoCloseFailure)))，原為同一次更新內的 state.present (R-3) |
| 14 | load | .none |
| 15 | loadRequested | .send(.load(.loadRequested))，不變 |
| 16 | reminder(.delegate(.failed(f))) | .send(.presentation(.noticeRequested(.reminderFailure(f))))，原為同步 state.present |
| 17 | reminder | .none |
| 18 | writes(.delegate(.saved(req?))) | .send(.reminder(.reconcileRequested(req)))，不變 |
| 19 | writes(.delegate(.renamed(from, to))) | .send(.delegate(.campaignRenamed(from:to:)))，不變 |
| 20 | writes(.delegate(.deleted(d))) | state.path.popDetail(campaignID:)；.concatenate(...)，不變 |
| 21 | writes(.delegate(.failed(f))) | .send(.presentation(.noticeRequested(.writeFailure(f))))，原為同步 state.present |
| 22 | writes | .none |

2.3 handleRequest (容器私有方法，依 CampaignRequestPlan 的 case 順序)
- .none：.none
- .showDetail(id)：state.showDetail(campaignID: id)；.none，不變
- .edit(original, link)：
    let form = CampaignEditFeature.State(original: original, link: link, id: uuid(), now: date.now, calendar: calendar)
    state.presentation.present(.edit(form))；.none
  (先組 let 的寫法比巢狀呼叫省 3 行，見 R-1。uuid() 的消耗點不變。)
- .present(d)：state.presentation.present(d)；.none
- .send(a)：.send(a)

2.4 save(r) (容器私有方法，次序與現行 save() 完全相同，只是入口由子層委派進來)
1. CampaignSavePlan.conflicts(...) 為真：state.presentation.showNameConflict()；.none。不消耗 uuid，destination 只多寫入重名訊息，表單維持開啟。
2. 否則 state.presentation.closeFormForSave()。
3. let id = request.original?.id ?? uuid().uuidString，新開團才消耗 uuid。
4. let plan = CampaignSavePlan.make(request:existingLink: state.reminderLinks[id], newID: id, calendar:)。
5. .send(.writes(.saveRequested(plan)))。

2.5 子層 core (CampaignPresentationFeature，依 Action 宣告順序)

| 序 | Action | 處理 |
|---|---|---|
| 1 | destination(.dismiss) | queue.markFormClosing(dismissing: destination)；.none，與現行一致 |
| 2 | destination(.presented(.edit(.delegate(.saveRequested(r))))) | .send(.delegate(.saveRequested(r)))，不改 State (D-1) |
| 3 | destination(.presented(.alert(.confirmDelete(id)))) | .send(.delegate(.deleteConfirmed(id)))，不改 State |
| 4 | destination(.presented(.alert(.confirmSettle(id)))) | .send(.delegate(.settleConfirmed(id)))，不改 State |
| 5 | destination(.presented(.alert(.openSettings))) | .run { await openSettingsService.open() } (D-3) |
| 6 | destination | .none |
| 7 | noticeRequested(n) | var current = destination; queue.present(n, in: &current); destination = current；.none |
| 8 | delegate | .none |

- 第 2 至 4 列不在子層改 State，表單與 alert 的關閉仍由容器決定 (closeFormForSave) 或由 PresentationAction 自動處理 (R-5)。
- 第 7 列沿用現行的臨時變數寫法，避免 @Presents 與 queue 的 inout 重疊存取。

==============================================================================
3. 計畫型別與刪除清單
==============================================================================

- CampaignRequestPlan.swift
  - case present(CampaignPresentationFeature.Destination.State)：只改型別名。
  - fulfill 的判斷與 case send(CampaignFeature.Action) 不變 (D-9)。
- CampaignSavePlan.swift：不變。
- CampaignPresentationQueue.swift：API 與檔名不變，型別參照改名。
- CampaignRequest.swift：不變。
- 刪除
  - CampaignFeature+Destination.swift (搬至子層檔名)。
  - CampaignFeature.State 的 destination、presentationQueue、present(_ notice:)。
  - 容器 Action 的 destination case。
  - 容器的 openSettingsService 依賴 (D-3 採子層執行時)。
  - 容器 core 中 destination 相關的 case，以及 handleRequest 中的 destination 直接寫入。
- 名稱改動：CampaignFeature.Destination 全部改為 CampaignPresentationFeature.Destination (參照位置見第 5 節)。
- 不改：RootFeature (7.23 另案)、CampaignFeature+Path.swift、CampaignFeature.State.showDetail 與 refreshDateContext、CampaignListFeature、CampaignDetailFeature。

==============================================================================
4. 各檔預估行數 (LEN 口徑)
==============================================================================

| 檔案 | 現況 | 估計 | 說明 |
|---|---:|---:|---|
| CampaignFeature.swift (M) | 324 (LEN 失敗) | 298 | 草稿以記憶體計算 (含 let form 寫法)，上限 300，餘量 2 |
| CampaignPresentationFeature.swift (A) | 新檔 | 113 | 草稿以記憶體計算 |
| CampaignPresentationFeature+Destination.swift (A，改名) | 187 | 187 | 只改型別名與檔頭第 2 行 |
| CampaignFeature+Destination.swift (D) | 187 | 刪除 | |
| CampaignPresentationQueue.swift (M) | 65 | 65 | 型別參照 |
| CampaignRequestPlan.swift (M) | 65 | 65 | 型別參照 |
| CampaignView.swift (M) | 69 | 約 69 | 綁定路徑與 typealias |
| CampaignPresentationFeatureTests.swift (A，測試) | 新檔 | 約 120 至 160 | 新子層單元測試 (5.6) |

- 現況 style_checks.py 明確清單 (6 檔：CampaignFeature、+Destination、+Path、CampaignPresentationQueue、CampaignRequestPlan、CampaignView)：TOTAL {'LEN': 1}，唯一失敗為 CampaignFeature.swift (324 行)。
- 估計方法：草稿在記憶體中組出，以 LEN 口徑計數，未寫入任何檔案。實作後須以實際檔案重算。

==============================================================================
5. 測試影響
==============================================================================

5.1 grep 計數 (apps/ios/BuyLedgerTests，grep 行數，未去重)

| 檔案 | destination | presentationQueue | @Test | 備註 |
|---|---:|---:|---:|---|
| CampaignFeatureTests.swift | 4 | 0 | 4 | |
| CampaignFeatureTests+DeletionReminder.swift | 10 | 0 | 3 | 含 confirmDelete |
| CampaignFeatureTests+Editing.swift | 5 | 0 | 3 | uuid .incrementing |
| CampaignFeatureTests+FailureTiming.swift | 14 | 15 | 3 | 通知與 saveButtonTapped |
| CampaignFeatureTests+FailureTimingFollowUp.swift | 12 | 9 | 2 | 通知、openSettings |
| CampaignFeatureTests+Fixtures.swift | 0 | 0 | 0 | 回傳型別改名 (settleAlert、deletionAlert、reminderFailureAlert、failureAlert、titledAlert) |
| CampaignFeatureTests+NameConflict.swift | 10 | 0 | 2 | 重名，saveButtonTapped 2 |
| CampaignFeatureTests+Presentation.swift | 38 | 16 | 8 | 最大的一檔，含 openSettings |
| CampaignFeatureTests+Reload.swift | 9 | 2 | 3 | 通知、confirm |
| CampaignFeatureTests+ReloadDelete.swift | 8 | 0 | 2 | confirm |
| CampaignFeatureTests+ReminderCancellation.swift | 8 | 3 | 1 | |
| CampaignFeatureTests+ReminderIntegration.swift | 8 | 3 | 3 | saveButtonTapped 2、uuid |
| CampaignFeatureTests+ReminderRename.swift | 4 | 2 | 1 | |
| CampaignFeatureTests+UnchangedName.swift | 13 | 3 | 3 | saveButtonTapped 3 |
| CampaignFeatureTests+WriteFailures.swift | 13 | 2 | 4 | 通知、confirm 2 |
| CampaignFeatureTests+Writes.swift | 6 | 0 | 2 | confirm 2 |
| CampaignIntegrationTests+Delete.swift | 3 | 0 | 1 | confirm 2 |
| CampaignIntegrationTests+Rename.swift | 6 | 1 | 1 | saveButtonTapped 1、uuid |
| RootFeatureTests+Campaigns.swift | 5 | 1 | 3 | campaigns. 前綴、saveButtonTapped 1、edit 2 |
| CampaignPresentationQueueTests.swift | 型別參照 30 | 0 | 13 | 只改型別名，語意不變 |
| 合計 (destination 欄) | 約 185 | 約 57 | | |

不需改動 (已核對)：CampaignFeatureTests+Navigation (path 15、showDetail 12，無 destination)、CampaignFeatureTests+Loading、+ReloadFixtures、+ReminderFixtures、CampaignIntegrationTests.swift、+Fixtures、+Navigation、+Receipt。

5.2 新增 receive 估計

- saveButtonTapped 14 處 (10 檔)：每處在原本的 receive(\.destination.presented.edit.delegate.saveRequested) 之後補 receive(\.presentation.delegate.saveRequested)。
  destination 為 nil 與 isFormClosing 的斷言，以及 NameConflict 的訊息斷言，移到新 receive 的 closure。
- confirmDelete 與 confirmSettle 約 15 至 17 處 (7 檔；其中 CampaignFeatureTests+Fixtures 的 2 處是 alert 字面值，不是 send)：每個送出點補 receive(\.presentation.delegate.deleteConfirmed 或 settleConfirmed)。
- openSettings 4 處 (3 檔，含 Fixtures 的字面值)：子層 .run，不增加 receive (D-3)。若改為 delegate，補 4 處。
- 通知 receive 約 5 至 9 處 (writes、reminder、autoClose 的失敗路徑)：補 receive(\.presentation.noticeRequested, 字面值 Destination.State)。
- 路徑改寫
  - .destination 改為 .presentation.destination。
  - .presentationQueue 改為 .presentation.queue (依 D-4)。
  - .campaigns.destination 改為 .campaigns.presentation.destination。
  - .edit 與 .path 的路徑不變 (path 留在容器)。
- 合計新增約 35 至 40 處 receive。

5.3 型別與 fixture 改名
- CampaignFeatureTests+Fixtures.swift 的回傳型別 (settleAlert、deletionAlert、reminderFailureAlert、failureAlert、titledAlert)。
- CampaignPresentationQueueTests.swift 的型別參照約 30 行；13 個 @Test 的語意與名稱不變。
- CampaignFeatureTests 的 initial.destination 設值改為 initial.presentation.destination；initial.presentationQueue 改為 initial.presentation.queue。

5.4 守門與其他
- ProjectionWriteBoundaryTests：CampaignFeature 的投影只有 orders，home file 仍是 Features/Campaigns/CampaignFeature.swift。子層不持有、不讀取 orders；showDetail 保留在主檔。無需改守門。
- ActionGroupingScanTests：CampaignView 的 store.send 只能送 view action。sheet 的 onDismiss 必須維持 store.send(.view(.formSheetDismissed))，不得改為 send(.presentation(...))。子層沒有 view 分組。
- TestSuiteIntegrityTests：子層與容器的 core 都不得有 default 分支；TestStore 不得設 exhaustivity = .off。
- SnapshotTests：沒有直接讀取容器 destination 的程式，畫面輸出不變，不重錄。
- UI 測試：沒有程式碼引用，行為不變。
- RootFeature 與 Dashboard、Insights 只有 CampaignFeature.State() 與 CampaignFeature.Action 的引用，以及註解，不需改動。

5.5 新增子層單元測試 (CampaignPresentationFeatureTests.swift，Swift Testing，字面值預期，依 ios-unit-tests.md)
- destination_表單送出名稱_轉交儲存意圖
- destination_確認刪除_轉交刪除意圖
- destination_確認結團_轉交結團意圖
- destination_前往設定_呼叫系統設定服務 (覆寫 openSettingsService)
- destination_關閉表單_標記關閉中
- destination_關閉提示_不標記關閉中
- noticeRequested_表單已關閉_直接呈現
- noticeRequested_表單開啟中_暫存且不取代表單
- present_直接呈現_不經暫存佇列
- finishFormClosing_有暫存通知_移入目的地
- closeFormForSave_送出儲存_關閉表單並標記關閉中
- showNameConflict_重名_寫入原因且表單維持開啟 (訊息為字面值)
約 12 條。State 方法可直接在測試中以 var state 呼叫，預期值為字面值。

5.6 變異建議 (交第二階段的主對話執行，設計階段不執行)
- M1：子層 core 的 .dismiss 移除 markFormClosing。預期轉紅：destination_關閉表單_標記關閉中 與 +FailureTiming 系列。
- M2：noticeRequested 改為直接 destination = n，繞過佇列。預期轉紅：noticeRequested_表單開啟中_暫存且不取代表單 與 +FailureTiming。
- M3：closeFormForSave 移除 beginFormClosing。預期轉紅：closeFormForSave 測試與 +FailureTiming。
- M4：showNameConflict 改為 destination = nil。預期轉紅：showNameConflict 測試與 +NameConflict。
- M5：容器 save 把 uuid() 提前到衝突判定之前。預期轉紅：使用 .incrementing 的 +Editing 與 +ReminderIntegration (依實際結果確認)。
- M6：子層 confirmDelete 送出錯誤的 id。預期轉紅：destination_確認刪除_轉交刪除意圖。

==============================================================================
6. 時序風險 (uuid、date、clock 消耗次序)
==============================================================================

- uuid
  - 現況消耗點：(a) handleRequest 的 .edit 於同一次更新內；(b) save 新開團時，於衝突判定與 closeFormForSave 之後。
  - 設計後：(a) 不變；(b) 次序不變，仍在 closeFormForSave 之後、CampaignSavePlan.make 之前。改變的只有 save 的入口，由子層委派回到容器那一拍。
  - 同一流程內沒有其他 uuid 消耗者 (writes、reminder 不使用 uuid)，.incrementing 的計數不變。
- date.now 與 calendar：只在 .edit 的 CampaignEditFeature.State 建構與 CampaignSavePlan.make 使用，都留在容器，消耗次序不變。子層不取用這些依賴。
- clock：CampaignFeature 與新子層都不取用 clock，沒有 sleep 與延遲。
- 新 hop 的執行機制
  - Effect.send 實作為 .publisher(Just(action))，見本機 TCA checkout (1.26.2) 的 Effect.swift:147-149。
  - publisher 經 AsyncStream 在 effect 的 Task 中送出，見 Internal/EffectActions.swift:8-20。因此 hop 之間不是同一個同步呼叫堆疊，理論上可能插入其他已排隊的主執行緒事件。
- 對呈現的影響
  - save：destination = nil 與 beginFormClosing 仍在容器的同一次更新內完成，但比現況晚一拍。表單在這一拍內保持開啟，實際上不會被使用者看見。TestStore 需要 receive。
  - notice：由同一次更新改為下一拍。佇列的不變式 (表單開啟或關閉中先暫存、關閉回呼才取出) 不依賴拍數，最終呈現相同，由 +FailureTiming 系列驗證。
  - formSheetDismissed：仍是容器的同步呼叫，不增加拍數。
  - dismiss：子層 core 先於子層 ifLet 執行，markFormClosing 時 destination 仍為表單，與現況相同。

==============================================================================
7. 風險、替代方案與推薦
==============================================================================

- R-1 容器行數 (最大風險)
  - 草稿估算 298，餘量 2。
  - 已計入估算的節省：destination 的 ifLet 隨子層移出 (容器 body 少一行)；.edit 改為 let form 寫法 (省 3 行)。
  - 不可用的壓縮
    - 把 showDetail 外移到 CampaignFeature+Path.swift：守門不會失敗 (Features/Campaigns/ 內 $orders 只允許 SharedReader(...) 唯讀寫法，見 ProjectionWriteBoundaryTests+Scanner.swift:149-166)，但 apps/ios/CLAUDE.md 規定投影擁有者的主檔以外不接收 inout 容器 State，showDetail 是容器 State 的 mutating 方法，依規則文字不建議外移。
    - 刪除 kit 要求的 /// 文件：每個宣告都需要。
    - 不把 ARG4 規則要求的參數斷行合併成一行。
  - 若實作後超過 300：停下回報，不自行登記例外。備案 (需主對話裁決)：
    (a) 把 save 的衝突判定與計畫組裝抽成 CampaignSavePlan 的值型別，uuid 必須在衝突判定之後才消耗，因此需以閉包延後呼叫，約省 3 至 5 行。
    (b) 把 .edit 的表單建構改為子層 action，多一個 hop，約 10 至 15 處新 receive，不推薦。
    (c) 把 save 委派給子層，需要子層持有 SharedReader 自行判定重名，違反 ios-navigation.md 的父層決定規則，不推薦。

- R-2 receive 的比對力度
  - TestStore.receive(\.case) 只比對 case，不比對 payload (TestStore.swift:1388-1420)。帶值的 overload 才比對 payload (TestStore.swift:1654 起)。
  - 既有的 saveRequested 與 writes receive 多為 case-only。
  - 新增 receive 建議帶值：deleteConfirmed 與 settleConfirmed 的 id、noticeRequested 的 Destination.State 字面值。
  - saveRequested 的 SaveRequest 若要帶值比對，需以字面值建構 (D-8)。

- R-3 通知時序 (D3)
  - 通知由同一次更新改為下一拍，見第 6 節。
  - 若主對話不接受多一拍，替代做法是容器以同步 mutating 方法 state.presentation.present(...) 直接呈現通知。這與 D3「一次性通知維持 action」不符，需要裁決 (D-2)。

- R-4 共享狀態的斷言位置
  - ios-unit-tests.md 規定：effect 鏈中 reducer 以 withLock 寫入的共享變更，寫在觸發該鏈的 send 之後的第一個 receive。
  - 新 hop 會改變「第一個 receive」的位置。凡斷言 campaigns 或 reminderLinks 變化的測試，需逐檔核對，例如 +Rename、+ReminderRename、+Reload、+ReloadDelete。

- R-5 alert 自動清空
  - 純 AlertState 的 ifLet 收到 .presented 後，會在 base reducer 之後自動清空呈現 (ios-unit-tests.md)。
  - 子層 core 先於 ifLet 執行，所以 confirmDelete 與 confirmSettle 的 delegate 仍會送出。
  - 測試中 destination = nil 的斷言仍放在 send 的 closure，依實際行為核對。

- R-6 任務依賴
  - tasks.md 的 7.22 標示 [after: 7.17]，但 7.17 仍是未勾選狀態。
  - 副本 baseline 的 CampaignFeature 已符合 7.17 的 Action 次序要求 (view、delegate、path、destination...)，.path 與 .list 的 case 本體也未超過十行。
  - 需主對話確認：副本中的 CampaignFeature.swift 是否已包含 7.17 的改動。若否，7.22 與 7.17 會在同一檔衝突。

- R-7 規則張力
  - apps/ios/CLAUDE.md 的「父層要求子層載入或套用資料時，送專用請求 action」與 D3 (同一次更新內以子 State 的同步方法套用) 有張力。
  - 本設計依 D3，該裁決已由使用者於 716 採用。7.21 需把 D3 的分工登記進 CLAUDE.md。

- R-8 守門：$orders
  - 子層不持有也不讀取 orders，不觸及 orders 守門。showDetail 留在容器主檔的理由是 apps/ios/CLAUDE.md「投影擁有者的主檔以外不接收 inout 容器 State」(掃描器只檢查 inout CampaignFeature.State 參數的文字，見 ProjectionWriteBoundaryTests+Scanner.swift:293-319，不檢查 mutating 方法)。

==============================================================================
8. 需要主對話決定的事項
==============================================================================

- D-1 (存檔判定位置)
  - 推薦 (B)：容器判定重名，子層以 closeFormForSave 與 showNameConflict 套用結果。符合 ios-navigation.md 的規則。代價是每次儲存多一拍，約 14 處 receive，並且 destination 斷言移位。
  - 替代 (A)：子層持有 SharedReader，自行判定重名。少一拍，但違反「父層決定是否關閉表單」，不推薦。

- D-2 (一次性通知)
  - 推薦 D3：noticeRequested action，經 .send 送出，多一拍 (R-3)。
  - 替代：容器同步呼叫子層 present(notice)，與 D3 不符。

- D-3 (openSettings)
  - 推薦：子層以 .run 直接呼叫 openSettingsService。不增加 hop，子層的 alert 與該服務同處。
  - 替代：子層 delegate(.openSettingsRequested)，由容器執行 .run，約 4 處新 receive。

- D-4 (命名)
  - 子層 State 欄位推薦 queue，與 716 的 OrdersPresentationFeature.State.queue 一致；原名 presentationQueue。
  - 型別名 CampaignPresentationFeature.Destination 與 CampaignPresentationQueue 保持不變。

- D-5 (行數餘量)
  - 容器草稿 298，餘量 2。推薦：實作後超過 300 即停下，依 R-1 的備案由主對話裁決。

- D-6 (CampaignView 綁定)
  - 推薦 V1：以 key path 組合
      $store.scope(state: \.presentation.$destination, action: \.presentation.destination)
    alertBinding(isDetail:) 的簽章、sheet 的 .edit、onDismiss 皆不變。typealias AlertAction 改為 CampaignPresentationFeature.Destination.Alert。
  - 替代 V2：在 body 內以 @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation) 建立區域變數，再把它傳入 alertBinding。
  - 兩者都需要 build 驗證，swiftc -parse 抓不到這類型別錯誤。

- D-7 (Given 直設)
  - ios-unit-tests.md 與 gate71 裁決 3 要求能直接設進初始 State 的 Given 不用 send。
  - 推薦本 task 只改路徑並補 receive，不擴大為 Given 重寫。若主對話要求一併套用，需另列檔案與 receive 數。

- D-8 (receive 的比對力度)
  - 推薦 deleteConfirmed、settleConfirmed、noticeRequested 帶值比對。
  - saveRequested 可比照既有寫法 (case-only 加狀態閉包)，或以字面值 SaveRequest 帶值比對。

- D-9 (計畫型別)
  - 推薦 CampaignRequestPlan 只改型別名，不收窄 .send(CampaignFeature.Action)。
  - 替代：收窄為 writes 與 delegate 專用型別 (與 716 的 OrdersRequestOutcome 做法一致)，但改動範圍較大。

- D-10 (7.17 順序)：同 R-6，需確認 7.17 已完成或副本已含其 CampaignFeature 改動。

- 附註 (不改)：CampaignView 的 typealias 全名化。gate71-round2 只列 OrdersCompactView 與 OrdersView，未列 CampaignView，本設計不改。

==============================================================================
9. 文件同步 (由 7.21 處理，第二階段不改)
==============================================================================

- .claude/rules/ios-navigation.md
  - 第 50 行：同一 destination 的表單與 alert 的描述。
  - 第 54 行：「開團的容器 CampaignFeature 是唯一呈現者」，改為容器持有的呈現子 Feature。
- .claude/rules/ios-integrations.md 第 40 行：提醒失敗由容器統一呈現，需對應新結構。
- .claude/rules/ios-data-layer.md 第 41、63 行：確認資料來源與提示流程是否需要更新。
- apps/ios/CLAUDE.md
  - 架構分層中「父層要求子層載入或套用資料時」一條：登記 D3 的同步子 State 方法例外。
  - 第 169 行：CampaignFeature 的 @Shared 持有，補上 CampaignPresentationFeature 的分工。
- apps/ios/README.md 第 40 行：Campaigns 目錄說明加入 CampaignPresentationFeature。

==============================================================================
10. 讀取範圍與約束紀錄
==============================================================================

- 讀取
  - 派工單與 impl6a/rules.md。
  - 副本的 openspec/changes/order-edit-style-compliance/：reference/716-design.md、gate71-round1.md、gate71-round2.md、design.md (拆檔方式、7.1 第一與第二輪修正、Implementation Contract)、tasks.md (7.17、7.21、7.22、7.23)、reference/style_checks.py (口徑)。
  - 副本的 apps/ios/BuyLedger/Features/Campaigns/ 相關檔案，以及 RootFeature、Dashboard、Insights 中的引用行。
  - 副本的 apps/ios/BuyLedgerTests：CampaignFeatureTests 系列、CampaignIntegrationTests 系列、RootFeatureTests+Campaigns、CampaignPresentationQueueTests、ProjectionWriteBoundaryTests、ActionGroupingScanTests。
  - 副本的 apps/ios/CLAUDE.md、.claude/rules/ios-navigation.md、ios-unit-tests.md、ios-integrations.md、ios-data-layer.md。
  - ios-dev-kit：SKILL.md、references/tca-architecture.md (拆分與 Feature 型別)、assets/templates/tca/Feature.swift。
- TCA 查證：本機 checkout (DerivedData/BuyLedger-7e23f7e00e0e/SourcePackages/checkouts/swift-composable-architecture，版本 1.26.2，與副本 Package.resolved 相同)。查證項目：Effect.send (Effect.swift:138-149)、Internal/EffectActions.swift、TestStore.receive 的 case-only 與帶值 overload (TestStore.swift:1388-1420、1654 起)。
- 約束事故 (如實揭露)
  - 查 TCA 版本時，曾以 /Users/leoho/Develop/BuyLedger/apps/ios/BuyLedger.xcodeproj/... 的路徑執行一次 grep，讀到主 repo 的 Package.resolved 中 TCA 的 identity、location、version 三行。
  - 這違反派工單「絕對不可讀取或修改 /Users/leoho/Develop/BuyLedger」。該次為唯讀，未寫入任何檔案，之後版本確認改用副本路徑。
- 寫入：本設計檔 722-design.txt 是唯一寫入的檔案。未修改副本或主 repo 的任何檔案；未執行 build、test、模擬器、spectra 或 git 寫入指令；style_checks.py 與 grep 皆為唯讀；草稿行數以記憶體計算，未寫入檔案。
