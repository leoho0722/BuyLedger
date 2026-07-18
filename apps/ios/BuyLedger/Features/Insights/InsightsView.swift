//
//  InsightsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 分析分頁的主要畫面
///
/// 對應設計稿 iPhone / iPad 的「分析」頁：bar chart 走勢、商品類別排行、成本結構 donut、N 週下單熱力圖 (N 由 ``InsightsStats/heatmapWeekCount`` 控制)；可切換期間、可點擊類別 drill-down 到訂單頁
struct InsightsView: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone (compact) 與 iPad (regular)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 用來計算趨勢期間與熱力圖的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 趨勢分組與熱力圖週界計算所用的行事曆 (含時區)；測試可注入固定 gregorian／UTC
    @Dependency(\.calendar) private var calendar

    /// hero 總獲利金額字級，隨 Dynamic Type 縮放 (以 `.title` 為基準)
    @ScaledMetric(relativeTo: .title) private var heroProfitSize: CGFloat = 28

    // MARK: - View Body

    /// 分析頁的畫面內容
    ///
    /// 訂單為空時改顯示 ``emptyState(palette:)``——空圖表 ($0、空 heatmap) 對使用者沒有價值且容易誤導
    /// 首次載入完成前 (``OrdersFeature/State/hasLoaded`` 為 `false`) 顯示中性 ``loadingPlaceholder(palette:)``，
    /// 避免訂單為空時每次切換 tab 因 `isLoading` 暫時翻成 `true` 而落入「有資料」分支造成閃爍
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        let core = Group {
            if !store.orders.hasLoaded {
                loadingPlaceholder(palette: palette)
            } else if store.orders.orders.isEmpty {
                emptyState(palette: palette)
            } else {
                analyticsContent(palette: palette)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .task {
            await store.send(.orders(.task)).finish()
        }

        return NavigationStack {
            core
                .navigationTitle(Text("分析"))
        }
    }
}

// MARK: - ViewBuilder

private extension InsightsView {

    /// 有訂單資料時的完整分析內容
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 分析內容 view
    @ViewBuilder
    func analyticsContent(palette: BLPalette) -> some View {
        let stats = InsightsStats(
            orders: store.orders.orders,
            range: store.insightsDateRange,
            referenceDate: date(),
            calendar: calendar,
            locale: locale,
            palette: palette
        )
        // 掃全部訂單的排行與熱力圖在一次 render 內各算一次，避免 card view builder 每次重算
        let campaignRanks = InsightsStats.campaignProfitRanking(
            campaigns: store.campaigns.campaigns,
            orders: store.orders.orders
        )
        let heatmapCells = InsightsStats.computeHeatmap(
            orders: store.orders.orders,
            referenceDate: date(),
            calendar: calendar
        )

        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                rangePicker
                trendCard(stats: stats, palette: palette)
                breakdownGrid(stats: stats, palette: palette)
                campaignProfitCard(ranks: campaignRanks, palette: palette)
                heatmapCard(cells: heatmapCells, palette: palette)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 沒有訂單時的空狀態，引導使用者先建立訂單
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 空狀態 view
    @ViewBuilder
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView {
            Label("尚未有足夠可用於分析的資料", systemImage: "chart.bar.xaxis")
        } description: {
            Text("先到「訂單」分頁新增幾筆訂單，這裡就會出現走勢、類別排行、成本結構與下單熱力圖。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 首次載入訂單前顯示的中性佔位畫面
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 佔位 view
    @ViewBuilder
    func loadingPlaceholder(palette: BLPalette) -> some View {
        ProgressView()
            .controlSize(.regular)
            .tint(palette.secondaryLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 期間選擇器
    @ViewBuilder
    var rangePicker: some View {
        Picker("期間", selection: $store.insightsDateRange) {
            ForEach(InsightsDateRange.allCases) { range in
                Text(LocalizedStringKey(range.title)).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    /// 走勢卡
    /// - Parameters:
    ///   - stats: 已計算的分析資料
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 走勢卡 view
    @ViewBuilder
    func trendCard(stats: InsightsStats, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStringKey(store.insightsDateRange.trendCardTitle))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.secondaryLabel)

                    Spacer()

                    Text(LocalizedStringKey(stats.trendDelta))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(trendDeltaColor(stats.trendDeltaIsPositive, palette: palette))
                }

                Text(formatTwd(stats.totalProfit))
                    .font(.system(size: heroProfitSize, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)

                BLBarChart(
                    data: stats.trendBars,
                    height: 200,
                    isScrollEnabled: true
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 類別排行 + 成本結構並列
    /// - Parameters:
    ///   - stats: 已計算的分析資料
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 並列卡片 view
    @ViewBuilder
    func breakdownGrid(stats: InsightsStats, palette: BLPalette) -> some View {
        if useWideLayout {
            HStack(alignment: .top, spacing: BLSpacing.medium) {
                categoryCard(stats: stats, palette: palette)
                    .frame(maxWidth: .infinity)
                costStructureCard(stats: stats, palette: palette)
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: BLSpacing.medium) {
                categoryCard(stats: stats, palette: palette)
                costStructureCard(stats: stats, palette: palette)
            }
        }
    }

    /// 每團毛利排行卡：依毛利由高到低排序各開團 (排除無歸屬訂單的團)；點擊跳到該開團詳情。沒有可排行的開團時整卡隱藏
    /// - Parameters:
    ///   - ranks: 由 ``analyticsContent(palette:)`` 一次算好的開團毛利排行
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 開團毛利排行卡 view (無資料時為 `EmptyView`)
    @ViewBuilder
    func campaignProfitCard(ranks: [CampaignProfitRank], palette: BLPalette) -> some View {
        if !ranks.isEmpty {
            BLCard {
                VStack(alignment: .leading, spacing: BLSpacing.medium) {
                    Text("每團毛利排行")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.label)

                    ForEach(ranks) { rank in
                        Button {
                            store.send(.campaignSelected(rank.campaignName))
                        } label: {
                            BLProgressBar(
                                title: "\(rank.rank). \(rank.campaignName)",
                                value: rank.ratio,
                                tint: palette.accent,
                                trailingText: CampaignFormatters.twd(rank.profit, locale: locale)
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("查看 \(rank.campaignName) 的詳情")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// 類別排行卡
    /// - Parameters:
    ///   - stats: 已計算的分析資料
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 類別卡 view
    @ViewBuilder
    func categoryCard(stats: InsightsStats, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("類別排行")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                if stats.categories.isEmpty {
                    Text("尚無分類資料")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryLabel)
                } else {
                    let topProfit = stats.categories.first?.profit ?? 1
                    ForEach(Array(stats.categories.enumerated()), id: \.element.name) { index, category in
                        Button {
                            store.send(.categorySelected(category.name))
                        } label: {
                            categoryRow(
                                rank: index + 1,
                                category: category,
                                topProfit: topProfit,
                                tint: categoryTints(palette: palette)[index % categoryTints(palette: palette).count],
                                palette: palette
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("查看 \(category.name) 類別的訂單")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 類別排行單列
    /// - Parameters:
    ///   - rank: 名次
    ///   - category: 類別資料
    ///   - topProfit: 第一名的獲利金額 (作為比例基準)
    ///   - tint: bar 顏色
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 類別列 view
    @ViewBuilder
    func categoryRow(
        rank: Int,
        category: InsightsCategory,
        topProfit: Decimal,
        tint: Color,
        palette: BLPalette
    ) -> some View {
        let value = NSDecimalNumber(decimal: category.profit).doubleValue
        let total = NSDecimalNumber(decimal: topProfit).doubleValue
        let fraction = total > 0 ? CGFloat(value / total) : 0

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(rank). \(category.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                Spacer()

                Text(formatTwd(category.profit))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(palette.tertiaryLabel)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.fillQuaternary)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
    }

    /// 成本結構 donut 卡
    /// - Parameters:
    ///   - stats: 已計算的分析資料
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 成本結構卡 view
    @ViewBuilder
    func costStructureCard(stats: InsightsStats, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("成本結構")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                HStack(alignment: .center, spacing: BLSpacing.large) {
                    BLDonutChart(
                        segments: stats.costSegments.map {
                            BLDonutSegment(
                                label: $0.label,
                                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                                color: $0.color
                            )
                        },
                        centerTitle: "總成本",
                        centerValue: formatTwd(stats.totalCost)
                    )

                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        ForEach(stats.costSegments) { segment in
                            HStack(spacing: BLSpacing.small) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(segment.color)
                                    .frame(width: 8, height: 8)

                                Text(segment.label)
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryLabel)

                                Spacer()

                                Text(formatTwd(segment.value))
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(palette.label)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// 過去 N 週的下單熱力圖；N 由 ``InsightsStats/heatmapWeekCount`` 決定
    /// - Parameters:
    ///   - cells: 由 ``analyticsContent(palette:)`` 一次算好的熱力圖格值
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 熱力圖卡 view
    @ViewBuilder
    func heatmapCard(cells: [HeatmapKey: Int], palette: BLPalette) -> some View {
        let weekCount = InsightsStats.heatmapWeekCount
        let maxCount = cells.values.max() ?? 1

        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("下單熱力 · 過去 \(weekCount) 週")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                LazyVGrid(
                    columns: [GridItem(.fixed(28), spacing: 6)] + Array(
                        repeating: GridItem(.flexible(), spacing: 6),
                        count: weekCount
                    ),
                    spacing: 6
                ) {
                    Text(" ")
                        .frame(width: 28)

                    ForEach(0..<weekCount, id: \.self) { week in
                        Text("W\(week + 1)")
                            .font(.caption2)
                            .foregroundStyle(palette.tertiaryLabel)
                            .frame(maxWidth: .infinity)
                    }

                    // 攤平成單層 ForEach；LazyVGrid 只可靠展開直接子層的 ForEach，
                    // 外層 ForEach 內再巢狀 ForEach (且帶 sibling Text) 時，巢狀那層不會被攤成 cell
                    ForEach(0..<(7 * (weekCount + 1)), id: \.self) { index in
                        let weekday = index / (weekCount + 1)
                        let column = index % (weekCount + 1)

                        if column == 0 {
                            Text(weekdayLabel(weekday))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryLabel)
                                .frame(width: 28, alignment: .leading)
                        } else {
                            heatmapCell(
                                count: cells[HeatmapKey(week: column - 1, weekday: weekday)] ?? 0,
                                maxCount: maxCount,
                                palette: palette
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 熱力圖單一 cell
    /// - Parameters:
    ///   - count: 訂單筆數
    ///   - maxCount: 整張熱力圖中最高的訂單筆數，用來決定相對深淺
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: cell view
    @ViewBuilder
    func heatmapCell(count: Int, maxCount: Int, palette: BLPalette) -> some View {
        let opacity: Double = {
            guard count > 0, maxCount > 0 else {
                return 0.06
            }
            return 0.2 + (Double(count) / Double(maxCount)) * 0.8
        }()

        // 用明確高度撐起格子；`RoundedRectangle` 是 Shape 無 intrinsic size，
        // 在 LazyVGrid 中靠 `aspectRatio` 會被旁邊 Text 那列壓成 0 高度而完全不顯示
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(palette.accent.opacity(opacity))
            .frame(maxWidth: .infinity)
            .frame(height: Self.heatmapCellHeight)
            .overlay {
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(count == 0 ? "0 單" : "\(count) 單")
    }
}

// MARK: - Private Method

private extension InsightsView {

    // MARK: Layout

    /// 是否使用寬版面 (並列兩張卡)
    var useWideLayout: Bool {
        return horizontalSizeClass != .compact
    }

    /// 類別 bar 的色盤序列
    func categoryTints(palette: BLPalette) -> [Color] {
        [
            palette.accent,
            palette.purple,
            palette.orange,
            palette.teal,
            palette.pink
        ]
    }

    /// 依 App 選定 locale 顯示在熱力圖左側的星期縮寫
    /// - Parameter index: 0 為週一、6 為週日
    /// - Returns: 依選定 locale 呈現的星期縮寫
    func weekdayLabel(_ index: Int) -> String {
        var localizedCalendar = Calendar.current
        localizedCalendar.locale = locale
        let symbols = localizedCalendar.veryShortStandaloneWeekdaySymbols
        let mondayFirstIndex = (index + 1) % symbols.count
        return symbols[mondayFirstIndex]
    }

    // MARK: Heatmap

    /// 熱力圖單一格子的高度 (pt)；格子寬度由 grid 的 flexible 欄位決定，高度需明確指定避免 Shape 被壓扁
    static let heatmapCellHeight: CGFloat = 30

    // MARK: Formatting

    /// 依 App 選定 locale 將金額格式化為新台幣 (無小數位)
    /// - Parameter amount: 金額
    /// - Returns: 依選定 locale 呈現的金額字串
    func formatTwd(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }

    /// 將 ``InsightsStats/trendDeltaIsPositive`` 轉成顯示色：上升綠、下降紅、無對照灰
    /// - Parameters:
    ///   - isPositive: 方向旗標
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 對應的字色
    func trendDeltaColor(_ isPositive: Bool?, palette: BLPalette) -> Color {
        switch isPositive {
        case .some(true):
            return palette.green
        case .some(false):
            return palette.red
        case .none:
            return palette.tertiaryLabel
        }
    }
}

// MARK: - Preview

#Preview("分析") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.hasLoaded = true
        return state
    }()

    return InsightsView(
        store: Store(initialState: previewState) {
            RootFeature()
        }
    )
}
