---
paths:
  - "apps/ios/BuyLedger/Core/**"
  - "apps/ios/BuyLedger/Features/{Orders,Campaigns,Lookups,Customers,Dashboard,Insights,More}/**"
  - "apps/ios/BuyLedger/Features/App/Root{Feature,NavigationOperations,LaunchFeature,LaunchOperations}.swift"
  - "apps/ios/BuyLedgerTests/*{Persistence,Migration,Database,Residue}*.swift"
  - "apps/ios/BuyLedgerTests/{Order,Campaign,Lookup}Service*.swift"
---

# iOS 資料層與 SwiftData

## 容器與注入

- **容器共用、Service 注入與 `liveValue` 不 seed 的規則在 `apps/ios/CLAUDE.md` 的「環境相依性與依賴注入」**。
- **持久層是普通 `actor` 的 `BuyLedgerDatabase`，不用 `@ModelActor`**：macro 綁定單一長命 `modelContext`，正是 save 失敗後殘留的成因 (見「訂單寫入」)；`@ModelActor` 的 init 還帶 main actor 隔離，只能在 `async` context 建立，同步的 computed `liveValue` 無法建立它。

## 訂單寫入

- **建立與更新分兩個入口**：`OrderService.createOrder` 遇到同編號資料列拋 `OrderError.identifierCollision` 且不寫入；`saveOrder` 才是 upsert。
    - 表單驗證通過後送 `delegate(.saveRequested)`，容器轉給 `OrderWritesFeature`，採用 `OrderDraft.resolveWriteResult` 算出的意圖呼叫 `createOrder`／`saveOrder`，不自行以 `editState.original == nil` 重算：兩者在並行刪除或詳情堆疊過期時會分歧，撞號會退回靜默覆寫。
- **每次讀寫都經 `BuyLedgerDatabase.read`／`write` 取得一次性 `ModelContext`；`write` 成功只呼叫一次 `save()`，closure 拋錯或 `save()` 失敗就丟棄該 context，不呼叫 `rollback()`**：長命 context 在 save 失敗後，即使 `rollback()` 讓 `hasChanges` 變回 `false`，model 實例仍留著改過的值或刪除標記，之後對同一筆資料的寫入會把殘留帶進 store。
    - Service 不持有跨呼叫的 `ModelContext`／`ModelContainer`，closure 內只回傳 `Sendable` 的 domain 值，不回傳 `@Model`。
    - closure 是同步的，網路、行事曆、使用者確認等 `await` 步驟留在 Service 或 Feature，分成多次 `read`／`write`：`refreshIfStale`、付款方式更正 (確認前讀筆數、確認後寫入)、行事曆都不是單一交易。
    - 改動 `BuyLedgerDatabase` 的 context 生命週期或錯誤處理後跑 `OrderServiceResidueTests` (刪除首次儲存失敗後重試、同 id 建立、同 id 更新三個情境) 與 `CampaignServiceTests` 的 `renameCampaign_訂單更新儲存失敗後_改名不帶入失敗欄位`。
- **資料表無唯一性約束 (CloudKit 限制)，「查撞號再插入」必須在同一個 `write` closure 內完成**：`BuyLedgerDatabase` 是 actor 且 closure 同步執行，其他寫入插不進查詢與插入之間；拆成兩次呼叫會讓同編號並發寫入各自查無、各自插入。
    - live 只有一個 `BuyLedgerDatabase` 實例 (依賴快取只求值一次 `BuyLedgerDatabaseKey.liveValue`)，Service 內不另建；`OrderServiceTests.liveValue_連續解析兩次_取得同一資料庫實例()` 與 `createOrder_並行建立相同識別值_只成功一筆其餘明確撞號()` 守門。
- **`LedgerOrder.id` 存完整長度的隨機識別碼，不截短**；需要短碼顯示時用 `LedgerOrder.displayID`。
- **`LedgerOrder` 是 immutable struct**：改欄位用 memberwise init 重建整筆 (參考 `renaming*`／`removingCampaign` 系列擴充方法)。
- **照片位元組不隨訂單列常駐**：`OrderService.fetchOrders` 以 `propertiesToFetch` 排除 `photos` (回傳空陣列不代表沒有照片)，需要時用 `fetchOrderPhotos`；高頻的整表或多筆讀取路徑不得碰 `photos`。
    - `@Attribute(.externalStorage)` 對 `[Data]` 陣列不生效，不要依賴它。
- **`OrderRecord.apply(_:)` 永不寫照片**：照片只在插入 (`OrderRecord.init(order:)`) 與 `saveOrderPersistingPhotos` 的顯式覆寫時落地；不要把 `photos` 併進 `apply(_:)`，否則漏改的路徑會讓照片消失。

## 跨檔不變式

- **四種主檔 (訂單來源、商品類別、付款方式、對帳狀態) 以 `@Shared(.lookupCatalog)` 的 `LookupCatalog` 為單一來源**，管理頁 CRUD 走 `LookupManagementFeature` (以 `LookupKind` 分流共用 reducer 與 view)。
    - 主檔目錄的寫入者只有 `LookupManagementFeature` 與 `LookupCatalogFeature`，訂單端 (`OrdersFeature`、`OrderListFeature`) 以 `@SharedReader(.lookupCatalog)` 唯讀 (`ServiceOwnershipScanTests` 掃描 `Features/Orders/` 不得出現可寫入的 `Shared(.lookupCatalog)` 或 `Shared<LookupCatalog>`)。所有訂單載入都排在主檔目錄讀取結束之後 (Root 先送 `.more(.catalogLoadRequested)`)；表單新增選項經 Root 與 `MoreFeature` 交給 `LookupCatalogFeature` 落盤，成功才更新目錄，結果以 `.orders(.rootRequest(.optionAdditionCompleted(_:isStored:)))` 送回容器。
    - 持久層改名成功後，`LookupManagementFeature` 送出 `.delegate(.itemRenamed)`，`MoreFeature` 帶上主檔種類轉成 `.delegate(.lookupItemRenamed(kind:rename:))`，Root 送 `.orders(.rootRequest(.cascade(.lookupItemRenamed(kind:rename:))))`；容器轉給 `OrderWritesFeature`，由 reducer 以 `Features/Orders/OrdersCascadeOperations` 更新共用訂單，分派經 `LookupKind.isReferenced(by:name:)`／`LookupKind.renamingReference(in:from:to:)` 處理。
    - 新增第五種主檔時編譯器會標出待補的 switch，但 `MoreFeature.Entry` 的 case 與其推入對照、`BLAccessibilityID.More.Row` 是手寫列舉，漏補會靜默缺少管理畫面與入口。
    - 共享範圍為主檔目錄 (`.lookupCatalog`)、幣別清單 (`.currencyCodes`)、訂單與開團容器的無鍵資料及載入狀態、`MoreFeature.State.orders` 投影；其他跨 feature 狀態 (客戶彙總等) 由 Root 以 `onChange` 投影成副本，跨 feature 意圖以 delegate 交給 Root，擴用前先確認需要共用引用。
    - `NameLookupRecordProtocol` 協定遵循放各記錄檔尾端的 extension，不碰型別主體：主體變動會改變 SwiftData 指紋、破壞 migration。
- **開團資料以 `CampaignFeature.State` 的無鍵 `@Shared` 為來源**：`campaigns`、`orders` (訂單投影)、`reminderLinks`、`isShowingUnpaidOnly` 四份，建立容器時同時指派給自己與各子 Feature 的 State，父子共用同一份引用。
    - 子 Feature 的 `init` 對唯讀資料只接 `SharedReader`，由父層以 `SharedReader(_:)` 轉換後傳入：`SharedReader` 沒有 setter 與 `withLock`，列表與詳情在編譯期就無法寫入投影與連結。
    - 開團與「更多」的訂單投影僅由 Root 以 `state.campaigns.$orders.withLock` 與 `state.more.$orders.withLock` 寫入，不能當成訂單資料來源；`Features/Campaigns/` 與 `Features/More/` 內投影的 `$orders` 只能作為 `SharedReader(` 的引數，`ProjectionWriteBoundaryTests` 守門。
    - `MoreFeature.State.orders` 是同型的投影，推入客戶頁時以 `SharedReader(state.$orders)` 傳入。
    - 共享寫入在 reducer 內同步完成，不移到 effect 裡再回送：`RootFeature` 的 `onChange(of: \.campaigns.campaigns)` 只觀察得到 reducer 內的 `withLock`。
- **訂單資料以 `OrdersFeature.State.orders` 的無鍵 `@Shared` 為來源**：容器建立同一份引用交給子層，清單與詳情只接 `SharedReader`，容器本身不寫。
    - 只有 `OrdersLoadFeature` (套用讀取結果) 與 `OrderWritesFeature` (寫入結果、cascade、付款方式旗標套用) 在 reducer 內以 `withLock` 更新來源；不在 `.run` effect 內寫，也不外傳可寫引用，`ProjectionWriteBoundaryTests` 分別守住來源與 Root 的投影寫入。
    - Root 的 `onChange(of: \.orders.orders)` 在實際修改來源的那一次 action 同步開團、「更多」、總覽與分析；這一次是載入回應、寫入回應或 `writes` 套用 cascade 的 action，不能以最初請求或 delegate 的時點代替。
    - `campaigns`、`defaultCurrency`、`aiSummarySettings` 是 Root 寫入 Orders 的投影，Orders 內部與 helper 只讀；Root 透過容器的 State 方法處理新訂單、日期刷新與篩選導覽，不直接改清單子 State。
- **幣別清單以 `@Shared(.currencyCodes)` 在記憶體內共用**：Root 的 `RootLaunchFeature` 在 `refreshIfStale` 後讀一次 `fetchCodes`，刷新失敗也讀快取，成功且非空才更新；Orders 只以 `@SharedReader(.currencyCodes)` 建立選項。
    - 讀取失敗或空結果保留原值；只有共用清單為空時，表單選項才使用 `CurrencyCode.defaults`。
- **付款方式旗標正規化只有 `LedgerOrder.applyingPaymentMethodFlags(...)` 一處**：折抵上限、對帳狀態清空、貨到付款運費三條規則都在這裡，手動編輯與回溯更正共用。
- **主檔改名是一次原子操作**：`LookupService.renameItem` 在一次 `database.write` 內改主檔與引用訂單，成功只 `save()` 一次；任一步失敗就丟棄整個 context，不能讓主檔與訂單只改一邊。名稱撞到既有項目時依主檔規則合併，付款方式同時合併旗標。
    - 改名只經 `LookupService.renameItem` 一個入口，依 `LookupKind` 分派；`LookupService` 沒有只改主檔不改訂單的操作，否則會留下孤兒引用。
- **付款方式編輯是一次原子操作**：`LookupService.applyPaymentMethodEdit` 在單一 `database.write` 內更新主檔，並以原名稱選取訂單後重算，失敗整批丟棄；`countOrders` 提供確認筆數。
    - 只更新既有訂單、不插入；交易內選取到零筆訂單時只更新主檔。
    - `PaymentMethodCorrectionFeature` 旗標有變時先以 `countOrders` 讀筆數，確認後才呼叫 `applyPaymentMethodEdit`；兩者之間若另有訂單寫入，確認筆數可能與實際重算的筆數不同，寫入一律以資料庫當下的訂單為準。
    - 取消確認時主檔旗標也不套用；零筆受影響或旗標未變的純改名不出現確認。
    - 資料流：`PaymentMethodCorrectionFeature` 讀筆數並要求必要確認 → `LookupService.applyPaymentMethodEdit` 原子寫入並回傳訂單 → `PaymentMethodCorrectionFeature` 送 `.delegate(.edited(plan))` → `LookupManagementFeature` 更新目錄並送 `paymentMethodEdited` delegate → `MoreFeature` 原樣轉送 → Root 送 `.orders(.rootRequest(.paymentMethodFlagsApply(plan.affectedOrders)))` → 容器轉給 `OrderWritesFeature` 在 reducer 內套用同一份已正規化資料，不重算旗標、不重複落盤；改動時一併檢查這些型別。
    - 付款方式編輯成功不走 `.delegate(.itemRenamed)`：旗標是權威覆寫，語意與更名 cascade 不同。
- **開團刪除在單一 `database.write` 交易內完成**：`CampaignService.removeCampaign` 移除 `CampaignRecord`、剝除所有訂單 `campaignNames` 中的該名稱、移除 `CampaignReminderRecord`，最後單次 `save()`，並回傳被移除提醒連結的行事曆事件 id。
    - 行事曆事件在本機刪除成功後才移除，失敗不回滾，但要以 `CampaignReminderFeature` 的 `delegate(.failed(.eventRemovalAfterDeleteFailed))` 告知。
    - 資料流：`CampaignWritesFeature` 收到刪除結果才更新共用開團並送 `delegate(.deleted)` → `CampaignFeature` 移除該開團的詳情，再送 `delegate(.campaignDeleted)` 與 `.reminder(.campaignRemoved)` → Root 送 `.orders(.rootRequest(.cascade(.campaignDeleted(name))))` → 容器轉給 `OrderWritesFeature` 在 reducer 內調整共用訂單；改動時一併檢查這些型別。開團改名由 `CampaignService.renameCampaign` 在同一筆交易內更新開團與訂單的 `campaignNames`，`CampaignFeature` 送 `delegate(.campaignRenamed)` 後 Root 只送 cascade 同步記憶體內的訂單。
- **開團是否已收單一律呼叫 `Campaign.evaluatingAutoClose(asOf:calendar:)`** (`CampaignLoadFeature` 載入與 `OrdersEditorOptions` 建構表單選項共用)，不各寫日期比對。
    - 結單日當天仍進行中，隔天 00:00 才轉已收單。
    - `asOf`／`calendar` 吃 reducer 注入的 `date.now`／`calendar`。
    - 自動結單的更新與存檔只由 `CampaignLoadFeature` 負責；Orders 的開團來自 Root 投影，選項建構只評估、不寫回。
- **營收歸屬一律呼叫 `LedgerOrder.revenueAttributionOrders(from:)`** (總覽本月損益、分析走勢與成本結構、客戶累計消費)，不各寫 predicate。
    - 類別與開團彙總用另一口徑 `contributesToCategoryBreakdown`，兩者刻意並存、不可互換。
    - 被現存合併結果列為來源的訂單不計入營收；合併結果刪除後來源恢復計入。不在來源訂單上寫永久標記。
    - 合併結果被取消時，來源維持排除且該筆營收不計；這與刪除後恢復計入是刻意不同的規則。
- **客戶列的資格取自全部訂單** (成員、initials、tier、最近訂單日期)，金額與筆數取自營收歸屬子集，讓訂單全部取消的客人仍在名單且顯示零元。
- **成長率的百分比與方向同源**：`DashboardStats.ratio` 與 `InsightsStats.trendRatio` 都以本期減上期的差額除以 `abs(previous)` 計算 (上期為 0 時為 `nil`)，百分比文字與 `BLTrend(delta:)` 的方向都由這個比值的正負決定。

## 生成型別 (`Core/Domain/Generated/`)

- **`<Type>.generated.swift` 不手改** (磁碟上唯讀)：改 `shared/data-model/schema/` 後在 `shared/data-model/generator` 跑 `bun run generate`；IDE 提示唯讀無法存檔即代表正在手改生成檔。
- **手寫邏輯放同名 extension 檔** (如 `LedgerOrder.swift` 只含 `extension LedgerOrder`)；沒有手寫邏輯的型別 (`Money`、`LedgerCustomer`、`PaymentMethodInfo`) 沒有手寫檔。
- **`Sendable` 由 emitter 對所有生成型別無條件加上**，不是 schema trait，不寫進 schema。
- **`serialization: custom` 的型別 (`CurrencyCode`、`LedgerOrderItem`) 生成宣告不含 `Codable`**：自訂 `Codable` 留在手寫 extension，保住既有編碼形狀 (如 `LedgerOrderItem` 不寫出 `id`)。
- **新增或刪除 Domain 型別後 iOS 與 iPadOS 各 build 一次**，確認 synchronized group 拾取 `Generated/` 下的新檔。

## Schema 與遷移

- **改 schema 前先 invoke `/swiftdata-schema-migration`**：schema 全定義在 `Core/Persistence/BuyLedgerSchema.swift` (`VersionedSchema` + `BuyLedgerMigrationPlan`)，目前的 floor 與 target 以 `BuyLedgerMigrationPlan.schemas` 為準。
- **floor 以外每個保留版本把當時的 `@Model` 凍結為內嵌 shadow**：target 的 `models` 引用 top-level `@Model`，改 top-level 型別會破壞舊版指紋、導致遷移失敗。
    - shadow 註解寫明「僅為保住該版本指紋而凍結，runtime 恆為空、勿新增讀寫」，不保留已移除機制的描述。
- **遷移方式依改動類型選擇**：
    - 加欄位、加表、丟棄零列 entity、加索引 (`#Index`) → `.lightweight`；改既有欄位型別 → `.custom` dump-and-restore。
    - 改欄位名 → `@Attribute(originalName:)` (lightweight，底層欄位名不變)。
    - 改 `@Model` 類別名 → `.custom`：SwiftData 沒有 entity 級 originalName；凍結舊 shadow 後在 `willMigrate` 讀舊 entity 暫存 (`nonisolated(unsafe) static`)、`didMigrate` 寫新 entity。
    - stage 種類拿不準時，用 `SchemaMigrationTests` 的落地 store 遷移測試判定，不憑文件推測。
- **加索引不需凍結 shadow，但證據只涵蓋「單一 `String` 欄位的單欄 `#Index`、不拉新版本」** (`SchemaMigrationTests.init_同版本schema加單欄索引_直接開啟並保留資料()`)：複合索引、非 `String` 欄位、伴隨拉新版本的索引調整要另補落地 store 測試。
    - 「store 開得起來」不能證明指紋沒變：SwiftData 會為未登記的改動自動推導輕量遷移。
    - `OrderRecord` 現有的 `Date` 欄位索引超出上述證據，由 `SchemaMigrationTests` 的兩條落地 store 遷移測試守住。
- **移除舊版本會抬高 floor，單向不可逆**：停在低於新 floor 的 store 會失去遷移路徑 (啟動時保留原始檔案並顯示阻斷式復原畫面)。
    - 只在確定沒有 store 停在被移除版本時才可移除；上架後這個前提幾乎不成立，要保留完整版本鏈。
    - 「已在 target 就安全」是單一裝置的結論，建立在 CloudKit `.disabled` 上；啟用同步前要重新評估。
- **store 開不起來時保留檔案、退到 in-memory 並阻斷正常介面**：恢復資料要補正確的 migration stage，或經使用者確認後搬移 store 改用空白資料庫 (`PersistenceFailureFeature`)。
    - 搬移走 `PersistenceRecoveryService.quarantineStore`，由 `BuyLedgerDatabase.quarantineStore()` 依建立時給定的 `StoreLocation` 處理 (production 為 `.applicationSupport`)，不從 container 推斷：降級後 container 是 in-memory，仍要能隔離磁碟上的 store。
