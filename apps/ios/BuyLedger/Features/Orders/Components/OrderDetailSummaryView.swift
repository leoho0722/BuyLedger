//
//  OrderDetailSummaryView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 窄欄財務摘要與寬欄三項指標卡片
struct OrderDetailSummaryView: View {

    // MARK: - Properties

    /// 系統選用的動態字級，用於無障礙字級下改採直排
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 指標標籤旁的裝飾色點尺寸，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var indicatorSize: CGFloat = 8

    /// 指標標籤與色點的間距，隨字級縮放
    @ScaledMetric(relativeTo: .footnote) private var labelSpacing: CGFloat = 6

    /// 詳情採用的窄欄或寬欄版面
    let layout: OrderDetailView.OrderDetailLayout

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 詳情區段的畫面骨架
    var body: some View {
        switch layout {
        case .compact:
            profitCard

        case .wide:
            kpiThreeUp
        }
    }
}

// MARK: - Private Views

private extension OrderDetailSummaryView {

    /// 收款、成本與獲利摘要卡片
    var profitCard: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                profitSummary

                Divider()

                financialMetrics
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 獲利與毛利率，無障礙字級下改為直排
    @ViewBuilder
    var profitSummary: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                profitValues
            }
        } else {
            HStack(alignment: .bottom) {
                profitValues
            }
        }
    }

    /// 獲利與毛利率共用的文字內容
    @ViewBuilder
    var profitValues: some View {
        let summary = order.summary
        let profitValue = OrderFormatters.signedTWD(summary.profit, locale: locale)

        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("orders.detail.label.profit")
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(.blSecondaryLabel)

            Text(profitValue)
                .blTextStyle(.largeTitle)
                .foregroundStyle(profitColor(for: summary.profit))
                .monospacedDigit()
        }
        // 合併朗讀，主要數值由 `accessibilityValue` 承載供 UI 測試讀取
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.profit))
        .accessibilityValue(profitValue)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer()
        }

        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: BLSpacing.extraSmall
        ) {
            Text("orders.detail.label.grossMargin")
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(.blSecondaryLabel)

            Text(OrderFormatters.marginPercent(summary, locale: locale))
                .blTextStyle(.title3Bold)
                .monospacedDigit()
        }
    }

    /// 收款、成本與手續費，無障礙字級下改為直排
    @ViewBuilder
    var financialMetrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                metricValues
            }
        } else {
            HStack {
                metricValues
            }
        }
    }

    /// 收款、成本與手續費共用的文字內容
    @ViewBuilder
    var metricValues: some View {
        let summary = order.summary
        let revenueValue = OrderFormatters.twd(summary.revenue, locale: locale)
        let costValue = OrderFormatters.twd(summary.totalCost, locale: locale)

        metric("orders.detail.label.totalPayment", value: revenueValue)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.revenue))
            .accessibilityValue(revenueValue)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer()
        }

        metric("orders.detail.label.totalCost", value: costValue)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.cost))
            .accessibilityValue(costValue)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer()
        }

        metric("orders.detail.label.fees", value: OrderFormatters.twd(summary.fees, locale: locale))
    }

    /// 寬欄版面的三項財務指標，無障礙字級下改為直排
    @ViewBuilder
    var kpiThreeUp: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                kpiTiles
            }
        } else {
            HStack(alignment: .top, spacing: BLSpacing.medium) {
                kpiTiles
            }
        }
    }

    /// 寬欄版面共用的收款、成本與獲利卡片
    @ViewBuilder
    var kpiTiles: some View {
        let summary = order.summary
        let revenueValue = OrderFormatters.twd(summary.revenue, locale: locale)
        let costValue = OrderFormatters.twd(summary.totalCost, locale: locale)
        let profitValue = OrderFormatters.signedTWD(summary.profit, locale: locale)

        kpiTile(label: "orders.detail.label.totalPayment", value: revenueValue, tint: .blAccent)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.revenue))
            .accessibilityValue(revenueValue)

        kpiTile(label: "orders.detail.label.totalCost", value: costValue, tint: .blOrange)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.cost))
            .accessibilityValue(costValue)

        kpiTile(
            label: "orders.detail.label.profit",
            value: profitValue,
            delta: OrderFormatters.marginPercent(summary, locale: locale),
            deltaTint: profitColor(for: summary.profit),
            tint: profitColor(for: summary.profit)
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailSummaryTile(.profit))
        .accessibilityValue(profitValue)
    }

    /// 顯示單一 KPI 卡片
    ///
    /// - Parameters:
    ///   - label: 指標標題
    ///   - value: 主要數值
    ///   - delta: 副標數值，例如毛利率，可省略
    ///   - deltaTint: 副標數值的色彩，未指定時採中性色
    ///   - tint: 標籤前色點與主要數值的強調色
    /// - Returns: KPI 卡片 view
    @ViewBuilder
    func kpiTile(
        label: String,
        value: String,
        delta: String? = nil,
        deltaTint: Color? = nil,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            HStack(spacing: labelSpacing) {
                // 純裝飾色點，語意已由標籤文字承載
                Circle()
                    .frame(width: indicatorSize, height: indicatorSize)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(LocalizedStringKey(label))
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                    .foregroundStyle(.blSecondaryLabel)
            }

            Text(value)
                .blTextStyle(.title2)
                .monospacedDigit()
                .foregroundStyle(.blLabel)

            if let delta {
                Text(delta)
                    .font(BLTypographyStyle.caption.font.weight(.medium))
                    .foregroundStyle(deltaTint ?? .blTertiaryLabel)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(.blSurface)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                .stroke(.blSeparator, lineWidth: 0.5)
        }
        // 合併為單一朗讀單位；裝飾色點已先排除
        .accessibilityElement(children: .combine)
    }

    /// 顯示單一財務指標
    ///
    /// - Parameters:
    ///   - title: 指標標題
    ///   - value: 指標值
    /// - Returns: 指標 view
    @ViewBuilder
    func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(LocalizedStringKey(title))
                .blTextStyle(.caption)
                .foregroundStyle(.blSecondaryLabel)

            Text(value)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .monospacedDigit()
        }
    }
}

// MARK: - Private Method

private extension OrderDetailSummaryView {

    /// 依獲利正負取得對應的色盤顏色
    ///
    /// - Parameter profit: 訂單的獲利金額
    /// - Returns: 獲利為零或正數時為綠色，負數時為紅色
    func profitColor(for profit: Decimal) -> Color {
        profit >= 0 ? .blGreen : .blRed
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    OrderDetailSummaryView(layout: .compact, order: LedgerOrder.sampleOrders[0])
}
