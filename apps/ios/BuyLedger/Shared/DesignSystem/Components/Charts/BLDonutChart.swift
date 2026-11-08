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

    // MARK: - Properties

    /// 目前的動態字級，判斷是否為無障礙字級
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 圈狀圖直徑，隨字級縮放
    @ScaledMetric(relativeTo: .headline) private var diameter: CGFloat = 150

    /// 圖表無障礙描述的 X 軸標題；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var axisXTitle: String? = nil

    /// 圖表無障礙描述的 Y 軸標題；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var axisYTitle: String? = nil

    /// 圈狀圖中央上方的輔助標題，以 catalog key 攜帶，跟隨畫面 `\.locale` 呈現
    let centerTitle: LocalizedStringResource

    /// 圈狀圖中央主要顯示值
    let centerValue: String

    /// 圈狀圖要呈現的區段
    let segments: [BLDonutSegment]

    /// 圖表資料序列名稱；`nil` 時依環境 `locale` 解析預設文字；
    /// `AXChartDescriptor` 不會翻譯，呼叫端傳入字串時應已本地化
    var seriesName: String? = nil

    // MARK: - Body

    /// 圈狀圖的畫面內容
    var body: some View {
        donutContent
    }
}

// MARK: - Private Views

private extension BLDonutChart {

    /// 圈狀圖與中央文字的畫面內容
    var donutContent: some View {
        let layout: AnyLayout
        if dynamicTypeSize.isAccessibilitySize {
            layout = AnyLayout(VStackLayout(spacing: BLSpacing.small))
        } else {
            layout = AnyLayout(ZStackLayout())
        }

        return layout {
            donutChart
            centerContent
        }
    }

    /// 依可用寬度與字級縮放上限呈現的圈狀圖
    var donutChart: some View {
        Chart(segments) {
            SectorMark(
                angle: .value("orders.detail.label.share", $0.value),
                innerRadius: .ratio(0.68),
                angularInset: 1
            )
            // 以類別維度驅動配色，讓 Swift Charts 將區段身分帶進無障礙樹
            // 直接指定色值會讓區段名稱完全不進畫面也不進輔助技術
            .foregroundStyle(by: .value("orders.list.label.category2", $0.label))
            .accessibilityLabel($0.label)
            .accessibilityValue($0.valueDescription)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: diameter, maxHeight: diameter)
        .chartForegroundStyleScale(domain: segments.map(\.label), range: segments.map(\.color))
        .chartLegend(.hidden)
        .accessibilityLabel(ChartAccessibilityDescriptor.summary(for: segments, locale: locale))
        .accessibilityChartDescriptor(
            ChartAccessibilityDescriptor(
                segments: segments,
                axisXTitle: resolvedTitles.axisX,
                axisYTitle: resolvedTitles.axisY,
                seriesName: resolvedTitles.series
            )
        )
    }

    /// 圈狀圖標題與數值的置中內容與輔助字級堆疊內容
    var centerContent: some View {
        VStack(spacing: 2) {
            Text(centerTitle)
                .blTextStyle(.caption2)
                .foregroundStyle(.blSecondaryLabel)

            Text(centerValue)
                // 無障礙字級解除單行與縮放限制，不以縮放係數壓回字級
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.6)
                .blTextStyle(.headline)
                .foregroundStyle(.blLabel)
                .monospacedDigit()
        }
        // 輔助字級時中心文字移到圖下方並置中換行，標準字級維持預設對齊
        .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .center : .leading)
    }
}

// MARK: - Nested Types

extension BLDonutChart {

    /// 圈狀圖的輔助技術描述
    struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable {

        /// 對應圖表目前呈現的區段
        let segments: [BLDonutSegment]

        /// X 軸標題
        let axisXTitle: String

        /// Y 軸標題
        let axisYTitle: String

        /// 資料序列名稱
        let seriesName: String

        /// 圈狀圖的輔助技術文字，已依環境 `locale` 解析
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
        ///   - axisX: X 軸標題，未提供時為 `orders.list.label.category2`
        ///   - axisY: Y 軸標題，未提供時為 `orders.detail.label.share`
        ///   - series: 資料序列名稱，未提供時為 `orders.detail.label.donutChart`
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
                    LocalizedStringResource("orders.list.label.category2"),
                    locale: locale
                ),
                axisY: axisY ?? AppLanguage.resolve(
                    LocalizedStringResource("orders.detail.label.share"),
                    locale: locale
                ),
                series: series ?? AppLanguage.resolve(
                    LocalizedStringResource("orders.detail.label.donutChart"),
                    locale: locale
                )
            )
        }

        /// 建立圖表層級的輔助技術摘要
        ///
        /// - Parameters:
        ///   - segments: 圈狀圖資料
        ///   - locale: 目前的 `Locale`
        /// - Returns: 供輔助技術朗讀的摘要
        static func summary(for segments: [BLDonutSegment], locale: Locale) -> String {
            guard let largest = segments.max(by: { left, right in left.value < right.value }) else {
                return AppLanguage.resolve(
                    LocalizedStringResource("common.ui.label.donutChartData"),
                    locale: locale
                )
            }
            return AppLanguage.resolve(
                LocalizedStringResource(
                    "common.ui.accessibility.donutChartSummary",
                    defaultValue: "\(segments.count)\(largest.label)\(largest.valueDescription)"
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
            let values = segments.map(\.value)
            let xAxis = AXCategoricalDataAxisDescriptor(
                title: axisXTitle,
                categoryOrder: segments.map(\.label)
            )
            let yAxis = AXNumericDataAxisDescriptor(
                title: axisYTitle,
                range: (values.min() ?? 0)...(values.max() ?? 0),
                gridlinePositions: []
            ) { $0.formatted() }
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
    }
}

// MARK: - Private Method

private extension BLDonutChart {

    /// 依目前的參數與環境 `locale` 解析的三個無障礙文字
    var resolvedTitles: ChartAccessibilityDescriptor.Titles {
        ChartAccessibilityDescriptor.titles(
            axisX: axisXTitle,
            axisY: axisYTitle,
            series: seriesName,
            locale: locale
        )
    }
}

// MARK: - Preview

#Preview("orders.detail.label.donutChart") {
    BLDonutChart(
        centerTitle: "orders.detail.label.totalCost",
        centerValue: "$12.4K",
        segments: [
            BLDonutSegment(
                label: "餐飲",
                value: 42,
                color: .blAccent,
                valueDescription: "NT$42"
            ),
            BLDonutSegment(
                label: "交通",
                value: 24,
                color: .blGreen,
                valueDescription: "NT$24"
            ),
            BLDonutSegment(
                label: "購物",
                value: 34,
                color: .blOrange,
                valueDescription: "NT$34"
            ),
        ]
    )
    .padding()
}
