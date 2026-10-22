## Summary

本 change 合併兩件事，改到的檔一律依 `/ios-dev-kit` 整檔對齊 (2026-10-09 裁決 1)：

- **色盤改為 `ShapeStyle` 靜態擴充 (插單)**：刪除 `BLPalette` 實例與每個 View 的 `palette` 屬性，色彩改為 `extension ShapeStyle where Self == Color` 的 `bl` 前綴靜態成員，呼叫端寫 `.foregroundStyle(.blLabel)`。
- **第 7 步：首頁 (`Features/Dashboard/`) 與分析頁 (`Features/Insights/`) 對齊**：現在時間改由 reducer 記錄在 State，統計移出畫面，格式化移到格式化型別，回到前景與跨日時一併刷新。

範圍演變：

- 2026-10-09 使用者裁決色盤採 `ShapeStyle` 靜態擴充 (方案二)，不採 Environment。
- 2026-10-15 propose 時實測色盤會改到首頁與分析頁的畫面檔 (`DashboardKPITile`、`DashboardKPITiles`、分析頁五張卡與 `DashboardView`、`InsightsView` 等)；使用者裁決照「改到即整檔對齊」處理。這些畫面剩下的項目正是第 7 步核心，因此第 7 步整個併入本 change。
- 更正 (2026-10-15 第二輪審查)：propose 時我曾說其中 7 檔「從未整檔對齊」，實際上它們已在 2026-10-05 (6e) 拆檔並通過當時的檢查腳本；尚未完成的是畫面內格式化與計算移出，屬第 7 步。使用者知悉後維持上述兩項裁決。

## Motivation

- **色盤要先取得實例才能用** (2026-10-15 實測)：
    - 45 檔宣告 `var palette: BLPalette { BLPalette() }`，共 84 處 `BLPalette()`；`OrderSelectableRow`、`OrdersCompactListView`、`OrdersToolbarContent` 以 `let palette: BLPalette` 接收，Design System 元件的 helper 也以參數一路傳遞。
    - `BLPalette` 是沒有欄位的空 struct，成員全是系統或 asset catalog 的動態色，實例沒有存在必要。
    - 為了上色，`InsightsStats` 的 init 收色盤參數，`CustomerRankBadgeStyle` 的方法也收色盤參數。
    - 次要文字另有 `Color.blSecondaryLabel` 縮寫，在 27 個 production 檔有 49 處實際呼叫，其中 19 個檔沒有用到色盤。它與色盤是兩套寫法，還要一條測試防止兩者漂移。
- **首頁與分析頁自己讀現在時間** (`apps/ios/CLAUDE.md` 登記的兩條過渡例外)：
    - `DashboardView` 宣告 `@Dependency(\.date)`、`\.calendar`、`\.timeZone`，`InsightsView` 宣告前兩者。
    - `InsightsView.weekdayLabels` 是 production 唯一直接呼叫 `Calendar.current` 之處。
    - 回到前景與重大時間變更只刷新開團與訂單清單的日期脈絡，首頁與分析頁沒有對應的記錄點。
- **統計與格式化寫在畫面**：
    - `DashboardView` 每次重繪都建立 `DashboardStats`；`InsightsView` 每次重繪都計算 `InsightsStats`、開團毛利排行與熱力圖。
    - 首頁 hero 卡與 KPI 卡在畫面內組正負號、箭頭與 `MoM` 字串，目標進度在畫面內組字。
    - 分析頁開團排行標題以 `+` 拼接字串，類別進度比例在畫面內由 `Decimal` 換算，熱力圖最高筆數與週次標籤也在畫面內計算。
    - `InsightsStats.swift` 一檔有五個頂層型別，成長方向以 `Bool?` 表達三種狀態。
- **規模** (2026-10-15 以 6a＋6b 的 `style_checks.py` 量測)：
    - 逐檔清單在 `reference/file-list.txt`：修改 108 檔 (色盤 86 檔、首頁分析頁與 Root、掃描及相關測試 22 檔)、預期新增 30 檔、刪除 2 檔。
    - 修改段基準 653 筆，分布在 56 檔；其中 `InsightsStats.swift` (364 行)、`DashboardStatsTests.swift` (365 行)、`InsightsStatsTests.swift` (305 行) 已超過 300 行。

## Proposed Solution

- **色盤**：
    - 新增 `Shared/DesignSystem/Foundations/Color+Semantic.swift`，以 SDK 宣告 `ShapeStyle.red` 的同一形式定義 19 個 `bl` 前綴靜態成員；沒有任何呼叫點的 5 個成員不搬。
    - 刪除 `BLPalette` 型別、`Color.blSecondaryLabel` 所在的 `Color+Extensions.swift`、所有 `palette` 屬性與 `palette:` 參數；`InsightsStats`、`CustomerRankBadgeStyle` 與 Design System 元件不再接收色盤。
    - hero 漸層兩端改由 `BLHeroCardBackground` 直接讀取 asset，畫面入口維持 `.blHeroCardBackground()`。
    - 掃描守門的豁免檔名與訊息改為新檔；`Color.blSecondaryLabel` 的漂移測試刪除，因為次要文字色本身就是色盤成員。
    - 做法依序是：先加新成員並讓舊色盤代理過去，再依目錄平行遷移呼叫端，最後刪除舊型別。
- **首頁與分析頁 (第 7 步)**：
    - **現在時間**：比照開團與訂單清單，`DashboardFeature.State`、`InsightsFeature.State` 記錄 `dateContext`，在畫面出現與重試時由 reducer 以注入的 `date.now`、`calendar` 寫入；Root 回到前景與收到重大時間變更時也一併刷新。畫面拿掉 `@Dependency`，星期標籤改用記錄的 calendar。
    - **統計移到 State**：State 依 `dateContext` 推導本月統計、走勢、排行與熱力圖，並提供單一的畫面狀態 (載入中、失敗、首次使用或空狀態、內容)。訂單、目標或期間改變時以記錄的日期立即重算；載入失敗一律顯示失敗畫面；尚未記錄日期時顯示載入骨架，不顯示空狀態，也不顯示以其他日期算出的數字。
    - **格式化**：移到新的 `DashboardFormatters`、`InsightsFormatters`。成長方向改用 Design System 的 `BLTrend` 列舉，取代兩個畫面各自的列舉與 `Bool?`。成本區塊比照 `OrderCostBreakdown.Tone` 只帶語意色調，由畫面換算顏色。
    - **守門**：新增掃描規則，鎖住「畫面不宣告依賴、production 不引用 `Calendar.current`」。
    - **拆檔**：`InsightsStats.swift` 依一檔一個頂層型別與主題拆開；`DashboardStatsTests`、`InsightsStatsTests` 依受測主題拆檔。
- **整檔對齊與測試**：
    - 改到與新增的 production、單元測試與 snapshot 測試檔都整檔對齊。
    - snapshot 不重錄：首頁與分析頁的 snapshot 改在 State 帶入固定的 `dateContext`；沒有 snapshot 涵蓋的改動畫面在改動前先補錄基準，並以雜湊清單防止重錄。
    - 新增的格式化與統計以字面值預期驗證，並以變異確認測試守得住。
    - 改動前後以 UI Automation 對照首頁日期子標，以及英文模式下分析頁的星期標籤。

## Alternatives Considered (optional)

- **以 Environment 注入色盤**：`BLPalette` 沒有需要依子樹替換的值，使用者 2026-10-09 不採用。
- **保留 `Color.blSecondaryLabel` 的完整寫法**：新成員可以直接用前置點縮寫，保留舊寫法會讓同一個色彩有兩種呼叫形式，因此一併改寫。
- **首頁與分析頁的畫面檔只換色彩，畫面內計算登記例外交給第 7 步**：插單會維持純機械替換，但使用者 2026-10-15 依裁決 1 選擇整檔對齊，連帶把第 7 步併入。

## Non-Goals (optional)

詳見 design.md。其中一項需在此註明：首頁 KPI 卡與分析頁走勢卡在沒有上期比較值時以三級文字色顯示說明文字，與 `design-system-color-contrast` 既有需求「Tertiary label color is reserved for non-informational text」衝突。改色會改變像素，違反本 change「畫面像素不變」的目標，因此照原色並另案處理。

## Impact

- Affected specs：
    - 修改 `color-system-foundation` 的「Semantic and system colors are obtained through system APIs」
    - 修改 `design-system-color-contrast` 的「Informational text meets the 4.5:1 contrast floor」
    - 在 `analytics-trend-comparison` 新增需求
- Affected code (逐檔清單見 openspec/changes/palette-analytics-style-compliance/reference/file-list.txt)：
    - Modified：
        - apps/ios/BuyLedger/Shared/DesignSystem/Components/ 下引用色盤或次要文字縮寫的元件 (Buttons、Cards、Charts、Chips、Forms、Images、Progress、Tags)，以及 apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
        - apps/ios/BuyLedger/Features/Orders/、Campaigns/、Quote/、FX/、Customers/、App/、Lookups/、More/、Settings/、AISummary/ 下引用色盤或次要文字縮寫的畫面
        - apps/ios/BuyLedger/Features/Dashboard/ 與 apps/ios/BuyLedger/Features/Insights/ 的全部檔案
        - apps/ios/BuyLedger/Features/App/RootFeature.swift (兩個刷新點)
        - 5.1 閘門整檔對齊的邏輯調整：apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift (`State.failureMessage`)、apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift (`State.visibleSections`)、apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift (初始化參數 `wantsReminder:` 改名 `isReminderWanted:`)、apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
        - apps/ios/BuyLedger/Resources/Localizable.xcstrings (新增 `customers.list.label.topCount`、`fx.rates.label.conversionRate`、`fx.rates.label.sourceTimestamp`)、apps/ios/BuyLedger.xcodeproj/project.pbxproj (build number)
        - apps/ios/BuyLedgerTests/ 的 `DesignSystemSourceScanTests`、`DependencyConventionScanTests` 與 `+Rules`、`+Scanner`、`DependencyConventionScanScenario`、`ContrastComplianceTests`、`ColorContrast`、`ColorContrastTests`、`DashboardFeatureTests`、`DashboardStatsTests`、`InsightsFeatureTests`、`InsightsStatsTests`、`InsightsAttributionTests`、`SnapshotTests+Dashboard`、`SnapshotTests+Insights`、`SnapshotTests+Shared`、`RootFeatureTests+Foreground`、`RootFeatureTests+LoadRequests`、`RootFeatureTests+DeepLinks`、`RootFeatureTests+Fixtures`；5.1 閘門與 review 另外改到 `DependencyConventionScanTests+TestValueRules`、`DesignSystemSourceScanTests+Patterns`、`DesignSystemSourceScanTests+Scanner`、`CampaignListFeatureTests+DateContext`、`CustomersFeatureTests`、`OrderPercentConversionTests`、`AISummaryFeatureTests`、`CampaignEditFeatureTests`、`CampaignFeatureTests+Editing`、`+FailureTimingFollowUp`、`+NameConflict`、`+ReminderIntegration`、`+ReminderRename`、`SnapshotTests+CampaignDetail`
        - apps/ios/CLAUDE.md、.claude/rules/ios-design-system.md、.claude/rules/ios-data-layer.md、.claude/rules/ios-navigation.md、.claude/rules/ios-unit-tests.md、.claude/rules/ios-accessibility-localization.md (apps/ios/README.md 經 4.2 確認無影響)
    - New：
        - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/Color+Semantic.swift、BLTrend.swift，以及由 BLMetrics.swift 拆出的 BLRadius.swift、BLSpacing.swift、BLListMetrics.swift、BLHitTarget.swift
        - apps/ios/BuyLedger/Features/Customers/CustomerFormatters.swift、CustomerRank.swift，apps/ios/BuyLedger/Features/Quote/QuoteFormatters.swift (5.1 閘門移出畫面計算)
        - apps/ios/BuyLedger/Features/Dashboard/DashboardDateContext.swift、DashboardFormatters.swift
        - apps/ios/BuyLedger/Features/Insights/InsightsDateContext.swift、InsightsFormatters.swift、InsightsStats+Trend.swift、InsightsTrendBucket.swift、InsightsCategory.swift、InsightsCostSegment.swift、InsightsHeatmap.swift、CampaignProfitRank.swift
        - apps/ios/BuyLedgerTests/BLTrendTests.swift、DashboardFormattersTests.swift、InsightsFormattersTests.swift、InsightsHeatmapTests.swift、DashboardFeatureTests+DateContext.swift、DashboardFeatureTests+ScreenState.swift、InsightsFeatureTests+DateContext.swift、InsightsFeatureTests+ScreenState.swift、DashboardStatsTests+Comparison.swift、DashboardStatsTests+Progress.swift、InsightsStatsTests+Breakdown.swift、DashboardStatsTests+Fixtures.swift、InsightsStatsTests+Fixtures.swift、DependencyConventionScanTests+ViewRules.swift、DependencyConventionScanScenario+ViewCases.swift、SnapshotTests+Customers.swift、SnapshotTests+More.swift、SnapshotTests+OrderMerge.swift 與 0.3 補錄的基準圖
        - 5.1 閘門與 review 新增的測試：apps/ios/BuyLedgerTests/CampaignEditFeatureTests+NavigationTitle.swift、CampaignFormattersTests.swift、CampaignListFeatureTests+RowSummaries.swift、CampaignListFeatureTests+VisibleSections.swift、CustomerFormattersTests.swift、FxFeatureTests+CurrencyCodes.swift、FxFormattersTests.swift、QuoteFeatureTests+CurrencyCodes.swift、QuoteFormattersTests.swift、DashboardFormattersTests+Summary.swift、DesignSystemSourceScanTests+ScaledMetric.swift、DesignSystemSourceScanTests+ScaledMetricScanner.swift
        - openspec/changes/palette-analytics-style-compliance/reference/ 的 style_checks.py、file-list.txt、baseline.txt、snapshot-hashes.txt、snapshot-failures/
    - Removed：
        - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
        - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
        - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift (拆成四檔)
