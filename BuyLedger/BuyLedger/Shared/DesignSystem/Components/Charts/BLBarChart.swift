//
//  BLBarChart.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Charts
import SwiftUI

/// 使用設計系統主色的簡潔長條圖。
struct BLBarChart: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 長條圖要呈現的資料。
    let data: [BLBarChartValue]

    /// 圖表高度。
    var height: CGFloat = 180

    // MARK: - View Body

    /// 長條圖的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        Chart(data) { item in
            BarMark(
                x: .value("月份", item.label),
                y: .value("金額", item.value)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .foregroundStyle(palette.accent.gradient)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(palette.tertiaryLabel)
                    .font(.caption2)
            }
        }
        .frame(height: height)
    }
}

// MARK: - ViewBuilder

private extension BLBarChart {}

// MARK: - Preview

#Preview("長條圖") {
    BLBarChart(
        data: [
            BLBarChartValue(label: "1月", value: 82),
            BLBarChartValue(label: "2月", value: 126),
            BLBarChartValue(label: "3月", value: 96),
            BLBarChartValue(label: "4月", value: 142),
        ]
    )
    .padding()
}
