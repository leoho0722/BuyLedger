## Context

- **Service 位置** (2026-10-16 實測)：
    - `Core/Dependencies/` 有 `OrderService` (本體、`+Dependency`、`+Preview`、`+Reads`、`+Renames`、`+Writes`) 與四個主檔 Service (`CategoryService`、`OrderSourceService`、`PaymentMethodService`、`ReconciliationStatusService`，各有本體、`+Dependency`、`+Preview`)。
    - 四個主檔 Service 形狀幾乎相同 (讀取、新增、刪除)，付款方式另有 `applyPaymentMethodEdit`；改名入口在 `OrderService`。
    - 錯誤型別 `OrderPersistenceError`、`PaymentMethodPersistenceError` 在 `Core/Persistence/`。
    - `OrderRecord.toDomain(includingPhotos:)` 與 `OrderRecord.apply(_:)` 在 `Core/Persistence/`，任何 Service 都能在交易內使用。
- **跨 Feature 注入** (以 `@Dependency(\.<key>)` 盤點)：
    - `orderService`：Campaigns (`CampaignWritesFeature`)、Lookups (`LookupManagementFeature`、`PaymentMethodCorrectionFeature`) 與 Orders 都在用。
    - 四個主檔 Service：Lookups 與 Orders (`OrdersLoadFeature`、`OrderWritesFeature`) 都在用。
    - 其餘 Feature 專屬 Service (`campaignService`、`photoService`、`aiSummaryService`、`settingsService` 等) 只被自己的 Feature 與 App 組合根引用。
    - 以資料庫為下層的 Feature Service：Campaigns 有兩個 (`CampaignService`、`CampaignReminderService`)，App 有一個 (`PersistenceRecoveryService`)；`CampaignReminderService` 只有 `CampaignReminderFeature` 使用。
- **主檔目錄**：
    - `@Shared(.lookupCatalog)` 由 `LookupManagementFeature` 與 `OrdersLoadFeature`／`OrderWritesFeature` 寫入；`OrdersFeature`、`OrderListFeature` 也以可寫宣告，`OrdersFilterOperations` 與 `OrderFilterPreviewFixtures` 以 `SharedReader(state.$lookupCatalog)` 轉成唯讀 (swift-sharing 的 `SharedReader` 沒有從 `SharedReader` 建立的 init，來源改成唯讀後這兩處必須改寫)。
    - `OrdersLoadFeature` 在 `!isLoading && !hasLoaded` 時才讀取：並行讀取訂單與四種主檔，**全部完成才送出一次回應**，主檔逐種成功才覆寫 (`try?`，失敗保留舊值)；訂單成功後 `hasLoaded` 為真，之後的載入請求都不再讀取。所以訂單變成「已載入」時主檔讀取一定已結束。
    - 載入請求有兩個來源：Root 的 `.orders(.loadRequested)` (啟動與首頁、分析頁、客戶頁的重試)，以及 `OrderListFeature` 的 `view(.task)`／`view(.retryTapped)` 經 `delegate(.loadRequested)` 由 `OrdersFeature` 直接轉給載入子層。
    - `OrdersEditorOptions.make` 在建立表單時讀目錄快照，`OrderEditPickersFeature.State.init` 保存它，之後目錄變動不會補進已開的表單。
- **新增選項的現行路徑**：`OrderEditFeature` 送 `delegate(.addOptionRequested)` → `OrdersPresentationFeature` 包成 `OrderOptionWritePlan` → `OrdersFeature` 轉給 `OrderWritesFeature` → 以主檔 Service 寫入、成功才更新目錄 → `OrdersContainerPlan+Writes` 的 `addedOption` 讓目前表單 (表單實例 id 相符) 加入並選取；失敗為 `OrderWriteOperations.Failure.option(kind)`，由容器顯示該種類的寫入失敗提示。
- **開團改名**：`CampaignWritesFeature` 先 `campaignService.saveCampaign`，成功後再 `orderService.renameOrderCampaign`，兩筆交易；後者失敗回報 `Failure.rename` (文案 key `campaigns.general.message.campaignSavedBut`)。`saveCampaign` 另有 28 個檔在呼叫或覆寫 (自動結單、狀態、結算與大量測試)。
- **付款方式更正**：`PaymentMethodCorrectionFeature` 每次請求都以 `orderService.fetchOrders()` 讀取建立 `PaymentMethodEditPlan` (確認筆數與重算對象取自同一份快照)；計畫沒有受影響訂單或旗標未變時直接寫入，否則暫存並要求確認。寫入時 `paymentMethodService.applyPaymentMethodEdit` 把計畫內的整筆訂單以 `OrderRecord.apply(_:)` 換入資料庫 (找不到即 `orderNotFound`)；`apply(_:)` 不碰照片，清單讀取的訂單本來就不含照片。
- **Root 送進訂單容器的請求**：`loadRequested`、`cascadeRequested`、`receiptStatusChangeRequested`、`paymentMethodFlagsApplyRequested` 四個 Action case，各有文件註解；Root 有七處送出。
- **行數** (`style_checks.py` 口徑，不含檔頭與空行)：`RootFeature` 297、`OrdersFeature` 359 (登記的上限)、`OrderWritesFeature` 299、`LookupManagementFeature` 290、`CampaignReminderFeature` 290、`MoreFeature` 211、`RootNavigationOperations` 53、`PaymentMethodCorrectionFeatureTests` 466。
- **既有守門**：`LayerBoundaryTests` 動態列舉 Features 下所有頂層型別，Core 與 Shared 引用任一個就失敗；`ActionGroupingScanTests` 只擋父層送出或攔截子層 `.view(`。
- **使用者裁決**：
    - 10/04 第 6 步 discuss：Service 搬到擁有者、改名在同一交易、新增選項經 Root 轉主檔端無 View 子 Feature (主檔清單載入也交給它)、`<Feature>Error`、改到即整檔對齊。
    - 10/16：四個主檔 Service 合併成 `LookupService`；`CampaignReminderService` 併入 `CampaignService`。
    - 10/16 第一輪三方審查後：付款方式更正改由 `LookupService` 在交易內讀資料庫 (推翻 10/04「改讀 Root 訂單投影」)；Root 送進訂單容器的請求收成一個列舉，讓 `OrdersFeature` 維持在 359 行內。
- **平行**：`palette-analytics-style-compliance` 在主 checkout 進行，與本 change 共用 `RootFeature.swift`、`RootFeatureTests+LoadRequests`、`+Fixtures`、`+Foreground`、`apps/ios/CLAUDE.md` 與 `.claude/rules/`。

## Goals / Non-Goals

**Goals:**

- 每個 Feature 專屬的 Service 放在該 Feature 的 `Data/`，只被該 Feature 與 App 組合根、測試引用；每個 Feature 至多一個以資料庫為下層的 Service；兩者由掃描守門鎖住。
- 主檔改名、開團改名與付款方式更正各在一筆交易內同時更新主檔／開團與訂單，訂單由擁有交易的 Service 自己從資料庫選取。
- 訂單端只讀主檔目錄；主檔目錄只有主檔端寫入；訂單變成已載入時，主檔目錄一定已讀取過。
- 畫面不變；行為只有規格 delta 列出的三處改變：開團改名失敗的提示、付款方式更正改以寫入當下的資料庫訂單重算、訂單載入一律在主檔目錄讀取之後。
- 每個 task 完成時都能編譯並通過受影響的測試；改到與新增的 Swift 檔整檔符合 `/ios-dev-kit`，`style_checks.py` 只剩不計失敗的代碼，每檔不超過 300 行 (`OrdersFeature` 359)。

**Non-Goals:**

- **系統 framework 的 Service**：`CalendarReminderService` (EventKit)、`OpenSettingsService` (UIApplication)、`PhotoService` (PhotosUI) 屬第 10 步，本 change 不處理；它們不以資料庫為下層，不受「至多一個」限制。
- **`ExchangeRateService`、`CurrencyMetadataService`、`BiometricAuthService`**：維持在 `Core/Dependencies/`，依第 10 步決定。
- **畫面**：不改任何 View 的版面、identifier 與文案 (`OrdersView`、`OrdersRegularListColumn` 雖引用篩選用的可選清單，但本 change 不改它們)。
- **6d**：篩選 sheet 重新設計。
- **`saveCampaign` 的呼叫端**：簽章不變，自動結單、狀態與結算的存檔路徑不動。

## Decisions

### 四個主檔 Service 合併成 LookupService

`Features/Lookups/Data/LookupService.swift` (`Sendable` struct 裝 closure，依 kit `tca/Service.swift` 樣板)，`DependencyValues.lookupService`，所有操作都 `throws(PersistenceError)`：

| 操作 | 型別 | 取代 |
| --- | --- | --- |
| `fetchItems` | `(_ kind: LookupKind) async throws(PersistenceError) -> LookupCatalog` | 四個 `fetch…`；回傳只填該種類的目錄 (同 `LookupItemOperations.loadItems(kind:)`)，主檔管理畫面與主檔目錄載入都逐種讀取，保留「一種失敗不影響其他種」 |
| `addItem` | `(_ kind: LookupKind, _ addition: LookupItemAddition) async throws(PersistenceError) -> Void` | 四個 `add…`；付款方式使用 `addition.flags` |
| `removeItem` | `(_ kind: LookupKind, _ name: String) async throws(PersistenceError) -> Void` | 四個 `remove…` |
| `renameItem` | `(_ kind: LookupKind, _ rename: LookupItemRename) async throws(PersistenceError) -> Void` | `OrderService` 的四個 `apply…Rename`；同一次 `database.write` 內改主檔與引用訂單 |
| `countOrders` | `(_ paymentMethod: String) async throws(PersistenceError) -> Int` | 付款方式更正確認前的筆數讀取 |
| `applyPaymentMethodEdit` | `(_ originalName: String, _ newName: String, _ flags: PaymentMethodFlags) async throws(PersistenceError) -> [LedgerOrder]` | `PaymentMethodService.applyPaymentMethodEdit`；見「付款方式更正在 LookupService 的交易內重算訂單」 |

- 各操作的同步實作 (`static func …(in context:)`) 從原 Service 與 `OrderService+Renames` 複製進來，演算法與正規化不變 (原處在 3.1 刪除)；依主題分成 `LookupService+Renames.swift` 與 `LookupService+PaymentMethods.swift`，每檔不超過 300 行。
- `testValue` 全部 `unimplemented` (`fetchItems` 的 placeholder 為空目錄、`countOrders` 為 0、`applyPaymentMethodEdit` 為空陣列)；`previewValue` 比照現行四個 `+Preview`。
- 不新增 `LookupError`：更正改由 Service 自己選訂單後，`orderNotFound` 不再可能發生，Lookups 只剩儲存失敗，沿用共用的 `PersistenceError` (與 `CampaignService` 相同，`apps/ios/CLAUDE.md` 已登記)。`PaymentMethodPersistenceError` 在收尾時刪除。

### 付款方式更正在 LookupService 的交易內重算訂單

使用者 2026-10-16 裁決，取代 10/04「改讀 Root 訂單投影」：

- `PaymentMethodCorrectionFeature` 刪除 `orderService` 與 `paymentMethodService`，只注入 `lookupService`：
    - 請求以巢狀型別 `Request` (原名稱、新名稱、旗標、旗標是否變更) 表示。`requested` 時旗標未變 (只改名) 就直接寫入，不讀筆數；旗標有變時以 `countOrders(originalName)` 讀取受影響筆數，回應 `countResponse(request: Request, result: Result<Int, PersistenceError>)` 帶著發出它的請求 (同現行 `planResponse` 帶著完整計畫)，筆數為 0 直接寫入該請求，否則把該請求存進 `pendingRequest` (取代 `pendingPlan`) 並送 `delegate(.confirmationRequired(affectedOrderCount:))`。
    - 讀取筆數期間使用者送出另一個編輯時，兩個回應各自對應自己的請求，前一個請求的 0 筆結果不會讓後一個請求跳過確認；兩個都需要確認時後到的取代 `pendingRequest`，與現行 `pendingPlan` 相同。
    - 確認後呼叫 `applyPaymentMethodEdit`。成功時以回傳的訂單組成 `PaymentMethodEditPlan` (`affectedOrders` 為實際寫入的訂單)，送 `delegate(.edited(plan))`；讀取或寫入失敗都送 `delegate(.failed)`，沿用現行提示。
    - `PaymentMethodEditPlan` 的型別說明改為「寫入完成後交給父層的結果」。
- `LookupService.applyPaymentMethodEdit` 在單一 `database.write` 內完成：
    - 改名或覆寫付款方式主檔與旗標 (沿用現行演算法，新名稱去除空白後為空字串時不處理並回傳空陣列)。
    - 取出 `paymentMethod == originalName` 的 `OrderRecord`，以 `toDomain(includingPhotos: false)` 轉回訂單，套用 `renamingPaymentMethod(to:)` 與 `applyingPaymentMethodFlags(_:)` (順序與現行 `preparePlan` 相同) 後以 `apply(_:)` 寫回。
    - 回傳寫回的訂單；任一步失敗就丟棄整個 context。
- Root 收到 `paymentMethodEdited(plan)` 後以 `plan.affectedOrders` 依編號替換記憶體內訂單的流程不變 (`OrdersCascadeOperations.applyPaymentMethodFlags` 只替換、不插入)。
- 確認時的筆數與寫入時實際重算的筆數，只在兩者之間另有訂單寫入時可能不同；寫入一律以資料庫當下的訂單為準，不會蓋掉較新的欄位。不再需要訂單投影或載入狀態，訂單尚未載入時也能正確更正。
- 規格：`lookup-management` 的「Payment method editing via the editor sheet」改寫重算對象與確認筆數的來源；「Lookup item management operations are preserved across platforms」原文的「讀取受影響訂單失敗」仍對應 `countOrders` 失敗，不需修改。

### 開團提醒連結併入 CampaignService

- 使用者 2026-10-16 裁決：`CampaignReminderService` 的 `fetchLinks`、`saveLink`、`removeLink` 併入 `CampaignService`，改名為 `fetchReminderLinks`、`saveReminderLink`、`removeReminderLink` (型別與錯誤不變，皆為 `PersistenceError`)。
- 同步實作 (`static func …(in context:)`) 搬到 `Features/Campaigns/Data/CampaignService+Reminders.swift`；`CampaignService.swift` 維持本體、儲存、刪除與讀取。
- `CampaignReminderFeature` 的依賴改為 `campaignService`，呼叫與效果不變；`DependencyValues+BLUITestOverrides` 的提醒 Service 建構併入 `campaignService`。
- `CampaignReminderServiceTests` 以 `git mv` 改為 `CampaignServiceTests+Reminders` (改為 `extension CampaignServiceTests`) 並改用新名稱；它的 `makeService(database:)` 回傳 `CampaignReminderService`，與既有 `CampaignServiceTests.makeService(database:)` 簽名相同，移入後會重複宣告，因此刪除，提醒測試與 `CampaignServiceTests+Delete`、`+DeleteFailure` 都改用 `CampaignServiceTests.makeService` 建立的 `CampaignService` 呼叫 `saveReminderLink`／`fetchReminderLinks`；`CampaignReminderFeatureTests` 系列、`CampaignFeatureTests+DeletionReminder`、`+ReminderIntegration`、`CampaignServiceTests+Delete`、`+DeleteFailure` 的覆寫改為 `campaignService` 的對應 closure，斷言不變。
- 刪除 `CampaignReminderService` 的三個檔。

### OrderService 搬到 Orders 並刪除改名入口

- `OrderService` 的六個檔 (本體、`+Dependency`、`+Preview`、`+Reads`、`+Renames`、`+Writes`) 以 `git mv` 搬到 `Features/Orders/Data/` (key path 與型別名不變)；`+Renames` 在收尾時刪除。
- 刪除 `applyOrderSourceRename`、`applyCategoryRename`、`applyPaymentMethodRename`、`applyReconciliationStatusRename`、`renameOrderCampaign` 五個 closure；同步實作分別搬到 `LookupService+Renames` 與 `CampaignService`。
- `OrderPersistenceError` 以 `git mv` 改名 `OrderError`，放 `Features/Orders/Data/OrderError.swift`；Core 若再引用它，`LayerBoundaryTests` 的動態列舉會轉紅。

### 開團改名以 renameCampaign 在同一筆交易更新訂單

- 採第一輪審查 (gemini 01) 的建議：`saveCampaign` 簽章不變，`CampaignService` 新增 `renameCampaign: (_ campaign: Campaign, _ previousName: String) async throws(PersistenceError) -> Void`，在同一次 `database.write` 內存開團並改寫訂單的 `campaignNames`；改寫訂單的同步實作從 `OrderService.renameOrderCampaign` 複製進 `CampaignService` (演算法不變，原處在 3.1 刪除)，不跨 Feature 呼叫 `OrderService`。
- `CampaignWritesFeature` 刪除 `orderService` 依賴、`renameResponse` 與 `Failure.rename`：`saveRequested` 時 `plan.rename` 不為 `nil` 改呼叫 `renameCampaign`，回應仍是 `saveResponse`；成功時若有改名先送 `delegate(.renamed)` 再送 `delegate(.saved)` (與現行順序相同)，失敗一律是 `Failure.save`。
- `CampaignPresentationFeature+Destination` 刪除 `.rename` 的提示，`campaigns.general.message.campaignSavedBut` 從 `Localizable.xcstrings` 移除；`CampaignFeatureTests+FailureTimingFollowUp` 原本斷言該文案的測試改為斷言存檔失敗文案。
- 受影響的測試：`CampaignWritesFeatureTests+Rename`、`CampaignFeatureTests+ReminderRename`、`+FailureTimingFollowUp`、`CampaignIntegrationTests+Rename`、`RootFeatureTests+Campaigns`、`CampaignServiceTests`；UI 測試替身若注入開團存檔失敗，也同時覆寫 `renameCampaign`。
- Root 收到 `campaignRenamed` 後送訂單 cascade 改寫記憶體內訂單的流程不變。

### 主檔目錄由主檔端的 LookupCatalogFeature 載入與寫入

- 新增 `Features/Lookups/LookupCatalogFeature.swift`，無 View、不設 `view` 分組 (`apps/ios/CLAUDE.md` 的無 View 子 Feature 規則)：
    - State：`@Shared(.lookupCatalog) var catalog`、`isLoading` 與 `hasLoaded` (四種都讀取成功過)。
    - Action：`loadRequested`、`catalogResponse([LookupKind: LookupCatalog])` (只含讀取成功的種類)、`additionRequested(LookupAdditionRequest)`、`additionResponse(request:result:)`、`delegate(Delegate)`；Delegate 為 `loadFinished` 與 `additionCompleted(LookupAdditionRequest, isStored: Bool)`。
    - `loadRequested`：`hasLoaded` 時直接送 `delegate(.loadFinished)`；`isLoading` 時略過 (進行中的讀取結束時會送)；否則以 `fetchItems` 並行讀取四種 (`LookupKind.allCases`)，失敗的種類記錄警告後略過。
    - `catalogResponse`：以 `LookupCatalog.replaceItems(of:from:)` 覆寫讀取成功的種類，四種都成功才把 `hasLoaded` 設為真，再送 `delegate(.loadFinished)`。逐種覆寫與失敗保留舊值和現行 `OrdersLoadFeature.apply` 相同。
    - `additionRequested`：名稱去除空白後為空時略過 (同現行 `OrderWritesFeature`)；否則先 `lookupService.addItem`，成功才 `withLock` 以 `LookupCatalog.add(name:kind:flags:)` 更新目錄，成功與失敗都送 `delegate(.additionCompleted(request, isStored:))`。
- **請求型別**：`OrderOptionWritePlan` 以 `git mv` 搬到 Lookups 改名 `LookupAdditionRequest` (`id: UUID` 為發起表單的實例 id、`kind`、`addition: LookupItemAddition`，init 去除頭尾空白)。它是 Lookups 的 Model，Orders 依 kit「跨 Feature 可引用對方 Domain Model」直接使用，Root 轉送時不需轉換。
- **組合位置**：由 `MoreFeature` 以 `Scope(state: \.catalog, action: \.catalog)` 組合 (主檔管理畫面也在「更多」之下，`MoreFeature` 是登記的殼層宿主)。`MoreFeature` 新增請求 action `catalogLoadRequested`、`optionAdditionRequested(LookupAdditionRequest)`，以及 delegate `catalogLoadFinished`、`optionAdditionCompleted(LookupAdditionRequest, isStored: Bool)`，只做轉送。
    - 不由 Root 直接組合：Root 需多 State、Action、Scope 與四個 case，估計約 308 行；放在「更多」估計約 297 行 (見「Root 為控制行數的調整」)。`MoreFeature` 估計由 211 行增為約 243 行。
- **訂單一定在主檔讀取後才載入** (第一輪審查 codex C04、claude 6)：
    - Root 的 `view(.task)` 不再直接送訂單載入，改送 `.more(.catalogLoadRequested)`；`.more(.delegate(.catalogLoadFinished))` 時才送 `.orders(.rootRequest(.load))`。
    - 其餘載入請求也全部先經主檔：首頁與分析頁的 `refresh`、客戶頁的 `ordersLoadRequested`，以及訂單分頁本身 (`OrderListFeature` 的 `view(.task)`／`view(.retryTapped)`)。`OrdersFeature` 收到 `.list(.delegate(.loadRequested))` 時不再直接轉給載入子層，改送新的 `delegate(.loadRequested)` 交給 Root，與另外三個來源併在同一個 case 送 `.more(.catalogLoadRequested)`。
    - 主檔已全部讀取成功時立即完成，否則先重讀；`OrdersLoadFeature` 的去重 (`!isLoading && !hasLoaded`) 不變，訂單已載入後的請求仍不讀取。
    - 因此訂單變成已載入時主檔目錄一定已讀取過，首次開啟的表單拿得到已存的主檔；代價是主檔與訂單由並行改為先後讀取 (主檔是四張小表)。
- **訂單端**：
    - `OrdersFeature`、`OrderListFeature` 改 `@SharedReader(.lookupCatalog)`；`OrdersLoadFeature`、`OrderWritesFeature` 移除主檔目錄與四個主檔 Service。
    - `OrderFilterPreviewFixtures` 改以 `state.$lookupCatalog = SharedReader(value:)` 放入常數目錄 (swift-sharing 的 `SharedReader.projectedValue` 有 nonmutating setter)，不寫具名目錄；`OrdersFilterOperations` 直接傳入 `state.$lookupCatalog`。
    - `OrdersPresentationFeature` 送出的新增請求由 `OrdersFeature` 以 `delegate(.optionAddRequested(LookupAdditionRequest))` 交給 Root。
    - 結果經 `.orders(.rootRequest(.optionAdditionCompleted(request, isStored:)))` 送回，由容器交給呈現子 Feature 的 State 方法：成功時以表單實例 id 相符才加入並選取 (沿用 `OrderEditFeature.State.applyAddedOption`)，失敗時以 `OrderWriteOperations.Failure.option(kind)` 的文案送出寫入失敗提示，顯示時機沿用呈現子 Feature 現行的提示規則 (表單開著時延到表單關閉後)。
    - `OrderWritesFeature` 的 `optionAddRequested`／`optionResponse`／`delegate(.optionAdded)` 與 `OrdersWriteOutcome.addedOption`、`OrdersContainerPlan+Writes` 對應分支刪除。

### Root 送進訂單容器的請求收成 OrdersRootRequest

- 使用者 2026-10-16 裁決：新增 `Features/Orders/OrdersRootRequest.swift` (頂層 enum，比照 `OrdersCascadeOperations.Request`)，case 為 `load`、`cascade(OrdersCascadeOperations.Request)`、`receiptStatusChange(id:status:)`、`paymentMethodFlagsApply([LedgerOrder])`、`optionAdditionCompleted(LookupAdditionRequest, isStored: Bool)`。
- `OrdersFeature.Action` 以一個 `rootRequest(OrdersRootRequest)` 取代 `loadRequested`、`cascadeRequested`、`receiptStatusChangeRequested`、`paymentMethodFlagsApplyRequested` 四個 case；`core` 依 `OrdersRootRequest` 的 case 逐一轉送，轉送目標與現行相同。
- 估計 (以 `style_checks.py` 口徑，實作後實測)：四個 case 的文件註解與宣告 16 行收成 4 行 (−12)；`core` 仍逐 case 轉送 (`case .rootRequest(.load):` 等)，行數不變，另加結果轉送 (+3)；Delegate 新增 `loadRequested` 與 `optionAddRequested` (+6)。`OrdersFeature` 約 356 行，不超過 359；回到 300 行內才刪除 `apps/ios/CLAUDE.md` 的例外。
- 呼叫端：Root 的七處送出與既有測試 (`OrdersFeatureTests` 系列、`RootFeatureTests` 系列、`CampaignIntegrationTests` 系列、`OrdersLoadStateTests`、`ServiceTestValueStrictnessTests`、`ActionGroupingScanTests+Scenarios` 的合規片段) 改用新形式，斷言值不變；逐檔清單見 `reference/file-list.txt` 標 1.7 的列。`ActionGroupingScanTests` 只擋 `.view(`，新形式不受影響。
- 本項先於主檔端接管單獨完成 (純機械改寫)，之後新增的 Root 對訂單請求直接加在 `OrdersRootRequest`。
- `apps/ios/CLAUDE.md`「父層送專用請求 action」一節的例子改為新名稱。

### Root 為控制行數的調整

- `refreshDateContexts(state:)` 移到 `RootNavigationOperations` (它已持有注入的 `referenceDate` 與 `calendar`)，呼叫端改 `navigation.refreshDateContexts(state: &state)`；寫的是 `dateContext`，不屬 `ProjectionWriteBoundaryTests` 的投影屬性。
- 首頁與分析頁相同的 `delegate(.campaignTapped)` 轉送合併成一個 case。
- 估計 (實作後實測，必須不超過 300)：兩項合計 −10 行；主檔目錄與新增選項的三個轉送 case +6、載入來源併入既有 case +1、`OrdersRootRequest` 改寫後超過行寬 100 的主檔改名轉送斷行 +3，`RootFeature` 約 297 行。超過 300 時先回報使用者，不另登記例外。
- `palette-analytics-style-compliance` 會在 `refreshDateContexts` 內加首頁與分析頁兩行；後合併的一方把那兩行移到新位置 (在 tasks 註明)。

### 訂單編輯選擇器直接持有選項

`OrderEditPickersFeature.State` 以一個 `options` (正規化後的 `OrderEditOptions`) 取代六個 `available…` 欄位 (kit `tca-architecture.md`「不把 Model 的欄位攤平複製進 State」)；`OrderEditOptions` 的欄位改為 `var`，新增選項時以它的 mutating 方法加入。呼叫端 (`OrderEditCampaignSection` 等選擇列、`OrderEditPickerOperations`) 與測試 (`OrderEditPickersFeatureTests`、`OrderEditFeatureTests+Campaigns`、`OrderEditCampaignOptionsTests` 等) 改讀 `options.…`。

### Feature 專屬 Service 的掃描守門

新增獨立的 `BuyLedgerTests/ServiceOwnershipScanTests.swift` (不擴充 `DependencyConventionScanTests`，避免與平行 change 共檔)，含兩條規則：

- **共同前處理**：以 `DependencyConventionScanTests.blankedCommentsAndStrings(in:)` 清空註解與字串後掃描 production 根目錄；key path 比對同時涵蓋縮寫 `\.<key>` 與完整的 `\DependencyValues.<key>`，以及 `@Dependency(` 與 key path 之間的空白與換行 (比照 `DependencyConventionScanTests+Rules` 處理完整 key path 的方式)。
- **Feature 專屬 Service 只被該 Feature 引用**：
    - 從各 `*+Dependency.swift` 的 `DependencyValues` 擴充收集 `<key>Service` 與宣告它的目錄：`Features/<X>/` (含 `Data/`) 屬 Feature X；`Core/` 與 `App/` 屬共用。
    - `Features/<Y>/` 下的檔引用屬於 Feature X (X ≠ Y) 的 key 即違規，訊息含檔名、行號與 key；`App/` (組合根與 `App/Testing/`) 不在檢查範圍。
- **每個 Feature 至多一個以資料庫為下層的 Service**：數 `Features/<X>/Data/` 下 `*+Dependency.swift` 內取用 `buyLedgerDatabase` (縮寫與完整形式) 的 Service，超過一個即失敗。本 change 完成後 Campaigns、Lookups、Orders、App 各一個 (App 的是 `PersistenceRecoveryService`)。
- 根目錄找不到或一個 Service 宣告都沒收集到時失敗。
- 附違規與合規片段案例：跨 Feature 引用 (縮寫與完整形式) 失敗、同 Feature 引用通過、Core Service 通過、註解與字串內的引用不算、同 Feature 第二個資料庫 Service (縮寫與完整形式) 失敗；並以變異 (暫時讓 `CampaignWritesFeature` 引用 `\.orderService`) 確認會轉紅。

### 整檔對齊、測試拆分與驗收

- `openspec/changes/archive/2026-10-10-order-edit-style-compliance/reference/style_checks.py` 複製到本 change 的 `reference/`，`EXISTING_OVER_LIMIT` 清空，`BOUNDED_LENGTH_LIMITS` 保留 `OrdersFeature` 的 359 行 (與 `apps/ios/CLAUDE.md` 登記的上限一致；實測回到 300 行內時一併刪除)。
    - 腳本從自己的位置往上找 repo 根目錄並 `chdir`，放在主 checkout 的 `openspec/` 時會量到主 checkout 的檔 (色盤 change 正在改的版本)，`BOUNDED_LENGTH_LIMITS` 的相對路徑也對不上。複製時加上「環境變數 `STYLE_ROOT` 有值就以它為根目錄」，本 change 一律以 `STYLE_ROOT=/Users/leoho/Develop/BuyLedger-6c python3 -I <reference 內的 style_checks.py> <相對路徑…>` 執行。
    - 逐檔清單與負責 task 在 `reference/file-list.txt`；0.1 以修改與搬移段的現有 123 檔量測基準 (2026-10-16 以上述方式預量：`W` 44、`TYPEDCL` 47、`LEN` 1 計失敗，`WCL` 38、`WSIG` 2、`LENB` 1 不計，共 133 筆分布在 38 檔)。
    - 之後在本 change 刪除的檔 (`OrderService+Renames`、`OrderWritesFeatureTests+Options`、四個主檔 Service 與其測試、`CampaignReminderService`、`PaymentMethodPersistenceError`) 在刪除前只做讓編譯通過的最小修改，不整檔對齊，不列入基準與整檔檢查。
    - 改寫後超過 300 行的檔依受測行為或主題拆檔，新檔加入 `reference/file-list.txt` 新增段並記在 task 下方；已知接近上限的有 `OrderEditFeature` 300 行 (1.2、3.2)、`RootFeatureTests+NewOrderOptions` 285 行 (2.5、2.6、3.2)、`RootFeatureTests+LoadRequests` 275 行 (2.4)。
- **測試搬遷** (「搬遷不減測試」：同時記錄方法數、參數化展開後的案例數與逐項對照)：
    - `OrderServiceTests+Renames`、`+RenameFailures`、`+RenameNoOps`、`+RenameSupport` 在 1.3 以 `git mv` 改為 `LookupServiceTests+Rename…`，主檔四種改呼叫 `lookupService.renameItem`。它們現為 `extension OrderServiceTests`，用到 `makeOrder`、`makeService`、`seed`、`fetchOrder` 等訂單測試 fixture；改為 `extension LookupServiceTests` 後，訂單 fixture 以 `OrderServiceTests.` 明確引用 (前例：`CampaignServiceTests+Delete` 引用 `CampaignReminderServiceTests.makeService`)，Service 的建立改用 `LookupServiceTests` 自己的 helper。這些測試以同一個 `OrderService` 同時做訂單讀寫 (`fetchOrders`、`createOrder`) 與改名，搬移後每個測試建立兩個指向同一資料庫的實例：`OrderServiceTests.makeService(database:)` 負責訂單讀寫與 `.campaign` 的 `renameOrderCampaign`，`LookupServiceTests.makeService(database:)` 負責主檔改名；`applyRename` 改為接收 `LookupService` 與 `OrderService` (3.1 移除 `.campaign` 後只接收 `LookupService`)。測試用的 `LookupRenameOperation` 含 `.campaign`，`+RenameNoOps` 有三個以它的 `allCases` 參數化的測試、`+Renames` 有一個 `renameOrderCampaign` 測試；1.4 先在 `CampaignServiceTests` 以 `renameCampaign` 寫出對應測試 (含無改名、照片保留與重複舊名稱)，`.campaign` 案例在 1.3 至 3.1 之間仍呼叫 `orderService.renameOrderCampaign`，3.1 刪除改名入口時一併移除。
    - `CategoryServiceTests`、`OrderSourceServiceTests`、`ReconciliationStatusServiceTests`、`PaymentMethodServiceTests` (與 `+ApplyEdit`) 的情境移植到 `LookupServiceTests` 與主題檔後刪除；`orderNotFound` 情境改為「更正以資料庫當下的訂單為準」。
    - `OrderServiceResidueTests` 的「編輯失敗後改開團名稱」情境改到 `CampaignServiceTests`。
    - `OrdersLoadFeatureTests` 的主檔部分與 `OrderWritesFeatureTests+Options` 改到 `LookupCatalogFeatureTests` 或新的 `RootFeatureTests+LookupCatalog` (Root 層級的載入順序與新增選項往返)。
- **既有超長檔**：`PaymentMethodCorrectionFeatureTests` (466 行) 依受測行為拆出 `PaymentMethodCorrectionFeatureTests+Confirmation`。
- **改寫共享主檔目錄的測試**：訂單端改唯讀後，經 `OrdersFeature.State`／`OrderListFeature.State` 的 `$lookupCatalog.withLock` 準備或斷言目錄的測試 (清單標 2.6 的列) 分兩種改法：只測訂單端的 (篩選、清單、容器計畫、snapshot) 以 `$lookupCatalog = SharedReader(value:)` 放入常數目錄，不碰具名鍵；Root 層級的整合測試改由主檔端子狀態 (`more.catalog`) 或測試自己宣告的 `@Shared(.lookupCatalog)` 寫入與斷言。`.claude/rules/ios-unit-tests.md` 的具名共享資料隔離規則照舊適用。
- **主檔讀取覆寫的遷移 (2.4)**：訂單載入不再讀主檔後，下列以舊四個 Service 覆寫主檔讀取的測試 helper 都在 2.4 處理，不留到 3.1：
    - `OrdersFeatureTests.suppressOrderLookupEffects` (呼叫端 `OrdersFeatureTests+DeleteEditFailures`、`+LoadAndSummary`、`+StatusFailures`) 與 `OrdersLoadFeatureTests.suppressLookups` (呼叫端 `OrdersLoadStateTests`) 失去用途，連同呼叫一併刪除。
    - `RootFeatureTests+CampaignLoading.suppressCampaignLoadingLookups`、`RootFeatureTests+LoadRequests` 的主檔讀取覆寫與 `ServiceTestValueStrictnessTests` 改為覆寫 `lookupService.fetchItems`；失敗斷言改看主檔目錄載入，避免舊覆寫留著卻已不被呼叫的假綠。
    - `RootFeatureTests+Fixtures.receiveLaunchLoadRequests` 改為接收新的啟動順序 (主檔目錄的請求與完成在前、訂單載入在後)；在 `view(.task)` 前把 `orders.load.hasLoaded` 設為真的 Root 測試 (`RootFeatureTests`、`+Foreground`、`+CurrencyCodes`) 同時把 `more.catalog.hasLoaded` 設為真，否則主檔讀取會呼叫未實作的 `lookupService`。
- **UI 測試替身** (`DependencyValues+BLUITestOverrides`，熱點檔，依 1.4 → 1.5 → 1.6 → 3.1 修改)：
    - 1.4：開團寫入失敗的注入同時覆寫 `renameCampaign`。1.5：提醒連結改由 `campaignService` 提供。
    - 1.6：這個檔已有 280 行，先把 `applyLookupOverrides` 整個移到新檔 `App/Testing/DependencyValues+BLUITestLookupOverrides.swift` (改為 internal，仍在 `#if DEBUG` 內)，再在新檔建立指向 UI 測試資料庫的 `lookupService`，與舊的四個 Service 並存：`loadFailure == .lookups` 時 `fetchItems` 依種類丟出與現行相同來源的讀取失敗；`shouldFailLookupWrites` 時 `addItem`、`removeItem`、`renameItem`、`applyPaymentMethodEdit` 丟出寫入失敗 (`countOrders` 不注入失敗，與現行讀取訂單不注入失敗相同)。
    - 3.1：刪除舊四個 Service 與 `orderService` 改名入口的注入。`self.orderService = orderService` 現在只在 `applyLookupOverrides` 內，去掉它的 `orderService` 參數時，改在 `applyUITestOverrides` 直接把 `makeOrderService(...)` 的結果指定給 `self.orderService`，保留訂單讀取失敗 (`.orders`、`.ordersFirstReadOnly`) 的注入。
- **snapshot**：本 worktree 在 0.1 以實跑結果記錄已知失敗的 snapshot 清單並保存失敗圖。預期是 `1cd7e6c` 記錄的 4 條 (`campaignEditView_編輯既有開團_符合基準圖`、`orderEditView_一般既有訂單_符合基準圖`、`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼`)，實跑不同時以實跑清單為準並在 0.1 下方說明。之後的驗收要求清單內的測試通過，或失敗圖與 0.1 保存的逐像素相同，不只比失敗名稱；清單外的 snapshot 一律通過。
- **驗收**：
    - 單元：受影響類別逐 task 執行，選擇性執行記錄實際執行數大於 0；最後完整回歸。
    - UI：`LookupManagementTests`、`OrderCreateTests`、`OrderEditDirtyTests`、`OrderDetailTests`、`OrdersListTests`、`CustomersTests`、`CampaignCrudTests`、`CampaignFlowTests`、`DashboardLaunchLoadingTests`、`InsightsLaunchLoadingTests` 在受影響的 task 執行；4.3 的 iPhone 與 iPad 主回歸全數通過。
    - UI Automation：在 worktree 的模擬器實測從訂單編輯新增類別後立即可選、開團改名後訂單的開團欄位同步，以及付款方式更正 (以 `paymentMethodCorrection` 種子改旗標、確認筆數、確認後訂單詳情反映新旗標；目前沒有 UI 測試涵蓋這個流程)。
- **worktree 環境**：
    - 從主 checkout 複製 `apps/ios/BuyLedger/Resources/Config.xcconfig`、`GoogleService-Info.plist`。
    - 建立本 worktree 自己的 `.mobilebuildmcp/config.yaml` (指向 worktree 路徑)，另建一台 iPhone 17 與一台 iPad 模擬器，不與主 checkout 的色盤 change 共用。
    - build 後若 `Localizable.xcstrings` 出現非本 change 的變動，提交前還原。
    - 用完以 `mobilebuildmcp purge` 清 workspace 產物。

### 文件同步

- `.claude/rules/ios-data-layer.md`：
    - 「主檔改名是一次原子操作」改為 `LookupService.renameItem`。
    - 「付款方式編輯是一次原子操作」改為 `LookupService.applyPaymentMethodEdit` 在交易內選取並重算訂單、`countOrders` 提供確認筆數；資料流描述同步。
    - 跨檔不變式的主檔目錄寫入者改為 `LookupManagementFeature` 與 `LookupCatalogFeature`，訂單端唯讀；所有訂單載入請求都先經主檔目錄。
    - 開團改名改為 `renameCampaign` 單一交易 (刪除「開團儲存後改名…不是單一交易」)。
    - `OrderServiceResidueTests` 的情境清單與規則檔的路徑條件 (涵蓋 `LookupServiceTests`) 改寫。
- `.claude/rules/ios-integrations.md`：`CampaignReminderLink` 改為在 `CampaignService` 與 Feature 間傳遞。
- `.claude/rules/ios-navigation.md`：啟動與重試的載入改為 Root 先送主檔目錄、完成後才送訂單 (訂單分頁自己的載入也交給 Root)；表單新增主檔選項的流程改為經 Root 交給主檔端。
- `apps/ios/CLAUDE.md`：
    - 刪除 6c 前的過渡例外 (訂單端注入四種主檔 Service、`CampaignWritesFeature` 經 `OrderService` 改名)；`Core/Dependencies/` 的過渡清單改寫。
    - 錯誤型別命名條目改為：Orders 用 `OrderError`，Campaigns 與 Lookups 沿用 `PersistenceError`。
    - 「父層送專用請求 action」的例子改為 `rootRequest(...)`；`OrdersFeature` 行數例外依實測處理。
    - 補「Feature 專屬 Service 只被該 Feature 引用」「每個 Feature 至多一個以資料庫為下層的 Service」與掃描守門。
- `apps/ios/README.md`：專案結構中 Service 的位置。

## Implementation Contract

- **可觀察行為**：
    - 主檔新增、改名、刪除、付款方式編輯，與從訂單表單新增選項的結果和提示與改動前相同。
    - 開團改名時開團與訂單同成同敗；失敗只出現「開團儲存失敗」提示，不再有「開團已儲存，但訂單歸屬改名失敗」。
    - 付款方式更正以資料庫當下的訂單重算，訂單尚未載入時也正確；確認筆數取自確認前的讀取。
    - 每次載入訂單前先讀取 (或確認已讀取) 主檔目錄；首次開啟的訂單表單即可選到已存的主檔。
    - 規格見 `specs/` 下五份 delta。
- **介面與資料形狀**：決策表中的 `LookupService` 與 `OrderError`；`CampaignService.renameCampaign` 與 `fetchReminderLinks`、`saveReminderLink`、`removeReminderLink`；`LookupCatalogFeature` 的 State、Action 與 Delegate；`LookupAdditionRequest`；`OrdersRootRequest` 與 `OrdersFeature.Action.rootRequest(_:)`、`delegate(.loadRequested)`、`delegate(.optionAddRequested)`；`MoreFeature` 的 `catalog` 子狀態與四個轉送 action；`PaymentMethodCorrectionFeature` 的 `Request`、帶請求的 `countResponse(request:result:)` 與 `pendingRequest`；`OrderEditPickersFeature.State.options`；`RootNavigationOperations.refreshDateContexts(state:)`。
- **失敗模式**：主檔目錄載入失敗保留原目錄、不呈現，並照常接著載入訂單；新增選項失敗沿用訂單容器的失敗提示；改名失敗沿用主檔管理的失敗提示且不送改名 delegate；付款方式更正的讀取或寫入失敗沿用「付款方式編輯失敗」；開團改名失敗為存檔失敗。
- **驗收**：
    - `grep -rn` 在 `apps/ios/BuyLedger/Core/` 找不到 `OrderService`、`OrderError`、`LookupService` 與四個主檔 Service 名稱；`LayerBoundaryTests` 通過。
    - `ServiceOwnershipScanTests` 兩條規則通過，且變異會轉紅。
    - `DependencyConventionScanTests`、`ProjectionWriteBoundaryTests`、`ActionGroupingScanTests`、`ServiceTestValueStrictnessTests` 通過。
    - 搬遷不減測試；新行為 (單一交易改名、交易內重算更正、新增選項經 Root、訂單在主檔讀取後載入) 有字面值測試並以變異確認。
    - `style_checks.py` 對清單現存檔只剩不計失敗的代碼。
    - 完整單元回歸與 iPhone、iPad 的 UI 主回歸通過；snapshot 不重錄，已知 4 條失敗依失敗圖判定。
- **範圍**：
    - **在範圍內**：上述 Service (含提醒連結併入 `CampaignService`)、錯誤型別、Feature 與測試的搬遷與改寫、`OrdersRootRequest`、Root 的行數調整、掃描守門、文件。
    - **不在範圍內**：Non-Goals 所列各項；不改 SwiftData schema 與任何 View 的版面。

## Risks / Trade-offs

- [與色盤 change 共用 Root 與 Root 測試檔] → 本 change 的 Root 修改集中在 1.7、2.4、2.5；後合併的一方 rebase 時把對方的兩行刷新呼叫與日期脈絡斷言移到新位置，合併後重跑 Root 測試與 `style_checks.py`。
- [啟動時主檔與訂單改為先後讀取] → 主檔是四張小表，延遲很小；換來「訂單已載入時主檔一定已讀取」，消除首次表單拿到空選項的時序問題。
- [確認筆數與實際重算筆數可能不同] → 只在確認與寫入之間另有訂單寫入時發生；寫入以資料庫當下為準，資料不會被舊值蓋掉。
- [`OrdersRootRequest` 改寫大量呼叫端與測試] → 純機械改寫，轉送目標不變，以既有測試不改斷言值驗證；與色盤 change 共用的 Root 測試檔依前述 rebase 方式處理。
- [`OrdersFeature` 仍可能接近 359 行] → 估計約 356 行；超過時先回報使用者，不另拆容器。
- [UI 測試替身是熱點檔] → 1.4 → 1.5 → 1.6 依序修改，之後只在 3.1 刪除舊部分。
- [合併主檔 Service 的測試大量改寫] → 依「預期值寫字面值」與搬遷前後的方法數、展開案例數比對，避免假綠。
