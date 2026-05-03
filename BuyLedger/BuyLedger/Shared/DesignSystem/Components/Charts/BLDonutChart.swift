//
//  BLDonutChart.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Charts
import SwiftUI

/// 可放置中心文字的圈狀圖。
struct BLDonutChart: View {
    
    // MARK: - View Properties
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme
    
    /// 圈狀圖要呈現的區段。
    let segments: [BLDonutSegment]
    
    /// 圈狀圖中央上方的輔助標題。
    let centerTitle: String
    
    /// 圈狀圖中央主要顯示值。
    let centerValue: String
    
    // MARK: - View Body
    
    /// 圈狀圖的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        ZStack {
            Chart(segments) { segment in
                SectorMark(
                    angle: .value("占比", segment.value),
                    innerRadius: .ratio(0.68),
                    angularInset: 1
                )
                .foregroundStyle(segment.color)
            }
            .chartLegend(.hidden)
            .frame(width: 150, height: 150)
            
            VStack(spacing: 2) {
                Text(centerTitle)
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryLabel)
                
                Text(centerValue)
                    .font(.headline)
                    .foregroundStyle(palette.label)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - ViewBuilder

private extension BLDonutChart {}

// MARK: - Preview

#Preview("圈狀圖") {
    BLDonutChart(
        segments: [
            BLDonutSegment(label: "餐飲", value: 42, color: .blue),
            BLDonutSegment(label: "交通", value: 24, color: .green),
            BLDonutSegment(label: "購物", value: 34, color: .orange),
        ],
        centerTitle: "總支出",
        centerValue: "$12.4K"
    )
    .padding()
}
