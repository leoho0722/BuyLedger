//
//  BLBarChart.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Accessibility
import Charts
import SwiftUI

/// 使用設計系統主色的簡潔長條圖
struct BLBarChart: View {

    // MARK: - Properties

    /// 長條圖要呈現的資料
    let data: [BLBarChartValue]

    /// 圖表高度
    var height: CGFloat = 180

    /// 是否啟用水平捲動；預設關閉
    var isScrollEnabled: Bool = false

    /// 圖表無障礙描述 (`AXChartDescriptor`) 的 X 軸標題；預設正體中文字面值
    var axisXTitle: String = "項目"

    /// 圖表無障礙描述的 Y 軸標題；預設正體中文字面值，
    /// 說明同 ``axisXTitle``
    var axisYTitle: String = "數值"

    /// 圖表資料序列名稱
    var seriesName: String = "長條圖"

    // MARK: - Body

    /// 長條圖的畫面內容
    var body: some View {
        GeometryReader { proxy in
            chart(palette: palette, viewportWidth: proxy.size.width)
        }
        .frame(height: height)
    }
}

// MARK: - Private Views

private extension BLBarChart {

    /// 依可用寬度繪製長條圖，必要時允許水平捲動
    /// - Parameters:
    ///   - palette: 目前外觀使用的色盤
    ///   - viewportWidth: `GeometryReader` 量到的可用寬度
    /// - Returns: 依可用寬度組合出的長條圖內容
    @ViewBuilder
    func chart(palette: BLPalette, viewportWidth: CGFloat) -> some View {
        let total = data.count
        let visibleCount = visibleBarCount(total: total, viewportWidth: viewportWidth)

        if isScrollEnabled, total > visibleCount, viewportWidth > 0 {
            // 內容過寬時以水平捲動查看，預設顯示最新資料
            let contentWidth = viewportWidth * CGFloat(total) / CGFloat(visibleCount)

            ScrollView(.horizontal, showsIndicators: false) {
                barChart(palette: palette, renderWidth: contentWidth)
                    .frame(width: contentWidth)
            }
            .defaultScrollAnchor(.trailing)
        } else {
            barChart(palette: palette, renderWidth: viewportWidth)
        }
    }

    /// 建構長條圖本體；X 軸標籤依 `renderWidth` 抽稀，只在會重疊時稀疏
    /// - Parameters:
    ///   - palette: 目前外觀使用的色盤
    ///   - renderWidth: 圖表實際繪製寬度 (捲動時為內容寬度，否則為視窗寬度)
    /// - Returns: 依繪製寬度組合出的 Chart
    @ViewBuilder
    func barChart(palette: BLPalette, renderWidth: CGFloat) -> some View {
        let axisLabels = stridedLabels(renderWidth: renderWidth)

        Chart(Array(data.enumerated()), id: \.offset) { _, item in
            BarMark(
                x: .value(axisXTitle, item.label),
                y: .value(axisYTitle, item.value)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .foregroundStyle(palette.accent.gradient)
            .accessibilityLabel(item.label)
            .accessibilityValue(item.valueDescription)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: axisLabels) { _ in
                AxisValueLabel()
                    .foregroundStyle(palette.secondaryLabel)
                    // AxisValueLabel 不是 View，改用純 Font
                    .font(BLTypographyStyle.caption2.font)
            }
        }
        .accessibilityLabel(Text(accessibilitySummary))
        .accessibilityChartDescriptor(
            ChartAccessibilityDescriptor(
                data: data,
                axisXTitle: axisXTitle,
                axisYTitle: axisYTitle,
                seriesName: seriesName
            )
        )
    }
}

// MARK: - Nested Types

private extension BLBarChart {

    /// 長條圖的版面常數與標籤抽稀演算法
    private enum Layout {

        // MARK: - Properties

        /// X 軸標籤的最小間距
        static let minLabelSpacing: CGFloat = 28

        /// 啟用捲動時的單一長條最小寬度
        static let minBarWidth: CGFloat = 44

        // MARK: - Internal Method

        /// 依繪製寬度計算 X 軸標籤
        /// - Parameters:
        ///   - data: 長條圖資料
        ///   - renderWidth: 圖表實際繪製寬度
        /// - Returns: 要繪製的標籤子集；資料為空時回傳空陣列
        static func stridedLabels(
            data: [BLBarChartValue],
            renderWidth: CGFloat
        ) -> [String] {
            let total = data.count
            guard total > 0 else {
                return []
            }

            let capacity = max(1, Int(renderWidth / minLabelSpacing))
            let stride = max(1, Int((Double(total) / Double(capacity)).rounded(.up)))

            var indices = Array(Swift.stride(from: 0, to: total, by: stride))
            // 補上最後一筆作為右端錨點，太近時取代前一筆
            if let last = indices.last, last != total - 1 {
                if total - 1 - last < stride {
                    indices[indices.count - 1] = total - 1
                } else {
                    indices.append(total - 1)
                }
            }
            return indices.map { data[$0].label }
        }
    }

    /// 長條圖的輔助技術描述
    struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable {

        // MARK: - Properties

        /// 對應圖表目前呈現的資料
        let data: [BLBarChartValue]

        /// X 軸標題
        let axisXTitle: String

        /// Y 軸標題
        let axisYTitle: String

        /// 資料序列名稱
        let seriesName: String

        /// 建立目前資料的輔助技術圖表描述
        /// - Returns: 供輔助技術使用的圖表描述
        func makeChartDescriptor() -> AXChartDescriptor {
            let values = data.map(\.value)
            let xAxis = AXCategoricalDataAxisDescriptor(
                title: axisXTitle,
                categoryOrder: data.map(\.label)
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
                dataPoints: data.map { item in
                    AXDataPoint(x: item.label, y: item.value, label: item.valueDescription)
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

        /// 更新既有輔助技術圖表描述的資料序列
        /// - Parameter descriptor: 要更新的圖表描述
        func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
            descriptor.series = makeChartDescriptor().series
        }

        /// 建立圖表層級的輔助技術摘要
        /// - Parameter data: 長條圖資料
        /// - Returns: 供輔助技術朗讀的摘要
        static func summary(for data: [BLBarChartValue]) -> LocalizedStringKey {
            guard let highest = data.max(by: { left, right in left.value < right.value }),
                  let lowest = data.min(by: { left, right in left.value < right.value })
            else {
                return "長條圖，目前沒有資料"
            }
            return """
                長條圖，共 \(data.count) 個期間，\
                最高 \(highest.label) \(highest.valueDescription)，\
                最低 \(lowest.label) \(lowest.valueDescription)
                """
        }
    }
}

// MARK: - Computed Properties

private extension BLBarChart {

    /// 目前外觀對應的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Private Method

private extension BLBarChart {

    /// 圖表層級摘要
    var accessibilitySummary: LocalizedStringKey {
        ChartAccessibilityDescriptor.summary(for: data)
    }

    /// 計算一個視窗內可容納的長條數 (用來決定捲動時的內容寬度)
    /// - Parameters:
    ///   - total: 資料總筆數
    ///   - viewportWidth: 可用寬度
    /// - Returns: 介於 `1...total` 的可視長條數
    func visibleBarCount(total: Int, viewportWidth: CGFloat) -> Int {
        guard isScrollEnabled, total > 0, viewportWidth > 0 else {
            return max(total, 1)
        }
        let capacity = max(1, Int(viewportWidth / Layout.minBarWidth))
        return min(total, capacity)
    }

    /// 依繪製寬度計算 X 軸標籤
    /// - Parameter renderWidth: 圖表實際繪製寬度
    /// - Returns: 要繪製標籤的標籤子集；資料為空時回傳空陣列
    func stridedLabels(renderWidth: CGFloat) -> [String] {
        Layout.stridedLabels(
            data: data,
            renderWidth: renderWidth
        )
    }
}

// MARK: - Preview

#Preview("長條圖") {
    BLBarChart(
        data: [
            BLBarChartValue(label: "1月", value: 82, valueDescription: "NT$82"),
            BLBarChartValue(label: "2月", value: 126, valueDescription: "NT$126"),
            BLBarChartValue(label: "3月", value: 96, valueDescription: "NT$96"),
            BLBarChartValue(label: "4月", value: 142, valueDescription: "NT$142"),
        ]
    )
    .padding()
}

#Preview("30 天逐日 (可捲動)") {
    let calendar = Calendar(identifier: .gregorian)
    let base = Date(timeIntervalSince1970: 1_777_500_000)
    let data = (0..<30).reversed().compactMap { offset -> BLBarChartValue? in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: base) else {
            return nil
        }
        return BLBarChartValue(
            label: day.formatted(
                .verbatim(
                    "\(month: .twoDigits)/\(day: .twoDigits)",
                    timeZone: calendar.timeZone,
                    calendar: calendar
                )
            ),
            value: Double((offset * 37) % 160 + 20),
            valueDescription: "NT$\((offset * 37) % 160 + 20)"
        )
    }

    BLBarChart(data: data, height: 200, isScrollEnabled: true)
        .padding()
}
