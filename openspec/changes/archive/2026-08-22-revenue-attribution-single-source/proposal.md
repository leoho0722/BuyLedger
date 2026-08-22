## Why

彙總面的營收歸屬目前分成兩種口徑，而這個分工本身是刻意且正確的：總覽與趨勢以「已實現狀態」計入合併產生的新訂單，類別與開團彙總則排除合併結果、改計入合併前的來源訂單。後者是必要的，因為合併結果訂單同時歸屬多個開團與多個類別，而彙總是把一張訂單的獲利**全額**計入它的每一個開團與每一個類別；若計入合併結果，同一筆錢會在開團排行與類別排行中被算兩次。

問題不在這個分工，而在它缺一道守門：**合併來源訂單可以被改回其他狀態，而沒有任何東西阻止它與合併結果同時被計入。** 單筆狀態變更沒有任何守門（批次那條只擋「改成已合併」，不擋「從已合併改出」）。把一筆來源訂單改回「已送達」之後，總覽與趨勢會同時計入該來源訂單與合併結果，總營收憑空多出一份。這條路徑是刻意保留的誤合併回復手段，因此不該封死，但必須擋住重複計算。

第二個問題在客戶頁：它**完全不過濾訂單**，把已取消訂單、合併來源訂單與合併結果訂單全部計入累計消費。一位客人取消的訂單仍會計入他的消費總額，合併過的訂單則被算兩次。

第三個問題在總覽 KPI delta 與趨勢卡的成長率：百分比與方向取自不同來源，上期為負時呈現可能互相矛盾。虧損收窄會顯示向下箭頭，虧損擴大會顯示向上箭頭；總覽 KPI 的帶號 Decimal delta 也會因分母符號而呈現錯誤方向。

## What Changes

- 新增守門：一筆訂單若被其他訂單列為合併來源，則它與該合併結果不得同時計入任何總量彙總。來源訂單被改回其他狀態時，彙總以合併結果為準。改回的操作本身不被封鎖，因為它是誤合併的回復手段。
- 客戶頁的累計消費與訂單筆數改用與總覽相同的口徑（已實現狀態），排除已取消訂單與合併來源訂單。客戶仍會出現在名單上（成員資格仍取自全部訂單），只是金額與筆數只計入已成立的訂單。
- 總覽 KPI delta 與趨勢卡的百分比與方向改為同源計算，並在上期為負時以「虧損收窄為改善」的語意呈現，消除帶號 delta、箭頭與顏色互相矛盾的情形。

## Non-Goals

- 不改變總覽與趨勢計入合併結果、類別與開團計入來源訂單這個既有分工。查證後確認它是刻意設計且對多開團與多類別的歸屬是必要的。
- 不改變彙總把一張訂單的獲利全額計入其每一個開團與每一個類別的作法。分攤規則的變更屬於「訂單直接支援多開團」那個獨立提案的範圍。
- 不封鎖把合併來源訂單改回其他狀態的操作。
- 不改動單筆訂單的任何財務計算公式。那屬於同批次的另一個變更。
- 不改動合併流程本身、合併草稿的預填規則或合併結果的日期取法。

## Capabilities

### New Capabilities

- `analytics-trend-comparison`: 總覽 KPI delta 與 Insights 趨勢卡在上期為負時，以損益改善／惡化決定方向與百分比語意。

### Modified Capabilities

- `order-merge`: 補上合併來源訂單被改回其他狀態時的彙總語意，明訂它與合併結果不得同時計入。
- `customer-summary`: 累計消費與訂單筆數的計入範圍由「全部訂單」收斂為「已成立的訂單」。

## Impact

- Affected specs: `order-merge`（修改）、`customer-summary`（修改）、`analytics-trend-comparison`（新增）
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
    - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
    - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
    - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
    - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
    - apps/ios/CLAUDE.md
  - New: （無）
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀；既有資料零影響。
- 本變更的範圍較原規劃縮減：原規劃要把四個入口統一到單一謂詞，查證後確認該分工是刻意且必要的，故只補守門與修正客戶頁與成長率。
