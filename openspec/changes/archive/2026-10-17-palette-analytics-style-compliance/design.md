## Context

- **色盤現況**：`Shared/DesignSystem/Foundations/BLPalette.swift` 的 `struct BLPalette {}` 以 24 個實例成員回傳 `Color(uiColor:)` 系統動態色，另有靜態 `heroGradient` 讀兩個 asset。
    - 呼叫端各自宣告 `var palette: BLPalette { BLPalette() }`。
    - Design System 元件的 helper、`OrderSelectableRow` 等列元件、`RootSidebarLayout.logoRow`、`OrderDetailSummaryView.metric` 以 `palette:` 參數傳遞。
    - `InsightsStats.init` 收 `palette:` 為成本區塊上色，`CustomerRankBadgeStyle` 以 `background(in:)`／`numeral(in:)` 收色盤。
- **次要文字縮寫**：`Shared/Extensions/Color+Extensions.swift` 只有 `Color.blSecondaryLabel`，代理到 `BLPalette().secondaryLabel`；`ContrastComplianceTests` 另有一條參數化測試 (四種外觀) 確認兩者分量相同。
- **規則與守門**：
    - `.claude/rules/ios-design-system.md` 規定系統取色介面只在 `BLPalette.swift`，並明文「不為了支援前置點改成 `extension ShapeStyle where Self == Color`」。使用者 2026-10-09 已推翻後者。
    - `DesignSystemSourceScanTests` 規則四、五以檔名 `BLPalette.swift` 豁免；規則一到三的違規訊息指向 `Color.blSecondaryLabel` 與「色盤實例」。
- **首頁與分析頁現況**：
    - `DashboardView` 與 `InsightsView` 以 `@Dependency` 讀現在時間，在 `body` 期間建立統計 (`DashboardStats`、`InsightsStats`、`campaignProfitRanking`、`computeHeatmap`)。
    - 卡片在畫面內格式化與組字；`InsightsView.weekdayLabels` 呼叫 `Calendar.current`。
    - `DashboardView.currentDateSubtitle` 只設定 `Date.FormatStyle` 的時區與 locale，曆法沿用預設的裝置曆法。
    - `apps/ios/CLAUDE.md` 把畫面讀依賴與 `Calendar.current` 登記為第 7 步過渡例外。
- **P 做法的既有實作** (第 5 步裁決 P)：
    - `CampaignListFeature.State.dateContext` 與 `OrderListFeature.State.dateContext` 在 `view(.task)`、`view(.retryTapped)` 由 reducer 寫入。
    - Root 在 `appLock(.delegate(.didBecomeActive))` 與 `launch(.delegate(.significantTimeChanged))` 呼叫 `refreshDateContexts(state:)` 重寫。
    - 型別 `CampaignDateContext`、`OrderDateContext` 各屬自己的 Feature。
- **使用者裁決** (見 proposal)：
    - 色盤採 `ShapeStyle` 靜態擴充、名稱加 `bl` 前綴。
    - 改到的檔一律整檔對齊，第 7 步併入本 change。
    - 2026-10-09 的 6a＋6b 裁決沿用：畫面內資料處理與組字全部移出、測試預期值寫字面值等，見 `openspec/changes/archive/2026-10-10-order-edit-style-compliance/reference/gate71-round2.md`。
- **量測** (2026-10-15，以 6a＋6b 的 `style_checks.py`)：
    - 逐檔清單在 `reference/file-list.txt`：修改 108 檔、預期新增 30 檔、刪除 2 檔。修改段的基準 653 筆，分布在 56 檔。
    - 首頁與分析頁的畫面檔已在 2026-10-05 (6e) 拆檔並通過當時的 `style_checks.py`；今天剩下結構化 key 造成的少數行寬問題，以及尚未移出的畫面內格式化與計算 (第 7 步)。
    - 已超過 300 行的檔 (不含檔頭與空行)：`InsightsStats.swift` 364、`DashboardStatsTests.swift` 365、`InsightsStatsTests.swift` 305。
    - `RootFeature.swift` 297 行。
    - `Color.blSecondaryLabel` 的實際呼叫在 27 個 production 檔共 49 處；其中 19 個檔沒有用到色盤。
    - 已以 `swiftc -typecheck` 對 iPhoneSimulator 27.0 SDK 確認以下寫法都能編譯：前置點靜態成員用在 `foregroundStyle`、三元運算、`.opacity(_:)` 鏈、`Color` 型別參數、`[Color]` 陣列、`LinearGradient(colors:)`、`.tint`、Swift Charts 的 `foregroundStyle`。

## Goals / Non-Goals

**Goals:**

- 色盤只剩 `bl` 前綴靜態成員；任何型別都不建立、不持有、也不傳遞色盤值；次要文字色只有一個定義。
- 首頁與分析頁不讀現在時間、不在畫面計算統計或組字，現在時間依 P 記錄並在回到前景與跨日時刷新。
- 改到與新增的 Swift 檔整檔符合 `/ios-dev-kit` 與 `apps/ios/CLAUDE.md`，`style_checks.py` 只剩不計失敗的代碼，每檔不超過 300 行。
- 畫面像素不變：既有與 0.3 補錄的 snapshot 不重錄即通過。
- 實作可分給多位實作者同時進行，同時進行的組改的檔不重疊，而且每個 task 完成時都能編譯。

**Non-Goals:**

- **6c、6d**：Service 搬遷與篩選 sheet 重新設計。篩選 sheet 的三個區段 (`OrderFilterCategorySection`、`OrderFilterDateSection`、`OrderFilterPaymentMethodSection`) 本 change 只換色彩並整檔對齊，畫面不變。
- **範圍外的已知問題，結案時回報**：
    - 首頁 KPI 卡與分析頁走勢卡在「沒有上期比較值」時，以 `tertiaryLabel` 顯示「— MoM」或比較說明。這與 `design-system-color-contrast` 既有需求「Tertiary label color is reserved for non-informational text」衝突；改色會改變像素，本 change 照原色，另案處理。
    - `OrderFormatters.paymentMethodFilterTitle`、`categoryFilterTitle` 以 `locale: Locale = .current` 為預設參數，屬 Orders 範圍。
    - 試算頁偶發 `fetchCodes` Unimplemented。
- **日期脈絡型別合併**：四個 Feature 各有一個同形狀的日期脈絡型別，是否合併留第 10 步。
- **UI 測試與 page object**：identifier 與畫面結構不變，不修改 `BuyLedgerUITests`；首頁日期子標既有 `HarnessSelfCheckTests` 守住。例外是成本結構圖例的朗讀結構，見「5.1 閘門與 review 擴大的範圍」。
- **`OrdersFeaturePerformanceTests`**：它以 `DashboardStats(orders:monthlyGoal:referenceDate:calendar:)` 建立統計，這個 init 不變，不需修改。

## Decisions

### 色盤成員以 ShapeStyle 靜態擴充宣告於 Color+Semantic.swift

- `apps/ios/BuyLedger/Shared/DesignSystem/Foundations/Color+Semantic.swift` 宣告 `extension ShapeStyle where Self == Color`，與 SDK 宣告 `ShapeStyle.red` 的形式相同 (`SwiftUICore` swiftinterface 已確認)。這個檔就是規格所稱的色盤。
- 檔名依 kit `project-structure.md` DesignSystem 一節的 Tokens 範例 `Color+Semantic.swift`；原檔名是型別名，型別刪除後不保留。
- 成員共 19 個，各自回傳與原 `BLPalette` 同名成員完全相同的運算式 (含 `blSecondaryLabel` 的 `.opacity(0.6)`)：
    - 背景與表面：`blBackground`、`blSecondaryBackground`、`blPlainBackground`、`blSurface`
    - 文字與分隔：`blLabel`、`blSecondaryLabel`、`blTertiaryLabel`、`blSeparator`
    - 填色：`blFillTertiary`、`blFillQuaternary`
    - 色相：`blAccent`、`blGreen`、`blRed`、`blOrange`、`blYellow`、`blPurple`、`blPink`、`blTeal`、`blIndigo`
- `tertiaryBackground`、`elevatedSurface`、`opaqueSeparator`、`fillPrimary`、`fillSecondary` 在 production 與測試都沒有呼叫點，比照 `ios-design-system.md`「零呼叫點的元件直接刪除」，在擴充階段 (1.1) 直接刪除，不搬。
- 原檔的「語意色彩」`#Preview` 改用新成員，搬進新檔。
- 不採 Environment：色盤沒有需要依子樹替換的值 (使用者 2026-10-09 裁決)。

### 呼叫端以前置點寫法取用色盤

- 有型別脈絡 (`ShapeStyle` 泛型參數、`Color` 參數或回傳值、`[Color]` 字面值) 時一律寫 `.blX`；沒有型別脈絡時 (例如 `let color = Color.blAccent`) 才寫 `Color.blX`。
- 刪除所有 `var palette` 屬性、`let palette: BLPalette` 欄位與 `palette:` 參數，呼叫鏈一併改簽章。
- `Color.blSecondaryLabel` 的 49 處實際呼叫同樣改為前置點寫法，包括沒有用到色盤的 19 個 production 檔。這些檔因此被改到，依裁決 1 整檔對齊。
- `CustomerRankBadgeStyle` 的 `background(in:)`、`numeral(in:)` 改為不收參數的計算屬性 `background`、`numeral`。

### 先擴充再遷移，最後刪除 BLPalette

- **擴充 (1.1)**：
    - 新檔定義實際運算式。
    - `BLPalette` 刪除 5 個零呼叫點成員，其餘 19 個實例成員改為回傳對應的 `.blX`，因此 `BLPalette.swift` 不再呼叫系統取色介面；`heroGradient` 讀 asset，不在規則四、五的比對範圍。
    - `Color+Extensions.swift` 刪除 (它的成員改由新檔提供，`Color.blSecondaryLabel` 呼叫端照常編譯)。
    - 同一步把 `DesignSystemSourceScanTests` 規則四、五的豁免檔名改為 `Color+Semantic.swift`，並把規則一到四的違規訊息改為新成員的前置點寫法。這支掃描測試只在 1.1 改一次。
- **遷移 (2.x、3.x)**：依目錄分組平行，每組改完都能編譯並通過受影響的測試。
- **收尾 (4.1)**：所有呼叫端遷移後刪除 `BLPalette.swift` (含 `heroGradient`)。

### hero 漸層由 BLHeroCardBackground 直接讀取資源

`BLHeroCardBackground.gradientColors` 直接回傳 `[Color("BLHeroGradientStart", bundle: .assets), Color("BLHeroGradientEnd", bundle: .assets)]`，簽章不變，對比測試照舊讀它。asset 讀取本來就不限於色盤檔 (`BLTone`、`BLHeatmapDepth`、`CustomerRankBadgeStyle` 皆然)。畫面入口仍只有 `.blHeroCardBackground()`。

### 對比測試改量新成員並刪除漂移測試

- `ColorContrast.Appearance.palette` 刪除，`ContrastComplianceTests`、`ColorContrastTests` 改量 `Color.blX`。
- 刪除參數化測試 `blSecondaryLabel_各外觀情境_與色盤次要標籤色分量相同(appearance:)`：次要文字色只剩一個定義，比對自己與自己沒有守門力。`@Test` 少 1 條、實際執行的案例少 4 個。規格改以「只有一個定義」的情境取代。
- `ColorContrastTests` 的方法改為三段式正體中文命名與 Given／When／Then (整檔對齊)；斷言的比值與容差不變。

### 首頁與分析頁比照 P 記錄日期脈絡

- 新增 `DashboardDateContext`、`InsightsDateContext` (`now: Date`、`calendar: Calendar`，`Equatable`、`Sendable`)，各放自己的 Feature 目錄，比照 `CampaignDateContext`、`OrderDateContext` 的既有做法。
- `DashboardFeature.State.dateContext`、`InsightsFeature.State.dateContext` 為 optional，初始 `nil`。
- reducer 在 `// MARK: - Dependencies` 宣告 `@Dependency(\.calendar)`、`@Dependency(\.date)`。`.view(.task)` 與 `.view(.retryTapped)` 每次都覆寫 `dateContext` (不論原本是否為 `nil`)，再送 `.delegate(.refresh)`。
- 兩個 State 各加 `mutating func refreshDateContext(now: Date, calendar: Calendar)`，同樣一律覆寫；Root 的 `refreshDateContexts(state:)` 再呼叫這兩個方法 (增加兩行，`RootFeature.swift` 約 299 行)。它的 doc 摘要就地改寫為涵蓋四個分頁，不增加其他行數。
- 記錄的日期只在上述四個時點改變。訂單、開團、月目標或分析期間改變時，統計以既有的 `dateContext` 立即重算，不等待四個時點。
- **日期子標**：`DashboardFormatters.dateSubtitle(for:locale:)` 以 `Date.FormatStyle.dateTime` 套用記錄的 calendar、該 calendar 的時區與 App locale，取代畫面的 `@Dependency(\.timeZone)` 與預設的裝置曆法。
    - production：注入的 `\.calendar` 是裝置目前的曆法與時區，與現行輸出相同。
    - 測試與 UI 測試：注入的是 UTC 西曆 (`TestDependencies.withFixedNow`、`DependencyValues+BLUITestOverrides`)，現行寫法卻用裝置曆法。兩者只在裝置是西曆時相同，所以「snapshot 與 `HarnessSelfCheckTests` 輸出不變」限定在西曆的基準模擬器；0.2 記錄基準模擬器的曆法。
    - 非西曆裝置上跑 `HarnessSelfCheckTests` 時，預期值 (以裝置曆法計算) 會與新輸出 (注入的西曆) 不同。這屬已知差異，本 change 不改該 UI 測試。
    - 依 `apps/ios/CLAUDE.md`「驗證依注入的時區或曆法格式化」的例外，另以與執行環境不同的時區 (接近午夜的非 UTC) 與月份不同於西曆的曆法 (例如希伯來曆) 寫測試，證明用的是注入值。
- **星期標籤**：`InsightsFormatters.weekdayLabels(calendar:locale:)` 複製記錄的 calendar 並設定 App locale，取 `veryShortStandaloneWeekdaySymbols` 轉為週一起排，取代 `Calendar.current`。

### 統計與畫面狀態由 State 推導

- `ScreenState` 是各自 State 的巢狀 `enum`，遵循 `Equatable`。畫面在 `content` 只讀一次 `store.screenState`，統計以參數傳入各分支，避免同一次 `body` 重複計算。
- `DashboardFeature.State`：
    - `stats: DashboardStats?` 以 `orders`、`monthlyProfitGoalTWD`、`dateContext` 建立，沒有日期脈絡時為 `nil`。
    - `screenState`：`.loading`、`.failed(String)`、`.onboarding`、`.overview(DashboardStats)`。
    - `ongoingCampaignRows` 不依賴日期，維持原樣。
- `InsightsFeature.State`：
    - `stats: InsightsStats?`、`heatmap: InsightsHeatmap?` 依 `orders`、`insightsDateRange`、`dateContext` 推導，沒有日期脈絡時為 `nil`；`campaignRanks: [CampaignProfitRank]` 只依開團與訂單計算 (與現行一樣不依賴日期)。
    - `screenState`：`.loading`、`.failed(String)`、`.empty`、`.analytics(InsightsStats, InsightsHeatmap)`。
- **判斷順序** (兩頁相同)：`loadState` 為失敗時是 `.failed` (失敗畫面不需要日期，與現行相同)；`loadState` 載入中，或日期脈絡為 `nil` 時是 `.loading`；已載入且沒有訂單時是首頁 `.onboarding`／分析頁 `.empty`；其餘是內容。
- **identifier 與容器逐一對應現行畫面**：
    - 首頁 `.onboarding` 與 `.overview` 都包在掛 `Dashboard.root` 的同一個 `ScrollView` 內；首次使用畫面仍掛 `Dashboard.emptyState`。
    - 載入骨架掛 `Dashboard.loading`；失敗掛 `Dashboard.loadFailure` 與重試鈕 identifier。
    - 分析頁 `.empty` 掛 `Insights.emptyState` (不在 `Insights.root` 內)，`.analytics` 的 `ScrollView` 掛 `Insights.root`；骨架與失敗沿用 `Common.loading("insights")`、`Common.loadFailure("insights")`。
- **`Equatable`**：`DashboardStats`、`InsightsStats`、`InsightsTrendBucket`、`InsightsCategory`、`InsightsCostSegment`、`InsightsHeatmap` (`Key` 為 `Hashable`)、`CampaignProfitRank` 都遵循 `Equatable`。`BLBarChartValue` 不放進 State，不需修改。

### 分析頁資料形狀分兩步改寫並保持可編譯

- **3.3**：改寫資料形狀與拆檔，並以最小改動讓 `InsightsView`、五張卡與 preview 改用新介面，維持可編譯、snapshot 不變。最小改動只限於：
    - 改傳新參數、以 `tone` 換算顏色、改用 `InsightsHeatmap`。
    - 以新的格式化函式取代被移除的欄位，`InsightsTrendCard.delta` 由 `String` 改為 `LocalizedStringKey` 並刪除卡片內的包裝。
    - 3.3 的整檔檢查只涵蓋它新增或改寫的資料、格式化與測試檔；這些畫面檔的整檔檢查由 3.4 驗收，3.4 一定接在 3.3 之後處理同一批檔。
- **3.4**：再整檔改寫畫面 (`screenState`、刪除 `@Dependency` 與 `Calendar.current`、組字移出、整檔對齊)。
- 兩個 task 改到同一批畫面檔，依序進行 (3.4 在 3.3 之後)。首頁的 3.1 只新增、不移除既有介面，3.2 再改畫面，順序相同。

### 格式化移到 DashboardFormatters 與 InsightsFormatters

依 `apps/ios/CLAUDE.md`「格式化用靜態函式，不是 `FormatStyle`」，新增兩個無 case 的 enum。輸出與回傳型別必須與現行呼叫端吃到的完全相同：

| 函式 (示意名稱) | 現行來源 | 回傳型別 | 輸出規則 |
| --- | --- | --- | --- |
| `DashboardFormatters.signedProfit(_:locale:)` | `DashboardHeroCard.profitDisplay` | `String` | 大於 0 時在 `BLFormatters.twd` 前加 `+`，其餘原樣 |
| `DashboardFormatters.profitDelta(_:locale:)` | `DashboardHeroCard.profitDeltaDisplay` | `String` (畫面以 verbatim 顯示，同現行) | `nil` 為 `— MoM`；否則 `↑`／`↓` (大於或等於 0 為 `↑`)、空格、`BLFormatters.percent` 的絕對值、` MoM` |
| `DashboardFormatters.percentDelta(_:locale:)` | `DashboardKPITiles.percentDeltaDisplay` | `String` (呼叫端包成 `LocalizedStringKey`，同現行；回傳 `LocalizedStringKey` 時 `LocalizationCatalogTests` 會把函式內的字面值當成目錄 key) | `nil` 為 `— MoM`；否則大於或等於 0 時加 `+`，接 `BLFormatters.percent`、` MoM` |
| `DashboardFormatters.marginDelta(_:locale:)` | `DashboardKPITiles.marginDeltaDisplay` | `String` (同 `percentDelta`) | `nil` 為 `— MoM`；否則大於或等於 0 時加 `+`，接百分點 (乘 100、一位小數、套 locale)、` pt MoM` |
| `DashboardFormatters.goalProgress(_:goal:locale:)` | `DashboardHeroCard.goalProgressBar` 內的字串 | `String` | `Int(progress * 100)` 接 `% / ` 與 `BLFormatters.twd(goal)` |
| `DashboardFormatters.sparklineSummary(_:locale:)` | `DashboardHeroCard.sparklineSummary` | `LocalizedStringKey` | 少於兩點為 `dashboard.overview.label.monthlyProfitTrend`；否則依首尾比較選上升、下降、持平三個帶參數的 key |
| `DashboardFormatters.dateSubtitle(for:locale:)` | `DashboardView.currentDateSubtitle` | `String` | 見上一節 |
| `DashboardFormatters.deliveryProgress(arrived:active:)` | `DashboardOngoingCampaignsSection` 的到貨進度文字 | `String` | `"\(arrived)/\(active)"` |
| `InsightsFormatters.trendDelta(_:locale:)` | `InsightsStats.trendDelta` 的文字部分 | `String` (同 `percentDelta`；現行由 `InsightsTrendCard` 在卡片內包，改後卡片的 `delta` 參數改為 `LocalizedStringKey`，由 `InsightsView` 包) | 比值為 `nil` 時為 `insights.chart.label.comparison`；否則 `↑`／`↓`、空格、比值絕對值的 `BLFormatters.percent` |
| `InsightsFormatters.trendBars(_:locale:)` | `InsightsStats.trendBuckets` 的圖表值 | `[BLBarChartValue]` | 每個 `InsightsTrendBucket` 轉成一個值：標籤沿用 bucket 的 verbatim 字串，數值沿用現行的 `NSDecimalNumber(decimal: profit).doubleValue`，`valueDescription` 為 `BLFormatters.twd` |
| `InsightsFormatters.rankTitle(rank:name:)` | 類別列 (現為插值) 與開團排行列 (現為 `+` 拼接) 的標題 | `String` | `"\(rank). \(name)"` |
| `InsightsFormatters.weekLabel(_ weekNumber:)` | `InsightsHeatmapCard.weekLabels` | `String` | 參數是由 1 起算的週次，輸出 `W` 接該數字 |
| `InsightsFormatters.weekdayLabels(calendar:locale:)` | `InsightsView.weekdayLabels` | `[String]` | 見上一節 |
| `InsightsFormatters.costDonutSlices(_:locale:)` | `InsightsCostStructureCard.donut` 的區段映射 | `[InsightsFormatters.CostSlice]` (巢狀值型別：`label` 本地化 key、`value: Double`、`valueDescription`、`tone`；比照 `OrderCostBreakdown.DonutSlice`) | 金額以 `NSDecimalNumber(decimal:).doubleValue` 轉換，附 `BLFormatters.twd` 描述與語意色調；畫面再轉成 `BLDonutSegment`，色彩與標籤本地化由畫面處理 |

- 函式名稱由實作者依 kit 命名定案，回傳型別與輸出規則不變。
- 單一本地化 key 帶插值 (例如 `AppLanguage.format("dashboard.overview.label.orderCount", …)`) 與單一數值的 verbatim 顯示 (例如熱力格的筆數) 屬呈現，留在畫面 (`gate71-round2.md` 判定原則)。
- 圖表的無障礙標題 (`language.localized(...)`) 也留在畫面。

### 資料層以語意色調、方向列舉與比例取代色彩與 Bool?

- **`BLTrend`**：新增於 `Shared/DesignSystem/Foundations/`，有 `up`、`down`、`unavailable` 三個 case 與 `init(delta: Decimal?)` (`nil` 為 `unavailable`、大於或等於 0 為 `up`)。
    - 取代 `DashboardKPITile.Trend`、`InsightsTrendCard.Trend` 與 `InsightsStats.trendDeltaIsPositive: Bool?` (gate71 第二輪 P-01)。
    - 只用 `Decimal`，符合 Design System 不引用領域型別的規則。
    - 色彩換算 (綠、紅、三級文字色) 留在畫面。
- **`InsightsTrendBucket`**：新增頂層型別 (`label: String`、`profit: Decimal`)，取代 `InsightsStats` 私有的 `TrendBucket`。`InsightsStats.trendBuckets: [InsightsTrendBucket]` 取代已格式化的 `trendBars`，標籤仍是依 calendar 與時區算好的 verbatim 字串 (`MM/dd`、`yyyy/MM`、`yy/MM`)。
- **`InsightsStats` 的比較值**：改存原始比值 `trendRatio: Decimal?`，即本期減上期除以上期絕對值；上期沒有訂單或合計為 0 時為 `nil` (與現行 `previousPeriodProfit` 相同)。文字由 `InsightsFormatters.trendDelta` 產生、方向由 `BLTrend(delta:)` 產生，符合 `analytics-trend-comparison` 既有情境 (例如上期 -100、本期 50 呈現 `↑ 150.0%`)。
- **`InsightsCostSegment`**：改帶 `tone: Tone` (`accent`、`teal`、`purple`、`orange`)，不再持有 `Color`；`id` 維持以 `label` 為識別值。
- **`InsightsCategory`**：新增 `ratio: Double`，在 `categoryBreakdown` 依現行畫面的公式計算：以第一名獲利為分母，分母大於 0 才相除，否則為 0；結果夾在 0 到 1 之間。
    - 依獲利遞減排序後，上限夾限不會發生；下限在其他類別為負獲利時發生 (第一名 100、某類別 -20 時比例為 0)。
    - 測試以這兩種可達的情況驗證，不為不可達的上限設計會轉紅的變異。
- **`InsightsHeatmap`**：新增此值型別，包含 `cells: [Key: Int]`、`maxCount` (沒有資料時為 1) 與週數。
    - `InsightsStats.computeHeatmap` 搬為它的靜態建構方法，取代畫面內的 `cells.values.max() ?? 1` 與 `InsightsStats.heatmapWeekCount`。
    - `HeatmapKey` 改為它的巢狀型別 `Key`。
- **類別色相**：依排行順位循環取色，屬純 UI 對應，留在畫面 Private Method，改用前置點成員。

### InsightsStats 與兩個測試檔依主題拆檔

- production：
    - `InsightsStats.swift`：儲存屬性、init、`categoryBreakdown`、`campaignProfitRanking`。
    - `InsightsStats+Trend.swift`：走勢區間、上期獲利與比值。這些函式目前在 `private extension`，搬檔後被主檔 init 跨檔呼叫，改為 internal static (`apps/ios/CLAUDE.md`「被它跨檔呼叫的靜態工廠要是 internal」)。
    - `InsightsTrendBucket.swift`、`InsightsCategory.swift`、`InsightsCostSegment.swift`、`InsightsHeatmap.swift` (含建構方法)、`CampaignProfitRank.swift` 各自一檔。
    - `DashboardStats` 的 `MonthlyTotals` 依 kit 巢狀型別規則整理。
- 測試 (依受測主題，拆後各檔不超過 300 行)：
    - 共用 helper (`DashboardStatsTests` 的 `aprilDate`、`marchDate`、`makeOrder`、`replacingStatus`，`InsightsStatsTests` 的 `date`、`makeOrder`) 目前是 `private static`，拆檔後跨檔呼叫不到，改為 internal 並移到 `DashboardStatsTests+Fixtures.swift`、`InsightsStatsTests+Fixtures.swift`；`InsightsHeatmapTests` 使用後者。
    - `DashboardStatsTests.swift`：本月彙總與營收歸屬 (含合併情境)。
    - `DashboardStatsTests+Comparison.swift`：上月比較與成長率。
    - `DashboardStatsTests+Progress.swift`：月目標、進行中筆數、近期訂單與走勢。
    - `InsightsStatsTests.swift`：走勢與上期比較。
    - `InsightsStatsTests+Breakdown.swift`：成本結構、類別比例與色調、每團毛利排行。
    - `InsightsHeatmapTests.swift`：熱力圖的週次與星期，以 `extension InsightsStatsTests` 撰寫 (與 `+Breakdown` 同形)，沿用 `+Fixtures` 的 helper；受測名稱改為 `InsightsHeatmap` 的建構方法、`InsightsHeatmap.Key` 與它的週數常數 (取代 `computeHeatmap`、`HeatmapKey`、`heatmapWeekCount`)。
    - `DashboardFeatureTests`、`InsightsFeatureTests`：既有的 view action 與進行中開團測試留在主檔；1.2 新增的日期脈絡測試放 `+DateContext`，3.1、3.3 新增的畫面狀態與統計重算測試放 `+ScreenState`。
- 拆檔後仍超過 300 行，或另需拆出的檔，加到 `reference/file-list.txt` 的新增段，並在 task 下方註明。

### 畫面不宣告依賴由掃描守門

`DependencyConventionScanTests` 新增一條 `ScanRule`，只套用在 `sourceTree == .production` 的檔 (單元測試檔不適用，掃描器自己的違規片段因此不會誤判)。比對前先以 `blankedCommentsAndStrings(in:)` 清空註解與字串，再檢查兩件事：

- **View 型別的依賴宣告**：分兩步。
    - 先在全部 production 檔收集「遵循 `View` 的型別名稱」：`struct`／`class`／`enum`／`extension` 宣告的繼承子句 (可跨行，到 `{` 為止) 含整字 `View` (以 `\bView\b` 比對，`ViewModifier`、`ViewBuilder` 不算)。
    - 再檢查這些型別的所有宣告 (主宣告與每個 extension，不論同檔或跨檔)，以 `matchingDelimiter` 取得本體範圍，本體內不得出現 `@Dependency(`。這樣主宣告與 `View` 遵循分開寫的形狀也會被檢查到。
- **裝置曆法引用**：整個 production 檔不得出現 `Calendar.current` 或 `Calendar.autoupdatingCurrent`。

- **實作位置**：
    - 規則實作放新檔 `DependencyConventionScanTests+ViewRules.swift`。
    - `ScanRule` 新增 case (主檔)，`violations(of:in:)` 分派放 `+Rules.swift`，`scanTree(rule:roots:)` 的 `requiredSubrules` 窮舉分派放 `+Scanner.swift`。
    - 跨檔收集型別名稱若需要整樹資訊，在 `+Scanner.swift` 的掃描流程內先收集再逐檔檢查。
- **片段案例**放新檔 `DependencyConventionScanScenario+ViewCases.swift`，在 `DependencyConventionScanScenario.swift` 組合：
    - 違規：View 結構內的依賴、以 extension 遵循 View 時的依賴、主宣告帶依賴而 `View` 遵循寫在另一個 extension、跨行繼承子句、非 View 型別內的 `Calendar.current` 與 `Calendar.autoupdatingCurrent`。
    - 合規：同檔 reducer 宣告的依賴、非 View 型別的依賴、只遵循 `ViewModifier` 的型別、註解與字串裡的 `@Dependency(` 與 `Calendar.current`。
- 範圍刻意只到這兩項：`Locale = .current` 預設參數等形式屬 Orders，列為範圍外問題。

### 整檔對齊沿用 6a＋6b 的檢查腳本與裁決

- `openspec/changes/archive/2026-10-10-order-edit-style-compliance/reference/style_checks.py` 複製到本 change 的 `reference/`，改檔頭用法說明，`EXISTING_OVER_LIMIT` 與 `BOUNDED_LENGTH_LIMITS` 清空 (本 change 沒有行數例外)。
- 0.1 以 `reference/file-list.txt` 的修改段量測，基準存 `reference/baseline.txt`；新增檔建立後加入檢查。
- 審查與修正依 `/ios-dev-kit` 現行版本原文、`apps/ios/CLAUDE.md`「ios-dev-kit 規範與專案差異」與 `gate71-round2.md` 判定原則。
- 測試整檔對齊沿用 `.claude/rules/ios-unit-tests.md`：
    - 三段式正體中文命名、Given／When／Then、預期值寫字面值、只含 `@Test` 的 extension 不設 MARK。
    - TestStore 一律注入 `$0.date = .constant(TestDependencies.fixedNow)` 與 `$0.calendar = TestDependencies.fixedCalendar`。只有驗證「依注入值格式化」的測試例外，改用與執行環境不同的值。

### snapshot 與 UI Automation 驗收

- snapshot 一律不重錄。
    - 首頁與分析頁的 snapshot 測試改在 State 帶入固定的 `dateContext` (`TestDependencies.fixedNow`、`TestDependencies.fixedCalendar`)，依 `ios-unit-tests.md`「畫面不讀時間時改在 State 帶入」的規則處理 `withFixedNow`。
    - 換色與搬移計算後，以同一批基準圖通過證明像素不變。
- **已知的 4 條失敗**：日期與時間上下排列的 snapshot (`campaignEditView_編輯既有開團_符合基準圖`、`orderEditView_一般既有訂單_符合基準圖`、`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼`) 在 0.1 記錄失敗，並把當時 result bundle 內的失敗圖複製到 `reference/snapshot-failures/`。
    - 這 4 條涵蓋訂單編輯與開團編輯的全部 snapshot，基準時已紅，單靠「通過」無法證明 2.2、2.3 沒改到像素。
    - 這 4 條的驗收比照 `order-edit-snapshot-effect-isolation` 的做法：通過，或失敗且失敗圖與 0.1 保存的逐像素相同。
    - 不豁免其他新增失敗。
- **改動前補錄基準** (0.3)：被改到但沒有任何 snapshot 涵蓋的畫面，在未改的程式上先補錄，之後不得重錄：
    - `SnapshotTests+Customers.swift`：客戶頁 (含名次徽章與排行卡)。
    - `SnapshotTests+More.swift`：「更多」、設定頁、App 鎖定畫面。
    - `SnapshotTests+OrderMerge.swift`：合併候選 sheet、合併照片選擇 sheet。
    - `SnapshotTests+Shared.swift`：付款方式編輯 sheet。
    - `SnapshotTests+Dashboard.swift`：首頁的載入骨架與首次使用畫面。
    - `SnapshotTests+Insights.swift`：分析頁的載入骨架、空狀態，以及帶開團資料、會顯示每團毛利排行卡的內容 (既有三條都沒有開團，排行卡被隱藏)。
    - AI 摘要畫面若無法在不呼叫 Service 的情況下呈現，改列入 UI Automation 對照並記錄原因。
- **防止重錄的比較基點**：0.3 完成後，把 `apps/ios/BuyLedgerTests/__Snapshots__/` 下所有 PNG 的 `shasum` 存成 `reference/snapshot-hashes.txt`。之後每個 task 與 5.3 以 `shasum -c` 確認全數相符，不只看 `git status` (未提交的新圖被覆寫時 `git status` 不會變)。
- **UI Automation**：0.2 在改動前、5.2 在 style 閘門修正完成後，以 `-BLUITest` 種子資料記錄下列項目並對照：
    - iPhone 與 iPad 的首頁 `currentDateSubtitle` 文字。
    - 英文模式下分析頁熱力圖的星期標籤、類別排行與成本結構的金額。
    - snapshot 無法涵蓋的 iPad 側邊欄 (`RootSidebarLayout`) 與照片檢視器 (`BLPhotoViewer`) 截圖，以目視比對。
    - 5.2 之後若再改到這些畫面，重做對應的對照。
- **刷新時機**：畫面出現、重試、回到前景、重大時間變更由 reducer 與 Root 的單元測試守住，比照第 5 步。
    - 測試的初始 State 帶與注入值不同的舊日期與舊 calendar，斷言被覆寫。
    - 「只在 `dateContext` 為 `nil` 時才寫入」的變異必須讓測試轉紅。

### 平行開發分組

- **主對話**：build 與測試由主對話序列執行，實作可同時分派。
- **熱點檔不跨平行組共檔** (同一個熱點檔只在依賴鏈上依序被改)：
    - `DesignSystemSourceScanTests` (只有 1.1)
    - `RootFeature.swift` 與 Root 測試 (只有 1.2)
    - `Color+Semantic.swift` (只有 1.1)
    - `DashboardFeature.swift` (1.2 → 3.1)、`InsightsFeature.swift` (1.2 → 3.3)
    - 分析頁畫面檔 (3.3 → 3.4)、首頁畫面檔 (只有 3.2)
    - `SnapshotTests+Dashboard`、`+Insights` (0.3 → 3.2／3.4)
    - 文件 (只有 4.2)
- **可同時進行的組**：
    - 1.1、1.2、1.3 互不共檔。
    - 1.1 之後：2.1 (Shared)、2.2 (Orders)、2.3 (Campaigns、Quote、FX)、2.4 (App、Lookups、More、Settings、AISummary)、2.5 (Customers 與對比測試)。
    - 1.2、1.3 之後：3.1 (首頁資料) 與 3.3 (分析頁資料與最小畫面調整)，可與 2.x 同時進行。
    - 3.2 (首頁畫面) 與 3.4 (分析頁畫面) 互不共檔。
    - 4.2 文件隨時可做。
- **與 6c worktree 的衝突點**：`RootFeature.swift` (6c 改 delegate 轉送)、`apps/ios/CLAUDE.md`、`.claude/rules/`。後合併的一方 rebase。
    - 5.1 閘門把 `CampaignEditFeature` 的初始化參數 `wantsReminder:` 改名 `isReminderWanted:`，6c 也改過的 `CampaignFeatureTests+FailureTimingFollowUp` 在同一行衝突，合併後寫成 `isReminderWanted: false`。

### 5.1 閘門與 review 擴大的範圍

整檔對齊與 review 修正讓範圍超出 proposal 原本列的檔案，逐檔清單以 `reference/file-list.txt` 為準 (修改段末尾與新增段的註解標出各批來源)。

- **`BLMetrics.swift` 依一檔一頂層型別拆成 `BLRadius`、`BLSpacing`、`BLListMetrics`、`BLHitTarget` 四檔**，原檔刪除；連同 `BLPalette.swift`、`Color+Extensions.swift` 共刪除 3 檔。
- **畫面內計算依閘門裁決 C 移出**，各附字面值測試與變異驗證：
    - 新增 `CustomerFormatters`、`CustomerRank`、`QuoteFormatters`，`CampaignFormatters` 補畫面用的方法。
    - `AISummaryFeature.State.failureMessage`、`CampaignListFeature.State.visibleSections` 由 State 推導。
    - 畫面組字改成單一帶參數的本地化 key：`customers.list.label.topCount`、`fx.rates.label.conversionRate`、`fx.rates.label.sourceTimestamp`。
- **Bool 命名套用到初始化參數**：`CampaignEditFeature` 的 `wantsReminder:` 改名 `isReminderWanted:`，呼叫它的 Campaign 測試同步修改。
- **成本結構圖例合併朗讀**：`InsightsCostStructureCard` 的圖例列以 `.accessibilityElement(children: .combine)` 合併成單一朗讀單位、色塊標 `.accessibilityHidden(true)`，依 `ios-accessibility-localization.md` 的複合列規則調整；像素不變，可及性樹結構與 0.2 不同，使用者裁決保留。
- **圖表高度只在元件縮放一次**：`BLSparkline`／`BLBarChart` 的 `height` 改成 `@ScaledMetric` 後，呼叫端傳基準值 (36、200)，不再包一層 `@ScaledMetric`；`DesignSystemSourceScanTests` 新增規則十二 (`+ScaledMetric`、`+ScaledMetricScanner`) 守門。

### 文件同步

- `.claude/rules/ios-design-system.md` 色彩一節：
    - 改寫取色入口與前置點寫法，刪除「呼叫端寫 `Color.blSecondaryLabel` 完整形式」與「不改成 `ShapeStyle` 擴充」兩條。
    - hero 漸層、強調色、次要文字不透明度例外改用新名稱。
    - 補「資料型別帶語意色調，由畫面換算色彩」。
- `.claude/rules/ios-data-layer.md`：「成長率的百分比與方向同源」改寫為 `DashboardStats.ratio` 與 `InsightsStats.trendRatio` 以同一個差額與 `abs(previous)` 分母計算，方向由 `BLTrend` 依比值正負決定。
- `apps/ios/CLAUDE.md`：
    - 刪除 `DashboardView`／`InsightsView` 的 `@Dependency` 與 `Calendar.current` 兩條過渡例外。
    - 日期脈絡寫入點與 Root 刷新對象補上首頁與分析頁，並註明新掃描規則守住「畫面不宣告依賴、不引用 `Calendar.current`」。
    - 「未修改的既有 Feature 檔留到第 6、7 步」改為只剩第 6 步。
    - 格式化靜態函式清單補上 `DashboardFormatters`、`InsightsFormatters`。
- `.claude/rules/ios-navigation.md`：回到前景時 Root 更新的日期脈絡補上首頁與分析頁。
- `.claude/rules/ios-unit-tests.md`：snapshot「畫面不讀時間」的例子補上首頁與分析頁。
- `apps/ios/README.md`：專案結構描述若提到色盤型別則同步。

## Implementation Contract

- **可觀察行為**：
    - 色彩、版面與文字與改動前逐像素相同，既有與 0.3 補錄的 snapshot 不重錄即通過。
    - 首頁與分析頁記錄的現在時間只在畫面出現、重試、回到前景、重大時間變更時更新；訂單、開團、月目標與分析期間改變時，數字以記錄的日期立即重算。
    - 載入失敗時一律顯示失敗畫面；第一次進入分析頁或首頁、已載入但尚未記錄日期時，顯示載入骨架而非首次使用或空狀態。
    - 規格見 `specs/analytics-trend-comparison`、`specs/color-system-foundation`、`specs/design-system-color-contrast` 的 delta。
- **介面與資料形狀**：
    - `extension ShapeStyle where Self == Color` 的 19 個 `static var blX: Color` (見決策「色盤成員以 ShapeStyle 靜態擴充宣告於 Color+Semantic.swift」)。
    - `BLHeroCardBackground.gradientColors: [Color]` 簽章不變；`CustomerRankBadgeStyle.background`、`.numeral` 為計算屬性。
    - `DashboardDateContext`／`InsightsDateContext` (`now`、`calendar`)；兩個 State 的 `dateContext`、`refreshDateContext(now:calendar:)`、`stats`、巢狀 `ScreenState` 與 `screenState`；`InsightsFeature.State.campaignRanks`、`heatmap`。
    - `BLTrend(delta:)`；`InsightsTrendBucket`；`InsightsStats.trendBuckets`、`trendRatio`；`InsightsCostSegment.tone`；`InsightsCategory.ratio`；`InsightsHeatmap` 與 `InsightsHeatmap.Key`。
    - `DashboardFormatters`、`InsightsFormatters` 的函式，依決策表的回傳型別與輸出規則。
- **失敗模式**：
    - 載入失敗顯示 `BLLoadFailureView` 與重試鈕，不論是否已記錄日期；重試先覆寫日期再送 `.delegate(.refresh)`。
    - 沒有日期脈絡且未失敗時一律顯示骨架，不靜默顯示零值。
- **驗收**：
    - **原始文字歸零**：`apps/ios/` 的 Swift 檔 (production 與測試) 以 `grep -rn` 找不到 `BLPalette`、`var palette`、`palette:`、`Color+Extensions`；`Color.blSecondaryLabel` 只出現在沒有型別脈絡的位置 (預期 0 處)。
    - **依賴與曆法**：由 3.5 的新掃描規則判定 (只看 production 的 View 型別本體與清空註解字串後的原始碼)，不以整個目錄的 grep 判定，因為 reducer 合法宣告依賴、掃描器測試片段合法含 `Calendar.current`。
    - **掃描守門**：`DesignSystemSourceScanTests`、`DependencyConventionScanTests` (含新規則與其變異)、`ContrastComplianceTests`、`ColorContrastTests` 通過。
    - **單元測試**：
        - 新增或改寫：`DashboardFeatureTests`、`InsightsFeatureTests` 的日期脈絡覆寫與 `screenState`、`RootFeatureTests+Foreground` 的兩個刷新點涵蓋首頁與分析頁、`RootFeatureTests+LoadRequests`／`+DeepLinks` 對首頁與分析頁 view action 的窮舉斷言、`DashboardFormattersTests`、`InsightsFormattersTests`、`BLTrendTests`、`InsightsHeatmapTests`、`InsightsStatsTests` 的比例與色調。
        - 預期值都是字面值，並以變異確認至少一條會轉紅。
        - 選擇性執行一律記錄實際執行數且大於 0。
    - **snapshot**：`SnapshotTests` 整批 (含 0.3 補錄的基準) 除 0.1 的 4 條已知失敗外全數通過；這 4 條通過，或失敗圖與 0.1 保存的逐像素相同；`shasum -c reference/snapshot-hashes.txt` 全數相符。
    - **檢查腳本**：`reference/style_checks.py` 對 `reference/file-list.txt` 修改與新增段的現存檔，`TOTAL` 只含不計失敗的代碼，每檔不超過 300 行。
    - **UI Automation**：5.2 的記錄與 0.2 相符。
    - **完整回歸**：iPhone 17 與 iPad 的 `BuyLedgerUITests` 主回歸與完整單元回歸通過。
- **範圍**：
    - **在範圍內**：上列色盤、首頁與分析頁、Root 兩個刷新點、對比與掃描測試、0.3 補錄的 snapshot、文件；以及只因次要文字縮寫被改到的 19 個 production 檔的整檔對齊。
    - **不在範圍內**：Non-Goals 所列各項；不改 SwiftData schema、Service、導覽結構與 accessibility identifier。

## Risks / Trade-offs

- [`RootFeature.swift` 加兩行後約 299 行，6c 也要改 Root] → 本 change 只在 `refreshDateContexts(state:)` 加兩行，doc 摘要就地改寫、不增加行數；若合併後超過 300 行，由後合併的一方依 kit 拆分順序處理，不登記例外。
- [前置點成員在大型三元運算式可能拖慢型別檢查] → 遇到型別檢查逾時改寫成具名區域常數，不退回色盤實例。
- [日期脈絡在畫面第一次出現前為 `nil`，切到尚未出現過的分頁時可能閃一次骨架] → 這是 P 的既有取捨 (開團與訂單清單相同)，以真實資料優先；5.2 實測若肉眼可見再回報使用者決定。
- [數字不再隨任意重繪改用新的現在時間] → 規格明定日期只在四個時點刷新，與開團、訂單清單一致；其他輸入改變仍立即重算。
- [刪除 5 個沒有呼叫點的色彩成員] → 之後需要時再加回新檔，不保留未使用的公開 token。
- [日期子標改用記錄的 calendar 而非預設的裝置曆法] → production 注入的就是裝置曆法與時區，兩套測試環境都是 UTC 西曆；另以非 UTC 與希伯來曆的測試證明用的是注入值。
- [範圍約 140 檔] → 依平行分組分派，每組驗收只跑受影響的測試，完整回歸只在最後執行 (驗證分層)。
