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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

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

    /// 畫面骨架：導覽堆疊內顯示依畫面狀態切換的主體，出現時載入資料，標題為「分析」
    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.blBackground)
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

    /// 組出有分析資料時的完整內容：期間選擇器與各張分析卡片
    ///
    /// - Parameters:
    ///   - stats: 依記錄的日期脈絡計算的分析統計
    ///   - heatmap: 依記錄的日期脈絡計算的下單熱力圖
    /// - Returns: 可捲動的分析內容
    func analyticsContent(stats: InsightsStats, heatmap: InsightsHeatmap) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                rangePicker

                trendCard(stats: stats)

                breakdownGrid(stats: stats)

                campaignProfitCard(ranks: store.campaignRanks)

                InsightsHeatmapCard(heatmap: heatmap, weekdayLabels: weekdayLabels)
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

    /// 載入中或尚未記錄日期時顯示的骨架
    var loadingPlaceholder: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                    .frame(height: rangePlaceholderHeight)
                    .foregroundStyle(.blFillQuaternary)

                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .frame(height: trendPlaceholderHeight)
                    .foregroundStyle(.blFillTertiary)

                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .frame(height: rankingPlaceholderHeight)
                    .foregroundStyle(.blFillQuaternary)
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

    /// 依畫面狀態切換的主體：載入骨架、載入失敗、空狀態或分析內容，狀態只讀一次
    var content: some View {
        Group {
            switch store.screenState {
            case .loading:
                loadingPlaceholder

            case .failed(let message):
                BLLoadFailureView(
                    message: message,
                    retryIdentifier: BLAccessibilityID.Common.loadFailureRetryButton("insights")
                ) {
                    store.send(.view(.retryTapped))
                }
                .accessibilityIdentifier(BLAccessibilityID.Common.loadFailure("insights"))

            case .empty:
                emptyState

            case .analytics(let stats, let heatmap):
                analyticsContent(stats: stats, heatmap: heatmap)
            }
        }
    }

    /// 組出走勢卡，顯示目前選取期間的淨獲利與成長率
    ///
    /// - Parameter stats: 已計算的分析資料
    /// - Returns: 走勢卡
    func trendCard(stats: InsightsStats) -> some View {
        InsightsTrendCard(
            bars: InsightsFormatters.trendBars(stats.trendBuckets, locale: locale),
            delta: LocalizedStringKey(
                InsightsFormatters.trendDelta(stats.trendRatio, locale: locale)
            ),
            language: language,
            range: store.insightsDateRange,
            totalProfit: stats.totalProfit,
            trend: BLTrend(delta: stats.trendRatio)
        )
    }

    /// 組出類別排行與成本結構兩張卡：寬版並列，窄版上下堆疊
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

    /// 組出類別排行卡，點擊一列會要求查看該類別的訂單
    ///
    /// - Parameter stats: 已計算的分析資料
    /// - Returns: 類別排行卡
    func categoryCard(stats: InsightsStats) -> some View {
        InsightsCategoryCard(categories: stats.categories) {
            store.send(.view(.categoryTapped($0)))
        }
    }

    /// 組出成本結構卡，以圈狀圖與圖例呈現各項成本占總成本的比例
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

    /// 組出每團毛利排行卡；沒有可排行的開團時隱藏，點擊一列會要求查看該開團
    ///
    /// - Parameter ranks: 依開團與訂單算出的每團毛利排行
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

    /// 是否使用寬版面 (並列兩張卡，版面分類為 `regular`)
    var shouldUseWideLayout: Bool {
        layoutClass == .regular
    }

    /// 熱力圖左側的星期縮寫，依記錄的行事曆與 App 選定的 `locale` 排列；尚未記錄日期時為空陣列
    var weekdayLabels: [String] {
        guard let calendar = store.dateContext?.calendar else {
            return []
        }
        return InsightsFormatters.weekdayLabels(calendar: calendar, locale: locale)
    }
}

// MARK: - Preview

#Preview("orders.filter.title.insights") {
    let previewState: InsightsFeature.State = {
        var state = InsightsFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.loadState = .loaded
        state.dateContext = InsightsDateContext(
            now: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
        return state
    }()

    InsightsView(
        store: Store(initialState: previewState) {
            InsightsFeature()
        },
        language: .traditionalChinese
    )
}
