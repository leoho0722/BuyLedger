## Summary

讓五個畫面停止直接吃根 store：改由各自 feature 的 scoped store 取得資料、以 delegate 表達跨 feature 意圖，並把「只有根導覽宿主能宣告根 store」這條邊界加進既有的分層守門測試。

## Motivation

**九個畫面宣告根 store，其中五個不是導覽宿主。** 總覽、分析、客戶、開團列表與開團詳情五個畫面直接持有根 store，因此可以任意讀取任何 feature 的狀態、直接送出任何 feature 的 action。開團詳情就是這樣讀取訂單清單並直接送出訂單 feature 的收款狀態 action。這讓跨 feature 的讀寫沒有任何邊界：誰讀了誰、誰改了誰，只能靠逐檔閱讀得知。

**正確作法已經存在，只是沒有推廣。** 客戶 feature 已經示範了對的模式——狀態只放一份唯讀的訂單投影，由根 feature 的變更監看同步。但它的 action 目前是空的，導覽仍走根 store。本案是把同一個模式補完。

**分析區間住在根狀態。** 它不屬於根，屬於分析 feature。

**前一個 change 立起的守門只覆蓋一半。** 檔案層的分層已由掃描測試守住，但 store 層的邊界還沒有機器強制力。

## Proposed Solution

**一、補齊兩個缺席的 feature。** 新建總覽 feature 與分析 feature，狀態各持有唯讀投影 (訂單、開團、載入狀態，總覽另含月獲利目標)；分析 feature 順帶收編目前住在根狀態的分析區間。兩者的 action 只有載入與 delegate，不自行寫任何跨 feature 狀態。

**二、擴充兩個既有 feature 的邊界。** 客戶 feature 的 action 自空列舉改為含載入與 delegate；開團 feature 的狀態新增訂單投影供開團摘要使用，並新增收款狀態切換的 action 與對應 delegate。

**三、跨 feature 的意圖一律走 delegate。** 四個新 delegate 只轉發到根 feature **既有**的導覽 case，不新增平行的根 case，避免根 feature 換個位置再膨脹。開團 feature 既有的改名 delegate 已是這個模式。

**四、投影全部由根 feature 單向同步。** 所有變更監看集中掛在同一處，投影一律唯讀語意：只有根 feature 寫、feature 端不得改，避免與訂單 feature 產生雙寫。

**五、語言走建構參數。** 訂單畫面已建立「語言走建構參數」的既有慣例，四個畫面照抄，不為語言另做投影。

**六、把 store 邊界加進守門測試。** 掃描根 store 的宣告位置，與白名單常數逐一比對，多一個或少一個都失敗。

## Non-Goals

- **不改任何使用者可見行為。** 版面、可及性識別碼與互動全部不動，基準圖不得重錄。
- **不把「更多」畫面改成吃 scoped store。** 它持有導覽路徑並為七個目的地各自建立子 store，做的事與另外兩個根版面完全同構，是導覽宿主而非 feature 畫面。硬要收斂就得再造一個持有全部子狀態的 feature，只是把根換個名字。
- **不動客戶摘要的聚合口徑。** 那屬另一個 change。
- **不拆訂單 feature。** 那是後續的 change。

## Alternatives Considered

- **投影改用共享狀態機制而非根 feature 的變更監看。** 已否決：共享狀態機制的採用範圍已定為主檔目錄一處，本案是純結構、零行為變更的重構，夾帶新機制會讓發版時的回歸範圍講不清楚。既有的客戶 feature 投影模式已足以達成邊界目的。
- **為「更多」畫面新建一個持有導覽路徑與全部子狀態的 feature。** 已否決：那個 feature 的狀態依然要放七個子 feature 的狀態，型別上什麼都沒收斂，只是把根 feature 換個名字。改為列為白名單例外並在檔頭與平台指引寫明理由。
- **把「更多」畫面移到 app 進入點目錄讓它與兩個根版面同層。** 已評估：角色會一望即知，但會讓原目錄變成空目錄需一併刪除，churn 大於收益。

## Impact

- Affected specs: `app-layer-boundaries` (修改)、`customer-summary` (修改)、`campaign-analytics-surfaces` (修改)
- Affected code:
  - New:
    - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
    - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
    - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - Modified:
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift
    - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests.swift
    - apps/ios/CLAUDE.md
