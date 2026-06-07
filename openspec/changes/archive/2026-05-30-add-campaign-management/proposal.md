## Why

代購業務的核心節奏是「開團」——一次開團收集多筆客戶訂單。目前 App 只有單筆訂單與其履約狀態 (OrderStatus)，沒有「團」這個層級，因此無法追蹤目前哪些團還在收單、哪些已截單、各團收了多少錢、到貨幾筆、賺多少。本變更把「開團」做成有狀態的獨立實體並給它專屬分頁，補足開團進度追蹤的缺口；分貨與結算全部由歸屬訂單彙總而來 (單一真實來源)，不另存資料。

## What Changes

- 新增「開團 (Campaign)」為有狀態的獨立實體：狀態為兩態 (開團中 → 已收單)；「結團」是設定 settledDate 的完成動作，不是狀態。
- 新增「開團」獨立分頁 (主分頁由 4 個增為 5 個)：開團列表 (狀態 pill + 彙總進度) 與開團詳情 (分貨清單 + 結團結算)。團的新增、改名、刪除都在此分頁完成。
- 截單日自動轉狀態：有設截單日的團，截單日到時自動由「開團中」轉「已收單」(App 啟動與進入列表時掃描，時間一律走依賴注入的日期)；沒設截單日的維持手動；結團永遠手動。
- 訂單新增兩個欄位：campaignName (歸屬的開團，沿用訂單來源的字串名稱 + cascade rename 模式) 與收款狀態 (待收款／已收款)。
- 分貨清單與結團結算全部 derive 自歸屬訂單：依客戶名稱 (去頭尾空白) 分組；結算同時呈現收款面 (應收／已收／未收，以實收金額 chargedAmount 為基準) 與損益面 (成本／毛利／利潤率，重用既有 OrderSummary 加總)；內建未付款名單；分貨列可展開檢視品項。
- 訂單列表新增兩種開團篩選維度：按開團狀態 (全部／開團中／已收單) 與按指定團名。
- Dashboard 新增「進行中的開團」進度卡；Insights 新增「每團毛利排行」長條圖；新增跨頁導覽 action，從這些入口點擊可跳到開團分頁的該團詳情。
- SwiftData Schema 升版至 V8 (lightweight)：新增 CampaignRecord 表與訂單兩個帶 default 的欄位，並凍結 V7 的 OrderRecord 影子型別以保住既有 schema 指紋。

## Capabilities

### New Capabilities

- `campaign-management`: 開團實體與生命週期 (兩態狀態、截單日自動轉、結團 settledDate 標記)、開團 CRUD、開團分頁 (列表與詳情)、分貨清單、結團結算 (收款面與損益面)、CampaignRecord 持久化與 Schema V8 遷移。
- `order-campaign-assignment`: 訂單歸屬開團——campaignName 欄位、訂單編輯時選擇既有開團、開團改名時 cascade 更新所有歸屬訂單與記憶體副本。
- `order-payment-receipt-status`: 訂單收款狀態欄位 (待收款／已收款)，於訂單編輯呈現，並作為分貨清單與結團結算「已收款」判定的來源。
- `order-campaign-filter`: 訂單列表按開團狀態 (全部／開團中／已收單) 與按指定團名兩種維度篩選。
- `campaign-analytics-surfaces`: Dashboard「進行中的開團」進度卡與 Insights「每團毛利排行」分析，含點擊跳轉至開團詳情的跨頁導覽。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 campaign-management、order-campaign-assignment、order-payment-receipt-status、order-campaign-filter、campaign-analytics-surfaces 五個 capability。
- Affected code:
  - New:
    - apps/apple/BuyLedger/Core/Domain/Campaign.swift
    - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
    - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
    - apps/apple/BuyLedger/Core/Persistence/CampaignRecord.swift
    - apps/apple/BuyLedger/Core/Persistence/CampaignPersistence.swift
    - apps/apple/BuyLedger/Core/Dependencies/CampaignRepository.swift
    - apps/apple/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/apple/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/apple/BuyLedger/Features/Campaigns/CampaignSummary.swift
    - apps/apple/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/apple/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
    - apps/apple/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/apple/BuyLedgerTests/CampaignPersistenceTests.swift
  - Modified:
    - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
    - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
    - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
    - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
    - apps/apple/BuyLedger/Features/App/RootFeature.swift
    - apps/apple/BuyLedger/Features/App/RootTab.swift
    - apps/apple/BuyLedger/Features/App/RootTabLayout.swift
    - apps/apple/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/apple/BuyLedger/Features/Insights/InsightsView.swift
  - Removed: (none)
- 持久化與同步：SwiftData Schema V8 lightweight 遷移；CloudKit 多裝置同步沿用既有相容設計 (不使用唯一性約束、新欄位帶 default)，cascade rename 與截單日自動轉狀態的並發行為於 design.md 補充說明。
- 範圍邊界：客戶主檔 (讓分貨分組更可靠) 不在本次，另開後續獨立 change。
