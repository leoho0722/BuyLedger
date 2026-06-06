## Context

BuyLedger 的訂單目前以單一字串欄位記錄商品類別 (`LedgerOrder.category`) 與開團歸屬 (`LedgerOrder.campaignName`，空字串 = 未歸團)，SwiftData schema 為 V10 (floor V7，全部 stage 皆 `.lightweight`)。訂單狀態 `OrderStatus` 有六個 case，Insights 與 Dashboard 以 allowlist (`realizedStatuses = [confirmed, purchased, shipping, delivered]`) 篩選計入收益的訂單。編輯表單 (`OrderEditFeature` / `OrderEditView`) 的類別走 `OptionPickerSheet` 單選 sheet，開團走 inline `Picker`；表單儲存由父層 `OrdersFeature.applyEditDraft` 攔截 `saveTapped` 寫回。`OrderDetailView` 是無 store 的純 view，由 `OrdersCompactView` (push) 與 `OrdersView` (split detail pane) 各自掛載。

本變更要在此基礎上：(1) 類別與開團改多選、(2) 新增「已合併」狀態、(3) 建立兩筆訂單合併為一筆新訂單的完整流程。

## Goals / Non-Goals

**Goals:**

- 訂單可同時歸屬多個商品類別與多個開團，編輯、篩選、列表顯示、統計與 cascade rename 全鏈路一致。
- 兩筆訂單可經「候選選擇 → (照片超量挑選) → 預填確認表單 → 儲存」流程合併為一筆新訂單；儲存後兩筆舊訂單狀態轉「已合併」且不再計入收益統計。
- 合併計算為純函式、可單元測試；金額遵守「客戶實付與成本各 row 加總、手續費以實付加權平均 (金額守恆)」。
- SwiftData schema 安全升版 V10 → V11 (`.custom` stage)，既有 on-disk 資料不遺失。

**Non-Goals:**

- 一次合併三筆以上訂單 (流程固定為主訂單 + 一筆候選)。
- 合併還原 (un-merge)：舊訂單保留於資料庫即為歷史紀錄，不提供反向操作。
- 訂單列表的批次多選模式 (已否決的入口方案；本變更採 context menu + 詳情頁雙入口)。
- 照片上限調整 (維持 5 張) 與照片壓縮邏輯變更。
- CloudKit sync 啟用或相關 entitlements 變更。
- 開團主檔 (`CampaignRecord`)、商品類別主檔的資料結構變更——主檔本身仍是名稱清單，只有「訂單對主檔的歸屬」改多選。

## Decisions

### 資料模型改為多選並新增「已合併」狀態

- `LedgerOrder.category: String` → `categories: [String]`；`campaignName: String` → `campaignNames: [String]` (空陣列 = 未歸團)。`LedgerOrder` 為 immutable struct，所有重建一律走 memberwise init (現行 `RootFeature.rebuildOrder` 模式)。
- `LedgerOrder` 新增 `mergedSourceIDs: [String]` (預設空陣列)：由合併產生的訂單記錄兩筆來源訂單 ID，作為統計歸屬 (採合併前收益) 與鏈式合併展開的依據；非合併產生的訂單一律為空陣列。
- 選擇「改名 + 改型別」而非保留舊欄位名：呼叫點全部要動，藉編譯錯誤窮舉所有受影響位置，避免遺漏。
- `OrderStatus` 新增 `merged` case (rawValue `"merged"`、title「已合併」)，排在 `cancelled` 之後。DB 以 String rawValue 儲存，**新增 case 不需 schema 變更**。
- `realizedStatuses` allowlist 維持不變，`merged` 自然被排除——已合併舊訂單不會與合併後新訂單重複計入收益。
- 編輯表單的狀態 Picker 過濾掉 `merged` (僅當該筆訂單目前已是 `merged` 時才顯示)，「已合併」只能由合併流程寫入，避免使用者手動設置造成語意混亂。訂單列表的狀態篩選則包含「已合併」，讓使用者能找回被合併的舊單。

### SwiftData V11 custom migration

- 新增 `BuyLedgerSchemaV11`：`OrderRecord.category: String` → `categories: [String]`、`campaignName: String` → `campaignNames: [String]`，並新增 `mergedSourceIDs: [String]` (預設空陣列)；其餘欄位與 V10 相同；`CampaignRecord` 等其他 model 不變。
- V10 的 `OrderRecord` 凍結為 V10 enum 內嵌 shadow 型別，top-level `OrderRecord` 改為 V11 定義；migration plan 追加 V10 → V11 stage。
- 型別改變依專案政策走 `.custom` dump-and-restore：willMigrate 讀出每筆舊資料的 `category` 與 `campaignName`，寫入新欄位——`category` 非空字串映射為單元素陣列、空字串映射為空陣列；`campaignName` 空字串 (未歸團) 映射為空陣列；`mergedSourceIDs` 一律初始化為空陣列 (V10 以前不存在合併訂單)。
- 實作時 invoke `/swiftdata-schema-migration` skill 取得逐步指引；`SchemaMigrationTests` 新增 V10 on-disk store 升版的回歸案例，驗證單選值正確映射成陣列且資料不遺失。

### OptionPickerSheet 多選模式

- `OptionPickerSheet` 新增多選模式：以 `Set<String>` 表示目前選取、點列切換勾選、sheet 不自動關閉、toolbar 提供「完成」。現有單選 API 與行為完全保留 (option-picker spec 既有 requirement 不變)。
- **多選編輯僅在合併情境啟用**：合併確認表單 (`mergeSourceIDs` 非空的草稿) 與編輯合併產生的訂單 (`original.mergedSourceIDs` 非空) 時，類別列與開團列才使用多選模式——類別保留「新增類別」入口、開團僅可從既有開團挑選 (沿用現行限制)；trigger row 以「、」串接顯示已選值，開團空選取顯示「未歸團」。
- **一般訂單編輯維持現行單選體驗**：類別沿用單選 `OptionPickerSheet`、開團沿用 inline `Picker`，選取結果儲存為單元素陣列 (開團未歸團為空陣列)。

### 編輯表單多選草稿與金額欄位編輯性

- `OrderEditFeature.State.draftCategory: String` → `draftCategories: [String]`；`draftCampaignName: String` → `draftCampaignNames: [String]`。
- 必填驗證：類別至少選一個 (`canSave` 條件由「非空字串」改為「非空陣列」)；開團可為空。
- `OrdersFeature.applyEditDraft` 對應改為陣列寫回 (逐元素 trim、去除空字串與重複)。
- **金額與明細欄位維持可編輯** (2026-06-07 實機驗收後的需求變更，取消原「鎖定」決策)：收款金額 (客戶實付/無卡折抵/無卡補款)、成本 (四項)、手續費 (三項)、商品明細 (新增/編輯/刪除商品列) 四個 section 在合併確認表單、編輯合併產生的訂單、編輯「已合併」舊訂單時，皆與一般訂單一樣可編輯；不再有 `isAmountLocked` 判定與鎖定 footer。
- 已知後果：合併後調整新單或舊單金額時，類別/開團統計 (採合併前舊單數字) 與整體總收益 (採新單) 可能產生落差，屬已知且接受的語意 (見 Risks)。被合併舊單可藉由改狀態脫離「已合併」，作為誤合併後的手動回復路徑。

### 合併流程與 OrderMergeFeature

- 新增子 feature `OrderMergeFeature`，由 `OrdersFeature` 以 optional 子 state + `.sheet(item:)` 呈現，sheet 一律掛在 `OrdersView` 最外層 (與 `editOrder` sheet 同層，三平台共用)。
- 兩步驟狀態機：
  1. **候選選擇**：列出可合併訂單——排除主訂單自身、排除狀態為「已合併」與「已取消」者、限與主訂單同幣別、限與主訂單同客戶名稱 (不支援跨客戶合併)；支援搜尋；每列顯示客戶名稱、訂購日期、客戶實付。
  2. **照片挑選** (條件步驟)：兩筆照片合計超過 `LedgerOrder.maxPhotoCount` (5) 時，sheet 內切換到照片格狀挑選頁，使用者勾選保留至多 5 張後按「繼續」；合計未超限則跳過此步驟。
- 入口：
  - 訂單列 context menu (`OrdersView`、`OrdersCompactView` 與 `OrdersMacView` 三處，與現有「刪除」同層) 新增「合併訂單」，發起的訂單即主訂單；主訂單狀態為「已合併」或「已取消」時不顯示此項。
  - 詳情頁入口由各 host 的標題列／toolbar 直接送 `OrdersFeature` 同一個 action：`OrdersView` 寬版自繪標題列與 `OrdersMacView` inspector 標題列加「合併」按鈕、`OrdersCompactView` push 頁 toolbar 加合併動作；`OrderDetailView` 本身維持無 store、毋須修改。已合併/已取消訂單不顯示該動作。三處的「更新狀態」快速選單同步過濾「已合併」(僅當目前狀態已是已合併時保留)。
- 完成後 `OrderMergeFeature` 以 delegate action 回傳 (主訂單、副訂單、保留照片)；`OrdersFeature` 關閉合併 sheet、以合併結果預填 `editOrder` (新訂單草稿，`original = nil`)。合併 sheet 關閉與編輯 sheet 開啟需序列化，避免 SwiftUI 同 frame 換 sheet 的 presentation race (以 effect 延遲一拍再開編輯表單)。
- `OrderEditFeature.State` 新增 `mergeSourceIDs: [LedgerOrder.ID]` (預設空陣列)：非空代表這是合併草稿，儲存時父層據此把舊單轉「已合併」並把這組 ID 寫入新訂單的 `mergedSourceIDs`；取消則整個流程不留任何變更。

### 合併計算 OrderMerge 純函式

- 新增 domain 型別 `OrderMerge` (檔案 BuyLedger/BuyLedger/Core/Domain/OrderMerge.swift)，提供靜態純函式：輸入主訂單、副訂單與當下時間 (由 caller 以 `@Dependency(\.date)` 注入)，輸出合併草稿值 (供 `OrdersFeature` 映射到 `OrderEditFeature.State`)。
- 欄位規則 (對齊需求 2-1)：
  - 客戶名稱、訂單來源、狀態、幣別、收款狀態：取主訂單值 (客戶名稱因合併限同客戶，兩筆必然相同)。
  - 付款方式：兩筆相同時取該值；不同時，若恰有一筆屬無卡類則取該筆的付款方式 (以無卡為主，保住折抵/補款加總不被非無卡的歸零規則清掉)，其餘情況取主訂單值。對帳狀態與是否貨到付款一律隨「付款方式來源」那筆訂單。
  - 商品類別：兩筆 `categories` 聯集 (保序：主訂單在前，去重)。開團項目：兩筆 `campaignNames` 聯集 (同樣保序去重)。
  - 訂購日期：合併當下時間。
  - 客戶實付、無卡折抵、無卡補款、商品成本、外國國內運費、國際運費、國內運費：各 row 兩筆相加。
  - 手續費三項 (刷卡/平台/金流)：以兩筆客戶實付為權重做加權平均——`合併比例 = (比例A × 實付A + 比例B × 實付B) ÷ (實付A + 實付B)`，結果 clamp 至 [0, 1]；兩筆實付皆為 0 時沿用主訂單比例。
  - 商品明細：主訂單 items 在前、副訂單 items 在後串接，內容不變動。
  - 備註：兩筆皆非空時以獨立一行的 dash line (`----------`) 分隔串接 (`主訂單備註\n----------\n副訂單備註`)；任一邊為空則直接取非空者，不加分隔線。
  - 照片：主訂單在前、副訂單在後串接；合計超過 5 張時由照片挑選步驟決定保留集合，純函式本身不截斷。

### 統計歸屬與篩選比對

- 篩選：訂單列表的類別篩選與指定開團篩選維持「單選一個篩選值」，比對由相等改為 `contains`——訂單的類別/開團陣列包含所選值即符合 (篩選是導覽用途，合併產生的訂單照常被篩出，與統計歸屬規則無關)。
- 統計歸屬採「合併前收益 (葉端訂單)」：
  - 定義「葉端訂單」= `mergedSourceIDs` 為空的訂單 (非由合併產生)。由合併產生的訂單一律不參與類別/開團分組，其收益由合併前舊訂單以各自原始的類別、開團、金額與日期入帳。
  - 類別收益的計算來源為「狀態屬 `realizedStatuses` 或 `merged` 的葉端訂單」(對齊現行 realized-only 行為，僅放行已合併舊單)。開團統計 (`CampaignSummary`、獲利排行、Dashboard 卡片、分貨清單) 的成員為「葉端 + `campaignNames.contains`」、**不加新的狀態過濾** (分貨清單本來就需要報價中/已確認訂單，維持既有行為)；僅到貨進度分母比照已取消排除「已合併」。
  - 鏈式合併 (合併單再被合併) 因合併產生的訂單永不入組、葉端舊單永遠保留，天然不會重複計算，毋須遞迴展開。
  - 整體總收益、趨勢圖等不分類別/開團的彙總維持現行 realized 規則 (採合併後新訂單、合併日期)；已合併舊單仍被 realized allowlist 排除。
  - 因多選編輯僅在合併情境開放，葉端訂單必為單類別/單開團，分類歸屬即為精確值；防衛性規則：若葉端訂單仍出現多值 (理論上不會發生)，全額計入其每一個類別/開團；類別陣列為空的葉端訂單不歸入任何類別卡片。
  - Insights 每團獲利排行、Dashboard 開團卡片、`CampaignSummary` 的成員判定改為「葉端 + `campaignNames.contains(campaignName)`」。
- 列表顯示：`OrderRowView` 第三行 tag 將多個類別以「、」串接為單一 tag (版面風險最低；無類別維持現行缺席行為)。`OrderDetailView` 的類別與開團欄同樣以「、」串接顯示。

### 持久化合併寫入與 cascade rename

- `OrderPersistence` / `OrderRepository` 新增 `mergeOrders(new: LedgerOrder, consumedIDs: [LedgerOrder.ID])`：在同一次 save 內插入新訂單並把被合併訂單狀態改為 `merged`，保證原子性 (不可分兩次呼叫，避免中途失敗造成半合併狀態)。
- `renameOrderCategory` / `renameOrderCampaign` 的 cascade rename 改為「陣列內逐元素取代」；`RootFeature.rebuildOrder` 對應參數改陣列。`LookupManagementFeature` 與主檔刪除行為不變 (刪主檔不回寫訂單，維持現行語意)。
- `LedgerOrder+Samples` 與 `previewValue` seed 資料改用陣列欄位，並補一筆多類別/多開團樣本供 Preview 與 snapshot 驗證。

## Implementation Contract

**可觀察行為：**

1. 在訂單列 context menu 或訂單詳情頁對狀態非「已合併/已取消」的訂單觸發「合併訂單」，會出現候選 sheet：僅列同幣別、同客戶名稱、非已合併/已取消的其他訂單，可搜尋。
2. 選定候選後：兩筆照片合計 ≤ 5 直接進入預填的新訂單表單；> 5 先進入照片挑選頁，勾選至多 5 張後才進表單。
3. 預填表單各 section 值符合「合併計算 OrderMerge 純函式」一節的欄位規則；全部欄位 (含收款金額、成本、手續費、商品明細) 皆可調整後按「儲存」。
4. 儲存後：訂單列表出現一筆新訂單 (記錄兩筆來源訂單 ID)，兩筆舊訂單狀態變為「已合併」且仍可在列表 (狀態篩選「已合併」) 找到。整體總收益僅計入新訂單；類別收益與開團統計則由合併前舊訂單以原始類別/開團/金額/日期入帳 (合併產生的訂單不參與分組)，收益不重複計算。在表單按「取消」則資料庫與列表完全不變。
5. 合併情境 (合併確認表單、編輯合併產生的訂單) 的類別與開團為多選 (類別至少一個才能儲存、開團可全不選 = 未歸團)；一般訂單編輯維持單選體驗。列表第三行與詳情頁以「、」串接顯示多值。
6. 編輯合併產生的訂單或狀態為「已合併」的舊訂單時，所有欄位 (含收款金額、成本、手續費、商品明細) 照常可編輯；類別與開團維持多選 picker，狀態 Picker 仍過濾「已合併」(僅當目前狀態已是已合併時保留)。
7. 既有單類別/單開團的 on-disk 資料升級 App 後自動遷移為單元素陣列，未歸團遷移為空陣列，資料不遺失。

**介面／資料形狀：**

- `OrderStatus.merged` (rawValue `"merged"`)。
- `LedgerOrder.categories: [String]`、`LedgerOrder.campaignNames: [String]`、`LedgerOrder.mergedSourceIDs: [String]`。
- `OrderMerge` 靜態純函式：輸入 (主訂單, 副訂單, 合併當下 Date)，輸出合併草稿值集合。
- `OrderRepository.mergeOrders(new:consumedIDs:) async throws`。
- `OrderMergeFeature` (TCA reducer，兩步驟 state machine，delegate 回傳合併三元組)。
- `OrderEditFeature.State.mergeSourceIDs: [LedgerOrder.ID]`。
- `OptionPickerSheet` 多選模式 (Set 選取 + 完成按鈕)，單選 API 不變。

**失敗模式：**

- `mergeOrders` 持久化失敗：拋錯由 `OrdersFeature` 既有錯誤路徑呈現，in-memory 狀態不得只改一半 (新單與舊單狀態同進退)。
- 合併表單取消：無任何持久化副作用。
- 加權平均分母為 0 (兩筆實付皆 0)：沿用主訂單比例，不得產生 NaN。

**驗收標準：**

- 單元測試：`OrderMergeTests` (欄位規則逐項——加總、加權平均、備註串接、聯集去重、零實付 edge case)、`OrdersFeatureTests` (合併 action flow：候選過濾、照片步驟觸發條件、儲存後舊單轉 merged、取消不留變更)、`OrderEditFeatureTests` (多選草稿與必填驗證、合併情境的多選/單選分流)、`SchemaMigrationTests` (V10→V11 映射)、`OrderPersistenceTests` (mergeOrders 原子性、陣列 cascade rename)、`CampaignSummaryTests` (contains 歸屬)。
- 三平台 build 成功 (序列化執行)；iOS 實機 build-and-run 供使用者驗收互動流程。
- Snapshot 基準僅在 UI 實際變動的畫面重錄，並於 PR 說明。

**範圍邊界：**

- In scope：上述 domain/schema/feature/UI/統計/測試變更。
- Out of scope：合併超過兩筆、un-merge、列表批次多選模式、照片上限調整、CloudKit、開團主檔結構、AI 摘要 prompt 調整 (若僅欄位型別連動則屬編譯修正，不改其行為)。

## Risks / Trade-offs

- [首個 `.custom` migration stage，dump-and-restore 寫錯會毀損使用者資料] → 凍結 V10 shadow、依 `/swiftdata-schema-migration` skill 流程操作、`SchemaMigrationTests` 以 V10 on-disk store 做升版回歸；`makeForApp()` 的砍檔 fallback 僅為開發期保險，不作為依賴。
- [合併 sheet 關閉後立即開編輯 sheet 的 SwiftUI presentation race] → 兩段呈現序列化 (effect 延遲一拍)；若仍不穩定，退而把編輯表單併入同一個 sheet 的第三步驟。
- [合併後再編輯新訂單或被合併舊單的金額，類別/開團統計 (採合併前舊單數字) 與整體總收益 (採新單) 產生落差] → 已知且接受 (使用者 2026-06-07 實機驗收後選定金額與明細維持可編輯)；落差僅出現在合併後又改金額的情況。
- [被合併舊單若在合併單仍存在時被手動改回非「已合併」狀態，整體總收益會重複計算] → 屬使用者明確的回復操作；回復路徑的預期用法是先刪除合併單再改狀態，文件與測試以此為準。
- [來源訂單合併當下狀態若為報價中，轉「已合併」後即計入類別/開團統計 (合併前原本不計)] → 已知的近似；合併情境以已確認後的訂單為主，影響極小，不另存合併前狀態。
- [被合併舊單遭使用者手動刪除會使類別/開團統計失去該筆收益] → 與現行「刪除訂單即移除其統計」語意一致，接受。
- [付款方式不同的兩筆合併，無卡折抵/補款可能被非無卡付款方式的存檔歸零規則清掉] → 合併規則已以無卡為主預填付款方式；殘餘風險僅剩使用者在表單手動改成非無卡，屬使用者明確操作，依現行表單語意歸零。
- [類別/開團改名 cascade 現在要改寫陣列元素，與合併流程併發時可能互相覆蓋] → 兩者皆走同一 `PersistenceContainer.shared` 與 main-actor 序列化路徑，維持現行單寫者模式即可。
- [多 tag 以「、」串接在窄版列可能截斷] → 接受截斷 (lineLimit 維持現行)，詳情頁可看完整值。

## Migration Plan

1. Schema 先行：V11 + custom stage + 遷移測試，確保任何 UI 改動前資料層已穩定。
2. Domain 與呼叫點隨編譯錯誤逐一修正 (欄位改名策略保證窮舉)。
3. Feature 與 UI (多選 picker → 合併流程 → 入口) 依 tasks 順序實作。
4. Rollback：上架前發現問題直接 revert 整個 change branch；**V11 一旦隨正式版發布即不可移除** (依 schema-migration-plan 的 forward-only 政策，floor 不得越過任何已安裝版本)。

## Open Questions

- 統計歸屬主方向「採合併前收益 (葉端訂單)」為使用者選定；其三個子決策 (手動多選葉端訂單 fallback 全額計入、合併後編輯不回溯統計、類別/開團統計沿用舊單原始日期) 為依建議採行，使用者可推翻——調整時僅影響「統計歸屬與篩選比對」一節的彙總實作，合併流程不受影響。
