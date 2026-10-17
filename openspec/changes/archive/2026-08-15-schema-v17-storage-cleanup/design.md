## Context

`OrderRecord.photos` 是不帶任何 attribute option 的 `[Data]`，位元組內嵌在訂單列裡。`OrderPersistence.fetchAll()` 無 `propertiesToFetch`、無分頁，把全部訂單連同照片解成 `[LedgerOrder]` 後整包放進 `OrdersFeature.State.orders` 常駐；TCA 每次 action 的 State 比較還要走一遍 `[Data]` 相等判斷。

盤點全 codebase 的照片使用點後確認一件關鍵事實：**照片只在訂單編輯器與合併流程的照片挑選步驟顯示**，訂單清單列與訂單詳情頁完全不繪照片。也就是說，常駐的位元組沒有任何一個畫面在用。

寫入面則有五個路徑會經 `OrderRecord.apply(_:)` 落地：批次改狀態 (兩處)、主檔 cascade 更名重建訂單、合併時更新既有訂單、以及一般 upsert。`apply(_:)` 目前無條件寫 `photos`，因此一旦讀取端不再帶位元組，這五個路徑全部會把照片寫成空陣列。

另有兩張恆空表 `SyncMeta` 與 `SyncQueueItem`：除了 schema 的版本 model 清單之外沒有任何讀寫，卻仍在每台裝置建表並參與指紋計算。當初保留的唯一理由是移除後會與更舊版本撞 checksum，該理由已隨 migration floor 收斂到 V15 而失效。

約束：migration floor 為 V15、target 為 V16，V15 與 V16 的 model 清單目前都直接引用兩張同步表的頂層型別。產品已發版，schema 升版是不可逆的 forward-only 操作。

## Goals / Non-Goals

**Goals:**

- 訂單清單的讀取路徑不再載入照片位元組，`OrdersFeature.State` 不再常駐照片
- 任何不涉及照片的寫入路徑，都不可能改動已存照片，且此保證由呼叫形式而非開發紀律達成
- 批次寫入與合併只讀取相關訂單列，不再掃全表
- 兩張恆空同步表退出正式 schema，`Core/Sync` 目錄自 repo 移除
- 既有使用者資料 (訂單、開團、主檔、提醒連結、照片) 在升版後零損失

**Non-Goals:**

- 不拆出獨立的照片資料表
- 不動兩個比對字串陣列內容的 cascade 更名的全表掃描
- 不抬 migration floor、不移除任何既有版本
- 不在跨平台 data model 增刪欄位
- 不強制搬移既有內嵌照片到外部儲存

## Decisions

### D1 照片位元組退出清單讀取路徑

`OrderRecord` 的領域轉換拆成可選擇是否帶照片的兩種形式：清單讀取取不帶照片的形式，單筆讀取取帶照片的形式。`fetchAll()` 回傳的每筆訂單其照片欄位一律為空陣列，並在 `FetchDescriptor` 上以 `propertiesToFetch` 明確列出除照片外的欄位。照片改由新增的「依訂單編號讀取照片」路徑按需取得。

替代方案：在跨平台 data model 加一個照片張數欄位，讓清單能顯示「有照片」標記而不帶位元組。已否決，因為清單與詳情本來就不顯示照片、不需要這個標記，且該欄位純粹服務單一平台的載入策略，違反跨平台 schema 的平台中立原則。

由此產生的語意負擔要明講：清單來源的訂單，其照片欄位為空**不代表**該訂單沒有照片。這正是 D2 與 D7 要處理的問題。

### D2 apply 不再寫入照片

`OrderRecord.apply(_:)` 移除對照片欄位的賦值，並在文件註解寫明此路徑永不寫入照片。照片改由新增的專用寫入形式落地，該形式要求呼叫端顯式傳入照片陣列。

這是本 change 最重要的安全設計：改動後，漏改或未來新增的寫回路徑，其後果是「照片維持不變」而不是「照片被清空」。相對地，若沿用單一 `apply(_:)` 並要求每個呼叫端記得帶正確照片，正確性就取決於每個現有與未來呼叫端都不出錯，而失敗模式是不可逆的資料遺失。

新增訂單的插入分支維持寫入照片：插入只在訂單編號不存在時發生，該訂單的照片必然來自呼叫端本身，不存在被清空的情境。

### D3 propertiesToFetch 為唯一保險 (外部儲存實測不成立)

原構想是照片欄位加 `@Attribute(.externalStorage)` 與 `fetchAll()` 的 `propertiesToFetch` 雙保險並行：`propertiesToFetch` 保證讀取時不取該欄位、不依賴任何未載明的框架行為；外部儲存讓位元組離開訂單列，使所有不觸碰照片的路徑 (批次寫入、合併、三個 cascade 更名) 都不再把 blob 拉進 row cache。

Apple 官方文件與 Context7 兩邊都只記載外部儲存的作用 (把屬性值以二進位檔存於 model storage 旁)，都沒有說明它對陣列型別是否成立。**實測結論：不成立**——以 300 KB × 3 張寫入僅帶 `.externalStorage` 的 `[Data]` 屬性後，store 目錄下未出現任何外部 blob 目錄，位元組仍留在 `-wal` 內 (檔案大小與寫入量相符)。因此 V17 的 `OrderRecord.photos` **不加** `.externalStorage`，主目標完全由 `propertiesToFetch` 與 D1 (拆分帶／不帶照片的領域轉換) 達成；批次寫入與合併路徑不再全表掃描 (見 D5/任務 8) 進一步降低 row cache 帶入 blob 的機會，但沒有外部儲存這層保險，仍要靠 `propertiesToFetch` 精確排除欄位。實測結論已記入平台 `CLAUDE.md` 避免日後重複嘗試。

### D4 索引限縮在訂單表的 id 與 date，實測後擴及零成本的小表

只對訂單表的訂單編號與日期補索引。開團表與五張主檔表都是數十列量級，索引效益近零，而它們的頂層型別被 V15 的 model 清單直接引用，原本顧慮一旦改動就得在 V15 與 V16 各凍一份 shadow，換來的是往後每次升版都要帶著的樣板。

**實作階段的指紋實測 (見 Open Questions) 證實索引不計入 schema 指紋**，故上述顧慮不成立：小表補索引不需要新增 shadow，是真正的零遷移成本。因此除訂單表 id／date 外，另對六張小表的 upsert 識別欄位補齊索引 (``CampaignRecord.id``、``CategoryRecord.name``、``PaymentMethodRecord.name``、``OrderSourceRecord.name``、``ReconciliationStatusRecord.name``、``CurrencyMetadataRecord.code``)，供各自的 rename／upsert 等值查詢使用。

### D5 移除同步兩表改以凍結 shadow 達成

兩張同步表的頂層型別定義隨 `Core/Sync` 目錄一併刪除，但其形狀必須在 V15 與 V16 各凍結一份內嵌 shadow，兩個版本的 model 清單改為引用各自的 shadow。V17 的 model 清單不含這兩型。

shadow 的註解要改寫成「僅為保住該版本指紋而凍結，runtime 恆為空、勿新增讀寫」，並刪掉描述 HLC 時鐘、tombstone、Firestore Storage 參照這些不存在機制的原始敘述。這樣既移除誤導性的頂層目錄，又讓型別定義仍可自 schema 檔與 git 歷史取回。

### D6 遷移 stage 種類以實測決定

V16 到 V17 這一段的 stage 種類不預先寫死。丟棄兩個零列 entity 屬 Core Data 原生支援的輕量操作，而改變屬性的儲存位置是否同樣輕量則無文件依據 (見 D3)。實作以既有的落地 store 遷移測試判定：若輕量 stage 可讓 V16 store 完整遷移且照片全數保留，即採輕量；否則改為自訂 stage 且兩個 closure 皆留空 (不搬動照片)，並記錄原因。

判定依據是測試結果而非推測，因為猜錯的後果是升級時照片遺失。

**實測結論 (輕量 stage 可行，已採用)**：由於 D3 實測後 `OrderRecord.photos` 未加 `.externalStorage`，V16 → V17 實際只剩「移除兩個零列 entity」與「訂單記錄補索引」兩項變動，兩者皆屬 Core Data 原生輕量遷移涵蓋範圍 (索引依 D4 的指紋實測結論本就不計入指紋，等同零變動)。`.lightweight(fromVersion: BuyLedgerSchemaV16.self, toVersion: BuyLedgerSchemaV17.self)` 經 `v16StoreMigratesToV17PreservingOrdersAndPhotos`／`v15StoreMigratesThroughV16ToV17`／`v17StoreReopensWithoutMigration` 三條落地 store 測試驗證：兩筆帶照片訂單 (單張／雙張) 經遷移後筆數、欄位值與照片位元組逐張相等，V15 經兩段 stage 到 V17 亦完整，V17 store 重開無二次遷移。不需要 `.custom` stage。

### D7 編輯器在照片載入完成前不寫入照片

訂單編輯器開啟既有訂單時，照片草稿不再取自傳入的訂單 (那份已無位元組)，改為發出依訂單編號讀取照片的效果。編輯器狀態新增照片載入階段與「使用者是否實際更動過照片」兩項資訊，儲存時據此分流：

- 使用者未更動照片 (含載入尚未完成、載入失敗) → 走不帶照片的寫入，已存照片維持不變
- 使用者確實增刪過照片 → 走帶照片的專用寫入

載入未完成或失敗時，照片區塊顯示對應狀態且加入與刪除控制項停用，使用者無從產生「更動」，因此不可能觸發帶照片的寫入。這讓 D1 帶來的語意負擔在編輯器這個唯一的寫入來源被完整吸收。

### D8 合併流程在挑選步驟前載入雙方照片

合併流程判斷是否進入照片挑選步驟時，依據的是兩張來源訂單的照片合計張數，故必須先載入雙方照片。合併確認後寫入新訂單時走帶照片的專用寫入形式，把使用者挑選保留的照片顯式落地。

## Implementation Contract

**行為**

- 開啟 App 後訂單清單的載入不再把照片位元組讀進記憶體；記憶體常駐量與帶照片訂單的筆數脫鉤
- 訂單編輯器開啟既有訂單時，照片區塊先呈現載入中，載入完成後顯示該訂單既有照片；載入失敗時顯示失敗狀態並停用加入與刪除控制項
- 使用者未碰照片而儲存訂單、批次改狀態、更名任一主檔或開團、或合併訂單時，既有照片一律維持不變
- 合併流程在兩張來源訂單照片合計超過上限時才進入挑選步驟，且挑選畫面顯示的是雙方實際照片
- 升級後既有訂單、開團、主檔、提醒連結與照片全部保留

**介面與資料形狀**

- 持久層新增：依訂單編號讀取照片的方法、帶照片的訂單寫入方法、帶照片的合併寫入方法
- 持久層修改：領域轉換方法改為可指定是否帶照片；`apply(_:)` 不再涉及照片欄位；讀取全部訂單的 descriptor 帶 `propertiesToFetch`；批次 upsert 與合併改用捕獲訂單編號陣列的 `#Predicate`
- Repository 新增對應的三個 `@Sendable` 閉包欄位，既有欄位語意不變
- schema 新增 `BuyLedgerSchemaV17`；V15 與 V16 各新增兩張同步表的內嵌 shadow、V16 另新增改動前形狀的訂單記錄 shadow；migration plan 的版本清單成為三版、stage 成為兩段；容器建構指向 V17

**失敗模式**

- 照片載入失敗：編輯器顯示失敗狀態、停用照片控制項，儲存走不帶照片的路徑，已存照片不受影響。此失敗必須對使用者可見，不得靜默
- 遷移失敗：本 change 以先行的持久層安全復原改動為前提，store 原地保留、不刪檔
- 批次 predicate 若因訂單編號數量過多而轉譯失敗：改為分批讀取後合併字典，仍以單一儲存動作落盤以維持原子性

**驗收條件**

- 落地 store 遷移測試：以 V16 形狀寫入含照片訂單與主檔的 store，用 V17 計畫開啟後筆數、每個欄位值與照片位元組完全相同
- 落地 store 遷移測試：以 V15 形狀寫入的 store 經兩段 stage 後資料完整，證明 floor 未被意外抬高
- 落地 store 指紋守門測試：V17 store 再次開啟時不觸發任何遷移
- 同步表缺席測試：V17 的 model 清單不含兩張同步表，而 V15 與 V16 仍含 (防止未來誤刪 shadow)
- 讀取測試：讀取全部訂單所得的每筆訂單照片欄位為空，而依訂單編號讀取照片可取回完整位元組
- 照片保全測試：對含照片訂單執行批次改狀態、五種主檔與開團更名、以及不帶照片的一般寫入後，該訂單照片位元組不變
- 編輯器測試：載入未完成、載入失敗、載入完成但未更動三種情形下儲存，皆不寫入照片；載入完成且有增刪時才寫入
- 合併測試：挑選步驟出現前雙方照片已載入，且確認後寫入的照片與使用者勾選結果一致
- 批次讀取測試：庫內數百筆訂單、只批次更新或合併少數幾筆時，其餘訂單的狀態、日期與照片完全未變
- 原始碼檢查：專案內對兩張同步表的引用只剩 schema 檔中 V15 與 V16 的 shadow，`Core/Sync` 目錄不存在
- iPhone 與 iPad simulator 各 build 成功，主 scheme 全部單元測試綠
- 人工升級驗收：以改動前版本產生的 store 安裝本次 build 後，訂單筆數、照片張數與對帳狀態皆不變，且未進入記憶體內容器的退化路徑

**範圍界線**

- 在範圍內：訂單照片的儲存與載入路徑、訂單記錄的寫入語意、訂單編輯器與合併流程的照片載入、schema V17、兩張同步表的移除、批次寫入與合併的讀取收斂、相關文件同步
- 不在範圍內：獨立照片資料表、兩個比對字串陣列的 cascade 更名、migration floor 調整、跨平台 data model 形狀、既有內嵌照片的一次性搬移、照片以外的效能議題

## Risks / Trade-offs

- [外部儲存對陣列型別可能不成立，照片瘦身收益落空] → 主目標由 `propertiesToFetch` 與 D1 獨立達成，不依賴此 attribute；實作第一步先實測，不成立就拿掉並把結論寫進平台 `CLAUDE.md` 避免重複嘗試
- [V16 的訂單記錄 shadow 若漏欄位或漏欄位改名標註，會讓停在 V16 的 store 遷移失敗] → shadow 逐欄對照改動前的頂層定義建立，並以跨版本的落地 store 遷移測試作為機器守門；本 change 以先行的持久層安全復原改動為前提，遷移失敗時 store 原地保留
- [讀取端不帶照片後，任何未覆蓋到的照片寫入路徑會清空使用者照片] → D2 把預設行為改成不寫照片，使漏改的後果變成照片不變；照片保全測試對五種更名與批次改狀態逐一斷言
- [編輯器新增載入階段，可能在載入完成前被使用者儲存] → 載入未完成時照片控制項停用、儲存走不帶照片路徑，此情形有專屬測試涵蓋
- [捕獲訂單編號的 predicate 在數量很大時可能轉譯失敗] → 以數百筆規模的批次測試覆蓋實際可能的上限；失敗則改分批讀取，落盤仍為單一動作
- [新增索引增加寫入成本與 store 體積] → 索引範圍限縮在訂單表兩個實際高頻條件 (D4)，並在效能測試記錄改動前後數值
- [升版後無法退回舊版 App] → schema 為 forward-only，V17 store 無法被 V16 目標開啟；驗收期間保留一份升級前的 store 備份
- [單一 change 的任務數偏多] → 已評估拆成「schema 側」與「照片載入路徑」兩個 change 並否決：只做 schema 側無法降低記憶體常駐，會讓對應風險看似收斂而實際未解，且兩者的驗收本來就必須放在同一次升級驗證裡

## Migration Plan

1. 先確認先行的持久層安全復原改動已套用 (遷移失敗時 store 原地保留而非刪檔)，否則本 change 一旦出錯即為靜默清空
2. 實測外部儲存與索引指紋兩項未知數，據以定案 D3 與 D4 的最終範圍
3. 凍結 shadow → 新增 V17 → append stage → 容器指向 V17，順序不可調換
4. 以落地 store 測試逐一驗證 V16 到 V17、V15 經 V16 到 V17 兩條路徑
5. 人工升級驗收：以改動前 commit build 一份、寫入數筆帶照片訂單產生舊版 store，再安裝本次 build 覆蓋確認資料完整
6. 回退策略：本次為 forward-only 升版，無法以降版回退；發布前保留升級前 store 備份，發布後若發現問題只能以修補版前滾

## Open Questions

- 外部儲存對陣列型別是否成立：Apple 官方文件與 Context7 皆未記載，由實作第一步實測決定 (D3)
  - **實測結論 (不成立)**：以 300 KB × 3 張寫入僅帶 `@Attribute(.externalStorage)` 的 `[Data]` 屬性後，store 目錄下只有 `.store`／`-shm`／`-wal` 三檔，未出現 `_SUPPORT`／`_EXTERNAL_DATA` 等外部 blob 目錄；`-wal` 檔大小 (~972 KB) 與寫入的照片位元組總量 (~900 KB) 相符，顯示位元組仍內嵌於 WAL 而非外置。判定 `.externalStorage` 對 `[Data]` 陣列型別不生效，V17 不加此 attribute，主目標改由 D1 的 `propertiesToFetch` 獨立達成
- 索引是否計入 schema 指紋：同樣無文件依據，由實作第一步實測決定，結果影響 D4 是否擴及小表
  - **實測結論 (不計入)**：以一對僅差一個 `#Index` 宣告的 `VersionedSchema` (中間刻意不放任何 bridging stage) 測試，用「無索引」schema 建 store 寫入一筆資料後，改用「有索引」schema + 空 `stages` 陣列的 migration plan 重新開啟同一 store，開啟成功且資料完整讀回，未拋出任何遷移相關錯誤。判定 `#Index` 不計入 schema 指紋，故 D4 的索引範圍除訂單表 id／date 外，另對五張小表 (``CategoryRecord``／``PaymentMethodRecord``／``OrderSourceRecord``／``CurrencyMetadataRecord``／``CampaignRecord``) 的 upsert 識別欄位補齊索引，零遷移成本
