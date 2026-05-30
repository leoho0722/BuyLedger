## Context

BuyLedger 是 iOS／iPadOS／macOS 三平台代購記帳 App，採 Swift 6 strict concurrency、TCA、SwiftData (+ CloudKit 相容設計)。現有四種主檔 (商品類別／訂單來源／付款方式／對帳狀態) 皆為純名稱清單，由共用的 LookupManagementFeature 服務；訂單 (LedgerOrder，immutable struct) 以字串名稱引用主檔，改名時由 RootFeature 統一 cascade。訂單已有 6 階段履約狀態 (OrderStatus)，但缺少「團」這個聚合層級。

本設計新增「開團 (Campaign)」為有狀態的獨立實體與專屬分頁，並把分貨、收款、結算全部 derive 自歸屬訂單。SwiftData schema 目前最新為 V7。

## Goals / Non-Goals

**Goals:**

- 開團成為可追蹤進度的一級實體：有生命週期狀態、彙總進度、結團結算。
- 分貨清單與結算為訂單的純投影，零雙重輸入。
- 訂單可歸屬單一開團並標記收款狀態；訂單列表可按開團狀態與團名篩選。
- Dashboard 與 Insights 呈現開團摘要，並能跳轉到開團詳情。
- Schema 以 lightweight 遷移升 V8，不破壞既有使用者資料。

**Non-Goals:**

- 客戶主檔 (consistent customer entity)：本次以訂單上的客戶名稱分組，客戶主檔另開後續獨立 change。
- 一筆訂單歸屬多個開團 (多對多)：本次為單一歸屬。
- 結團後鎖定訂單編輯：本次結團僅為視覺與結算標記，不鎖定。
- 截單日自動轉用背景排程：本次採前景掃描 (啟動與進列表時)，不引入背景任務。
- 「部分收款」第三態：收款狀態本次只做待收款／已收款兩態。
- 訂單編輯時即時新增開團：訂單編輯只能選既有團。

## Decisions

### Campaign 採用獨立有狀態實體，不擴充為第五種 LookupKind

開團具備狀態、日期與彙總詳情，遠超純名稱主檔的能力。沿用 LookupManagementFeature 會被其「僅 name 欄位」的假設綁死。因此 Campaign 自帶 domain struct、CampaignRecord (@Model)、CampaignRepository、CampaignPersistence (@ModelActor) 與獨立的 CampaignFeature；但「名稱清單 + cascade rename」機制仍參考訂單來源既有作法。替代方案 (硬塞成 LookupKind) 因無法承載狀態／日期／結算而否決。

### CampaignStatus 兩態加 settledDate 結團標記

CampaignStatus 為兩態 enum：開團中 (ongoing) → 已收單 (closed)。「結團」不是第三個狀態，而是設定 settledDate 的完成動作；一個團可同時是「已收單 + 已結算」。如此狀態軸專注於「是否還在收單」，結算里程碑獨立記錄，避免狀態語意混雜。替代方案 (三態，把已結團當狀態) 因使用者明確偏好兩態而否決。CampaignRecord 以 statusRaw: String 儲存 rawValue (非 enum)，避免日後改動 enum 破壞 schema 指紋。

### 截單日到自動由開團中轉已收單，採前景掃描並走依賴注入日期

有設截單日 (closeDate) 的團，當截單日早於現在時，狀態自動由開團中轉已收單。觸發點為 App 啟動與進入開團／訂單列表時掃描，掃到符合者即更新並寫回持久層。所有「現在」時間一律取自 @Dependency(\.date)，不得直接呼叫 Date()。沒設截單日的團維持手動切換；結團永遠手動。替代方案 (背景排程自動轉) 因複雜度與「在使用者未操作時悄改資料」的疑慮而否決；不轉狀態的純手動方案因使用者要求自動而否決。

### 訂單以 campaignName 字串歸團並沿用 cascade rename

訂單以 campaignName (String，預設空字串代表未歸團散單) 引用開團，與訂單來源的 string-name 模式一致，便於 lightweight 遷移與 CloudKit 相容 (不需唯一性約束)。開團改名時由 RootFeature 攔截 CampaignFeature 發出的改名通知，rebuild 所有 campaignName 相符的 immutable LedgerOrder、呼叫 OrderRepository 的開團改名 cascade、並同步 OrdersFeature 記憶體副本。替代方案 (以穩定 id 引用 + join) 因偏離既有全專案字串引用慣例而否決。

### 訂單新增 paymentReceiptStatus 收款狀態欄位

訂單目前無「已收款／未收款」概念 (OrderStatus 是履約、chargedAmount 只是金額、verificationStatus 僅對無卡與匯款有意義)。新增固定二元 enum PaymentReceiptStatus (待收款／已收款)，於 OrderRecord 以 rawValue 字串儲存、帶 default，供分貨清單與結算判定「已收款」。此 enum 不接 LookupManagementFeature 主檔，因為已收款金額的彙總需要穩定可判定的值。

### 分貨清單與結算全部 derive 自歸屬訂單 (CampaignSummary)

新增純函式 helper CampaignSummary，輸入團名與全部訂單，輸出皆為投影：分貨清單依客戶名稱 (去頭尾空白) 分組，件數為品項數量加總、金額為 chargedAmount 加總、已收款判定為該客戶全部訂單皆為已收款；收款面為應收／已收／未收 (chargedAmount 基準)；損益面重用既有 OrderSummary 加總 (成本／毛利／利潤率)；到貨進度為已交付訂單比例，分母排除已取消。彙總邏輯不依賴「現在」時間。商業邏輯放可測試 helper，SwiftUI View 只呈現。

### Schema V8 lightweight 遷移與凍結 V7 OrderRecord 影子型別

新增 CampaignRecord 表與訂單兩個帶 default 的欄位，屬新增欄位／新增表，採 lightweight 遷移。標準流程：新增 BuyLedgerSchemaV8 列出含 CampaignRecord 的 models；把 V7 的 OrderRecord 凍結成 V7 enum 內的影子 @Model (欄位停在 verificationStatus，逐欄位對齊現行指紋)，V7.models 改指向影子；MigrationPlan append V8 與 lightweight stage；PersistenceContainer 的 Schema 指向 V8。其餘 record 在 V8 未變動，不需新增影子。

### CampaignFeature 與資料流：OrdersFeature 持有完整 Campaign 副本

CampaignFeature (State／Action／Reducer，reducer body 用顯式 some Reducer<State, Action>) 負責開團列表、狀態切換與 CRUD effect；CampaignEditFeature 為新增／編輯團的 sheet 子 reducer。開團詳情與列表 view 直接吃 RootFeature store (比照 Dashboard／Insights)，以讀取 store.orders.orders 做分貨投影。OrdersFeature 另持有完整 [Campaign] 副本 (非僅名稱)：供訂單編輯選團，並供訂單列表按開團狀態篩選時解析每筆訂單所屬團的狀態。Campaign 改名與狀態變更需同步 CampaignFeature 與 OrdersFeature 兩處副本。

### 訂單列表雙維度開團篩選

OrdersFeature 的篩選管道新增 selectedCampaign (指定團名) 與 selectedCampaignStatus (全部／開團中／已收單) 兩個維度，併入既有 filteredOrders(referenceDate:)，與類別、付款方式篩選並列；列表仍按日期分組。狀態篩選透過 OrdersFeature 的 Campaign 副本把訂單的 campaignName 對應到開團狀態。

### Dashboard 與 Insights 開團整合與 campaignSelected 跨頁導覽

Dashboard 在 KPI 與近期訂單間插入「進行中的開團」卡：列出開團中的團與其進度條 (到貨／收款) 與金額；無進行中的團則整卡隱藏。Insights 在成本結構卡附近插入「每團毛利排行」長條圖，於 InsightsStats 加開團分組 (比照類別分組)。新增 RootFeature.Action.campaignSelected(name)：切到開團分頁並選取該團詳情，比照既有 categorySelected。兩處圖卡點擊皆觸發此 action。

## Implementation Contract

**行為 (Behavior):**

- 使用者在「開團」分頁可建立、編輯、刪除開團；開團列表每列顯示團名、狀態 pill、筆數、總額、已收款與到貨進度；無開團時顯示空狀態。
- 開團詳情顯示：meta (開團日／截單日／狀態／備註)、結團結算卡 (應收／已收／未收、總成本／毛利／利潤率)、客戶分貨清單 (每列客戶、件數、金額、已收款標記，可展開品項，可一鍵只看未收款)、該團訂單逐筆 (可切換收款狀態)、「結團」按鈕 (設 settledDate)。
- 有截單日且已過期的開團中團，於 App 啟動與進列表時自動轉為已收單並持久化。
- 訂單編輯可選擇歸屬的既有開團與收款狀態；開團改名後，所有歸屬訂單的 campaignName 同步更新。
- 訂單列表可按開團狀態 (全部／開團中／已收單) 與指定團名篩選。
- Dashboard 顯示進行中的開團進度卡 (無則隱藏)；Insights 顯示每團毛利排行；點擊任一開團入口跳到該團詳情。

**介面／資料形狀 (Interface / Data shape):**

- 新 domain：Campaign { id: UUID, name, openDate, closeDate: Date?, status: CampaignStatus, settledDate: Date?, notes }；CampaignStatus { ongoing, closed }；PaymentReceiptStatus { pending, received }。
- LedgerOrder 新增 campaignName: String 與 paymentReceiptStatus: PaymentReceiptStatus；OrderRecord 對應新增 campaignName: String = "" 與收款狀態 rawValue 字串欄位 (帶 default)。
- CampaignRepository closures：fetchCampaigns、saveCampaign (upsert by id)、removeCampaign(id)、renameCampaign(from:to:)；OrderRepository 新增 renameOrderCampaign(from:to:)。
- CampaignSummary 純函式：distribution(分貨列含客戶／件數／金額／已收款)、收款面 (應收／已收／未收)、損益面 (重用 OrderSummary)、到貨比例。
- RootFeature.Action 新增 campaignSelected(String)；OrdersFeature.State 新增 selectedCampaign 與 selectedCampaignStatus 與完整 Campaign 副本。

**失敗模式 (Failure modes):**

- 持久層讀取失敗時，開團列表顯示錯誤訊息並維持空集合，不顯示假資料。
- 散單 (campaignName 為空字串) 不歸入任何團；空開團彙總為 0 筆／0 元／進度 0%。
- 應收為 0 時，收款比例與到貨比例回傳 0，不得除零。

**驗收標準 (Acceptance criteria):**

- 單元測試：CampaignSummaryTests (分組、件數與金額加總、已收款判定、收款面、損益面、到貨比例排除已取消、散單不納入)、CampaignFeatureTests (載入與自動轉狀態、狀態切換、結團、新增／刪除，使用固定注入日期與遞增 UUID)、CampaignPersistenceTests (in-memory upsert／fetch／rename／delete)、RootFeature 的開團改名 cascade 與 campaignSelected 跳轉、OrdersFeature 的開團載入與雙維度篩選。
- 手動驗證：以 V7 既有資料升級至 V8，確認舊訂單仍在；三平台序列 build 通過；iOS build-and-run 檢視開團分頁、訂單編輯新欄位、Dashboard 卡與 Insights 圖。

**範圍邊界 (Scope boundaries):**

- 範圍內：開團實體與分頁、分貨與結算、訂單兩新欄位與 cascade、雙維度篩選、Dashboard／Insights 整合、Schema V8。
- 範圍外：客戶主檔、多對多歸屬、結團鎖定、背景排程、部分收款、訂單編輯內新增團。

## Risks / Trade-offs

- [V7 OrderRecord 影子型別指紋凍結抄錯] → 逐欄位對照現行 OrderRecord (含 default)，build 後以既有 V7 資料實機／模擬器升級驗證舊訂單仍在；不依賴 PersistenceContainer 的砍檔 fallback。
- [LedgerOrder 為 immutable struct，多處手寫 memberwise 重建漏補新欄位] → 盤點所有重建點 (RootFeature 的 rebuild、OrdersFeature 的狀態變更與套用編輯草稿) 一次補齊；以編譯器全參數必填特性確保不漏。
- [Campaign 改名／狀態變更需同步 CampaignFeature 與 OrdersFeature 兩處副本] → 由 RootFeature 統一攔截處理，兩處副本與訂單表一次更新；補對應 RootFeature 測試。
- [新增分頁的 iPad／macOS sidebar layout 需手動加列] → iPhone TabView 自動帶出，iPad／macOS 的 sidebar 需手動補導覽列與 destination；三平台序列 build 驗證。
- [截單日自動轉狀態的時間相依] → 一律走 @Dependency(\.date)，掃描邏輯放 reducer，測試以固定注入日期覆蓋。
- [按客戶名稱分組受同名／打字不一致影響] → 本次接受並以去頭尾空白輕正規化；客戶主檔另開後續 change 根治。

## Migration Plan

1. 在 BuyLedgerSchema 新增 BuyLedgerSchemaV8，models 含既有全部 record 與新 CampaignRecord。
2. 將 V7 的 OrderRecord 凍結為 V7 enum 內影子 @Model (欄位停在 verificationStatus)，V7.models 指向影子。
3. MigrationPlan 的 schemas 與 stages append V8 與 lightweight stage (V7 → V8)。
4. PersistenceContainer 的 Schema(versionedSchema:) 指向 V8。
5. 回溯相容：新欄位皆帶 default、CampaignRecord 為全新表，舊資料自動沿用；rollback 為還原 schema 指向 V7 (僅開發期，正式發布後不回退已遷移資料)。

## Open Questions

- CloudKit 多裝置並發：兩裝置同時對同一開團改名、或一端手動截單而另一端自動截單時的最終一致性，採 last-writer-wins (SwiftData + CloudKit 預設)，本次不另做衝突解析；待客戶主檔與正式啟用 CloudKit 後再評估。
- 客戶主檔上線後，分貨分組鍵由客戶名稱改為客戶識別碼的遷移策略，留待該後續 change 設計。
