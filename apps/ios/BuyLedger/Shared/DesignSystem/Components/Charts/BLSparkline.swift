//
//  BLSparkline.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Accessibility
import SwiftUI

/// 呈現小型走勢的折線圖
struct BLSparkline: View {
    
    // MARK: - View Properties
    
    /// 走勢圖要呈現的數值
    let data: [Double]
    
    /// 可選的線條色彩；未提供時使用成功色
    var tint: Color? = nil
    
    /// 走勢圖高度
    var height: CGFloat = 40
    
    /// 供輔助技術朗讀的趨勢摘要
    var summary: LocalizedStringKey? = nil
    
    /// 圖表無障礙描述 (`AXChartDescriptor`) 的 X 軸標題；預設正體中文字面值
    var axisXTitle: String = "順序"
    
    /// 圖表無障礙描述的 Y 軸標題；預設正體中文字面值，說明同 ``axisXTitle``
    var axisYTitle: String = "數值"
    
    /// 圖表資料序列名稱
    var seriesName: String = "走勢圖"
    
    /// X 軸資料點的朗讀文字
    /// - Parameter ordinal: 該資料點在序列中的順位 (1-based)
    /// - Returns: 該資料點的朗讀文字
    var pointOrdinalDescription: (_ ordinal: Int) -> String = { ordinal in "第 \(ordinal) 筆" }
    
    // MARK: - View Body
    
    /// 小型走勢圖的畫面內容
    var body: some View {
        let palette = BLPalette()
        let color = tint ?? palette.green
        
        GeometryReader { proxy in
            let points = points(in: proxy.size)
            
            ZStack {
                Path { path in
                    guard let first = points.first else {
                        return
                    }
                    path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                    points.forEach { point in
                        path.addLine(to: point)
                    }
                    if let last = points.last {
                        path.addLine(to: CGPoint(x: last.x, y: proxy.size.height))
                    }
                    path.closeSubpath()
                }
                .fill(color.opacity(0.16))
                
                Path { path in
                    guard let first = points.first else {
                        return
                    }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 1.6,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(summary.map { Text($0) } ?? Text(verbatim: ""))
        .accessibilityChartDescriptor(
            ChartAccessibilityDescriptor(
                data: data,
                axisXTitle: axisXTitle,
                axisYTitle: axisYTitle,
                seriesName: seriesName,
                pointOrdinalDescription: pointOrdinalDescription
            )
        )
        .accessibilityHidden(summary == nil)
    }
}

// MARK: - Nested Types

private extension BLSparkline {
    
    /// 走勢圖的輔助技術描述
    struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable {
        
        // MARK: - Data Properties
        
        /// 對應圖表目前呈現的數值 (依繪製順序)
        let data: [Double]
        
        /// X 軸標題
        let axisXTitle: String
        
        /// Y 軸標題
        let axisYTitle: String
        
        /// 資料序列名稱
        let seriesName: String
        
        /// 單一資料點的朗讀描述
        /// - Returns: 該資料點的朗讀文字
        let pointOrdinalDescription: (Int) -> String
    }
}

// MARK: - AXChartDescriptorRepresentable

private extension BLSparkline.ChartAccessibilityDescriptor {
    
    func makeChartDescriptor() -> AXChartDescriptor {
        let lastIndex = Double(max(data.count - 1, 0))
        let xAxis = AXNumericDataAxisDescriptor(
            title: axisXTitle,
            range: 0...lastIndex,
            gridlinePositions: [],
            valueDescriptionProvider: { pointOrdinalDescription(Int($0) + 1) }
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: axisYTitle,
            range: (data.min() ?? 0)...(data.max() ?? 0),
            gridlinePositions: [],
            valueDescriptionProvider: { $0.formatted() }
        )
        let series = AXDataSeriesDescriptor(
            name: seriesName,
            isContinuous: true,
            dataPoints: data.enumerated().map { index, value in
                AXDataPoint(x: Double(index), y: value)
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

private extension BLSparkline {
    
    /// 將資料轉換成繪製路徑使用的座標點
    /// - Parameter size: 圖表可用繪製尺寸
    /// - Returns: 對應到目前尺寸的座標點集合
    func points(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else {
            return []
        }
        
        let maxValue = data.max() ?? 1
        let minValue = data.min() ?? 0
        let range = max(maxValue - minValue, 1)
        
        return data.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(data.count - 1)
            let normalized = CGFloat((value - minValue) / range)
            let y = size.height - normalized * (size.height - 4) - 2
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Preview

#Preview("走勢圖") {
    BLSparkline(data: [8, 12, 9, 15, 13, 18, 16, 22])
        .frame(width: 240)
        .padding()
}
