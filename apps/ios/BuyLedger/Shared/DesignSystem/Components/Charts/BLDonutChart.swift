//
//  BLDonutChart.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Accessibility
import Charts
import SwiftUI

/// 可放置中心文字的圈狀圖
struct BLDonutChart: View {
    
    // MARK: - View Properties
    
    /// 圈狀圖要呈現的區段
    let segments: [BLDonutSegment]
    
    /// 圈狀圖中央上方的輔助標題
    let centerTitle: String
    
    /// 圈狀圖中央主要顯示值
    let centerValue: String
    
    /// 圈狀圖直徑，隨字級縮放
    @ScaledMetric(relativeTo: .headline) private var diameter: CGFloat = 150
    
    /// 圖表無障礙描述 (`AXChartDescriptor`) 的 X 軸標題；預設正體中文字面值
    var axisXTitle: String = "類別"
    
    /// 圖表無障礙描述的 Y 軸標題；預設正體中文字面值，說明同 ``axisXTitle``
    var axisYTitle: String = "占比"
    
    /// 圖表資料序列名稱
    var seriesName: String = "圈狀圖"
    
    // MARK: - View Body
    
    /// 圈狀圖的畫面內容
    var body: some View {
        let palette = BLPalette()
        
        ZStack {
            Chart(segments) { segment in
                SectorMark(
                    angle: .value("占比", segment.value),
                    innerRadius: .ratio(0.68),
                    angularInset: 1
                )
                // 以類別維度驅動配色，讓 Swift Charts 將區段身分帶進無障礙樹。
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
            .accessibilityChartDescriptor(
                ChartAccessibilityDescriptor(
                    segments: segments,
                    axisXTitle: axisXTitle,
                    axisYTitle: axisYTitle,
                    seriesName: seriesName
                )
            )
            
            VStack(spacing: 2) {
                Text(LocalizedStringKey(centerTitle))
                    .blTextStyle(.caption2)
                    .foregroundStyle(palette.secondaryLabel)
                
                Text(centerValue)
                    .blTextStyle(.headline)
                    .foregroundStyle(palette.label)
                    .monospacedDigit()
                    // 圓環已隨字級長大，單行加縮放係數僅作為極端字級下的次要防線
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }
}

// MARK: - Nested Types

private extension BLDonutChart {
    
    /// 圈狀圖的輔助技術描述
    struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable {
        
        // MARK: - Data Properties
        
        /// 對應圖表目前呈現的區段
        let segments: [BLDonutSegment]
        
        /// X 軸標題
        let axisXTitle: String
        
        /// Y 軸標題
        let axisYTitle: String
        
        /// 資料序列名稱
        let seriesName: String
    }
}

// MARK: - AXChartDescriptorRepresentable

private extension BLDonutChart.ChartAccessibilityDescriptor {
    
    func makeChartDescriptor() -> AXChartDescriptor {
        let values = segments.map(\.value)
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: axisXTitle,
            categoryOrder: segments.map(\.label)
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: axisYTitle,
            range: (values.min() ?? 0)...(values.max() ?? 0),
            gridlinePositions: [],
            valueDescriptionProvider: { $0.formatted() }
        )
        let series = AXDataSeriesDescriptor(
            name: seriesName,
            isContinuous: false,
            dataPoints: segments.map {
                AXDataPoint(x: $0.label, y: $0.value, label: $0.valueDescription)
            }
        )
        return AXChartDescriptor(
            title: nil,
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            series: [series]
        )
    }
    
    func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
        descriptor.series = makeChartDescriptor().series
    }
}

// MARK: - Private Method

private extension BLDonutChart {
    
    /// 圖表層級摘要
    var accessibilitySummary: LocalizedStringKey {
        guard let largest = segments.max(by: { $0.value < $1.value }) else {
            return "圈狀圖，目前沒有資料"
        }
        return "圈狀圖，共 \(segments.count) 個類別，占比最高為 \(largest.label) \(largest.valueDescription)"
    }
}

// MARK: - Preview

#Preview("圈狀圖") {
    let palette = BLPalette()
    
    BLDonutChart(
        segments: [
            BLDonutSegment(
                label: "餐飲",
                value: 42,
                color: palette.accent,
                valueDescription: "NT$42"
            ),
            BLDonutSegment(
                label: "交通",
                value: 24,
                color: palette.green,
                valueDescription: "NT$24"
            ),
            BLDonutSegment(
                label: "購物",
                value: 34,
                color: palette.orange,
                valueDescription: "NT$34"
            ),
        ],
        centerTitle: "總支出",
        centerValue: "$12.4K"
    )
    .padding()
}
