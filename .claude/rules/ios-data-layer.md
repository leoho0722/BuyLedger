---
paths:
  - "apps/ios/BuyLedger/Core/**"
  - "apps/ios/BuyLedger/Features/{Orders,Campaigns,Lookups,Customers,Dashboard,Insights}/**"
  - "apps/ios/BuyLedger/Features/App/RootFeature.swift"
  - "apps/ios/BuyLedgerTests/*{Persistence,Migration,Database,Residue}*.swift"
  - "apps/ios/BuyLedgerTests/{Order,Campaign,Category,OrderSource,ReconciliationStatus,PaymentMethod}Service*.swift"
---

# iOS 資料層與 SwiftData

## 容器與注入

- **容器共用、Service 注入與 `liveValue` 不 seed 的規則在 `apps/ios/CLAUDE.md` 的「環境相依性與依賴注入」**。
- **持久層是普通 `actor` 的 `BuyLedgerDatabase`，不用 `@ModelActor`**：macro 綁定單一長命 `modelContext`，正是 save 失敗後殘留的成因 (見「訂單寫入」)；`@ModelActor` 的 init 還帶 main actor 隔離，只能在 `async` context 建立，同步的 computed `liveValue` 無法建立它。

## 訂單寫入

- **建立與更新分兩個入口**：`OrderService.createOrder` 遇到同編號資料列拋 `OrderPersistenceError.identifierCollision` 且不寫入；`saveOrder` 才是 upsert。
    - `saveTapped` 採用 `OrderDraft.resolveWriteResult` 算出的意圖呼叫 `createOrder`／`saveOrder`，不自行以 `editState.original == nil` 重算：兩者在並行刪除或詳情堆疊過期時會分歧，撞號會退回靜默覆寫。
- **每次讀寫都經 `BuyLedgerDatabase.read`／`write` 取得一次性 `ModelContext`；`write` 成功只呼叫一次 `save()`，closure 拋錯或 `save()` 失敗就丟棄該 context，不呼叫 `rollback()`**：長命 context 在 save 失敗後，即使 `rollback()` 讓 `hasChanges` 變回 `false`，model 實例仍留著改過的值或刪除標記，之後對同一筆資料的寫入會把殘留帶進 store。
    - Service 不持有跨呼叫的 `ModelContext`／`ModelContainer`，closure 內只回傳 `Sendable` 的 domain 值，不回傳 `@Model`。
    - closure 是同步的，網路、行事曆、使用者確認等 `await` 步驟留在 Service 或 Feature，分成多次 `read`／`write`：`refreshIfStale`、付款方式更正、開團儲存後改名與行事曆都不是單一交易。
    - 改動 `BuyLedgerDatabase` 的 context 生命週期或錯誤處理後跑 `OrderServiceResidueTests` (刪除失敗後再刪、同 id 建立、同 id 更新、編輯失敗後改開團名稱四個情境)。
- **資料表無唯一性約束 (CloudKit 限制)，「查撞號再插入」必須在同一個 `write` closure 內完成**：`BuyLedgerDatabase` 是 actor 且 closure 同步執行，其他寫入插不進查詢與插入之間；拆成兩次呼叫會讓同編號並發寫入各自查無、各自插入。
    - live 只有一個 `BuyLedgerDatabase` 實例 (依賴快取只求值一次 `BuyLedgerDatabaseKey.liveValue`)，Service 內不另建；`OrderServiceTests.liveValue_連續解析兩次_取得同一資料庫實例()` 與 `createOrder_並行建立相同識別值_只成功一筆其餘明確撞號()` 守門。
- **`LedgerOrder.id` 存完整長度的隨機識別碼，不截短**；需要短碼顯示時用 `LedgerOrder.displayID`。
- **`LedgerOrder` 是 immutable struct**：改欄位用 memberwise init 重建整筆 (參考 `renaming*`／`removingCampaign` 系列擴充方法)。
- **照片位元組不隨訂單列常駐**：`OrderService.fetchOrders` 以 `propertiesToFetch` 排除 `photos` (回傳空陣列不代表沒有照片)，需要時用 `fetchOrderPhotos`；高頻的整表或多筆讀取路徑不得碰 `photos`。
    - `@Attribute(.externalStorage)` 對 `[Data]` 陣列不生效，不要依賴它。
- **`OrderRecord.apply(_:)` 永不寫照片**：照片只在插入 (`OrderRecord.init(order:)`) 與 `saveOrderPersistingPhotos` 的顯式覆寫時落地；不要把 `photos` 併進 `apply(_:)`，否則漏改的路徑會讓照片消失。

## 跨檔不變式

- **四種主檔 (訂單來源、商品類別、付款方式、對帳狀態) 以 `@Shared(.lookupCatalog)` 的 `LookupCatalog` 為單一來源**，CRUD 走 `LookupManagementFeature` (以 `LookupKind` 分流共用 reducer 與 view)。
    - 持久層改名成功後，`RootFeature` 收到 `LookupManagementFeature` 的 `.delegate(.itemRenamed)`，再更新記憶體內訂單，並經 `LookupKind.isReferenced(by:name:)`／`LookupKind.renamingReference(in:from:to:)` 分派。
    - 新增第五種主檔時編譯器會標出待補的 switch，但 `RootFeature.State.lookupManagements` 的初始陣列與 `MoreRoute` 是手寫字面值，漏補會靜默缺少管理畫面與入口。
    - `@Shared` 只用在主檔目錄；其他跨 feature 狀態 (客戶彙總、開團列表) 由 `RootFeature` 攔截子 feature action 同步副本，擴用前先確認真的有多個 feature 讀寫同一份資料。
    - `NameLookupRecordProtocol` 協定遵循放各記錄檔尾端的 extension，不碰型別主體：主體變動會改變 SwiftData 指紋、破壞 migration。
- **付款方式旗標正規化只有 `LedgerOrder.applyingPaymentMethodFlags(...)` 一處**：折抵上限、對帳狀態清空、貨到付款運費三條規則都在這裡，手動編輯與回溯更正共用。
- **主檔改名是一次原子操作**：`OrderService.applyOrderSourceRename`、`applyCategoryRename`、`applyPaymentMethodRename`、`applyReconciliationStatusRename` 各在一次 `database.write` 內改主檔與引用訂單，成功只 `save()` 一次；失敗時拋出原始錯誤並丟棄該 context，不能讓主檔與訂單只改一邊。名稱撞到既有項目時依主檔規則合併，付款方式同時合併旗標。
    - 改名只有 `OrderService` 這四個入口，各主檔 Service (`CategoryService`、`OrderSourceService` 等) 不提供改名 closure：只改主檔不改訂單會留下孤兒引用。
- **付款方式編輯是一次原子操作**：`PaymentMethodService.applyPaymentMethodEdit` 在單一 `database.write` 內更新主檔與重算訂單，失敗整批丟棄。
    - 只更新既有訂單、不插入；找不到目標 id 時整批拋 `PaymentMethodPersistenceError.orderNotFound`。
    - `PaymentMethodCorrectionFeature` 以一次 fetch 建立 `PaymentMethodEditPlan`，確認筆數與重算對象都取自該快照。
    - 取消確認時主檔旗標也不套用；零筆受影響或旗標未變的純改名不出現確認。
    - 資料流：`PaymentMethodCorrectionFeature` 取樣並要求必要確認 → `PaymentMethodService` 原子寫入 → `LookupManagementFeature` 送出 `paymentMethodEdited` delegate → `RootFeature` 攔截並純轉送同一份已正規化 payload (不再正規化) → `OrdersFeature` 以 `paymentMethodFlagsApplied` 套到記憶體內訂單且不再落盤；改動時一併檢查這些型別。
    - 付款方式編輯成功不走 `.delegate(.itemRenamed)`：旗標是權威覆寫，語意與更名 cascade 不同。
- **開團刪除在單一 `database.write` 交易內完成**：`CampaignService.removeCampaign` 移除 `CampaignRecord`、剝除所有訂單 `campaignNames` 中的該名稱、移除 `CampaignReminderRecord`，最後單次 `save()`，並回傳被移除提醒連結的行事曆事件 id。
    - 行事曆事件在本機刪除成功後才移除，失敗不回滾，但要以 `campaignWriteFailed` 告知。
    - `CampaignFeature` 收到刪除結果才更新狀態，`RootFeature` 再攔截 `campaignDeleted` 同步 `OrdersFeature.State` 的訂單與 `campaigns` 副本；改動時四檔一起看。
- **開團是否已收單一律呼叫 `Campaign.evaluatingAutoClose(asOf:calendar:)`** (`CampaignFeature`／`OrdersFeature`／`OrderEditFeature` 共用)，不各寫日期比對。
    - 結單日當天仍進行中，隔天 00:00 才轉已收單。
    - `asOf`／`calendar` 吃 reducer 注入的 `date.now`／`calendar`。
- **營收歸屬一律呼叫 `LedgerOrder.revenueAttributionOrders(from:)`** (總覽本月損益、分析走勢與成本結構、客戶累計消費)，不各寫 predicate。
    - 類別與開團彙總用另一口徑 `contributesToCategoryBreakdown`，兩者刻意並存、不可互換。
    - 被現存合併結果列為來源的訂單不計入營收；合併結果刪除後來源恢復計入。不在來源訂單上寫永久標記。
    - 合併結果被取消時，來源維持排除且該筆營收不計；這與刪除後恢復計入是刻意不同的規則。
- **客戶列的資格取自全部訂單** (成員、initials、tier、最近訂單日期)，金額與筆數取自營收歸屬子集，讓訂單全部取消的客人仍在名單且顯示零元。
- **成長率的百分比與方向同源**：`DashboardStats.ratio` 與 `InsightsStats.trendDelta` 以同一個本期減上期的差額決定方向，分母取 `abs(previous)`。

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
