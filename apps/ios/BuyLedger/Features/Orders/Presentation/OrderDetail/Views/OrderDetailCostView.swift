//
//  OrderDetailCostView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 將詳情 State 的成本項目呈現為圈狀圖與圖例
struct OrderDetailCostView: View {

    // MARK: - Properties

    /// 目前的動態字級，無障礙字級時圖例名稱與金額上下排列
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 裝飾色點的圓角，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var indicatorRadius: CGFloat = 2

    /// 成本項目旁裝飾色點的尺寸，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var indicatorSize: CGFloat = 8

    /// 詳情 State 計算的成本項目
    let components: [OrderCostBreakdown.Component]

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 訂單的成本拆解區段
    var body: some View {
        costBreakdown
    }
}

// MARK: - Private Views

private extension OrderDetailCostView {

    /// 區段標題，以及包在卡片內的圈狀圖與逐項圖例
    var costBreakdown: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("orders.detail.label.costBreakdown")
                .blTextStyle(.headline)

            BLCard {
                VStack(alignment: .leading, spacing: BLSpacing.large) {
                    BLDonutChart(
                        centerTitle: "orders.detail.label.totalCost",
                        centerValue: OrderFormatters.twd(order.summary.totalCost, locale: locale),
                        segments: donutSegments
                    )
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: BLSpacing.medium) {
                        ForEach(components) {
                            legendRow($0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 顯示成本項目的色點、名稱與金額
    ///
    /// - Parameter component: 詳情狀態提供的成本項目
    /// - Returns: 合併為單一朗讀單位的圖例列
    func legendRow(_ component: OrderCostBreakdown.Component) -> some View {
        legendLayout {
            HStack(spacing: BLSpacing.small) {
                RoundedRectangle(cornerRadius: indicatorRadius, style: .continuous)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .foregroundStyle(costColor(for: component.tone))
                    .accessibilityHidden(true)

                Text(component.title)
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blSecondaryLabel)
            }

            Spacer()

            Text(OrderFormatters.twd(component.value, locale: locale))
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .monospacedDigit()
        }
        .fixedSize(horizontal: false, vertical: dynamicTypeSize.isAccessibilitySize)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private Method

private extension OrderDetailCostView {

    /// 圈狀圖的區段，由成本切片依語意色調換算為畫面色盤顏色
    var donutSegments: [BLDonutSegment] {
        OrderCostBreakdown.donutSlices(for: components, locale: locale).map {
            BLDonutSegment(
                label: AppLanguage.resolve($0.label, locale: locale),
                value: $0.value,
                color: costColor(for: $0.tone),
                valueDescription: $0.valueDescription
            )
        }
    }

    /// 圖例列的排列版面，標準字級橫排，無障礙字級時上下排列
    var legendLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(spacing: BLSpacing.small))
    }

    /// 取得成本語意色調對應的色盤顏色
    ///
    /// - Parameter tone: 成本項目的語意色調
    /// - Returns: 該色調在色盤中的顏色
    func costColor(for tone: OrderCostBreakdown.Tone) -> Color {
        switch tone {
        case .accent:
            return .blAccent

        case .orange:
            return .blOrange

        case .teal:
            return .blTeal

        case .purple:
            return .blPurple

        case .indigo:
            return .blIndigo

        case .pink:
            return .blPink

        case .yellow:
            return .blYellow
        }
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    let detail = OrderDetailFeature.State(
        orderID: LedgerOrder.sampleOrders[0].id,
        orders: SharedReader(value: LedgerOrder.sampleOrders)
    )

    OrderDetailCostView(components: detail.costComponents, order: LedgerOrder.sampleOrders[0])
}
