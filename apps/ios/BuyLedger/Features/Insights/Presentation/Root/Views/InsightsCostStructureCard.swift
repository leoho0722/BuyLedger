//
//  InsightsCostStructureCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 分析頁的成本結構卡，以圈狀圖與圖例呈現各項成本占總成本的比例
struct InsightsCostStructureCard: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// App 目前選用的顯示語系，用於圖表的無障礙標題
    let language: AppLanguage

    /// 成本結構的各個區塊
    let segments: [InsightsCostSegment]

    /// 全期成本總和，顯示在圈狀圖中央
    let totalCost: Decimal

    // MARK: - Body

    /// 卡片骨架，由上而下是標題，其下為圈狀圖與圖例
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                title

                breakdown
            }
        }
    }
}

// MARK: - Private Views

private extension InsightsCostStructureCard {

    /// 固定顯示「成本結構」的卡片標題
    var title: some View {
        Text("insights.chart.label.costStructure")
            .font(BLTypographyStyle.subhead.font.weight(.semibold))
            .foregroundStyle(.blLabel)
    }

    /// 成本結構圈狀圖，中央顯示總成本，圖表標題隨 App 內選用的語言翻譯
    var donut: some View {
        BLDonutChart(
            axisXTitle: language.localized("orders.list.label.category2"),
            axisYTitle: language.localized("orders.detail.label.share"),
            centerTitle: "orders.detail.label.totalCost",
            centerValue: BLFormatters.twd(totalCost, locale: locale),
            segments: donutSegments,
            seriesName: language.localized("orders.detail.label.donutChart")
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(BLAccessibilityID.Insights.costDonut)
    }

    /// 圖例，每個成本區塊一列
    var legend: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            ForEach(segments) {
                legendRow($0)
            }
        }
    }

    /// 圈狀圖與圖例上下排列
    var breakdown: some View {
        VStack(alignment: .leading, spacing: BLSpacing.large) {
            donut

            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 組出圖例單列，依序為色塊、區塊名稱與金額
    ///
    /// - Parameter segment: 成本區塊
    /// - Returns: 圖例列
    func legendRow(_ segment: InsightsCostSegment) -> some View {
        HStack(spacing: BLSpacing.small) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .frame(width: 8, height: 8)
                .foregroundStyle(color(for: segment.tone))
                .accessibilityHidden(true)

            Text(LocalizedStringKey(segment.label))
                .blTextStyle(.caption)
                .foregroundStyle(.blSecondaryLabel)

            Spacer()

            Text(BLFormatters.twd(segment.value, locale: locale))
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.blLabel)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private Method

private extension InsightsCostStructureCard {

    /// 圈狀圖的區段：金額與描述由 `InsightsFormatters` 換算，標籤本地化與色彩在這裡套用
    var donutSegments: [BLDonutSegment] {
        InsightsFormatters.costDonutSlices(segments, locale: locale).map {
            BLDonutSegment(
                label: language.localizedString(forKey: $0.label),
                value: $0.value,
                color: color(for: $0.tone),
                valueDescription: $0.valueDescription
            )
        }
    }

    /// 依語意色調取得圈狀圖與圖例使用的色彩
    ///
    /// - Parameter tone: 成本區塊的語意色調
    /// - Returns: 對應的色彩
    func color(for tone: InsightsCostSegment.Tone) -> Color {
        switch tone {
        case .accent:
            .blAccent

        case .teal:
            .blTeal

        case .purple:
            .blPurple

        case .orange:
            .blOrange
        }
    }
}

// MARK: - Preview

#Preview("insights.chart.label.costStructure") {
    InsightsCostStructureCard(
        language: .traditionalChinese,
        segments: [
            InsightsCostSegment(
                label: "orders.detail.label.itemCost",
                value: 12_000,
                tone: .accent
            ),
            InsightsCostSegment(
                label: "orders.detail.label.localShipping",
                value: 1_500,
                tone: .teal
            ),
            InsightsCostSegment(label: "orders.detail.label.fees", value: 900, tone: .orange),
        ],
        totalCost: 14_400
    )
    .padding()
}
