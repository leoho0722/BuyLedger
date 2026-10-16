<!--
平行分組見 design「平行開發分組」：1.1 ∥ 1.2 ∥ 1.3；之後 2.1 至 2.5 與 3.1、3.3 可同時進行；3.2 ∥ 3.4；4.2 隨時可做。
build 與測試由主對話序列執行；每個 task 只跑受影響的測試類別，完整回歸只在 5.3；選擇性執行一律記錄實際執行數且大於 0。
「整檔檢查通過」指 `openspec/changes/palette-analytics-style-compliance/reference/style_checks.py` 對該 task 改到與新增的 Swift 檔，`TOTAL` 只含不計失敗的代碼且每檔不超過 300 行；新增檔同時加進 `reference/file-list.txt` (design「整檔對齊沿用 6a＋6b 的檢查腳本與裁決」)。
「snapshot 不變」指所列 snapshot 不重錄即通過，且 `shasum -c reference/snapshot-hashes.txt` 全數相符；0.1 記錄的 4 條已知失敗則是通過，或失敗圖與 `reference/snapshot-failures/` 逐像素相同 (design「snapshot 與 UI Automation 驗收」)。
-->

## 0. 開工前基準

- [x] 0.1 依 design「整檔對齊沿用 6a＋6b 的檢查腳本與裁決」與「snapshot 與 UI Automation 驗收」建立修正前基準：
    - 以 `git rev-parse HEAD` 記錄基準 commit，並確認本 change 目錄以外的工作樹乾淨 (不乾淨停下回報)。
    - 把 6a＋6b 的 `style_checks.py` 複製到本 change 的 `reference/`，改檔頭用法並清空行數例外清單；以 `reference/file-list.txt` 修改段的 108 檔量測，結果存 `reference/baseline.txt`。
    - iPhone 17 (`DDAA3311-B464-4DD3-96B8-360B26AF1929`，先以 `mobilebuildmcp simulator list` 確認) 鎖淺色後跑完整單元回歸，從 result bundle 取出 4 條已知失敗 snapshot 的失敗圖，複製到 `reference/snapshot-failures/`。
    - 驗證：`baseline.txt` 的檔數為 108 且 `TOTAL` 為 653 筆左右 (差異逐項說明)；回歸的 `totalTestCount` 大於 0；失敗清單、4 張失敗圖與 result bundle 路徑記在本 task 下方
    - 記錄 (2026-10-16)：
        - 基準 commit `1cd7e6c8fc08d26adf567914081e9906598e86cc`；工作樹除 `openspec/changes/` 下兩個 change 目錄 (本 change 與平行的 `service-ownership-alignment`) 外乾淨。
        - `baseline.txt`：108 檔、`TOTAL` 662 筆、56 檔有問題；比 653 多的 9 筆全是 `WSTR` (只由單一字串字面值構成的超長行，不計失敗)，計失敗的筆數與 653 相同。
        - 模擬器：iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929` (iOS 26.5，已鎖淺色)。原文件的 iPad `6B65ED1C` 已不存在，改用同型號 iPad Air 11-inch (M4) `1157F07A-104E-4268-89E6-3577AE9BA3A8` (iOS 26.5)。
        - 完整單元回歸：Swift Testing 1403 個測試，1399 通過、4 失敗 (另有 2 個既有 known issue)；失敗只有 `campaignEditView_編輯既有開團_符合基準圖`、`orderEditView_一般既有訂單_符合基準圖`、`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼` (訂購日期的日期與時間改上下排列)。
        - 失敗圖：`reference/snapshot-failures/SnapshotTests+CampaignDetail/` 1 張、`SnapshotTests+OrderEdit/` 3 張。
        - result bundle：`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-16T02-38-01-373Z_pid84335_510ad622.xcresult`

- [x] 0.2 依 design「snapshot 與 UI Automation 驗收」在未改的程式上以 UI Automation 記錄對照基準：
    - iPhone 17 與 iPad (`6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`) 以 `-BLUITest` 種子資料與固定時間啟動，記錄首頁 `currentDateSubtitle` 的文字。
    - 切英文後，記錄分析頁熱力圖的星期標籤、類別排行與成本結構的金額。
    - 截取 iPad 側邊欄與 iPhone 照片檢視器，並記錄兩台模擬器的曆法設定 (design「首頁與分析頁比照 P 記錄日期脈絡」的日期子標相容範圍以西曆為前提)。
    - 驗證：`snapshot-ui` 輸出、截圖路徑、曆法與記錄值寫在本 task 下方 [after: 0.1]
    - 記錄 (2026-10-16，未改的程式，啟動參數 `-BLUITest -BLUITestSeed fullOrders -BLUITestNow 2026-06-15T00:00:00Z`)：
        - 曆法：兩台模擬器 `AppleLocale` 皆為 `zh_TW` (沒有 `@calendar`，即西曆)、`AppleLanguages` 為 zh-Hant-TW 與 en-TW、強制 24 小時制。
        - iPhone 17 `DDAA3311` 正體中文：首頁 `dashboard.currentDateSubtitle` 為「6月15日星期一」(英文為「Monday, June 15」)；`snapshot-ui` 原始輸出 `reference/ui-baseline/iphone-dashboard-zh.json`。
        - iPad Air 11-inch (M4) `1157F07A` 正體中文：首頁日期子標「6月15日星期一」；側邊欄截圖 `reference/ui-baseline/ipad-dashboard-sidebar.jpg`。
        - iPhone 17 英文分析頁 (預設 12 Months)：走勢「12-Month Net Profit」NT$11,412、「— No comparison」；類別排行「1. 美妝」NT$6,915、「2. 服飾」NT$2,505；成本結構 Total Cost NT$42,368、Item Cost NT$41,011、Local Shipping NT$450、International Shipping NT$2,270、Fees NT$1,357；熱力圖週次 W1 至 W8、星期標籤 M T W T F S S，有訂單的 8 格為 T Week 7、W Week 6、T Week 5、T Week 7、F Week 6、S Week 6、S Week 5、S Week 6 (各 1 筆)。原始輸出 `reference/ui-baseline/iphone-insights-en-top.json`、`iphone-insights-en-bottom.json`。
        - iPhone 17 照片檢視器 (`-BLUITestSeed photos`，訂單編輯第一張縮圖進入，顯示「1/5」)：截圖 `reference/ui-baseline/iphone-photo-viewer.jpg`。

- [x] 0.3 依 design「snapshot 與 UI Automation 驗收」的「改動前補錄基準」，在未改的程式上新增 snapshot 測試：
    - 新檔：`SnapshotTests+Customers` (客戶頁)、`SnapshotTests+More` (「更多」、設定頁、App 鎖定畫面)、`SnapshotTests+OrderMerge` (合併候選與合併照片選擇 sheet)。
    - 既有檔：`SnapshotTests+Shared` (付款方式編輯 sheet)、`SnapshotTests+Dashboard` (載入骨架、首次使用)、`SnapshotTests+Insights` (載入骨架、空狀態、帶開團資料而顯示每團毛利排行卡的內容)。
    - 依 `ios-unit-tests.md` 的 snapshot 規則注入固定時間、語言與尺寸分類，不呼叫 Service；AI 摘要做不到時依 design 改列 UI Automation，原因記在本 task 下方。
    - 錄製確認後，把 `apps/ios/BuyLedgerTests/__Snapshots__/` 下所有 PNG 的 `shasum` 存成 `reference/snapshot-hashes.txt`。
    - 驗證：每條新測試第一次錄製後逐張人工確認畫面正確，再跑一次通過；新增與改到的測試檔整檔檢查通過；`shasum -c reference/snapshot-hashes.txt` 全數相符 [after: 0.1]
    - 記錄 (2026-10-16，claude-impl 撰寫、主對話錄製與驗證)：
        - 新增 20 條：`SnapshotTests+Customers` 2 條 (一般資料含名次徽章與排行卡、空狀態)、`+More` 5 條 (「更多」、設定頁預設與開啟 AI 摘要與生物辨識、App 鎖定與解鎖失敗)、`+OrderMerge` 4 條 (合併候選有候選與空狀態、合併照片選擇選滿與部分選取)、`+Shared` 4 條 (付款方式編輯 sheet 新增與編輯、AI 摘要完成與失敗)、`+Dashboard` 2 條 (載入骨架、首次使用)、`+Insights` 3 條 (載入骨架、空狀態、帶開團資料顯示每團毛利排行卡)。既有 snapshot 測試一行未改。
        - 一律 `EmptyReducer`，不呼叫 Service；照片以 `UIGraphicsImageRenderer` 產生固定色 PNG。AI 摘要能以 State 呈現，納入 `+Shared`，只錄 `.finished` 與 `.failed` (`.idle`、`.streaming` 會畫 `ProgressView`，不入圖，由 5.2 以 UI Automation 補看)。
        - 逐張人工確認：第一次錄製的合併候選 sheet 兩張，導覽列標題與搜尋欄被畫成近乎白色；改為 `.image(drawHierarchyInKeyWindow: true)` 刪圖重錄後正常。其餘 18 張內容正確。
        - 第二次執行：新 20 條全數通過，`SnapshotTests` 共 60 條只剩 0.1 的 4 條已知失敗；6 個檔整檔檢查 `TOTAL {}`。
        - `reference/snapshot-hashes.txt`：`__Snapshots__` 下 58 張 PNG，`shasum -c` 全數相符。

## 1. 擴充：色盤成員、日期脈絡與趨勢方向

- [x] 1.1 依 design「色盤成員以 ShapeStyle 靜態擴充宣告於 Color+Semantic.swift」與「先擴充再遷移，最後刪除 BLPalette」落實修改後 spec「Semantic and system colors are obtained through system APIs」的擴充階段：
    - 新增 `Color+Semantic.swift`，19 個 `bl` 前綴靜態成員各自回傳與原 `BLPalette` 同名成員相同的運算式，並把「語意色彩」preview 搬入。
    - `BLPalette` 刪除 5 個零呼叫點成員，其餘實例成員改為回傳對應的 `.blX`；刪除 `Color+Extensions.swift`。
    - `DesignSystemSourceScanTests` 規則四、五的豁免檔名改為 `Color+Semantic.swift`，規則一到四的違規訊息改為新成員的前置點寫法，該檔整檔對齊。
    - 驗證：iPhone 與 iPad 各 build 一次 (確認 synchronized group 拾取新增與刪除)；`BLPalette.swift` `grep` 不到 `Color(uiColor:`；`DesignSystemSourceScanTests`、`ContrastComplianceTests`、`ColorContrastTests` 通過；`SnapshotTests` 整批 snapshot 不變；整檔檢查通過 [after: 0.2, 0.3]
    - 記錄 (2026-10-16，Haiku 子代理實作)：`Color+Semantic.swift` 19 個成員運算式與原 `BLPalette` 逐字相同 (對照表在實作回報)；5 個零呼叫點成員刪除前 grep 只命中宣告；`BLPalette.swift` 不再有 `Color(uiColor:`；`Color+Extensions.swift` 刪除。
        - iPhone 17：`DesignSystemSourceScanTests`、`ContrastComplianceTests`、`ColorContrastTests`、`SnapshotTests` 等 206 個測試只剩 0.1 的 4 條已知失敗，失敗圖與 `reference/snapshot-failures/` 逐位元相同；`shasum -c reference/snapshot-hashes.txt` 全數相符。iPad Air 11-inch (M4)：`DesignSystemSourceScanTests`、`BLTrendTests` 15 個通過。
        - 變異：規則四的豁免檔名改回 `BLPalette.swift`，`DesignSystemSourceScanTests` 1 條轉紅 (13 條通過)，已還原。

- [x] 1.2 依 design「首頁與分析頁比照 P 記錄日期脈絡」落實 spec「Overview and insights figures follow a recorded current date」的記錄與刷新時點：
    - 新增 `DashboardDateContext`、`InsightsDateContext`；兩個 Feature 的 State 加 `dateContext` 與 `refreshDateContext(now:calendar:)`。
    - reducer 宣告 `\.date`、`\.calendar` 依賴，`.view(.task)` 與 `.view(.retryTapped)` 一律覆寫 `dateContext`，再送 `.delegate(.refresh)`。
    - Root 的 `refreshDateContexts(state:)` 加這兩個呼叫，doc 摘要就地改寫為涵蓋四個分頁，`RootFeature.swift` 不增加其他行。
    - 本 task 不改畫面 (畫面仍讀依賴，3.2、3.4 才移除)。
    - 新增的日期脈絡測試放 `DashboardFeatureTests+DateContext`、`InsightsFeatureTests+DateContext` (design「InsightsStats 與兩個測試檔依主題拆檔」)。
    - 驗證：
        - `DashboardFeatureTests`、`InsightsFeatureTests` 注入 `TestDependencies.fixedNow`／`fixedCalendar`，出現與重試測試從與注入值不同的舊日期與舊 calendar 出發，斷言被覆寫為字面值日期。
        - `RootFeatureTests+Foreground` 三條測試的初始 State 帶首頁與分析頁的舊日期脈絡 (可擴充 `RootFeatureTests+Fixtures` 的建構方法)，斷言兩頁都被覆寫。
        - `RootFeatureTests+LoadRequests` 的首頁與分析頁重試、`RootFeatureTests+DeepLinks` 的首頁出現，依新行為補上窮舉斷言後通過。
        - 兩個變異都讓對應測試轉紅：移除 Root 其中一行呼叫；把寫入改成「只在 `nil` 時寫入」。
        - `RootFeature.swift` 不超過 300 行；整檔檢查通過 [after: 0.2, 0.3]
    - 記錄 (2026-10-16，claude-impl 實作)：新增 `DashboardDateContext`、`InsightsDateContext` 與兩個 `+DateContext` 測試檔；Root 的 `refreshDateContexts(state:)` 加兩行並就地改寫 doc 摘要，`RootFeature.swift` 299 行。
        - 測試：同上 206 個測試的一次執行涵蓋 `DashboardFeatureTests`、`InsightsFeatureTests`、`RootFeatureTests` 全數通過。
        - 變異：移除 Root 的首頁刷新呼叫，`RootFeatureTests` 3 條轉紅；`DashboardFeature.State.refreshDateContext` 改成只在 `nil` 時寫入，`DashboardFeatureTests`／`RootFeatureTests` 5 條轉紅；兩者皆已還原。

- [x] 1.3 依 design「資料層以語意色調、方向列舉與比例取代色彩與 Bool?」新增 Design System 的 `BLTrend` (`up`、`down`、`unavailable`，`init(delta:)`)，作為首頁 KPI 與分析頁走勢共用的方向來源，本 task 先不接呼叫端。驗證：新增 `BLTrendTests` 以字面值涵蓋 `nil`、負值、0、正值四種輸入；把 0 改判為 `down` 的變異讓測試轉紅；`LayerBoundaryTests` 通過；整檔檢查通過 [after: 0.2, 0.3]
    - 記錄 (2026-10-16，Haiku 子代理實作)：`BLTrend` (`Equatable`、`Sendable`、`CaseIterable`) 與參數化 `BLTrendTests` (四種輸入)；`BLTrendTests`、`LayerBoundaryTests` 通過；把 0 判為 `down` 的變異讓 `init_四種差值輸入_判定對應的走勢方向(scenario:)` 轉紅，已還原。

## 2. 色盤呼叫端遷移 (各組檔案互不重疊)

- [x] 2.1 依 design「呼叫端以前置點寫法取用色盤」與「hero 漸層由 BLHeroCardBackground 直接讀取資源」遷移 `Shared/` 的呼叫端：
    - 範圍：Design System 元件 (Buttons、Cards、Charts、Chips、Forms、Images、Progress、Tags 中引用色盤或 `Color.blSecondaryLabel` 的檔) 與 `BLMetrics`，刪除 `palette` 屬性與 helper 的 `palette:` 參數，並整檔對齊。
    - `BLHeroCardBackground.gradientColors` 改為直接讀兩個 asset，簽章不變。
    - 驗證：這些檔 `grep -E 'BLPalette|\bpalette(\.|:)|(var|let) palette|Color\.blSecondaryLabel'` 為 0 處 (`.symbolRenderingMode(.palette)` 是 SwiftUI 符號渲染模式，不屬色盤，保留)；`ContrastComplianceTests` 的 hero 漸層測試通過；`SnapshotTests` 整批 snapshot 不變 (含 0.3 的付款方式編輯 sheet)；整檔檢查通過 [after: 1.1]
    - 記錄 (2026-10-16，Haiku 子代理實作)：Design System 12 個元件與 `BLHeroCardBackground` 改用前置點成員；`BLMetrics.swift` 依一檔一頂層型別拆為 `BLRadius`、`BLSpacing`、`BLListMetrics`、`BLHitTarget` 後刪除 (preview 留在 `BLRadius.swift`，四檔加入 `reference/file-list.txt` 新增段)。
        - 主對話補 `BLBarChart` 第二個 preview 的資料型別標註 (`let data: [BLBarChartValue]`) 讓型別推斷通過。
        - 這些檔 `grep` 為 0 處；完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同；`ContrastComplianceTests` 通過；整檔檢查 PASS。

- [x] 2.2 依 design「呼叫端以前置點寫法取用色盤」遷移 `Features/Orders/` 的 29 個呼叫端，並整檔對齊：
    - 範圍包含 `OrderSelectableRow`、`OrdersCompactListView`、`OrdersToolbarContent` 的 `palette` 欄位、`OrderDetailSummaryView.metric` 的參數、篩選 sheet 的三個區段，以及只用次要文字縮寫的編輯區段。
    - 篩選 sheet 只換色彩，版面與行為留給 6d。
    - 驗證：這些檔 `grep -E 'BLPalette|\bpalette(\.|:)|(var|let) palette|Color\.blSecondaryLabel'` 為 0 處 (`.symbolRenderingMode(.palette)` 是 SwiftUI 符號渲染模式，不屬色盤，保留)；Orders 的 snapshot (`SnapshotTests+Orders`、`+OrdersBaseline`、`+OrderDetail`、`+OrderEdit`，以及 0.3 的 `+OrderMerge`) snapshot 不變；`OrderListFeatureTests`、`OrderDetailFeatureTests` 通過；整檔檢查通過 [after: 1.1]
    - 記錄 (2026-10-16，Haiku 子代理實作)：29 檔改用前置點成員並整檔對齊；`OrderRowView`、`OrderSelectableRow`、`MergePhotoPickerSheet` 依 kit「同組依名稱排序」重排 View 屬性並同步 memberwise init 呼叫端 (與 2.4 未重排的做法不一致，交 5.1 統一判定)。
        - 這些檔 `grep` 為 0 處；完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同；`OrderListFeatureTests`、`OrderDetailFeatureTests` 通過；整檔檢查 PASS。

- [x] 2.3 依 design「呼叫端以前置點寫法取用色盤」遷移 `Features/Campaigns/`、`Features/Quote/`、`Features/FX/` 的 13 個呼叫端，並整檔對齊。驗證：這些檔 `grep -E 'BLPalette|\bpalette(\.|:)|(var|let) palette|Color\.blSecondaryLabel'` 為 0 處 (`.symbolRenderingMode(.palette)` 是 SwiftUI 符號渲染模式，不屬色盤，保留)；`SnapshotTests+Campaigns`、`+CampaignDetail`、`+Tools` (含 `QuoteView`、`FxView`) snapshot 不變；`CampaignListFeatureTests`、`QuoteFeatureTests`、`FxFeatureTests` 與匯率模型測試 `FxRateSnapshotTests` (非圖片比對) 通過；整檔檢查通過 [after: 1.1]
    - 記錄 (2026-10-16，Haiku 子代理實作)：13 檔改用前置點成員並整檔對齊；`FxStatusBanner`、`FxRatesList` 與 Quote 三個元件重排 View 屬性 (同 2.2，交 5.1)；modifier 未跨組重排 (可能動像素，交 5.1)。
        - 這些檔 `grep` 為 0 處；完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同；`CampaignListFeatureTests`、`QuoteFeatureTests`、`FxFeatureTests`、`FxRateSnapshotTests` 通過；整檔檢查 PASS。

- [x] 2.4 依 design「呼叫端以前置點寫法取用色盤」遷移 `Features/App/` (`AppLockView`、`PersistenceFailureView`、`RootSidebarLayout`，含 `logoRow(palette:)`)、`Features/Lookups/`、`Features/More/`、`Features/Settings/`、`Features/AISummary/` 的 9 個呼叫端，並整檔對齊；不改 `RootFeature.swift` (屬 1.2)。驗證：這些檔 `grep -E 'BLPalette|\bpalette(\.|:)|(var|let) palette|Color\.blSecondaryLabel'` 為 0 處 (`.symbolRenderingMode(.palette)` 是 SwiftUI 符號渲染模式，不屬色盤，保留)；`SnapshotTests+Lookups`、`+Shared` 與 0.3 的 `+More` snapshot 不變；`LookupManagementFeatureTests`、`SettingsFeatureTests`、`AISummaryFeatureTests` 通過；整檔檢查通過 [after: 1.1]
    - 記錄 (2026-10-16，Haiku 子代理實作)：9 檔改用前置點成員並整檔對齊，未改 `RootFeature.swift`；`RootSidebarLayout`、`MoreView` 的 View 屬性未重排、`AISummaryView` 的 modifier 未重排，都交 5.1 判定。
        - 這些檔 `grep` 為 0 處；完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同；`LookupManagementFeatureTests`、`SettingsFeatureTests`、`AISummaryFeatureTests` 通過；整檔檢查 PASS。

- [x] 2.5 依 design「呼叫端以前置點寫法取用色盤」與「對比測試改量新成員並刪除漂移測試」落實修改後 spec「Informational text meets the 4.5:1 contrast floor」：
    - `Features/Customers/` 三個畫面改用前置點成員，`CustomerRankBadgeStyle` 改為 `background`、`numeral` 計算屬性。
    - `ColorContrast.Appearance.palette` 刪除，`ContrastComplianceTests`、`ColorContrastTests` 改量 `Color.blX`。
    - 刪除參數化測試 `blSecondaryLabel_各外觀情境_與色盤次要標籤色分量相同(appearance:)`；`ColorContrastTests` 改為三段式正體中文命名與 Given／When／Then，比值與容差不變；以上檔案整檔對齊。
    - 驗證：`ContrastComplianceTests`、`ColorContrastTests`、`CustomersFeatureTests` 通過，`@Test` 數少 1、實際執行案例少 4，其餘數量不變；0.3 的 `+Customers` snapshot 不變；整檔檢查通過 [after: 1.1]
    - 記錄 (2026-10-16，Haiku 子代理實作)：Customers 三個畫面與 `CustomerRankBadgeStyle` 改用前置點成員；`ContrastComplianceTests`、`ColorContrastTests` 改量 `Color.blX`，刪除參數化漂移測試，`ColorContrastTests` 改三段式命名與 Given／When／Then。
        - 兩檔合計 `@Test` 12 → 11、執行案例 134 → 130 (少 1 與 4)；`ratio_半透明前景_先合成後再量測` 的預期由 helper 算出改為字面值 21。
        - 完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同；`CustomersFeatureTests` 通過；整檔檢查 PASS。

## 3. 首頁與分析頁 (第 7 步)

- [x] 3.1 依 design「統計與畫面狀態由 State 推導」、「格式化移到 DashboardFormatters 與 InsightsFormatters」與「InsightsStats 與兩個測試檔依主題拆檔」完成首頁資料層，只新增、不移除畫面正在用的介面。落實 spec「Overview and insights figures follow a recorded current date」的首頁數字、資料變動重算、失敗優先與無日期骨架：
    - `DashboardStats` 遵循 `Equatable` 並整檔對齊 (含 `MonthlyTotals`)。
    - `DashboardFeature.State` 新增 `stats` 與巢狀 `ScreenState`／`screenState`，依 design 的判斷順序 (失敗優先)。
    - 新增 `DashboardFormatters`，各函式的回傳型別與輸出和 design 表格逐字相同 (含 `dateSubtitle(for:locale:)` 套用記錄的 calendar 與時區、`deliveryProgress`)。
    - `DashboardStatsTests` 依 design 拆成主檔、`+Comparison`、`+Progress`，共用 helper 改為 internal 並移到 `+Fixtures`，整檔對齊。
    - 驗證：
        - `DashboardFeatureTests+ScreenState` 以 spec「loaded orders without a recorded date」表格的首頁欄寫成字面值測試；`DashboardFeatureTests` 主檔與拆出各檔都不超過 300 行。
        - spec 的「one order in each month」「returning after the month ends」「a new order in the current month」三個範例以字面值寫成測試；另寫月目標改變後目標進度以同一個記錄日期重算、`dateContext` 不變的字面值測試。
        - 新增 `DashboardFormattersTests`：以字面值涵蓋 `nil`、0、正負值與 zh-Hant／英文；日期子標另含接近午夜的非 UTC 時區與希伯來曆案例。
        - `DashboardStatsTests` 三檔的 `@Test` 合計不少於改動前，且各檔不超過 300 行。
        - 把 `profitDelta` 的大於或等於改成大於的變異讓測試轉紅；整檔檢查通過 [after: 1.2, 1.3]
    - 記錄 (2026-10-16，claude-impl 實作)：`DashboardStats` 遵循 `Equatable`；`DashboardFeature.State` 新增 `stats`、`ScreenState`；新增 `DashboardFormatters`；`DashboardStatsTests` 拆為主檔、`+Comparison`、`+Progress`、`+Fixtures` (`@Test` 15 → 15)；`DashboardFormattersTests` 因 300 行上限拆出 `+Summary` (加入 `reference/file-list.txt` 新增段)。
        - 主對話修正：三個新測試檔缺 `import Foundation` (MemberImportVisibility，`Date` 與 `Decimal` 字面值編不過)；希伯來曆案例預期原寫 `Iyar 13`，實際 ICU 英文希伯來曆格式日數在月名前，改為完整字面值 `Thursday, 13 Iyar` (2026-04-30 為 5786 年伊雅月 13 日、星期四，另行推算確認，未改 production)。
        - `percentDelta`、`marginDelta` 依 design 表格原為回傳 `LocalizedStringKey`，`LocalizationCatalogTests` 把這類函式內的字面值當成目錄 key 而失敗 (`— MoM`、`%@%@ MoM`、`%@%@ pt MoM`)；改為回傳 `String` (與 `profitDelta` 及現行一致，呼叫端包 `LocalizedStringKey`)，design 表格同步更新。
        - 變異：`profitDelta` 的 `>=` 改 `>`，`profitDelta_零成長_箭頭為上升` 轉紅 (25 通過、1 失敗)，已還原。
        - 完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同 (修正前另有本 task 與 3.3 的 4 條失敗，修正後受影響類別 133 條只剩已知 4 條)；整檔檢查 PASS。

- [x] 3.2 依 design「首頁與分析頁比照 P 記錄日期脈絡」、「統計與畫面狀態由 State 推導」與「呼叫端以前置點寫法取用色盤」改寫首頁畫面：
    - `DashboardView` 刪除三個 `@Dependency`，在 `content` 只讀一次 `screenState` 切換分支，各分支的容器與 identifier 依 design 與現行逐一對應。
    - hero 卡、KPI 卡區段、KPI 卡、本月摘要、進行中開團、近期訂單改讀 State 與 `DashboardFormatters`；方向改用 `BLTrend`；色彩改用前置點成員；`DashboardKPITile.Trend` 刪除；畫面內不再有資料處理與組字 (gate71 第二輪延到第 7 步的首頁畫面計算)。
    - `SnapshotTests+Dashboard` 改在 State 帶入固定的 `dateContext`，以上檔案整檔對齊。
    - 驗證：`SnapshotTests+Dashboard` 的既有 4 條與 0.3 的 2 條 snapshot 不變；`ActionGroupingScanTests`、`LocalizationCatalogTests` 通過；`DashboardLaunchLoadingTests`、`HarnessSelfCheckTests`、`LaunchSmokeTests` (iPhone 17) 通過；`Features/Dashboard/` 的 View 檔 `grep -E '@Dependency|BLPalette|\bpalette(\.|:)|(var|let) palette'` 為 0 處 (reducer 的依賴屬合法)；整檔檢查通過 [after: 1.1, 3.1]
    - 記錄 (2026-10-16，claude-impl 實作)：`DashboardView` 刪除 `calendar`、`date`、`timeZone` 三個 `@Dependency`，`content` 只讀一次 `screenState`；hero、KPI、進行中、近期訂單改讀 State 與 `DashboardFormatters`，`DashboardKPITile.Trend` 改為 `BLTrend`；刪除畫面私有的 `currentDateSubtitle`、`profitDisplay`、`profitDeltaDisplay`、`sparklineSummary`、`percentDeltaDisplay`、`marginDeltaDisplay`、`trend(for:)` 與各檔的 `palette`。`DashboardSummarySection`、`DashboardStats`、`DashboardFeature` 未改。`SnapshotTests+Dashboard` 的 overview 與首次使用測試帶入固定 `dateContext`，骨架測試維持未記錄日期。
        - 七個畫面檔的 identifier 與 HEAD 逐一相同；`.onboarding`／`.overview` 都在 `Dashboard.root` 的 `ScrollView` 內。進行中區段金額由 `CampaignFormatters.twd` 改為 `BLFormatters.twd` (輸出相同)；單一金額與百分比仍在畫面呼叫 `BLFormatters`，交 5.1 判定是否屬「組字」。
        - iPhone 17 `DDAA3311`：`SnapshotTests` 整批與首頁、分析頁相關類別 208 條，只有已知 4 條失敗且失敗圖逐位元相同；`shasum -c reference/snapshot-hashes.txt` 58/58 相符；`ActionGroupingScanTests`、`LocalizationCatalogTests` 通過；UI `DashboardLaunchLoadingTests`、`HarnessSelfCheckTests`、`LaunchSmokeTests` (與 3.4 的兩類同一次執行，共 19 條) 通過。
        - `Features/Dashboard/` 的 View 檔 grep 為 0 處；整檔檢查 PASS。
        - 變異：`.onboarding` 分支的 `onboardingHero` 改為 `loadingPlaceholder`，`dashboardView_已載入無訂單_顯示首次使用畫面` 轉紅 (執行 1 條)，已還原。

- [x] 3.3 依 design「分析頁資料形狀分兩步改寫並保持可編譯」、「資料層以語意色調、方向列舉與比例取代色彩與 Bool?」、「InsightsStats 與兩個測試檔依主題拆檔」、「統計與畫面狀態由 State 推導」與「格式化移到 DashboardFormatters 與 InsightsFormatters」完成分析頁資料層。落實 spec「Overview and insights figures follow a recorded current date」的走勢、熱力圖、星期標籤、資料變動重算與失敗優先，以及修改後 spec「Semantic and system colors are obtained through system APIs」的「Data types describe colors with tones」：
    - 資料形狀：`InsightsStats` 不再收 `locale` 與色盤，改存 `trendBuckets` 與 `trendRatio`；新增 `InsightsTrendBucket`；`InsightsCostSegment` 改帶 `tone`；`InsightsCategory` 新增 `ratio`；新增 `InsightsHeatmap` (含建構方法與 `Key`)。
    - 拆檔：依 design 一檔一頂層型別並拆出 `InsightsStats+Trend` (搬過去的走勢函式改為 internal static)。
    - State 與格式化：`InsightsFeature.State` 新增 `stats`、`campaignRanks`、`heatmap` 與巢狀 `ScreenState`／`screenState`；新增 `InsightsFormatters`。
    - 畫面：以最小改動讓 `InsightsView`、五張卡與 preview 改用新介面 (含 `InsightsTrendCard.delta` 改為 `LocalizedStringKey`)，維持可編譯，整檔改寫與這些畫面檔的整檔檢查留給 3.4。
    - 測試：`InsightsStatsTests` 拆成主檔與 `+Breakdown`，共用 helper 改為 internal 並移到 `+Fixtures`，熱力圖測試移到 `InsightsHeatmapTests`，與 `InsightsAttributionTests` 一併整檔對齊。
    - 驗證：
        - `InsightsFeatureTests+ScreenState` 以 spec 表格的分析頁欄寫成字面值測試；`InsightsFeatureTests` 主檔與拆出各檔都不超過 300 行。
        - spec「midnight passes on the thirty-day range」「labels per app language」兩個範例以字面值寫成測試；另寫分析期間切換後走勢區間與期間總獲利重算、開團改變後每團毛利排行重算，兩者都斷言 `dateContext` 不變。
        - 比例測試涵蓋第一名 100、某類別 -20 時為 0，以及第一名獲利為 0 或負值時全為 0；`trendRatio` 涵蓋上期無訂單與合計為 0 時為 `nil`。
        - 新增 `InsightsFormattersTests` 涵蓋 `analytics-trend-comparison` 既有的四個走勢情境、`rankTitle`、`weekLabel`。
        - 拆檔後各測試檔的 `@Test` 合計不少於改動前；把比例的下限夾限移除的變異讓測試轉紅。
        - `SnapshotTests+Insights` 的既有 3 條與 0.3 的 3 條 snapshot 不變；整檔檢查 (限資料、格式化與測試檔) 通過 [after: 1.2, 1.3]
    - 記錄 (2026-10-16，Haiku 子代理實作)：資料形狀改寫、`InsightsStats+Trend` 與五個型別拆檔、`InsightsFormatters`、`InsightsFeature.State` 的 `stats`／`campaignRanks`／`heatmap`／`ScreenState`；畫面只做最小改動 (`InsightsView` 仍在 body 內計算、走勢卡仍用 `InsightsTrendCard.Trend`，交 3.4)。
        - `InsightsStatsTests` 系列與 `InsightsHeatmapTests` `@Test` 合計 15 (改動前 9)；`InsightsAttributionTests` 原已合規，未改。
        - `trendDelta` 原以插值建 `LocalizedStringKey`，產生 `%@ %@` 格式 key，`InsightsFormattersTests` 兩條與 `LocalizationCatalogTests` 失敗；改為回傳 `String`，`InsightsView` 包成 `LocalizedStringKey` 傳給卡片 (卡片 `delta` 仍為 `LocalizedStringKey`)，design 表格同步更新。
        - 變異：比例下限夾限 `min(max(ratio, 0), 1)` 改為 `min(ratio, 1)`，`categoryBreakdown_第一名為分母_負獲利類別比例為零` 轉紅 (14 通過、1 失敗)，已還原。
        - 完整單元回歸 (iPhone 17 `DDAA3311`) 1488 條，snapshot 只有已知 4 條失敗且失敗圖與 0.1 保存的逐位元相同；`SnapshotTests+Insights` 6 條通過；整檔檢查 (資料、格式化與測試檔) PASS，畫面檔既有超長行 (`InsightsCategoryCard`、`InsightsHeatmapCard`) 交 3.4。
        - `CampaignProfitRank.ratio` 毛利為負時為負值 (既有行為，design 未規定)，3.4 確認畫面是否夾限。

- [x] 3.4 依 design「首頁與分析頁比照 P 記錄日期脈絡」、「統計與畫面狀態由 State 推導」與「呼叫端以前置點寫法取用色盤」整檔改寫分析頁畫面：
    - `InsightsView` 刪除兩個 `@Dependency` 與 `Calendar.current`，在 `content` 只讀一次 `screenState` 切換分支，各分支的容器與 identifier 依 design 與現行逐一對應。
    - 走勢、類別、成本結構、每團毛利、熱力圖五張卡改讀 State 與 `InsightsFormatters`；方向改用 `BLTrend`；成本色調由畫面換算顏色；排行標題與週次標籤不再在畫面內組字；`InsightsTrendCard.Trend` 刪除。
    - 畫面內不再有資料處理與組字，涵蓋 gate71 第二輪延到第 7 步的 P-01 與分析頁畫面計算。
    - `InsightsDateRange` 與 `SnapshotTests+Insights` (改在 State 帶入固定的 `dateContext`) 一併整檔對齊；3.3 以最小改動碰過的畫面檔在這裡完成整檔檢查。
    - 驗證：`SnapshotTests+Insights` 的 6 條 snapshot 不變；`InsightsTests`、`InsightsLaunchLoadingTests` (iPhone 17) 通過；`ActionGroupingScanTests`、`LocalizationCatalogTests` 通過；`Features/Insights/` 的 View 檔 `grep -E '@Dependency|BLPalette|\bpalette(\.|:)|(var|let) palette'` 為 0 處，整個目錄 `grep` 不到 `Calendar.current`；整檔檢查通過 [after: 1.1, 3.3]
    - 記錄 (2026-10-16，Haiku 子代理實作)：`InsightsView` 刪除兩個 `@Dependency` 與 `Calendar.current`，`content` 只讀一次 `screenState`，星期標籤改用 `InsightsFormatters.weekdayLabels(calendar:locale:)` (calendar 取自記錄的 `dateContext`)；五張卡改讀 State 與 `InsightsFormatters` (`rankTitle`、`weekLabel`、`costDonutSlices`)，`InsightsTrendCard.Trend` 刪除，成本色調與類別色相由畫面換算；HEAD 既有的超長行已整檔對齊。`InsightsStats`、`InsightsStats+Trend`、`InsightsFeature` 沒有未引用成員，未改。
        - 六個畫面檔的 identifier 與 HEAD 逐一相同；`.empty` 掛 `Insights.emptyState` (不在 `Insights.root` 內)。`CampaignProfitRank.ratio` 為負時由 `BLProgressView` 既有的 `min(max(value, 0), 1)` 夾限，行為不變。
        - `SnapshotTests+Insights` 改在 State 帶入固定 `dateContext`，仍保留 `withFixedNow` 包裝 (reducer 的 `view(.task)` 會讀 `date.now`，與 `SnapshotTests+Campaigns` 相同)。
        - iPhone 17 `DDAA3311`：同 3.2 的同一次執行 (208 條只有已知 4 條、雜湊 58/58)；UI `InsightsTests`、`InsightsLaunchLoadingTests` 通過；`Features/Insights/` 的 View 檔 grep 為 0 處、整個目錄找不到 `Calendar.current`；整檔檢查 PASS。
        - 變異：`.empty` 分支的 `emptyState` 改為 `loadingPlaceholder`，`insightsView_已載入無訂單_顯示空狀態` 轉紅 (執行 1 條)，已還原。

- [x] 3.5 依 design「畫面不宣告依賴由掃描守門」在 `DependencyConventionScanTests` 新增掃描規則，涵蓋 spec「Overview and insights figures follow a recorded current date」的「Views do not read the current date」：
    - 只套用 production 檔；清空註解與字串後，所有遵循 `View` (整字比對) 的型別的每個宣告本體都不得出現 `@Dependency(`，整個檔不得出現 `Calendar.current` 或 `Calendar.autoupdatingCurrent`。
    - 實作放 `DependencyConventionScanTests+ViewRules.swift`，`ScanRule` 新 case、`+Rules.swift` 的分派與 `+Scanner.swift` 的 `requiredSubrules` 分派一併補上；案例放 `DependencyConventionScanScenario+ViewCases.swift`，涵蓋 design 列出的違規與合規片段 (含主宣告與 `View` 遵循分開寫的形狀)。
    - 改到的掃描測試檔整檔對齊。
    - 驗證：新規則在 3.2、3.4 完成後的程式碼上通過；片段案例全數通過；暫時在任一 View 加回 `@Dependency(\.date)`、在任一 reducer 加入 `Calendar.current` 的兩個變異都讓測試轉紅，且實際執行數大於 0；整檔檢查通過 [after: 3.2, 3.4]
    - 記錄 (2026-10-16，Haiku 子代理實作)：新規則 `ScanRule.viewDependency`，實作在 `DependencyConventionScanTests+ViewRules.swift`；`+Scanner` 先讀完整樹，只有這條規則收集 production 的 View 型別名稱 (繼承子句去掉泛型與 `where` 後以 `\bView\b` 比對，`SwiftUI.View`、跨行子句算，`ViewModifier`、`ViewBuilder`、`ViewModel` 不算)，再檢查這些型別所有宣告本體內的 `@Dependency(` 與全檔的 `Calendar.current`／`Calendar.autoupdatingCurrent`。片段案例在 `DependencyConventionScanScenario+ViewCases.swift`：違規 8 案、合規 6 案。
        - 主對話另把 `DependencyConventionScanTests+TestValueRules.swift` 文件註解的 `violations(of:in:)` 改為新簽章 `violations(of:in:viewTypeNames:)` (加入 `reference/file-list.txt` 修改段)。
        - iPhone 17 `DDAA3311`：`DependencyConventionScanTests`、`TestSuiteIntegrityTests` 8 條通過 (新規則在 3.2、3.4 後的程式碼上 0 違規)。
        - 變異：`DashboardView` 本體加 `@Dependency(\.date) private var date` → `scanTree_每條規則掃描App與單元測試程式碼_沒有違規(rule:)` 轉紅，回報 `DashboardView.swift:13 @Dependency(`；`DashboardFeature` 加一個回傳 `Calendar.current` 的屬性 → 同一測試轉紅，回報 `DashboardFeature.swift:186 Calendar.current`；兩次都只執行 5 條中的 1 條失敗，已還原。
        - 整檔檢查 PASS (`WSTR` 4 為既有長字串，不計失敗)。

## 4. 收尾

- [x] 4.1 依 design「先擴充再遷移，最後刪除 BLPalette」落實修改後 spec「Semantic and system colors are obtained through system APIs」的「No palette instance remains」：刪除 `BLPalette.swift` (含 `heroGradient`)。驗證：`apps/ios/` 的 Swift 檔 `grep -rn` 找不到 `BLPalette`、`var palette`、`palette:`、`Color+Extensions`，`Color.blSecondaryLabel` 只出現在沒有型別脈絡的位置 (預期 0 處)；iPhone 與 iPad 各 build 一次；`DesignSystemSourceScanTests`、`DependencyConventionScanTests`、`ContrastComplianceTests` 通過；`SnapshotTests` 整批 snapshot 不變 [after: 2.1, 2.2, 2.3, 2.4, 2.5, 3.2, 3.4, 3.5]
    - 記錄 (2026-10-16，主對話)：刪除 `BLPalette.swift` (以 `rm` 刪除，不動 git index)。刪除前 `apps/ios/` 的 Swift 檔只剩該檔自身引用 `BLPalette`；刪除後 `grep -rn` 找不到 `BLPalette`、`var palette`、`palette:` (`.symbolRenderingMode(.palette)` 除外)、`Color+Extensions`，`Color.blSecondaryLabel` 為 0 處。
        - iPhone 17 `DDAA3311`：`SnapshotTests`、`DesignSystemSourceScanTests`、`DependencyConventionScanTests`、`ContrastComplianceTests` 90 條，只有已知 4 條 snapshot 失敗且失敗圖逐位元相同，`shasum -c reference/snapshot-hashes.txt` 58/58 相符；iPad Air 11-inch (M4) `1157F07A`：`DesignSystemSourceScanTests` 14 條通過 (兩個平台的建置都經測試建置確認)。

- [x] 4.2 依 design「文件同步」與根目錄 `CLAUDE.md` 文件同步鐵則，更新 `.claude/rules/ios-design-system.md` 色彩一節、`.claude/rules/ios-data-layer.md` 的「成長率的百分比與方向同源」、`apps/ios/CLAUDE.md` (刪除兩條過渡例外、日期脈絡與 Root 刷新補首頁與分析頁、新掃描規則、第 6、7 步字樣、格式化型別清單)、`.claude/rules/ios-navigation.md`、`.claude/rules/ios-unit-tests.md`，並確認 `apps/ios/README.md` 是否需要同步。驗證：`grep -rn` 在 `apps/ios/CLAUDE.md`、`apps/ios/README.md`、`.claude/rules/` 找不到 `BLPalette`、`InsightsStats.trendDelta`、「完整形式」、「已決定不做」與兩條過渡例外的字樣；修改內容逐條與 design 對照，審視結論 (有影響已同步或確認無文件影響) 逐列記在本 task 下方
    - 記錄 (2026-10-16，主對話)：依 design「文件同步」逐條修改。
        - `.claude/rules/ios-design-system.md` 色彩一節：取色入口改 `Color+Semantic.swift` 並補前置點寫法規則；刪除「呼叫端寫 `Color.blSecondaryLabel` 完整形式」與「不改成 `ShapeStyle` 擴充 (已決定不做)」；強調色、次要文字不透明度例外改 `.blAccent`、`.blSecondaryLabel`；hero 漸層改為「不在其他地方讀取 `BLHeroGradientStart`／`End`」；新增「資料型別帶語意色調與方向，由畫面換算色彩」。
        - `.claude/rules/ios-data-layer.md`：「成長率的百分比與方向同源」改為 `DashboardStats.ratio` 與 `InsightsStats.trendRatio` 以同一差額除以 `abs(previous)`，方向由 `BLTrend(delta:)` 依比值正負決定。
        - `apps/ios/CLAUDE.md`：刪除 `DashboardView`／`InsightsView` 兩條過渡例外，改為新掃描規則守門；日期脈絡寫入點與 Root 刷新對象補首頁與分析頁；「第 6、7 步」兩處改為第 6 步；格式化型別清單補 `DashboardFormatters`、`InsightsFormatters`。
        - `.claude/rules/ios-navigation.md`：回到前景時更新的日期脈絡補首頁與分析頁。`.claude/rules/ios-unit-tests.md`：snapshot「畫面不讀時間」的例子補首頁與分析頁。
        - 另依文件同步鐵則補一條本次踩到的 gotcha 到 `.claude/rules/ios-accessibility-localization.md`：回傳 `LocalizedStringKey` 的函式內字面值會被 `LocalizationCatalogTests` 當成目錄 key，組 verbatim 文字的格式化函式回傳 `String` (3.1、3.3 的 4 條失敗即此原因)。
        - `grep -rn` 在 `apps/ios/CLAUDE.md`、`apps/ios/README.md`、`.claude/rules/` 找不到 `BLPalette`、`InsightsStats.trendDelta`、「完整形式」、「已決定不做」與兩條過渡例外的字樣。
    - 審視結論 (依 `git status --short`，2026-10-16，openspec 以外 162 列)：
        - `apps/ios/BuyLedger/Shared/DesignSystem/**` 修改 19、新增 4 (`BLRadius`、`BLSpacing`、`BLListMetrics`、`BLHitTarget`)、刪除 2 (`BLMetrics.swift`、`BLPalette.swift`) 與 `Shared/Extensions/Color+Extensions.swift` 刪除：有影響，已同步 `ios-design-system.md`；`apps/ios/README.md:90` 以「色盤、字級、間距、圓角等 token」概述 Foundations，仍正確，確認無影響。
        - `Features/Dashboard/**`、`Features/Insights/**` (修改與新增)：有影響，已同步 `apps/ios/CLAUDE.md`、`ios-data-layer.md`、`ios-navigation.md`、`ios-unit-tests.md`；README 的 Dashboard／Insights 目錄說明仍正確，確認無影響。
        - `Features/App`、`Campaigns`、`Customers`、`FX`、`Lookups`、`More`、`Orders`、`Quote`、`Settings`、`AISummary` 的色盤呼叫端改寫與 `RootFeature` 日期刷新兩行：行為不變 (前置點寫法已記在 `ios-design-system.md`、刷新對象已記在 `apps/ios/CLAUDE.md`)，確認無其他文件影響。
        - `apps/ios/BuyLedgerTests/**` (修改與新增，含 0.3 補錄 snapshot 與 `__Snapshots__` 新基準圖)：新掃描規則已記在 `apps/ios/CLAUDE.md`；本地化掃描 gotcha 已記在 `ios-accessibility-localization.md`；其餘確認無文件影響。
        - 技術棧、外部服務、API key、build／test 指令與目錄結構：無變動，`apps/ios/README.md` 與根目錄 `README.md` 確認無影響。
        - `project.pbxproj`、`Localizable.xcstrings`：未出現在 `git status`。

## 5. 驗收

- [x] 5.1 style 閘門：依 design「整檔對齊沿用 6a＋6b 的檢查腳本與裁決」，由專責 style agent 依 `/ios-dev-kit` 逐檔逐條審查 `reference/file-list.txt` 修改與新增段的所有現存 Swift 檔 (整檔，不抽查，可分組並行)，違規修正後重審改到的檔。驗證：逐檔檢查清單與「0 違規」結論記在本 task 下方；`style_checks.py` 以清單的全部現存檔執行，輸出檔數等於清單數且 `TOTAL` 只含不計失敗的代碼 [after: 3.5, 4.1, 4.2]
    - 記錄 (2026-10-16，Haiku 審查與修正，主對話裁決與驗證)：四輪閘門。
        - 第一輪：9 組整檔逐條審查清單全部現存檔，約 300 項；裁決 A (不算違規，含 TCA View 可持有 `@Environment`／`@ScaledMetric`／`static let` 並登記到 `apps/ios/CLAUDE.md`)、B (必修：`@Bindable var store`、`@ScaledMetric`、間距 token、modifier 四組只做不改語意的重排)、C (畫面計算移到 State 或格式化型別，各附字面值測試與變異)、D (多餘 import 與 `@MainActor` 以 build 判定)、E (跨組改名同步)、U (使用者決定，見下)；第二輪修跨組項目 (memberwise 參數字母序、`isInitial…` 標籤、`.blAccent.gradient` 等) 後 8 組重審。
        - 第三輪：依重審裁決修正 (explicit init 的 View 成員改 `private let`、Dashboard 區段改 `@Bindable`、`CampaignFormatters` 依畫面順序、`isReminderWanted` 改名、`AISummaryFeature.State.failureMessage`、`CampaignListFeature.State.visibleSections` 等)，改到的 54 檔整檔重審 6 組。
        - 第四輪：依第三輪重審裁決修正 28 檔 (摘要動詞開頭、`locale` 等識別字加反引號、`- Returns` 不重述摘要、`FxRatesList`／`QuoteInputsCard` body 只組合、FX 與 Quote 的 effect 改 `do throws(<Service 錯誤>)`、`allowsDecimalEntry` 改 `isDecimalEntryAllowed`、`BLAvatar` 標裝飾、`BLTagPill` 裝飾圖示隱藏、`AISummaryFeature` 的 switch 依 Action 順序等)；改動處逐項核對全數正確完成、無新違規，核對另提的 `FxFormatters` 摘要與清單內 19 檔「App 根層依語言偏好注入的 `locale`」反引號已補。
        - 變異：第一輪 12 個 (C 項移出的計算)、第三輪 4 個 (`failureMessage` 兩個、`visibleSections` 的 `!sections.isEmpty` 改 `!campaigns.isEmpty`、刪除 `CampaignEditFeature` 的 `BindingReducer()` 讓 5 條綁定測試失敗)，全部轉紅且還原後逐位元相同。
        - 驗證 (第四輪後)：完整單元回歸 (iPhone 17 `DDAA3311`) 1519 條只有 0.1 記錄的 4 條 snapshot 失敗，失敗圖雜湊與 0.1 相同 (`5fc17d7f`、`f208ee72`、`ec2dacce`、`ca771f57`)；`reference/snapshot-hashes.txt` 58/58 OK；iPad Air 11 (M4) `1157F07A` 的 `LayerBoundaryTests` 通過 (iPad build)；UI `AISummaryTests`、`CampaignListTests`、`CampaignCrudTests`、`CampaignFlowTests`、`CampaignDetailTests`、`CustomersTests`、`LookupManagementTests`、`FxTests`、`QuoteTests`、`DashboardLaunchLoadingTests`、`InsightsTests`、`OrderCreateTests`、`OrderEditDirtyTests`、`OrderDetailTests`、`PhotoViewerPagingTests`、`HarnessSelfCheckTests` 56 條通過 (前一次執行在 16:44 後模擬器啟動 App 全部瞬間失敗，屬環境，重跑全過)。
        - `style_checks.py` 以清單全部現存檔 (177 檔 = 180 列減刪除段 3 檔) 執行：`TOTAL {'WSTR': 8} files 177 PASS`。
        - 待使用者決定 (U，未改)：U1 `OrderRowView`「客戶實付」的資訊性 `.tertiary`；U2 `OrderEditPaymentSection` 顯示條件移到 `OrderEditFeature.State` (與 6c 共檔，合併後再做)；U3 `AISummaryView`、`LookupItemRow`、`DashboardHeroCard`、`BLFilterChip`、`BLSparkline` 以 `.opacity` 做的淡底；U4 `MoreView` 的 `.labelStyle(.titleAndIcon)` (實測會動 `moreView` 像素，已還原)。
        - 範圍外 (未改，回報使用者)：`BLStatusPill` 以 `LocalizedStringKey(title)` 顯示使用者資料 (分類名稱會被當成目錄 key)；`BLBarChart`／`BLDonutChart`／`OrderFormatters` 的 `locale: Locale = .current` 預設參數；`BLPhotoThumbnail.deleteIconSize` 在大字級的位移。
        - 逐檔結論 (全部 0 違規，以目錄分組)：
            - `BuyLedger/Features/AISummary/` (2)：AISummaryFeature、AISummaryView
            - `BuyLedger/Features/App/` (4)：AppLockView、PersistenceFailureView、RootFeature、RootSidebarLayout
            - `BuyLedger/Features/Campaigns/` (5)：CampaignEditFeature、CampaignEditView、CampaignFormatters、CampaignListFeature、CampaignListView
            - `BuyLedger/Features/Campaigns/Components/` (5)：CampaignDetailDistributionSection、CampaignDetailInfoSection、CampaignDetailSettlementSection、CampaignRow、CampaignSectionList
            - `BuyLedger/Features/Customers/` (5)：CustomerFormatters、CustomerRank、CustomerRankBadgeStyle、CustomersFeature、CustomersView
            - `BuyLedger/Features/Customers/Components/` (2)：CustomerListRow、CustomerTopCard
            - `BuyLedger/Features/Dashboard/` (11)：DashboardDateContext、DashboardFeature、DashboardFormatters、DashboardHeroCard、DashboardKPITile、DashboardKPITiles、DashboardOngoingCampaignsSection、DashboardRecentOrdersSection、DashboardStats、DashboardSummarySection、DashboardView
            - `BuyLedger/Features/FX/` (3)：FxFeature、FxFormatters、FxView
            - `BuyLedger/Features/FX/Components/` (2)：FxRatesList、FxStatusBanner
            - `BuyLedger/Features/Insights/` (17)：CampaignProfitRank、InsightsCampaignProfitCard、InsightsCategory、InsightsCategoryCard、InsightsCostSegment、InsightsCostStructureCard、InsightsDateContext、InsightsDateRange、InsightsFeature、InsightsFormatters、InsightsHeatmap、InsightsHeatmapCard、InsightsStats、InsightsStats+Trend、InsightsTrendBucket、InsightsTrendCard、InsightsView
            - `BuyLedger/Features/Lookups/` (2)：LookupManagementView、LookupNameEditorSheet
            - `BuyLedger/Features/Lookups/Components/` (2)：LookupItemList、LookupItemRow
            - `BuyLedger/Features/More/` (1)：MoreView
            - `BuyLedger/Features/Orders/` (6)：OrderEditPhotosSection、OrderPercentConversion、OrdersCompactView、OrdersRegularDetailColumn、OrdersRegularListColumn、OrdersView
            - `BuyLedger/Features/Orders/Components/` (24)：MergePhotoPickerSheet、MergePhotoTile、OrderDetailCardlessView、OrderDetailContentView、OrderDetailCostView、OrderDetailItemsView、OrderDetailNotesView、OrderDetailSourceView、OrderDetailSummaryView、OrderEditBasicSection、OrderEditCostSection、OrderEditFeesSection、OrderEditItemsSection、OrderEditPaymentSection、OrderEditPercentField、OrderEditSelectionRow、OrderFilterCategorySection、OrderFilterDateSection、OrderFilterPaymentMethodSection、OrderMergeCandidateSheet、OrderRowView、OrderSelectableRow、OrdersCompactListView、OrdersToolbarContent
            - `BuyLedger/Features/Quote/` (3)：QuoteFormatters、QuoteRateFeature、QuoteView
            - `BuyLedger/Features/Quote/Components/` (3)：QuoteBreakdownCard、QuoteInputsCard、QuoteStatusBanner
            - `BuyLedger/Features/Settings/` (1)：SettingsView
            - `BuyLedger/Shared/DesignSystem/Components/Buttons/` (1)：BLButtonStyle
            - `BuyLedger/Shared/DesignSystem/Components/Cards/` (1)：BLCard
            - `BuyLedger/Shared/DesignSystem/Components/Charts/` (3)：BLBarChart、BLDonutChart、BLSparkline
            - `BuyLedger/Shared/DesignSystem/Components/Chips/` (1)：BLFilterChip
            - `BuyLedger/Shared/DesignSystem/Components/Forms/` (1)：PaymentMethodEditorSheet
            - `BuyLedger/Shared/DesignSystem/Components/Images/` (2)：BLPhotoThumbnail、BLPhotoViewer
            - `BuyLedger/Shared/DesignSystem/Components/Progress/` (2)：BLProgressView、BLProgressViewStyle
            - `BuyLedger/Shared/DesignSystem/Components/Tags/` (1)：BLTagPill
            - `BuyLedger/Shared/DesignSystem/Foundations/` (6)：BLHitTarget、BLListMetrics、BLRadius、BLSpacing、BLTrend、Color+Semantic
            - `BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/` (1)：BLHeroCardBackground
            - `BuyLedgerTests/` (60)：AISummaryFeatureTests、BLTrendTests、CampaignEditFeatureTests、CampaignEditFeatureTests+NavigationTitle、CampaignFeatureTests+Editing、CampaignFeatureTests+FailureTimingFollowUp、CampaignFeatureTests+NameConflict、CampaignFeatureTests+ReminderIntegration、CampaignFeatureTests+ReminderRename、CampaignFormattersTests、CampaignListFeatureTests+DateContext、CampaignListFeatureTests+RowSummaries、CampaignListFeatureTests+VisibleSections、ColorContrast、ColorContrastTests、ContrastComplianceTests、CustomerFormattersTests、CustomersFeatureTests、DashboardFeatureTests、DashboardFeatureTests+DateContext、DashboardFeatureTests+ScreenState、DashboardFormattersTests、DashboardFormattersTests+Summary、DashboardStatsTests、DashboardStatsTests+Comparison、DashboardStatsTests+Fixtures、DashboardStatsTests+Progress、DependencyConventionScanScenario、DependencyConventionScanScenario+ViewCases、DependencyConventionScanTests、DependencyConventionScanTests+Rules、DependencyConventionScanTests+Scanner、DependencyConventionScanTests+TestValueRules、DependencyConventionScanTests+ViewRules、DesignSystemSourceScanTests、FxFeatureTests+CurrencyCodes、FxFormattersTests、InsightsAttributionTests、InsightsFeatureTests、InsightsFeatureTests+DateContext、InsightsFeatureTests+ScreenState、InsightsFormattersTests、InsightsHeatmapTests、InsightsStatsTests、InsightsStatsTests+Breakdown、InsightsStatsTests+Fixtures、OrderPercentConversionTests、QuoteFeatureTests+CurrencyCodes、QuoteFormattersTests、RootFeatureTests+DeepLinks、RootFeatureTests+Fixtures、RootFeatureTests+Foreground、RootFeatureTests+LoadRequests、SnapshotTests+CampaignDetail、SnapshotTests+Customers、SnapshotTests+Dashboard、SnapshotTests+Insights、SnapshotTests+More、SnapshotTests+OrderMerge、SnapshotTests+Shared

- [x] 5.2 依 design「snapshot 與 UI Automation 驗收」以 UI Automation 重做 0.2 的記錄並逐項對照：
    - iPhone 17 與 iPad 的首頁日期子標、英文模式分析頁的星期標籤與金額、iPad 側邊欄與照片檢視器截圖 (目視)。
    - iPhone 17 首次切到分析頁時，以 `simulator record-video` 逐格確認是否看得到載入骨架閃現；看得到就回報使用者決定。
    - 驗證：記錄值與 0.2 相同，截圖或錄影路徑寫在本 task 下方；之後若再改到這些畫面，重做對應的對照 [after: 5.1]
    - 記錄 (2026-10-16，主對話，5.1 之後的程式；build number 367 → 368 後 build-and-run，iPad 安裝同一個 App)：與 0.2 逐項相同。
        - iPhone 17 `DDAA3311` (可及性樹取不到，erase 後重裝)：首頁 `dashboard.currentDateSubtitle`「6月15日星期一」、英文「Monday, June 15」(`reference/ui-verify/iphone-dashboard-zh.json`、`.jpg`)。
        - 英文分析頁：「12-Month Net Profit」NT$11,412、「— No comparison」；類別排行 1. 美妝 NT$6,915、2. 服飾 NT$2,505；成本結構 Total Cost NT$42,368、Item Cost NT$41,011、Local Shipping NT$450、International Shipping NT$2,270、Fees NT$1,357；熱力圖 W1 至 W8、星期 M T W T F S S、8 格 T Week 7、W Week 6、T Week 5、T Week 7、F Week 6、S Week 6、S Week 5、S Week 6 各 1 筆 (`iphone-insights-en-top.json`、`iphone-insights-en-bottom2.json`)。
        - 首次切到分析頁錄影 (`iphone-insights-first-switch.mp4`，實際約 11 fps，140 格只有 3 個相異畫面)：總覽淡出、分析頁帶資料淡入，看不到載入骨架 (`iphone-insights-first-switch-frames.jpg`)；短於約 90ms 的閃現無法以此幀率排除。
        - iPad Air 11 (M4) `1157F07A`：首頁日期子標「6月15日星期一」(`ipad-dashboard-zh.json`)，側邊欄截圖與 0.2 目視相同 (`ipad-dashboard-sidebar.jpg`)。
        - iPhone 照片檢視器 (`-BLUITestSeed photos`，訂單編輯第一張縮圖)：顯示「1/5」，與 0.2 目視相同 (`iphone-photo-viewer.jpg`)。
        - 上面的「與 0.2 逐項相同」指顯示的文字與數值；成本結構圖例的可及性樹結構與 0.2 不同，見下一則記錄。
    - 記錄 (2026-10-17，`/spectra-review` 後修正，使用者裁決)：
        - 成本結構圖例：`InsightsCostStructureCard` 的圖例列以 `.accessibilityElement(children: .combine)` 合併成單一朗讀單位 (例如「Item Cost, NT$41,011」)，色塊標 `.accessibilityHidden(true)`；0.2 的 `ui-baseline/iphone-insights-en-bottom.json` 名稱與金額分開，`ui-verify/iphone-insights-en-bottom2.json` 多出合併元素。依 `ios-accessibility-localization.md` 的複合列規則屬刻意的無障礙調整，使用者裁決保留；design「畫面結構不變」的例外記在這裡。
        - 圖表高度雙重縮放：5.1 把 `BLSparkline`／`BLBarChart` 的 `height` 改成 `@ScaledMetric`，`DashboardHeroCard`、`InsightsTrendCard` 又各自宣告 `@ScaledMetric` 傳入，合成 `init` 再縮放一次。呼叫端改回傳基準值 36、200，與 HEAD 相同。
        - 守門：`DesignSystemSourceScanTests` 新增規則十二 (`+ScaledMetric` 測試、`+ScaledMetricScanner` 掃描、`+Patterns` 兩個樣式；`+Scanner` 的 `relativePath(of:under:)` 改 internal，整檔對齊時 `honoringExemptions` 參數改名 `shouldHonorExemptions`)。修正前正式掃描回報 `DashboardHeroCard.swift:100`、`InsightsTrendCard.swift:92` 而失敗；修正後通過；把 `DashboardHeroCard` 改回包一層 `@ScaledMetric` 的變異轉紅，還原後逐位元相同。
        - UI Automation (iPhone 17 `DDAA3311`，`-BLUITestSeed fullOrders`，`UICTContentSizeCategoryAccessibilityXXXL`；build number 368 → 369 → 370，修正前後各一次 build-and-run；可及性樹取不到時 erase 後重裝)：首頁走勢線高 284.47 → 100.13，分析頁走勢長條圖高 1588.67 → 563.67，修正後約為 36 與 200 乘同一縮放倍率 (約 2.8)，修正前約為乘兩次 (`ui-verify/iphone-ax5-dashboard-before`／`-after`、`iphone-ax5-insights-before`／`-after` 的 `.json`、`.jpg`)。
        - style：6 檔 (`reference/file-list.txt` 標「review 後」的 4 個測試檔與兩張卡片) 整檔逐條審查，必修 3 項 (`init` 反引號、Internal Method 呼叫者在前、Bool 參數命名) 已修，fixture 依 `DependencyConventionScanScenario+ViewCases` 改計算屬性；`+Patterns` 的 `static let` 維持 (`lineViolates` 以 `===` 比對樣式身分，改計算屬性會失效)。`style_checks.py` 7 檔 `TOTAL {'WSTR': 4} PASS`。
        - 驗證：完整單元回歸 1522 條 (新增 3 條) 只有 0.1 記錄的 4 條 snapshot 失敗 (`test_sim_2026-10-16T16-49-36-257Z_pid17555_41787df9.xcresult`)，erase 後失敗圖只在日期膠囊差幾個像素 (DatePicker 格式隨模擬器重置變動，這 4 條的畫面本次未改)；`reference/snapshot-hashes.txt` 58/58 OK；UI `InsightsTests`、`InsightsLaunchLoadingTests`、`DashboardLaunchLoadingTests` 8 條通過 (`test_sim_2026-10-16T16-53-02-745Z_pid24148_ee1c6976.xcresult`)；style 修正後 `DesignSystemSourceScanTests` 17 條通過 (`test_sim_2026-10-16T17-09-58-637Z_pid38849_36fd91e0.xcresult`)。兩個平台的 UI 主回歸留到與 6c 合併後重跑。

- [x] 5.3 完整回歸：
    - 先 clean build products，iPhone 17 鎖淺色後跑完整單元回歸。
    - 以 `mobilebuildmcp simulator-management boot` 開機 (Device Hub 未執行)，iPad 先單獨跑 `KeyboardDismissTests`，iPhone 17 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸 (`--extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)。
    - 驗證：單元回歸 snapshot 不變且其餘測試全數通過；兩個平台的 UI 主回歸全數通過；`git status --short` 沒有本 change 以外的變動 (`project.pbxproj` 的 build number 遞增屬預期；build 若改寫 `Localizable.xcstrings` 則還原並記錄)；result bundle 路徑與 `totalTestCount` 記在本 task 下方，且晚於最後一次改檔 [after: 5.2]
    - 記錄 (2026-10-16，主對話；最後一次改檔為 5.1 第四輪後的註解反引號，之後的執行都晚於它)：
        - `simulator clean` 後 iPhone 17 `DDAA3311` 鎖淺色跑完整單元回歸：1519 條只有 0.1 記錄的 4 條 snapshot 失敗，失敗圖雜湊與 0.1 相同 (`5fc17d7f`、`f208ee72`、`ec2dacce`、`ca771f57`)，`reference/snapshot-hashes.txt` 58/58 OK；bundle `test_sim_2026-10-16T11-22-34-448Z_pid23388_e513dc8c.xcresult` (`totalTestCount` 1519)。
        - iPad Air 11 (M4) `1157F07A` 以 `simulator-management boot` 開機 (Device Hub 未執行)，`KeyboardDismissTests` 2 條通過 (`test_sim_2026-10-16T11-28-23-440Z_pid33235_efe11b91.xcresult`)。
        - iPhone 17 UI 主回歸 89 條：88 通過、`CurrencyPickerTests.testOrderEditPickerUsesEnglishCodeAndSearches` 失敗 (「訂單編輯表單未就緒，無法開啟幣別選擇器」)，同一台單獨重跑 `CurrencyPickerTests` 8 條全過，判定為雜訊 (`test_sim_2026-10-16T11-31-12-115Z_pid36947_d1ffe7fd.xcresult`)。
        - iPad UI 主回歸 89 條全過 (`test_sim_2026-10-16T12-17-50-102Z_pid80552_94f3852b.xcresult`)。
        - `git status --short`：只有清單內的 Swift 檔、本 change 同步的文件 (`apps/ios/CLAUDE.md`、`.claude/rules/ios-*.md`)、0.3 補錄的 snapshot 基準、本 change 的 openspec 目錄、`project.pbxproj` 的 build number (367 → 368，5.2 的 build-and-run 前遞增) 與 `Localizable.xcstrings` (新增 `customers.list.label.topCount`、`fx.rates.label.conversionRate`、`fx.rates.label.sourceTimestamp` 與位置標記，沒有 build 污染)；另有 6c change (`service-ownership-alignment`) 的 openspec 目錄，依平行開發的安排放在主 checkout。
    - 記錄 (2026-10-17，修正 `/spectra-verify` 的警告，使用者指示)：
        - 規格範例「retrying the next morning」：`DashboardFeatureTests+DateContext` 新增 `retryTapped_載入失敗隔天早上重試_記錄日期先更新且月份數字取五月` (UTC 行事曆，2026-05-12 10:00 記錄後載入失敗，2026-05-13 09:00 重試；5 月與 4 月各一筆訂單，斷言 `send` 時就改成重試當下的日期，`stats` 的營收 1,000、單數 1)。把重試改成沿用舊日期的變異讓它轉紅，還原後逐位元相同。首頁與分析頁原本的重試測試 Given 改成從載入失敗開始並改名。
        - proposal 的 Impact 與 design 補上 5.1 閘門與 review 擴大的範圍 (design 新增「5.1 閘門與 review 擴大的範圍」，Non-Goals 註明圖例例外，平行開發分組補 6c 合併的同行衝突)；`apps/ios/CLAUDE.md` 的格式化型別清單補 `CustomerFormatters`、`QuoteFormatters`、`FxFormatters`。
        - style：兩個測試檔整檔逐條審查，必修 3 項 (重試測試的 doc 與 Given 不一致、一則 Note 講兩件事、Note 重述摘要) 已修；預期日期以測試 helper `DashboardStatsTests.utcDate` 組出屬待判斷，helper 不是受測程式，維持。`style_checks.py` 2 檔 PASS。
        - 驗證：完整單元回歸 1523 條只有 0.1 記錄的 4 條 snapshot 失敗 (`test_sim_2026-10-16T17-57-31-346Z_pid84184_d4b4a763.xcresult`)，`reference/snapshot-hashes.txt` 58/58 OK；style 修正後 `DashboardFeatureTests` 22 條通過 (`test_sim_2026-10-16T18-05-47-362Z_pid91523_277cff43.xcresult`)。
        - 未處理 (verify 的建議項)：「returning after the month ends」的上月營收字面值斷言 (`DashboardStats` 不公開上月營收，只能經 `revenueDelta`)；`blSecondaryLabel` 單一定義的常駐掃描。
