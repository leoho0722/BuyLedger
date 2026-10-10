# 7.16 訂單容器重做設計

Haiku 唯讀提案 (2026-10-09)，主對話審查後經使用者裁決採用。以下第 7 節的待決事項已定案：

- **D1 (採用)**：抽兩個無 View 子 Feature，`OrdersPresentationFeature` 與 `OrdersDetailNavigationFeature`。
- **D2 (硬性，後改例外)**：原定容器主檔不超過 300 行；A 段實作後實測 359 行，使用者裁決登記有邊界的例外 (上限 359 行，6c 後重量，見 `findings.md`「行數例外」)。
- **D3 (State 方法)**：同一次更新內必須完成的呈現與導覽 (Root 開新訂單、寫入結果關閉表單或套用新增選項、顯示詳情、表單關閉收尾) 用子 State 的 `mutating` 方法，與既有 `showDetail` 一致；寫入失敗等一次性通知維持 action (`noticeRequested`)。此分工登記進 `apps/ios/CLAUDE.md` (7.21)。
- **D4 (分段實作)**：先改 production 結構 (App target build 通過)，再改既有測試路徑並補子 Feature 委派多出的 `receive` (依主對話實跑的失敗訊息逐批補，完整單元回歸通過)，最後新增子 Feature 與計畫型別的測試。commit 由使用者決定，不屬本設計。
- **D5 (接受)**：`OrdersFeature.Destination`／`Path` 隨搬移改為子 Feature 的巢狀型別；`OrderListFeature` 新增 `availablePaymentMethodNames`。
- **R7 (不採提案)**：`OrdersDetailNavigationFeature` 仍寫 `Reduce(core)`，`core` 依 Action 次序逐 case 回傳 `.none`，body 形狀與其他 Feature 一致。

行數為提案時依結構估計，實作後以 `style_checks.py` 同一口徑實測。

- 範圍：apps/ios/BuyLedger/Features/Orders/ 的訂單容器 OrdersFeature 與其計畫型別。
- 依據：
  - openspec/changes/order-edit-style-compliance/：tasks.md (7.16)、design.md (「Orders 拆成容器、清單、詳情與寫入四個 Feature」「容器是唯一呈現者」「7.1 第二輪審查後的修正」)、reference/gate71-round2.md。
  - apps/ios/CLAUDE.md、.claude/rules/ios-navigation.md、ios-data-layer.md。
  - ios-dev-kit：tca-architecture.md (拆分順序、body 與 core 規則)、formatting.md 與 file-templates.md (300 行上限與分檔)。
- 框架查證：TCA 1.26.2 (Package.resolved)。Context7 (/pointfreeco/swift-composable-architecture) 確認 dismiss 會以 PresentationAction.dismiss 把呈現狀態設為 nil；文件未明寫 Scope、ifLet 與父層 reducer 的執行先後，本提案不依賴該先後，見 §6 R1。
- 行數口徑：現況數字為 wc 實測，去除檔頭與空行。新檔與改後數字為依結構估計，實作後以同一口徑實測。

## 0. 摘要

- 推薦方案 PD：抽出兩個無 View 子 Feature。
  - OrdersPresentationFeature：destination、呈現佇列、合併轉場 500ms、destination 開關時序。
  - OrdersDetailNavigationFeature：iPhone 詳情堆疊 path、iPad 右欄 regularDetail，以及它們的同步與 pop 規則。
  - 容器只留 Root API、請求分派、清單事件與寫入結果套用。
- 只抽呈現子 Feature (方案 P) 時，容器估計約 365 行，超過 300，不能滿足 7.16 的行數驗收。
- PD 的容器估計約 334 行；套用壓線手段 L1 至 L5 (§4) 後約 304 行 (範圍 290 至 315)，仍可能超過 300。是否接受此風險、或要求硬性 300 而再拆，需主對話裁決 (§7 D2)。
- 行數超標的主因是 core 分派、Root API 與寫入結果套用，不是呈現本身。

## 1. 子 Feature 與 destination 的位置

### 1.1 OrdersPresentationFeature (新，無 View)

- 檔案：
  - Features/Orders/OrdersPresentationFeature.swift (主檔)。
  - Features/Orders/OrdersPresentationFeature+Destination.swift：由 OrdersFeature+Destination.swift 改名搬移，型別 OrdersFeature.Destination 改為 OrdersPresentationFeature.Destination，內容不變。
  - Features/Orders/OrdersPresentationQueue.swift：不變，只改型別參照。
- State (@ObservableState，Equatable)：
  - `@Presents var destination: Destination.State?`：表單與 alert，同一時間只有一個。
  - `var queue = OrdersPresentationQueue()`。
  - 同步方法，由容器直接呼叫 (理由見 §6 R6)：
    - `mutating func present(_ destination: Destination.State)`：使用者觸發的表單或 alert，直接設定，不經佇列 (與現行 fulfill 的直接寫入等價)。
    - `mutating func finishFormClosing()`：`queue.finishFormClosing(into: &destination)`。
    - `mutating func apply(_ outcome: OrdersWriteOutcome)`：處理 closesEditOf 與 addedOption，見 §3。
    - `mutating func presentMergeConfirmation(_ confirmation: Destination.State)`：`queue.presentMergeConfirmation(_:in:)`。
- Action (子層沒有自己的 View，因此不設 view 分組；父層轉送的請求與內部事件平放)：
  - `destination(PresentationAction<Destination.Action>)`
  - `mergeCandidateCompleted(OrderMerge.Draft, keptPhotos: [Data])`：父層算好草稿後送入，啟動 500ms 轉場。
  - `noticeRequested(Destination.State)`：寫入失敗等一次性通知，經佇列呈現。維持 .send，保留現行「下一個 action 才呈現」的時序 (§6 R3)。
  - `delegate(Delegate)`
- Delegate (子層把使用者意圖交給容器)：
  - `saveRequested(OrderEditFeature.State)`
  - `optionAddRequested(OrderOptionWritePlan)`
  - `deleteConfirmed(LedgerOrder.ID)`
  - `aiSettingsRequested`
  - `mergeCandidatesCompleted(primary: LedgerOrder, secondary: LedgerOrder, keptPhotos: [Data])`：草稿需要付款方式清單與現在時間，由容器計算。
  - `mergeConfirmationDue(OrderMerge.Draft, keptPhotos: [Data])`：500ms 到期，確認表單需要選項與表單 id，由容器建立。
- 依賴：`@Dependency(\.continuousClock)`，由容器移入。
- body：`Reduce(core).ifLet(\.$destination, action: \.destination)`，與現行容器相同的組合形狀。
- core (依 Action 宣告順序)：
  1. destination(.dismiss)：`queue.markFormClosing(dismissing: state.destination)`。
  2. destination(.presented(.edit(.delegate(.saveRequested))))：送 delegate(.saveRequested(edit))，edit 取自子層 state。
  3. destination(.presented(.edit(.delegate(.addOptionRequested(...)))))：以表單 id 組 OrderOptionWritePlan，送 delegate(.optionAddRequested)。
  4. destination(.presented(.merge(.delegate(.completed(...)))))：送 delegate(.mergeCandidatesCompleted)。
  5. destination(.presented(.alert(.confirmDelete(id))))：送 delegate(.deleteConfirmed(id))。
  6. destination(.presented(.alert(.goToAISettings)))：送 delegate(.aiSettingsRequested)。
  7. destination (其餘)：.none。
  8. mergeCandidateCompleted(draft, keptPhotos)：`destination = nil`，`queue.beginMergeTransition()`，回傳 .run。effect 內 `clock.sleep(500ms)` 後送 delegate(.mergeConfirmationDue)；取消時 (sleep 丟錯) 直接 return，與現行一致。
  9. noticeRequested(notice)：`queue.present(notice, in: &destination)`。
  10. delegate：.none。

### 1.2 OrdersDetailNavigationFeature (新，無 View；PD 才需要)

- 檔案：
  - Features/Orders/OrdersDetailNavigationFeature.swift (主檔)。
  - Features/Orders/OrdersDetailNavigationFeature+Path.swift：由 OrdersFeature+Path.swift 改名，Path 內容與 popDetail 不變。
- State：
  - `var path = StackState<Path.State>()`
  - `var regularDetail: OrderDetailFeature.State?`
  - `let orders: SharedReader<[LedgerOrder]>` (建立詳情需要)
  - 同步方法：`showDetail(orderID:)`、`syncRegularDetail(selectedOrderID:)`、`popDetail(orderID:)`、`popUnavailable(orders:)`、`apply(_ outcome: OrdersWriteOutcome)`。內部沿用 OrdersDetailSelection (不變)。
- Action：`path(StackActionOf<Path>)`、`regularDetail(OrderDetailFeature.Action)`。
- body：`EmptyReducer().forEach(\.path, action: \.path).ifLet(\.regularDetail, action: \.regularDetail) { OrderDetailFeature() }`。本子層沒有自身邏輯，因此不設 core (偏離見 §6 R7)。

### 1.3 容器 OrdersFeature (留存)

- State：
  - 保留：orders、list、lookupCatalog、currencyCodes、defaultCurrency、aiSummarySettings、campaigns (Root 投影，守門不變)、load、writes。
  - 新增：presentation、detail。
  - 刪除：destination、presentationQueue、path、regularDetail，以及 isLoading、hasLoaded、errorMessage 投影 (L1)。
  - 方法：applyFilterNavigation、refreshDateContext、presentNewOrder、makeEditOptions 保留，Root 與 RootNavigationOperations 的呼叫點不變。showDetail 與 syncRegularDetail 移到詳情子層。
- Action (12 個)：binding、view(View)、delegate(Delegate)、detail(OrdersDetailNavigationFeature.Action)、presentation(OrdersPresentationFeature.Action)、cascadeRequested、list、load、loadRequested、paymentMethodFlagsApplyRequested、receiptStatusChangeRequested、writes。
  - 刪除：path、regularDetail (改進 detail)、destination (改進 presentation)、mergeConfirmationReady、orderWriteFailed (改進 presentation)。
- Dependencies：uuid、date、calendar。continuousClock 移走。
- body：BindingReducer() → Scope(list) → Scope(load) 加 onChange(of: \.load.hasLoaded) (預設選取與 detail.popUnavailable) → Scope(writes) → Scope(presentation) → Scope(detail) → Reduce(core)。

### 1.4 destination 放容器或子 Feature 的取捨

- 決定：放子 Feature (OrdersPresentationFeature)。
- 理由：
  - 派工目標要求 destination 開關時序抽到子 Feature。destination 留在容器時，dismiss、formSheetDismissed、merge 轉場的判斷會分散在兩層，需要 delegate 來回設定 destination，時序更難驗證。
  - 存檔、加選項、刪除確認與 AI 設定的委派，子層自己知道目的地內容，不必由容器讀 state.presentation.destination?.edit 之類的路徑。
- OrdersView 影響：
  - 新增 `@Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)`，三個 sheet 與 regularAlertBinding 的綁定由 `$store.scope(state: \.$destination, action: \.destination)` 改為 `$presentation.scope(state: \.$destination, action: \.destination)`。
  - sendFormSheetDismissed 仍送 `.view(.formSheetDismissed)`，由容器轉到子層的同步方法。
  - typealias AlertAction 依 gate71-round2 改用全名，AlertBinding 改寫為 `Binding<Store<AlertState<OrdersPresentationFeature.Destination.Alert>, OrdersPresentationFeature.Destination.Alert>?>`。
- OrdersCompactView 影響：alertBinding 改用 presentation 子 store；path 綁定改為 `\.detail.path`，`store.path.isEmpty` 改為 `store.detail.path.isEmpty`。
- OrdersRegularDetailColumn 影響：`store.scope(state: \.regularDetail, action: \.regularDetail)` 改為 `store.scope(state: \.detail.regularDetail, action: \.detail.regularDetail)`。
- 測試路徑影響見 §5。

## 2. Action 順序與 core 的 case 清單

容器 Action 宣告順序 (與 core 的 case 順序一致)：binding、view、delegate、detail、presentation、cascadeRequested、list、load、loadRequested、paymentMethodFlagsApplyRequested、receiptStatusChangeRequested、writes。

core 依序的 case 與處理方式：

| 序 | Action case | 處理 (呼叫的計畫方法或回傳的 effect) |
|---|---|---|
| 1 | binding | .none |
| 2 | view(.formSheetDismissed) | state.presentation.finishFormClosing()；.none |
| 3 | delegate | .none (aiSettingsRequested 由 Root 接) |
| 4 | detail(.path(.element(_, .detail(.delegate(.requested(r)))))) 與 detail(.regularDetail(.delegate(.requested(r)))) | fulfill(r, state:) |
| 5 | detail | .none |
| 6 | presentation(a) | forwardPresentation(a, state:)，見下方 |
| 7 | cascadeRequested(r) | .send(.writes(.cascadeRequested(r))) |
| 8 | list(.delegate(.loadRequested)) | .send(.load(.loadRequested)) |
| 9 | list(.delegate(.requested(r))) | fulfill(r, state:) |
| 10 | list(.delegate(.selectionChanged)) | state.detail.syncRegularDetail(selectedOrderID: state.list.selectedOrderID)；.none |
| 11 | list | .none |
| 12 | load | .none |
| 13 | loadRequested | .send(.load(.loadRequested)) |
| 14 | paymentMethodFlagsApplyRequested(orders) | .send(.writes(.paymentMethodFlagsApplyRequested(orders))) |
| 15 | receiptStatusChangeRequested(id, status) | .send(.writes(.receiptToggleRequested(id:status:))) |
| 16 | writes(a) | applyWriteResult(a, state:)，見下方 |

各 helper 的內容：

- fulfill(_ request: OrderRequest, state: inout State) -> Effect<Action>
  - formID = OrdersContainerPlan.requiresFormID(request, state:) 為真時才 uuid()。
  - context = OrdersContainerPlan.requiresDateContext(request, state:) 為真時才 OrderDateContext(now: date.now, calendar: calendar)。
  - 呼叫 OrdersContainerPlan.fulfill(request, state:, context:, formID:) -> OrdersRequestOutcome，然後依值套用：
    - .none：.none
    - .present(d)：state.presentation.present(d)；.none
    - .showDetail(id)：state.detail.showDetail(orderID: id)；.none
    - .write(a)：.send(.writes(a))
- forwardPresentation(_ action: OrdersPresentationFeature.Action, state: inout State) -> Effect<Action>
  - delegate(.saveRequested(edit))：.send(.writes(.saveRequested(edit)))
  - delegate(.optionAddRequested(plan))：.send(.writes(.optionAddRequested(plan)))
  - delegate(.deleteConfirmed(id))：.send(.writes(.deleteRequested(id)))
  - delegate(.aiSettingsRequested)：.send(.delegate(.aiSettingsRequested))
  - delegate(.mergeCandidatesCompleted(p, s, kept))：draft = OrdersContainerPlan.mergeCandidateDraft(primary: p, secondary: s, state:, now: date.now)；.send(.presentation(.mergeCandidateCompleted(draft, keptPhotos: kept)))
  - delegate(.mergeConfirmationDue(draft, kept))：confirmation = OrdersContainerPlan.mergeConfirmation(draft:keptPhotos:state:formID: uuid(), context: OrderDateContext(now: date.now, calendar: calendar))；state.presentation.presentMergeConfirmation(confirmation)；.none
  - destination、mergeCandidateCompleted、noticeRequested：.none (列舉以維持窮舉，不用 default)
- applyWriteResult(_ action: OrderWritesFeature.Action, state: inout State) -> Effect<Action>
  - guard case .delegate(let result)，其餘 case 為 .none。
  - outcome = OrdersContainerPlan.writeResult(result, state:)。
  - state.detail.apply(outcome)；state.presentation.apply(outcome) (同步，不經 action)。
  - 若 outcome.selection 存在，設 state.list.selectedOrderID；notifies 為真時回傳 .send(.list(.delegate(.selectionChanged(orderID))))。
  - 若 outcome.notice 存在，回傳 .send(.presentation(.noticeRequested(notice)))。
  - 三者互斥，因此至多一個 effect。

## 3. 計畫型別公開 API 與刪除清單

保留的純計算 (OrdersContainerPlan 為無 case 的 enum，只放 static func)：

| 檔案 | 方法簽章 | 說明 |
|---|---|---|
| OrdersContainerPlan.swift | static func requiresFormID(_ request: OrderRequest, state: OrdersFeature.State) -> Bool | 新增、有效編輯與合併需要表單 id |
| OrdersContainerPlan.swift | static func requiresDateContext(_ request: OrderRequest, state: OrdersFeature.State) -> Bool | 取代 action 版本 |
| OrdersContainerPlan+Requests.swift | static func fulfill(_ request: OrderRequest, state: OrdersFeature.State, context: OrderDateContext?, formID: UUID?) -> OrdersRequestOutcome | 判斷沿用 OrderRequestPlan.fulfill(_:orders:)，並組出編輯、合併、AI 摘要與刪除確認的目的地 |
| OrdersContainerPlan+Writes.swift | static func writeResult(_ result: OrderWritesFeature.Action.Delegate, state: OrdersFeature.State) -> OrdersWriteOutcome | 只回傳值，不寫入 |
| OrdersContainerPlan+Presentation.swift | static func mergeCandidateDraft(primary: LedgerOrder, secondary: LedgerOrder, state: OrdersFeature.State, now: Date) -> OrderMerge.Draft | 呼叫 OrdersMergeFlowOperations.mergeCandidateCompleted |
| OrdersContainerPlan+Presentation.swift | static func mergeConfirmation(draft: OrderMerge.Draft, keptPhotos: [Data], state: OrdersFeature.State, formID: UUID, context: OrderDateContext) -> OrdersPresentationFeature.Destination.State | 以 state.makeEditOptions 呼叫 OrdersMergeFlowOperations.mergeConfirmationReady |

新增的值型別 (各一檔，一檔一個頂層型別)：

- OrdersRequestOutcome.swift：`enum OrdersRequestOutcome { case none; case present(OrdersPresentationFeature.Destination.State); case showDetail(LedgerOrder.ID); case write(OrderWritesFeature.Action) }`
- OrdersWriteOutcome.swift：`struct OrdersWriteOutcome`，欄位：
  - selection: Selection? (Selection 含 orderID: LedgerOrder.ID? 與 notifies: Bool；刪除後的第一筆可為 nil)
  - detailPopIDs: [LedgerOrder.ID]
  - popsUnavailableDetails: Bool
  - closesEditOf: LedgerOrder.ID?
  - addedOption: OrderOptionWritePlan?
  - notice: OrdersPresentationFeature.Destination.State?

不變的檔案：
- OrderRequestPlan.swift：enum 與 static func fulfill(_:orders:) 不變，只改 present 的型別參照。
- OrdersDetailSelection.swift：不變，由詳情子層呼叫。
- OrderRequest.swift：不變。

刪除清單：
- OrdersTransition.swift (含 FollowUp 列舉)，整檔刪除。
- OrdersContainerPlan.make(action:state:context:formID:)，吃整個 Action 的分派。
- OrdersContainerPlan.requiresFormID(action:state:)、requiresDateContext(action:state:)、request(in:)，改為收 OrderRequest 或不再需要。
- 容器 Action 的 destination、mergeConfirmationReady、orderWriteFailed、path、regularDetail。
- 容器的 showDetail、syncRegularDetail (改由詳情子層提供)。
- 派工單的驗收 grep `func make(\|followUp` 在 apps/ios/BuyLedger/Features/Orders 應為 0 筆。

## 4. 各檔預估行數 (不含檔頭與空行)

現況 (wc 實測) 與估計：

| 檔案 | 現況 | 估計 | 說明 |
|---|---:|---:|---|
| OrdersFeature.swift (容器主檔) | 296 | 304 | 未套用 L1 至 L5 時為 334，範圍 290 至 315；超過 300 停下回報 (§7 D2) |
| OrdersPresentationFeature.swift (新) | 新檔 | 150 | 範圍 130 至 170：State 方法約 50、Action 與 Delegate 約 40、core 約 47 |
| OrdersPresentationFeature+Destination.swift | 117 | 117 | 由 OrdersFeature+Destination.swift 改名 |
| OrdersPresentationQueue.swift | 95 | 95 | 只改型別參照 |
| OrdersDetailNavigationFeature.swift (新) | 新檔 | 75 | 範圍 60 至 90 |
| OrdersDetailNavigationFeature+Path.swift | 29 | 29 | 由 OrdersFeature+Path.swift 改名 |
| OrdersDetailSelection.swift | 60 | 60 | 不變 |
| OrdersContainerPlan.swift | 189 | 35 | 只留 requiresFormID、requiresDateContext |
| OrdersContainerPlan+Requests.swift | 74 | 70 | fulfill 改回 OrdersRequestOutcome |
| OrdersContainerPlan+Writes.swift | 56 | 50 | writeResult 改回 OrdersWriteOutcome |
| OrdersContainerPlan+Presentation.swift (新) | 新檔 | 30 | 合併草稿與確認表單 |
| OrdersRequestOutcome.swift (新) | 新檔 | 20 | 值型別 |
| OrdersWriteOutcome.swift (新) | 新檔 | 35 | 值型別 |
| OrderRequestPlan.swift | 69 | 69 | 判斷值不變 |
| OrdersTransition.swift | 47 | 刪除 | |
| OrdersView.swift | 192 | 190 | 綁定改子層 store，刪 typealias |
| OrdersCompactView.swift | 94 | 92 | path 與 alert 綁定 |
| OrdersRegularDetailColumn.swift | 111 | 111 | 綁定路徑一行 |
| OrderListFeature.swift | 286 | 290 | 新增 availablePaymentMethodNames (7.16 要求 `.map(\.name)` 移到 State)；7.19 前接近上限 |

容器主檔的組成 (現況 296 由 wc 實測分段而來)：

| 區段 | 現況 | 估計 (未套用 L1 至 L5) |
|---|---:|---:|
| State | 134 | 108 |
| Action | 79 | 66 |
| Dependencies | 9 | 7 |
| Body | 29 | 31 |
| core 與 private (core 約 41、fulfill 約 19、forwardPresentation 約 28、applyWriteResult 約 24，外加分段註解) | 40 | 112 |
| MARK、import、型別宣告與其他 | 5 | 10 |
| 合計 | 296 | 334 |

壓線手段 (依序，各自在實作後確認)：

| 代號 | 內容 | 節省 |
|---|---|---:|
| L1 | 刪除容器的 isLoading、hasLoaded、errorMessage 投影與其 init 行，改讀 load 子狀態。實作前需 grep 確認這三個容器屬性沒有讀取點 (目前的 store.isLoading 讀的是清單 store) | −9 |
| L2 | presentNewOrder 的 OrderEditFeature.State 組裝移到 OrdersContainerPlan，容器只剩一行呼叫 | −5 |
| L3 | 寫入結果的套用移到 detail.apply 與 presentation.apply 兩個同步方法，容器只保留清單選取與單一 effect | −10 |
| L4 | onChange(of: \.load.hasLoaded) 的 popUnavailable 收進詳情子層方法 | −3 |
| L5 | applyFilterNavigation 與 refreshDateContext 合併為一個 State 方法，Root 呼叫點不變 | −3 |
| 合計 | | −30，約 304 |

估計口徑：本表為依結構估計，不是實測。容器超過 300 行時，依 design「子 Feature 從第一次完成起適用 300 行上限，容器超過就停下回報」處理，不自行登記例外。

## 5. 測試影響

現況計數 (grep，字面 glob；action 路徑為單行出現次數，state 為讀寫次數，未去重)：

- OrdersFeatureTests 系列 (27 檔)：
  - action 路徑 `.destination(`：44 處，改為 `.presentation(.destination(`。
  - state 的 `.destination` 讀寫：約 239 處，改為 `.presentation.destination`。
  - `presentationQueue`：86 處，改為 `.presentation.queue`。
  - state 的 `.path`：21 處，改為 `.detail.path`；`regularDetail`：19 處，改為 `.detail.regularDetail`。
  - `orderWriteFailed`：21 處，改為 `.presentation(.noticeRequested(...))` 的 receive 與斷言路徑。
  - `mergeConfirmationReady`：5 處，改為子層 delegate 的 receive 序列 (mergeCandidatesCompleted、mergeConfirmationDue)。
  - `view(.formSheetDismissed)`：送出 13 行，動作不變，因為容器仍由 .view 進入；只改斷言路徑。
  - 子層委派後需要補 receive 的觸發點：saveRequested 出現在 12 檔共 50 行；addOptionRequested 8 行；confirmDelete 4 行；goToAISettings 3 行。估計需補約 40 處 receive，實際以逐檔改寫為準。
  - `OrdersFeature.Destination` 型別參照：5 處，改為 OrdersPresentationFeature.Destination。
  - `showDetail(` 直接呼叫：約 5 處 (在 OrdersFeatureTests 與 RootFeatureTests 合計)，改呼叫詳情子層方法。
- RootFeatureTests 系列：提及 orders 的 destination 或 presentationQueue 的行約 69 行，改為 presentation 路徑；`orders.regularDetail` 7 行，改為 detail 路徑。
- 其他容器層級的測試：OrderSaveGuardTests 12 行、OrderWritesFeatureTests+Options 14 行、ServiceTestValueStrictnessTests 4 行 (含 destination)，改為 presentation 路徑。
- SnapshotTests：grep 確認未直接讀取容器的 destination，snapshot 不重錄。
- 守門測試：
  - ProjectionWriteBoundaryTests 的 home file 仍是 Features/Orders/OrdersFeature.swift，不變。新檔不得含 `inout OrdersFeature.State`；子層 State 方法只 inout 自己的 State。
  - TestSuiteIntegrityTests 禁止 `default:` 接 `return .none`，新 core 與 private switch 皆無 default。
  - ActionGroupingScanTests 不列容器與子層；Orders 畫面加入屬 task 4.10，本階段不動。
- 新增測試 (建議，字面值預期)：
  - OrdersPresentationFeatureTests 約 25 條：500ms 前後的 TestClock、通知 latest-only、dismiss 對 sheet 與 alert 的差異、closeEdit 與 applyAddedOption、merge 確認與通知的先後、delegate 轉送、取消 sleep 時不送出。
  - OrdersDetailNavigationFeatureTests 約 10 條：showDetail 先清空再推入、不存在的訂單不動、popDetail 保留前方識別值、popUnavailable、syncRegularDetail 保留同 id 的狀態。
  - OrdersContainerPlanTests 約 12 條：requiresFormID 與 requiresDateContext 規則、fulfill 各分支、writeResult 的 saved、merged、deleted、failed 結果。
- UI 測試：OrdersListTests、OrderDetailMenuTests、OrderMergeTests、AISummaryTests (iPhone 17 與 iPad) 依 7.16 於實作階段執行，本階段未跑。
- 合計：既有測試約 520 行的改寫 (含約 40 處補 receive)，新增約 47 條測試。

## 6. 風險、替代方案與推薦

風險：

- R1 (TCA 執行順序)：子層沿用 `Reduce(core).ifLet(\.$destination, action: \.destination)`，與現行容器的組合形狀相同，相對順序應保留。但 Context7 文件未明寫 Scope、ifLet 與父層的先後，只能以測試驗證。驗證方式：改寫後 OrdersFeatureTests+FailureTiming、+MergeTiming、+SaveFailureTiming 全部通過，且 .dismiss 的 closing 判斷不變。
- R2 (UUID 與日期的消耗時點)：uuid() 只在建立表單 (新增、有效編輯、合併確認) 時消耗，date.now 只在需要時讀取。避免 `.incrementing` 測試的 id 順序改變。
- R3 (通知時序)：noticeRequested 維持 .send，與現行 orderWriteFailed 一樣在下一個 action 才呈現。
- R4 (容器行數)：估計 304 (範圍 290 至 315)，見 §4。超過 300 時停下回報。
- R5 (OrderListFeature.swift)：286 行 → 290 行，7.19 會再改，接近上限。
- R6 (同步方法與既有規則的張力)：apps/ios/CLAUDE.md 規定「父層要求子層載入或套用資料時送專用請求 action」。本提案的 present、finishFormClosing、closeEdit、apply 採同步 State 方法，理由是：(a) 既有導覽寫法 (showDetail、showSettings) 就是 State 方法；(b) Root 的 presentNewOrder 必須在同一次更新內呈現 (ios-navigation.md)，action 會延後一拍。若主對話要求全部改 action，代價約 40 處 receive，且寫入結果的套用時序需另外驗證。
- R7 (詳情子層無 core)：body 以 EmptyReducer() 接 forEach 與 ifLet，偏離 kit 的 Reduce(core) 寫法。替代方案是保留一個只回傳 .none 的空 core，多 4 行且無實質邏輯。
- R8 (測試大量補 receive)：receive 補寫可能掩蓋行為差異。以變異驗證抽查 500ms、latest-only、dismiss 判斷與 closeEdit，並由 UI 測試覆蓋 sheet 呈現。

替代方案：

- A1 (推薦，PD)：呈現子層加詳情導覽子層。容器估計 304 (範圍 290 至 315)，子層與計畫型別各檔都在 300 以內。代價是多一個子 Feature 與約 520 行測試改寫。
- A2 (方案 P，只抽呈現子層)：容器估計約 365 行 (未套用壓線手段)，超過 300。不推薦，除非主對話放寬容器上限。
- A3 (destination 留在容器，子層只管佇列與轉場)：容器需保留 destination 與 dismiss 判斷，子層要透過 delegate 來回設定目的地，時序仍分散在兩層，與派工單目標不符，容器估計仍超過 360。不推薦。
- A4 (全部子層請求改 action)：事件紀錄較清楚，但約增加 40 處 receive 與容器約 10 行。不推薦，除非 D3 裁決採用。

推薦理由：PD 是唯一能在不改 Root API 的前提下，把容器壓到接近 300 行的切分。它的代價是多一個子 Feature 與測試改寫規模，這兩點需要主對話同意 (§7)。

## 7. 需要主對話決定的事項

- D1：是否授權新增詳情導覽子 Feature OrdersDetailNavigationFeature。派工單只列出呈現子 Feature，這是超出派工範圍的擴充。不授權時，容器估計約 365 行。
- D2：容器主檔 300 行是否為硬性驗收。PD 加 L1 至 L5 估計約 304 (範圍 290 至 315)，仍可能超過。若硬性，需在實作後以 wc 實測，超過時由主對話決定是否再拆寫入結果套用，或放寬。kit 規定不放寬上限，因此無裁決不可自行登記例外。
- D3：子層的同步呈現與寫入結果套用採 State 方法 (推薦，R6) 或全部改 action (約增 40 處 receive)。
- D4：測試改寫約 520 行，是否分兩次提交：先做純改名與路徑搬移，再補 delegate 的 receive。design 規定「拆檔只搬移，測試數與結果不變」，而本提案會新增 receive 與 47 條測試，需確認是否符合該分步原則。
- D5：OrdersFeature.Destination 與 OrdersFeature.Path 改名的範圍，以及 OrderListFeature.swift 新增 availablePaymentMethodNames 使其到 290 行，是否接受。
- 實作後的驗證 (不在本階段)：以 wc 實測各檔、grep 驗收、變異驗證、單元回歸、iPhone 17 與 iPad 的 OrdersListTests、OrderDetailMenuTests、OrderMergeTests、AISummaryTests。
