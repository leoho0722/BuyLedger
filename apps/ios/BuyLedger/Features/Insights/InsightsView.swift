//
//  InsightsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 分析分頁的主要畫面
struct InsightsView: View {
    
    // MARK: - View Properties
    
    /// 分析功能 store
    @Bindable var store: StoreOf<InsightsFeature>
    
    /// App 目前選用的顯示語系
    let language: AppLanguage
    
    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone (compact) 與 iPad (regular)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 用來計算趨勢期間與熱力圖的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 趨勢與熱力圖使用的行事曆
    @Dependency(\.calendar) private var calendar
    
    /// hero 總獲利金額字級，隨 Dynamic Type 縮放 (以 `.title` 為基準)
    @ScaledMetric(relativeTo: .title) private var heroProfitSize: CGFloat = 28
    
    /// 熱力圖左側星期欄寬，隨字級縮放 (以 `.caption` 為基準)
    @ScaledMetric(relativeTo: .caption) private var heatmapWeekdayColumnWidth: CGFloat = 28
    
    /// 熱力圖單一格子的高度，隨字級縮放 (以 `.caption2` 為基準)
    @ScaledMetric(relativeTo: .caption2) private var heatmapCellHeight: CGFloat = 30
    
    // MARK: - View Body
    
    /// 分析頁的畫面內容
    var body: some View {
        let palette = BLPalette()
        
        NavigationStack {
            Group {
                switch store.loadState {
                case .loaded:
                    if store.orders.isEmpty {
                        emptyState(palette: palette)
                    } else {
                        analyticsContent(palette: palette)
                    }
                    
                case let .failed(message):
                    BLLoadFailureView(
                        message: message,
                        retryIdentifier: BLAccessibilityID.Common.loadFailureRetryButton("insights")
                    ) {
                        store.send(.retryTapped)
                    }
                    .accessibilityIdentifier(BLAccessibilityID.Common.loadFailure("insights"))
                    
                case .loading:
                    loadingPlaceholder(palette: palette)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.background)
            .task {
                await store.send(.task).finish()
            }
            .rootNavigationTitle("分析", language: language)
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
            orders: store.orders,
            range: store.insightsDateRange,
            referenceDate: date(),
            calendar: calendar,
            locale: locale,
            palette: palette
        )
        // 每次 render 各計算一次排行與熱力圖。
        let campaignRanks = InsightsStats.campaignProfitRanking(
            campaigns: store.campaigns,
            orders: store.orders
        )
        let heatmapCells = InsightsStats.computeHeatmap(
            orders: store.orders,
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
        .accessibilityIdentifier(BLAccessibilityID.Insights.root)
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
        .accessibilityIdentifier(BLAccessibilityID.Insights.emptyState)
    }
    
    /// 首次載入訂單前顯示的骨架
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 骨架 view
    @ViewBuilder
    func loadingPlaceholder(palette: BLPalette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                    .fill(palette.fillQuaternary)
                    .frame(height: 32)
                
                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .fill(palette.fillTertiary)
                    .frame(height: 280)
                
                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .fill(palette.fillQuaternary)
                    .frame(height: 220)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
        }
        .scrollDisabled(true)
        .overlay {
            BLDelayedProgressView()
        }
        .accessibilityElement()
        .accessibilityLabel(Text("載入中"))
        .accessibilityIdentifier(BLAccessibilityID.Common.loading("insights"))
    }
    
    /// 期間選擇器
    @ViewBuilder
    var rangePicker: some View {
        // segmented picker 無法掛 identifier，測試端依序點選其按鈕
        Picker("期間", selection: $store.insightsDateRange) {
            ForEach(InsightsDateRange.allCases) { range in
                Text(LocalizedStringKey(range.title))
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier(BLAccessibilityID.Insights.rangePicker)
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
                        .font(BLTypographyStyle.subhead.font.weight(.medium))
                        .foregroundStyle(palette.secondaryLabel)
                    
                    Spacer()
                    
                    Text(LocalizedStringKey(stats.trendDelta))
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(
                            trendDeltaColor(
                                stats.trendDeltaIsPositive,
                                palette: palette
                            )
                        )
                }
                
                Text(BLFormatters.twd(stats.totalProfit, locale: locale))
                    .font(.system(size: heroProfitSize, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)
                    .accessibilityValue(Text(BLFormatters.twd(stats.totalProfit, locale: locale)))
                    .accessibilityIdentifier(BLAccessibilityID.Insights.trendTotalProfit)
                
                BLBarChart(
                    data: stats.trendBars,
                    height: 200,
                    isScrollEnabled: true,
                    axisXTitle: language.localized("項目"),
                    axisYTitle: language.localized("數值"),
                    seriesName: language.localized("長條圖")
                )
                .accessibilityIdentifier(BLAccessibilityID.Insights.trendChart)
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
    
    /// 顯示各開團的毛利排行；沒有可排行的開團時隱藏
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
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(palette.label)
                    
                    ForEach(ranks) { rank in
                        Button {
                            store.send(.delegate(.campaignTapped(rank.campaignName)))
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
                        .accessibilityValue(Text(CampaignFormatters.twd(rank.profit, locale: locale)))
                        .accessibilityIdentifier(
                            BLAccessibilityID.Insights.campaignRankRow(campaignID: rank.id)
                        )
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
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                
                if stats.categories.isEmpty {
                    Text("尚無分類資料")
                        .blTextStyle(.footnote)
                        .foregroundStyle(palette.secondaryLabel)
                } else {
                    let topProfit = stats.categories.first?.profit ?? 1
                    ForEach(Array(stats.categories.enumerated()), id: \.element.name) {
                        index, category in
                        Button {
                            store.send(.delegate(.categoryTapped(category.name)))
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
                        .accessibilityValue(Text(BLFormatters.twd(category.profit, locale: locale)))
                        .accessibilityIdentifier(
                            BLAccessibilityID.Insights.categoryRankRow(category: category.name)
                        )
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
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                
                Spacer()
                
                Text(BLFormatters.twd(category.profit, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)
                
                Image(systemName: "chevron.right")
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.tertiaryLabel)
                    .accessibilityHidden(true)
            }
            
            ProgressView(value: min(max(fraction, 0), 1))
                .progressViewStyle(BLProgressBarStyle(tint: tint))
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
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                
                VStack(alignment: .leading, spacing: BLSpacing.large) {
                    BLDonutChart(
                        segments: stats.costSegments.map {
                            BLDonutSegment(
                                label: $0.label,
                                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                                color: $0.color,
                                valueDescription: BLFormatters.twd($0.value, locale: locale)
                            )
                        },
                        centerTitle: "總成本",
                        centerValue: BLFormatters.twd(stats.totalCost, locale: locale),
                        axisXTitle: language.localized("類別"),
                        axisYTitle: language.localized("占比"),
                        seriesName: language.localized("圈狀圖")
                    )
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(BLAccessibilityID.Insights.costDonut)
                    
                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        ForEach(stats.costSegments) { segment in
                            HStack(spacing: BLSpacing.small) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(segment.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(LocalizedStringKey(segment.label))
                                    .blTextStyle(.caption)
                                    .foregroundStyle(palette.secondaryLabel)
                                
                                Spacer()
                                
                                Text(BLFormatters.twd(segment.value, locale: locale))
                                    .font(BLTypographyStyle.caption.font.weight(.semibold))
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
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                
                LazyVGrid(
                    columns: [GridItem(.fixed(heatmapWeekdayColumnWidth), spacing: 6)] + Array(
                        repeating: GridItem(.flexible(), spacing: 6),
                        count: weekCount
                    ),
                    spacing: 6
                ) {
                    Text(" ")
                        .frame(width: heatmapWeekdayColumnWidth)
                    
                    ForEach(0..<weekCount, id: \.self) { week in
                        Text("W\(week + 1)")
                            .blTextStyle(.caption2)
                            .foregroundStyle(palette.secondaryLabel)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // 攤平成單層 ForEach，確保 LazyVGrid 正確建立 cell
                    ForEach(0..<(7 * (weekCount + 1)), id: \.self) { index in
                        let weekday = index / (weekCount + 1)
                        let column = index % (weekCount + 1)
                        
                        if column == 0 {
                            Text(weekdayLabel(weekday))
                                .blTextStyle(.caption)
                                .foregroundStyle(palette.secondaryLabel)
                                .frame(width: heatmapWeekdayColumnWidth, alignment: .leading)
                        } else {
                            heatmapCell(
                                count: cells[HeatmapKey(week: column - 1, weekday: weekday)] ?? 0,
                                maxCount: maxCount,
                                weekday: weekdayLabel(weekday),
                                week: column,
                                palette: palette
                            )
                        }
                    }
                }
                // 整圖摘要：讓使用者不必逐格走過就能理解這張圖的範圍與規模
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("下單熱力圖，涵蓋過去 \(weekCount) 週，最高單日 \(maxCount) 單"))
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
    func heatmapCell(
        count: Int,
        maxCount: Int,
        weekday: String,
        week: Int,
        palette: BLPalette
    ) -> some View {
        let depth = BLHeatmapDepth.depth(for: count, maxCount: maxCount)
        
        // 明確設定高度撐起格子，因為 `RoundedRectangle` 沒有 intrinsic size。
        // 在 LazyVGrid 中靠 `aspectRatio` 會被旁邊 Text 那列壓成 0 高度而完全不顯示
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(depth?.background ?? palette.fillQuaternary)
            .frame(maxWidth: .infinity)
            .frame(height: heatmapCellHeight)
            .overlay {
                if let depth {
                    Text("\(count)")
                        .font(BLTypographyStyle.caption2.font.weight(.semibold))
                        .foregroundStyle(depth.numeral)
                        .accessibilityHidden(true)
                }
            }
            // 排除零值格，避免朗讀沒有意義的數字。
            // 非零格子帶上「星期 + 第幾週」讓數字有座標可依附
            .accessibilityHidden(count == 0)
            .accessibilityLabel(Text("\(weekday) 第 \(week) 週"))
            .accessibilityValue(Text("\(count) 單"))
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
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 依類別排行順序排列的 bar 色彩
    func categoryTints(palette: BLPalette) -> [Color] {
        [
            palette.accent,
            palette.purple,
            palette.orange,
            palette.teal,
            palette.pink,
        ]
    }

    // MARK: Heatmap
    
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

    // MARK: Formatting
    
    /// 將趨勢方向轉成顯示色
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
    let previewState: InsightsFeature.State = {
        var state = InsightsFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.loadState = .loaded
        return state
    }()
    
    return InsightsView(
        store: Store(initialState: previewState) {
            InsightsFeature()
        },
        language: .traditionalChinese
    )
}
