//
//  InsightsTrendCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 分析頁的淨獲利走勢卡，顯示期間標題、成長率、期間總獲利與長條圖
struct InsightsTrendCard: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 總獲利金額字級，隨 Dynamic Type 縮放 (以 `.title` 為基準)
    @ScaledMetric(relativeTo: .title) private var heroProfitSize: CGFloat = 28

    /// 走勢長條圖資料，30 天逐日、6 與 12 個月逐月
    let bars: [BLBarChartValue]

    /// 與上期比較的成長率文字，沒有比較值時為比較說明
    let delta: LocalizedStringKey

    /// App 目前選用的顯示語系，用於圖表的無障礙標題
    let language: AppLanguage

    /// 目前選取的趨勢期間，決定卡片標題
    let range: InsightsDateRange

    /// 期間內淨獲利總和
    let totalProfit: Decimal

    /// 相對上期的成長方向，決定成長率文字的顏色
    let trend: BLTrend

    // MARK: - Body

    /// 卡片骨架，由上而下是標題列、期間總獲利與走勢長條圖
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                header

                profitText

                chart
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension InsightsTrendCard {

    /// 標題列：左側為期間標題，右側為與上期比較的成長率
    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(range.trendCardTitle))
                .font(BLTypographyStyle.subhead.font.weight(.medium))
                .foregroundStyle(.blSecondaryLabel)

            Spacer()

            Text(delta)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(deltaColor)
        }
    }

    /// 期間內的淨獲利金額，朗讀內容與顯示金額相同
    var profitText: some View {
        Text(BLFormatters.twd(totalProfit, locale: locale))
            .font(.system(size: heroProfitSize, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(.blLabel)
            .accessibilityValue(Text(BLFormatters.twd(totalProfit, locale: locale)))
            .accessibilityIdentifier(BLAccessibilityID.Insights.trendTotalProfit)
    }

    /// 走勢長條圖，圖表標題隨 App 內選用的語言翻譯
    var chart: some View {
        BLBarChart(
            data: bars,
            height: 200,
            axisXTitle: language.localized("orders.list.label.text"),
            axisYTitle: language.localized("orders.detail.label.value"),
            isScrollEnabled: true,
            seriesName: language.localized("insights.chart.label.barChart")
        )
        .accessibilityIdentifier(BLAccessibilityID.Insights.trendChart)
    }
}

// MARK: - Private Method

private extension InsightsTrendCard {

    /// 成長率文字的顏色：上升為綠色、下降為紅色、沒有比較值為三級文字色
    var deltaColor: Color {
        switch trend {
        case .up:
            .blGreen

        case .down:
            .blRed

        case .unavailable:
            .blTertiaryLabel
        }
    }
}

// MARK: - Preview

#Preview("走勢") {
    InsightsTrendCard(
        bars: [
            BLBarChartValue(label: "4 月", value: 1_200, valueDescription: "NT$1,200"),
            BLBarChartValue(label: "5 月", value: 2_800, valueDescription: "NT$2,800"),
            BLBarChartValue(label: "6 月", value: 1_900, valueDescription: "NT$1,900"),
        ],
        delta: "↑ 18.5%",
        language: .traditionalChinese,
        range: .sixMonths,
        totalProfit: 5_900,
        trend: .up
    )
    .padding()
}
