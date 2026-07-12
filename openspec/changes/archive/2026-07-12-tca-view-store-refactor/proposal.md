## Why

一次平行 TCA 稽核 (10 個 sub-agent 覆蓋 26 個 View 檔與 39 個 @State) 確認 View 層沒有「直接繞過 reducer 竄改 domain state」的硬違規,但發現三類問題:兩處商業規則與衍生計算漏在 View binding 內、多個帶 domain 意義的 @State 被鎖在 View 內 (其中兩個造成使用者選擇在導覽/切換分頁時被重置的真實 bug)、以及數處資料彙總計算 inline 在 View,牴觸「計算一律下放 reducer 或可測試 feature helper」的平台硬規則。這些都使對應行為無法以 TestStore 驗證,並在 iPad 與導覽情境下產生不一致。本次一次性把這些狀態與計算收斂回 Store 與可測層。

## What Changes

**驗證與衍生計算下放 reducer**

- QuoteFeature:七個數值輸入欄的「非負」不變量從 View 的 nonNegativeBinding 移入 reducer 的 binding 處理,View 直接綁定 store。目標毛利維持只保證非負、不加上限。
- OrderEditFeature:新增 dateComponentsChanged action,把「以注入時間補秒數後組出存檔日期」的計算從 View binding setter 移入 reducer。

**帶 domain 意義的 @State 移入對應 feature state**

- 洞察頁分析區間選擇移入 RootFeature 狀態,新增對應 action。**BREAKING**(行為):修正 iPad 切換分頁後區間被重置為預設值。
- 開團詳情「只看未付款」篩選移入 CampaignFeature 狀態,新增對應 action。**BREAKING**(行為):修正 push/pop 重進詳情後篩選被重置。
- Lookup 改名與編輯流程的暫存狀態移入 LookupManagementFeature 的 Presents Destination,由 reducer 在進入編輯的當下自 state 快照初值。
- 訂單 compact 導覽路徑改用 OrdersFeature 狀態的 StackState,原本在 View 以 onChange 對訂單變動修剪路徑的收斂邏輯移入 reducer。

**新增 feature**

- 新增 CustomersFeature,承載原本 inline 在 CustomersView 的客戶彙總 (依客戶分組、加總消費、取最近訂單日、排序),並接進 Root 導覽;CustomersView 改為綁定該 feature。

**彙總計算下放可測層**

- Dashboard 與 Insights 的營收成本獲利彙總、走勢與熱力圖資料計算,以及側邊欄的進行中訂單徽章計數,從 View 移到 RootFeature 的可測 helper 或 state 方法。

**測試**

- 每個移入 Store 的項目補上 TestStore 單元測試,驗證 action flow、state mutation 與 (導覽路徑收斂等) 效果。

## Non-Goals

- 不變更 SwiftData schema;本次為純 in-memory 的 TCA state 重構。
- 訂單篩選 sheet 的 pending 暫存 (套用前 staging) 維持 View-local,不收進 reducer。
- 不為目標毛利加上限驗證。
- 除上述兩個持久化 bug 修正外,不變更任何畫面的視覺外觀或使用者操作流程。

## Capabilities

### New Capabilities

- `customer-summary`: 客戶彙總畫面的資料聚合 —— 由既有訂單投影出每位客戶的消費總額、訂單筆數、最近訂單日與排序,以可測試的 TCA feature 承載。

### Modified Capabilities

- `campaign-analytics-surfaces`: 洞察頁的分析區間選擇改由 feature state 擁有,並跨分頁與導覽保存。
- `campaign-management`: 開團詳情「只看未付款」檢視篩選改由 feature state 擁有,並跨導覽保存。

## Impact

- Affected specs: customer-summary (new), campaign-analytics-surfaces, campaign-management
- Affected code:
  - New:
    - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
    - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - Modified:
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - Removed:
    - (無整檔刪除;移除的是 View 內的 binding helper 與 inline 彙總方法)
