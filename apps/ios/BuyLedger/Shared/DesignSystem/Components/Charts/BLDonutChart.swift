//
//  BLDonutChart.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Charts
import SwiftUI

/// 可放置中心文字的圈狀圖
struct BLDonutChart: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 圈狀圖要呈現的區段
    let segments: [BLDonutSegment]

    /// 圈狀圖中央上方的輔助標題
    let centerTitle: String

    /// 圈狀圖中央主要顯示值
    let centerValue: String

    /// 圈狀圖直徑，隨字級縮放 (以 `.headline` 為基準)——中央文字放大時圓環也要跟著長大才容得下
    @ScaledMetric(relativeTo: .headline) private var diameter: CGFloat = 150

    // MARK: - View Body

    /// 圈狀圖的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        ZStack {
            Chart(segments) { segment in
                SectorMark(
                    angle: .value("占比", segment.value),
                    innerRadius: .ratio(0.68),
                    angularInset: 1
                )
                // 以類別維度驅動配色，Swift Charts 才拿得到區段身分並帶進無障礙樹；
                // 直接指定色值會讓區段名稱完全不進畫面也不進輔助技術
                .foregroundStyle(by: .value("類別", segment.label))
                .accessibilityLabel(segment.label)
                .accessibilityValue(segment.valueDescription)
            }
            .chartForegroundStyleScale(
                domain: segments.map(\.label),
                range: segments.map(\.color)
            )
            .chartLegend(.hidden)
            .frame(width: diameter, height: diameter)
            .accessibilityLabel(Text(accessibilitySummary))

            VStack(spacing: 2) {
                Text(LocalizedStringKey(centerTitle))
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryLabel)

                Text(centerValue)
                    .font(.headline)
                    .foregroundStyle(palette.label)
                    .monospacedDigit()
                    // 圓環已隨字級長大，單行加縮放係數僅作為極端字級下的次要防線
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }
}

// MARK: - Private Method

private extension BLDonutChart {

    /// 圖表層級摘要
    ///
    /// 描述資料的形狀而非重述上方既有的可見標題；資料為空時明說無資料，不朗讀零值
    var accessibilitySummary: LocalizedStringKey {
        guard let largest = segments.max(by: { $0.value < $1.value }) else {
            return "圈狀圖，目前沒有資料"
        }
        return "圈狀圖，共 \(segments.count) 個類別，占比最高為 \(largest.label) \(largest.valueDescription)"
    }
}

// MARK: - Preview

#Preview("圈狀圖") {
    BLDonutChart(
        segments: [
            BLDonutSegment(label: "餐飲", value: 42, color: .blue, valueDescription: "NT$42"),
            BLDonutSegment(label: "交通", value: 24, color: .green, valueDescription: "NT$24"),
            BLDonutSegment(label: "購物", value: 34, color: .orange, valueDescription: "NT$34"),
        ],
        centerTitle: "總支出",
        centerValue: "$12.4K"
    )
    .padding()
}
