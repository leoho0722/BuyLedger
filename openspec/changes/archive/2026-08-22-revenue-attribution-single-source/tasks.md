## 1. 重複計算守門

- [x] 1.1 先寫紅燈測試釘住不重複：建立兩筆來源與其合併結果，逐一把來源改回已實現狀態，斷言總覽總額在三種組合下皆相同。對應 spec requirement「A merge source and its merge result are never counted together」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/DashboardStatsTests.swift）。
- [x] 1.2 實作 requirement「Analytics attribution after a merge uses pre-merge revenue」：讓總量彙總在計入前先排除「被現存合併結果列為來源」的訂單：彙總開始時建立一次來源識別碼集合供該次共用，不新增任何持久化欄位。依 design「以合併來源識別碼集合判斷，不新增欄位」。驗證：1.1 測試轉綠；總覽與趨勢兩處皆套用（apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift、apps/ios/BuyLedger/Features/Insights/InsightsStats.swift）。
- [x] 1.3 讓合併結果被刪除後，其來源訂單恢復正常計入：守門條件為「存在現存的合併結果把我列為來源」，而非「曾被合併過」。依 design「合併結果被刪除時，來源訂單恢復正常計入」。驗證：新增測試斷言刪除合併結果後兩筆來源皆被計入。
- [x] 1.4 確認把合併來源改回其他狀態的操作本身未被封鎖：對應 spec requirement 的可回復情境。驗證：新增測試斷言該狀態變更成功落盤，僅彙總結果不受影響。
- [x] 1.5 確認新增的掃描未讓彙總效能退化。驗證：QA 已記錄 `OrdersFeaturePerformanceTests.testDashboardStatsRevenueAttributionBaselineWithThousandOrders` 基準平均 0.096s／20 次建構；log 顯示 `baselineName: ""` 且無存檔 baseline，故 `measure` 只記錄不比較，未自動確認無劣化。
  - [x] 新增並以 simulator 執行 `OrdersFeaturePerformanceTests.testDashboardStatsRevenueAttributionBaselineWithThousandOrders`；確實走 `DashboardStats.init → revenueAttributionOrders`。

## 2. 客戶頁的計入範圍

- [x] 2.1 先寫紅燈測試釘住客戶累計消費的口徑：斷言已取消訂單不計入金額、合併過的訂單只算一次、訂單全部取消的客人仍在名單且金額為零。對應 spec requirement「Customers screen aggregates orders into per-customer summaries」。驗證：三條斷言在實作前皆失敗（apps/ios/BuyLedgerTests/CustomersFeatureTests.swift）。
- [x] 2.2 讓客戶的累計消費與訂單筆數採用與總覽相同的口徑，但成員資格仍取自全部訂單。依 design「客戶頁採用與總覽相同的口徑，但成員資格取自全部訂單」。驗證：2.1 三條斷言轉綠；既有的客戶排序與分級測試維持綠燈（apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift）。

## 3. 趨勢成長率

- [x] 3.1 先寫紅燈測試釘住方向與百分比一致：涵蓋虧轉盈、虧損收窄、虧損擴大三種上期為負的情境，斷言方向旗標與百分比符號不矛盾。驗證：三條斷言在實作前皆失敗（apps/ios/BuyLedgerTests/InsightsStatsTests.swift）。
- [x] 3.2 實作 requirement「Trend comparison expresses improvement consistently」：讓成長率的百分比與方向由單一來源產出，分母改取上期絕對值，使虧損收窄呈現為改善。依 design「成長率的數字與方向同源，並以絕對值為分母」。驗證：3.1 三條斷言轉綠；上期為零時維持既有的無對照呈現。

## 4. 驗收

- [x] 4.1 執行整體驗收：主 scheme 全套單元測試綠燈，並人工確認總覽、趨勢、類別、開團四處的數字在含合併訂單的資料下彼此自洽。驗證：測試通過數不低於改動前；四處數字以同一批資料逐一核對。

## 修正輪補充

- [x] 驗證 R2 合併結果金額非來源和，並以反向歸屬變異確認測試轉紅後還原；QA 已完成變異驗證，紅燈訊息明確。
- [x] 驗證 R3 以非 Double 精確可表示的 Decimal 桶值，並以 Double 回推變異確認測試轉紅後還原；QA 已完成變異驗證，紅燈訊息明確。
- [x] 恢復既有的 `quotingCancelledAndMergedOrdersAreExcludedFromMonthlyTotals`，並與新增合併歸屬測試並存。
- [x] 補刪除合併結果、取消合併結果與合併來源狀態回復的常駐測試。
- [x] 補上虧轉盈、虧損收窄、虧損擴大的趨勢比較測試。
- [x] 回退 live spec 的未歸檔手改，將完整變更放入 delta。
- [x] 在 iOS 平台指引記錄營收歸屬、合併結果、客戶頁與成長率硬規則。
