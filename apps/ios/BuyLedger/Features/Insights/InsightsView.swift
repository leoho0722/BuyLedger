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

    // MARK: - Properties

    /// 目前版面分類，用來區分卡片上下堆疊的窄版與並列的寬版
    @Environment(\.blLayoutClass) private var layoutClass

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 趨勢與熱力圖使用的行事曆
    @Dependency(\.calendar) private var calendar

    /// 用來計算趨勢期間與熱力圖的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 骨架中期間選擇器的高度，隨字級縮放
    @ScaledMetric private var rangePlaceholderHeight: CGFloat = 32

    /// 骨架中排行卡的高度，隨字級縮放
    @ScaledMetric private var rankingPlaceholderHeight: CGFloat = 220

    /// 骨架中走勢卡的高度，隨字級縮放
    @ScaledMetric private var trendPlaceholderHeight: CGFloat = 280

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<InsightsFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 畫面骨架：導覽堆疊內顯示依載入狀態切換的主體，出現時載入資料，標題為「分析」
    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
                .task {
                    await store.send(.view(.task)).finish()
                }
                .rootNavigationTitle("orders.filter.title.insights", language: language)
        }
    }
}

// MARK: - Private Views

private extension InsightsView {

    /// 期間選擇器，切換走勢卡統計的期間
    var rangePicker: some View {
        // segmented picker 的選項無法個別掛 identifier，identifier 掛在 `Picker` 本體，測試端依宣告順序點選選項
        Picker("orders.list.label.period", selection: $store.insightsDateRange) {
            ForEach(InsightsDateRange.allCases) {
                Text(LocalizedStringKey($0.title))
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier(BLAccessibilityID.Insights.rangePicker)
    }

    /// 有訂單資料時的完整分析內容：期間選擇器與各張分析卡片
    @ViewBuilder
    var analyticsContent: some View {
        let stats = InsightsStats(
            orders: store.orders,
            range: store.insightsDateRange,
            referenceDate: date(),
            calendar: calendar,
            locale: locale,
            palette: palette
        )
        // 每次 render 各計算一次排行與熱力圖
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

                trendCard(stats: stats)

                breakdownGrid(stats: stats)

                campaignProfitCard(ranks: campaignRanks)

                InsightsHeatmapCard(cells: heatmapCells, weekdayLabels: weekdayLabels)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(BLAccessibilityID.Insights.root)
    }

    /// 沒有訂單時的空狀態，引導使用者先建立訂單
    var emptyState: some View {
        ContentUnavailableView {
            Label("insights.chart.label.enoughDataInsights", systemImage: "chart.bar.xaxis")
        } description: {
            Text("insights.chart.message.addFewOrders")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(BLAccessibilityID.Insights.emptyState)
    }

    /// 首次載入訂單前顯示的骨架
    var loadingPlaceholder: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                    .frame(height: rangePlaceholderHeight)
                    .foregroundStyle(palette.fillQuaternary)

                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .frame(height: trendPlaceholderHeight)
                    .foregroundStyle(palette.fillTertiary)

                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .frame(height: rankingPlaceholderHeight)
                    .foregroundStyle(palette.fillQuaternary)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
        }
        .overlay {
            BLDelayedProgressView()
        }
        .scrollDisabled(true)
        .accessibilityElement()
        .accessibilityLabel(Text("common.action.label.loading"))
        .accessibilityIdentifier(BLAccessibilityID.Common.loading("insights"))
    }

    /// 依載入狀態切換的畫面主體：分析內容、空狀態、載入失敗或載入骨架
    var content: some View {
        Group {
            switch store.loadState {
            case .loaded:
                if store.orders.isEmpty {
                    emptyState
                } else {
                    analyticsContent
                }

            case .failed(let message):
                BLLoadFailureView(
                    message: message,
                    retryIdentifier: BLAccessibilityID.Common.loadFailureRetryButton("insights")
                ) {
                    store.send(.view(.retryTapped))
                }
                .accessibilityIdentifier(BLAccessibilityID.Common.loadFailure("insights"))

            case .loading:
                loadingPlaceholder
            }
        }
    }

    /// 走勢卡，顯示目前選取期間的淨獲利與成長率
    ///
    /// - Parameter stats: 已計算的分析資料
    /// - Returns: 走勢卡
    func trendCard(stats: InsightsStats) -> some View {
        InsightsTrendCard(
            bars: stats.trendBars,
            delta: stats.trendDelta,
            language: language,
            range: store.insightsDateRange,
            totalProfit: stats.totalProfit,
            trend: trend(from: stats.trendDeltaIsPositive)
        )
    }

    /// 類別排行與成本結構兩張卡：寬版並列，窄版上下堆疊
    ///
    /// - Parameter stats: 已計算的分析資料
    /// - Returns: 兩張卡的排列
    @ViewBuilder
    func breakdownGrid(stats: InsightsStats) -> some View {
        if shouldUseWideLayout {
            HStack(alignment: .top, spacing: BLSpacing.medium) {
                categoryCard(stats: stats)
                    .frame(maxWidth: .infinity)

                costStructureCard(stats: stats)
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: BLSpacing.medium) {
                categoryCard(stats: stats)

                costStructureCard(stats: stats)
            }
        }
    }

    /// 類別排行卡，點擊一列會要求查看該類別的訂單
    ///
    /// - Parameter stats: 已計算的分析資料
    /// - Returns: 類別排行卡
    func categoryCard(stats: InsightsStats) -> some View {
        InsightsCategoryCard(categories: stats.categories) {
            store.send(.view(.categoryTapped($0)))
        }
    }

    /// 成本結構卡，以圈狀圖與圖例呈現各項成本占總成本的比例
    ///
    /// - Parameter stats: 已計算的分析資料
    /// - Returns: 圈狀圖加圖例的成本結構卡
    func costStructureCard(stats: InsightsStats) -> some View {
        InsightsCostStructureCard(
            language: language,
            segments: stats.costSegments,
            totalCost: stats.totalCost
        )
    }

    /// 每團毛利排行卡；沒有可排行的開團時隱藏，點擊一列會要求查看該開團
    ///
    /// - Parameter ranks: 由 ``analyticsContent`` 一次算好的開團毛利排行
    /// - Returns: 開團毛利排行卡，無資料時為空
    @ViewBuilder
    func campaignProfitCard(ranks: [CampaignProfitRank]) -> some View {
        if !ranks.isEmpty {
            InsightsCampaignProfitCard(
                onCampaignTapped: {
                    store.send(.view(.campaignTapped($0)))
                },
                ranks: ranks
            )
        }
    }
}

// MARK: - Private Method

private extension InsightsView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 是否使用寬版面 (並列兩張卡，版面分類為 `regular`)
    var shouldUseWideLayout: Bool {
        layoutClass == .regular
    }

    /// 依 App 選定 locale 顯示在熱力圖左側的星期縮寫，0 為週一、6 為週日
    var weekdayLabels: [String] {
        var localizedCalendar = Calendar.current
        localizedCalendar.locale = locale
        let symbols = localizedCalendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map {
            symbols[($0 + 1) % symbols.count]
        }
    }

    /// 把成長率方向旗標轉成走勢卡使用的三態方向
    ///
    /// - Parameter isPositive: 成長率方向；`nil` 表示沒有比較值
    /// - Returns: 上升、下降或沒有比較值
    func trend(from isPositive: Bool?) -> InsightsTrendCard.Trend {
        switch isPositive {
        case .some(true):
            .up

        case .some(false):
            .down

        case nil:
            .unavailable
        }
    }
}

// MARK: - Preview

#Preview("orders.filter.title.insights") {
    let previewState: InsightsFeature.State = {
        var state = InsightsFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.loadState = .loaded
        return state
    }()

    InsightsView(
        store: Store(initialState: previewState) {
            InsightsFeature()
        },
        language: .traditionalChinese
    )
}
