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

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`，用於預設的資料點朗讀文字
    @Environment(\.locale) private var locale

    /// 走勢圖高度
    @ScaledMetric var height: CGFloat = 40

    /// 圖表無障礙描述的 X 軸標題；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var axisXTitle: String? = nil

    /// 圖表無障礙描述的 Y 軸標題；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var axisYTitle: String? = nil

    /// 走勢圖要呈現的數值
    let data: [Double]

    /// X 軸資料點的朗讀文字；未提供時依環境 `locale` 解析預設文字
    ///
    /// - Parameter ordinal: 該資料點在序列中的順位 (1-based)
    /// - Returns: 該資料點的朗讀文字
    var pointOrdinalDescription: ((_ ordinal: Int) -> String)? = nil

    /// 圖表資料序列名稱；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var seriesName: String? = nil

    /// 供輔助技術朗讀的趨勢摘要，以 catalog key 攜帶
    var summary: LocalizedStringResource? = nil

    /// 可選的線條色彩；未提供時使用成功色
    var tint: Color? = nil

    // MARK: - Body

    /// 小型走勢圖的畫面內容
    var body: some View {
        sparklineContent
            .frame(height: height)
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
            .accessibilityChartDescriptor(
                ChartAccessibilityDescriptor(
                    data: data,
                    axisXTitle: resolvedTitles.axisX,
                    axisYTitle: resolvedTitles.axisY,
                    seriesName: resolvedTitles.series,
                    pointOrdinalDescription: ordinalDescription
                )
            )
            .accessibilityHidden(summary == nil)
    }
}

// MARK: - Private Views

private extension BLSparkline {

    /// 走勢圖的面積與折線內容
    @ViewBuilder
    var sparklineContent: some View {
        GeometryReader {
            sparkline(in: $0.size)
        }
    }

    /// 依繪製尺寸產生走勢圖面積與折線
    ///
    /// - Parameter size: 走勢圖的繪製尺寸
    /// - Returns: 面積與折線疊合的走勢圖內容
    @ViewBuilder
    func sparkline(in size: CGSize) -> some View {
        let points = points(in: size)

        ZStack {
            Path { path in
                guard let first = points.first else {
                    return
                }
                path.move(to: CGPoint(x: first.x, y: size.height))
                points.forEach {
                    path.addLine(to: $0)
                }
                if let last = points.last {
                    path.addLine(to: CGPoint(x: last.x, y: size.height))
                }
                path.closeSubpath()
            }
            .fill(lineColor.opacity(0.16))

            Path { path in
                guard let first = points.first else {
                    return
                }
                path.move(to: first)
                points.dropFirst().forEach {
                    path.addLine(to: $0)
                }
            }
            .stroke(
                lineColor,
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Nested Types

extension BLSparkline {

    /// 走勢圖的輔助技術描述
    struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable {

        /// 對應圖表目前呈現的數值 (依繪製順序)
        let data: [Double]

        /// X 軸標題
        let axisXTitle: String

        /// Y 軸標題
        let axisYTitle: String

        /// 資料序列名稱
        let seriesName: String

        /// 單一資料點的朗讀描述
        ///
        /// - Parameter ordinal: 該資料點在序列中的順位 (1-based)
        /// - Returns: 該資料點的朗讀文字
        let pointOrdinalDescription: (Int) -> String

        /// 圖表無障礙描述的三個文字，已依環境 `locale` 解析
        struct Titles {

            /// X 軸標題
            let axisX: String

            /// Y 軸標題
            let axisY: String

            /// 資料序列名稱
            let series: String
        }

        /// 解析無障礙標題；有提供時原樣使用，未提供時依 `locale` 解析預設的 catalog key
        ///
        /// - Parameters:
        ///   - axisX: X 軸標題，未提供時為 `orders.list.label.sequence`
        ///   - axisY: Y 軸標題，未提供時為 `orders.detail.label.value`
        ///   - series: 資料序列名稱，未提供時為 `dashboard.overview.label.trendChart`
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
                    LocalizedStringResource("orders.list.label.sequence"),
                    locale: locale
                ),
                axisY: axisY ?? AppLanguage.resolve(
                    LocalizedStringResource("orders.detail.label.value"),
                    locale: locale
                ),
                series: series ?? AppLanguage.resolve(
                    LocalizedStringResource("dashboard.overview.label.trendChart"),
                    locale: locale
                )
            )
        }

        /// 預設的資料點朗讀文字，依 `locale` 解析 `common.general.label.pointLd` (如「第 2 筆」、「Point 2」)
        ///
        /// - Parameters:
        ///   - ordinal: 該資料點在序列中的順位 (1-based)
        ///   - locale: 目前的 `Locale`
        /// - Returns: 該資料點的朗讀文字
        static func defaultPointOrdinalDescription(_ ordinal: Int, locale: Locale) -> String {
            AppLanguage.resolve(
                LocalizedStringResource("common.general.label.pointLd", defaultValue: "\(ordinal)"),
                locale: locale
            )
        }

        /// 建立目前資料的輔助技術圖表描述
        ///
        /// - Returns: 供輔助技術使用的圖表描述
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

        /// 更新既有輔助技術圖表描述的資料序列
        ///
        /// - Parameter descriptor: 要更新的圖表描述
        func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
            descriptor.series = makeChartDescriptor().series
        }
    }
}

// MARK: - Private Method

private extension BLSparkline {

    /// 依目前的參數與環境 `locale` 解析的三個無障礙文字
    var resolvedTitles: ChartAccessibilityDescriptor.Titles {
        ChartAccessibilityDescriptor.titles(
            axisX: axisXTitle,
            axisY: axisYTitle,
            series: seriesName,
            locale: locale
        )
    }

    /// 資料點朗讀文字的解析函式；未提供時依環境 `locale` 解析預設文字
    var ordinalDescription: (Int) -> String {
        if let pointOrdinalDescription {
            return pointOrdinalDescription
        }
        let locale = self.locale
        return { ChartAccessibilityDescriptor.defaultPointOrdinalDescription($0, locale: locale) }
    }

    /// 供輔助技術讀取的趨勢摘要文字
    var accessibilityText: Text {
        if let summary {
            return Text(summary)
        }
        return Text(verbatim: "")
    }

    /// 走勢圖使用的線條色彩
    var lineColor: Color {
        tint ?? .blGreen
    }

    /// 將資料轉換成繪製路徑使用的座標點
    ///
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

#Preview("dashboard.overview.label.trendChart") {
    BLSparkline(data: [8, 12, 9, 15, 13, 18, 16, 22])
        .frame(width: 240)
        .padding()
}
