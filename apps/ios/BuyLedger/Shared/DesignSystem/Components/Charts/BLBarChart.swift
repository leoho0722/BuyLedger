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

    /// 目前的動態字級，判斷是否採用放大後的 X 軸標籤間距
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 圖表高度
    @ScaledMetric var height: CGFloat = 180

    /// X 軸標籤的最小間距，隨 `.caption2` 字級縮放，與軸標字級同步
    @ScaledMetric(relativeTo: .caption2)
    private var scaledLabelSpacing: CGFloat = Layout.minLabelSpacing

    /// 圖表無障礙描述的 X 軸標題；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var axisXTitle: String? = nil

    /// 圖表無障礙描述的 Y 軸標題；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var axisYTitle: String? = nil

    /// 長條圖要呈現的資料
    let data: [BLBarChartValue]

    /// 是否啟用水平捲動；預設關閉
    var isScrollEnabled: Bool = false

    /// 圖表資料序列名稱；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var seriesName: String? = nil

    // MARK: - Body

    /// 長條圖的畫面內容
    var body: some View {
        GeometryReader {
            chart(viewportWidth: $0.size.width)
        }
        .frame(height: height)
    }
}

// MARK: - Private Views

private extension BLBarChart {

    /// 依可用寬度繪製長條圖，必要時允許水平捲動
    ///
    /// - Parameter viewportWidth: `GeometryReader` 量到的可用寬度
    /// - Returns: 依可用寬度組合出的長條圖內容
    @ViewBuilder
    func chart(viewportWidth: CGFloat) -> some View {
        let total = data.count
        let visibleCount = visibleBarCount(total: total, viewportWidth: viewportWidth)

        if isScrollEnabled, total > visibleCount, viewportWidth > 0 {
            // 內容過寬時以水平捲動查看，預設顯示最新資料；無障礙字級時內容等於可用寬度，不捲動
            let contentWidth = dynamicTypeSize.isAccessibilitySize
                ? viewportWidth
                : viewportWidth * CGFloat(total) / CGFloat(visibleCount)

            ScrollView(.horizontal, showsIndicators: false) {
                barChart(renderWidth: contentWidth)
                    .frame(width: contentWidth)
            }
            .defaultScrollAnchor(.trailing)
        } else {
            barChart(renderWidth: viewportWidth)
        }
    }

    /// 建構長條圖本體；X 軸標籤依 `renderWidth` 抽稀，只在會重疊時稀疏
    ///
    /// - Parameter renderWidth: 圖表實際繪製寬度 (捲動時為內容寬度，否則為視窗寬度)
    /// - Returns: 依繪製寬度組合出的 `Chart`
    @ViewBuilder
    func barChart(renderWidth: CGFloat) -> some View {
        let axisLabels = Layout.stridedLabels(
            data: data,
            renderWidth: renderWidth,
            minLabelSpacing: labelSpacing
        )
        let titles = resolvedTitles

        Chart(Array(data.enumerated()), id: \.offset) { _, item in
            BarMark(x: .value(titles.axisX, item.label), y: .value(titles.axisY, item.value))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .foregroundStyle(.blAccent.gradient)
                .accessibilityLabel(item.label)
                .accessibilityValue(item.valueDescription)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: axisLabels) {
                AxisValueLabel(anchor: axisLabelAnchor(for: $0))
                    .foregroundStyle(.blSecondaryLabel)
                    // `AxisValueLabel` 不是 `View`，改用純 `Font`
                    .font(BLTypographyStyle.caption2.font)
            }
        }
        .accessibilityLabel(ChartAccessibilityDescriptor.summary(for: data, locale: locale))
        .accessibilityChartDescriptor(
            ChartAccessibilityDescriptor(
                data: data,
                axisXTitle: titles.axisX,
                axisYTitle: titles.axisY,
                seriesName: titles.series
            )
        )
    }
}

// MARK: - Nested Types

extension BLBarChart {

    /// 長條圖的版面常數與標籤抽稀演算法
    enum Layout {

        /// X 軸標籤的最小間距
        static let minLabelSpacing: CGFloat = 28

        /// 啟用捲動時的單一長條最小寬度
        static let minBarWidth: CGFloat = 44

        /// 計算繪製寬度下的 X 軸標籤，相鄰標籤至少保留最小間距
        ///
        /// - Parameters:
        ///   - data: 長條圖資料
        ///   - renderWidth: 圖表實際繪製寬度
        ///   - minLabelSpacing: 相鄰標籤的最小間距 (單位：pt)
        /// - Returns: 要繪製的標籤子集；資料為空時回傳空陣列，容量不足兩個時只回傳首尾
        static func stridedLabels(
            data: [BLBarChartValue],
            renderWidth: CGFloat,
            minLabelSpacing: CGFloat
        ) -> [String] {
            let total = data.count
            guard total > 0 else {
                return []
            }

            let capacity = max(1, Int(renderWidth / minLabelSpacing))
            // 容量不足兩個標籤時只保留首尾，避免丟失起點
            if capacity < 2, total > 1 {
                return [data[0].label, data[total - 1].label]
            }
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

        /// 對應圖表目前呈現的資料
        let data: [BLBarChartValue]

        /// X 軸標題
        let axisXTitle: String

        /// Y 軸標題
        let axisYTitle: String

        /// 資料序列名稱
        let seriesName: String

        /// 圖表無障礙描述的三個文字，已依環境 `locale` 解析
        struct Titles {

            /// X 軸標題
            let axisX: String

            /// Y 軸標題
            let axisY: String

            /// 資料序列名稱
            let series: String
        }

        /// 解析圖表無障礙描述的三個文字；有提供時原樣使用，未提供時依 `locale` 解析預設的 catalog key
        ///
        /// - Parameters:
        ///   - axisX: X 軸標題，未提供時為 `orders.list.label.text`
        ///   - axisY: Y 軸標題，未提供時為 `orders.detail.label.value`
        ///   - series: 資料序列名稱，未提供時為 `insights.chart.label.barChart`
        ///   - locale: 目前的 `Locale`
        /// - Returns: X 軸標題、Y 軸標題與資料序列名稱
        static func titles(
            axisX: String?,
            axisY: String?,
            series: String?,
            locale: Locale
        ) -> Titles {
            Titles(
                axisX: axisX ?? AppLanguage.resolve(
                    LocalizedStringResource("orders.list.label.text"),
                    locale: locale
                ),
                axisY: axisY ?? AppLanguage.resolve(
                    LocalizedStringResource("orders.detail.label.value"),
                    locale: locale
                ),
                series: series ?? AppLanguage.resolve(
                    LocalizedStringResource("insights.chart.label.barChart"),
                    locale: locale
                )
            )
        }

        /// 建立圖表層級的輔助技術摘要
        ///
        /// - Parameters:
        ///   - data: 長條圖資料
        ///   - locale: 目前的 `Locale`
        /// - Returns: 供輔助技術朗讀的摘要
        static func summary(for data: [BLBarChartValue], locale: Locale) -> String {
            guard let highest = data.max(by: { left, right in left.value < right.value }),
                  let lowest = data.min(by: { left, right in left.value < right.value }) else {
                return AppLanguage.resolve(
                    LocalizedStringResource("common.ui.label.barChartData"),
                    locale: locale
                )
            }
            return AppLanguage.resolve(
                LocalizedStringResource(
                    "common.ui.accessibility.barChartSummary",
                    defaultValue: "\(data.count)\(highest.label)\(highest.valueDescription)\(lowest.label)\(lowest.valueDescription)"
                ),
                locale: locale
            )
        }

        /// 更新既有輔助技術圖表描述的資料序列
        ///
        /// - Parameter descriptor: 要更新的圖表描述
        func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
            descriptor.series = makeChartDescriptor().series
        }

        /// 建立目前資料的輔助技術圖表描述
        ///
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
                gridlinePositions: []
            ) { $0.formatted() }
            let series = AXDataSeriesDescriptor(
                name: seriesName,
                isContinuous: false,
                dataPoints: data.map {
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
    }
}

// MARK: - Private Method

private extension BLBarChart {

    /// 依目前的參數與環境 `locale` 解析的三個無障礙文字
    var resolvedTitles: ChartAccessibilityDescriptor.Titles {
        ChartAccessibilityDescriptor.titles(
            axisX: axisXTitle,
            axisY: axisYTitle,
            series: seriesName,
            locale: locale
        )
    }

    /// X 軸標籤的最小間距；無障礙字級時取放大後間距的兩倍，標準字級維持原本的間距
    var labelSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? scaledLabelSpacing * 2 : Layout.minLabelSpacing
    }

    /// 計算一個視窗內可容納的長條數 (用來決定捲動時的內容寬度)
    ///
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

    /// 回傳 X 軸標籤的對齊錨點，無障礙字級時首尾標籤靠內側對齊，其餘標籤維持置中
    ///
    /// - Parameter value: 軸標的位置資訊
    /// - Returns: 首尾標籤的錨點；其餘標籤與標準字級為 `nil`
    func axisLabelAnchor(for value: AxisValue) -> UnitPoint? {
        guard dynamicTypeSize.isAccessibilitySize, value.count > 1 else {
            return nil
        }
        if value.index == 0 {
            return .topLeading
        }
        if value.index == value.count - 1 {
            return .topTrailing
        }
        return nil
    }
}

// MARK: - Preview

#Preview("insights.chart.label.barChart") {
    BLBarChart(data: [
        BLBarChartValue(label: "1 月", value: 82, valueDescription: "NT$82"),
        BLBarChartValue(label: "2 月", value: 126, valueDescription: "NT$126"),
        BLBarChartValue(label: "3 月", value: 96, valueDescription: "NT$96"),
        BLBarChartValue(label: "4 月", value: 142, valueDescription: "NT$142"),
    ])
    .padding()
}

#Preview("30 天逐日 (可捲動)") {
    let calendar = Calendar(identifier: .gregorian)
    let base = Date(timeIntervalSince1970: 1_777_500_000)
    let data: [BLBarChartValue] = (0..<30).reversed().compactMap { offset in
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

    BLBarChart(height: 200, data: data, isScrollEnabled: true)
        .padding()
}
