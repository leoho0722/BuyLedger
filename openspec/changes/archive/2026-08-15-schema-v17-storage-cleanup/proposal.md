## Summary

升到 schema V17：讓訂單照片改走外部儲存、清單讀取不再載入照片位元組、批次寫入與合併不再全表掃描，並把兩張恆空的同步表與誤導性的 `Core/Sync` 目錄自正式 schema 與 repo 移除。

## Motivation

**照片位元組隨每次清單讀取整批進駐記憶體。** `OrderRecord.photos` 是不帶任何 attribute option 的 `[Data]`，位元組直接躺在訂單列裡；`OrderPersistence.fetchAll()` 既無 `propertiesToFetch` 也無分頁，一次把所有訂單連同全部照片解成 `[LedgerOrder]`，再整包塞進 `OrdersFeature.State.orders` 常駐。單張照片經 1600px／q0.75 正規化後約數百 KB、每單上限 5 張，累積數百筆帶照片訂單即數百 MB 常駐；更糟的是 TCA 每次 action 的 State 比較都要走一遍 `[Data]` 的相等判斷。這是隨使用時間單調惡化的壓力。

只加 `@Attribute(.externalStorage)` **不足以**解決：`fetchAll()` 走 `records.map { $0.toDomain() }`，而 `toDomain()` 無條件讀 `photos`，延後載入會立刻被打回原形。要真正讓清單不帶位元組，必須連同讀取路徑一起改。

**批次寫入為了建索引字典而掃全表。** `upsertAll` 與 `mergeOrders` 各有一次無 predicate 的 `FetchDescriptor<OrderRecord>()`：批次改三筆訂單的狀態，卻要把整庫連照片一起載進 row cache。這個成本與上一條相乘。

**兩張恆空表仍掛在正式 schema 上。** `SyncMeta` 與 `SyncQueueItem` 是為已放棄的跨裝置同步設計的，全 codebase 對它們只有 schema 版本清單這一處引用，沒有任何讀寫。它們仍在每台裝置建表並參與 migration 指紋計算，且註解仍描述 HLC 時鐘、tombstone 與 Firestore Storage 參照這些早已不存在的機制，對維護者具誤導性。當初保留的唯一技術理由是「移除後形狀會與更舊版本撞 checksum」，該理由已隨 migration floor 收斂到 V15 而失效。

## Proposed Solution

**一、schema 升到 V17。** 依 `/swiftdata-schema-migration` 的四步：把改動前的 `OrderRecord` 凍結為 `BuyLedgerSchemaV16` 的內嵌 shadow、把 `SyncMeta` 與 `SyncQueueItem` 分別凍進 V15 與 V16 的 shadow、新增 `BuyLedgerSchemaV17`、append 一段遷移 stage、把 `PersistenceContainer.make` 的 schema 指向 V17。V17 的 model 清單不再含那兩張同步表。migration floor 維持 V15 不動。

**二、照片改走外部儲存，且讀取路徑不再帶位元組。** `OrderRecord.photos` 加 `@Attribute(.externalStorage)`；`toDomain()` 拆成帶參數的版本，`fetchAll()` 以不含照片的形式回傳、並在 `FetchDescriptor` 上以 `propertiesToFetch` 明確排除 `photos`。照片改由專用讀取路徑依訂單編號按需取得，只有實際會顯示照片的兩個流程 (訂單編輯器、合併流程的照片挑選步驟) 才載入。

**三、把「照片被靜默清空」做成結構上不可能。** `OrderRecord.apply(_:)` 不再寫入 `photos`：所有經由它落地的路徑 (批次改狀態、主檔 cascade 更名、訂單重建) 從此不可能影響已存照片。照片只能經新增的專用寫入路徑落地，且該路徑只在使用者確實編輯過照片時才被呼叫。如此一來，任何漏改或新增的寫回路徑，其後果是「照片維持不變」而不是「照片消失」。

**四、收斂全表掃描。** `upsertAll` 與 `mergeOrders` 改用捕獲訂單編號集合的 `#Predicate` 只撈相關列。

**五、移除死碼層。** 刪除 `Core/Sync` 目錄兩檔與其過期註解，同步更新 README 專案結構表與平台 `CLAUDE.md`。

## Non-Goals

- **不拆出獨立的照片資料表。** 把照片移到 `OrderPhotoRecord` 並讓清單只讀縮圖是更徹底的作法，但成本遠高於本次目標；本次採能達成同一效果的最小改動。
- **不動 `renameCategory` 與 `renameCampaign` 的全表掃描。** 這兩者比對的是字串陣列的內容，`#Predicate` 對陣列 `contains` 的支援有限；照片外置後它們本來就不再拉進位元組，收益已大部分取得。
- **不抬 migration floor。** 產品已發版，無法排除仍有裝置停在 V15；抬 floor 會讓那些 store 失去遷移路徑。
- **不在跨平台 data model 加欄位。** 曾考慮加一個照片張數欄位讓清單顯示「有照片」標記，但清單與詳情本來就不顯示照片，且該欄位純粹服務單一平台的載入策略，違反跨平台 schema 的平台中立原則。
- **不強制搬移既有的內嵌照片。** 已落在訂單列內的位元組不做一次性外置，由 SwiftData 在該筆下次寫入時自然改走外部儲存；強制搬移等於在遷移期重寫整庫，風險遠高於收益。

## Alternatives Considered

- **只做 schema 側 (外部儲存、索引、predicate 收斂、移除同步表)，照片載入路徑另開 change。** 這是原始設計 brief 的預設值，好處是不把「可能清空照片」的行為改動與不可逆的 schema 升版綁在同一次發版。已評估並否決：只做 schema 側無法真正降低記憶體常駐 (`toDomain()` 仍無條件讀 `photos`)，會讓對應的稽核風險看起來已收斂而實際未解。取而代之的是把清空風險用第三點的結構性設計消除。
- **維持一份 `apply(_:)` 並在每個呼叫端記得帶正確照片。** 已否決：這要求每個現有與未來的寫回路徑都不出錯，而失敗模式是不可逆的資料遺失。改成「預設不寫照片」讓正確性由型別與呼叫形式保證，而非靠紀律。

## Impact

- Affected specs: `schema-migration-plan` (修改)、`order-photo-attachments` (修改)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
    - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
    - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
    - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/README.md
    - apps/ios/CLAUDE.md
  - Removed:
    - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
    - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
