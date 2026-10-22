//
//  OrderDetailSummaryView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 訂單詳情的財務摘要卡片
struct OrderDetailSummaryView: View {

    // MARK: - Properties

    /// 系統選用的動態字級，用於無障礙字級下改採直排
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 呈現獲利與毛利率、收款、成本與手續費的財務摘要卡片
    var body: some View {
        profitCard
    }
}

// MARK: - Private Views

private extension OrderDetailSummaryView {

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
        .accessibilityElement(children: .combine)
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
            .accessibilityElement(children: .combine)
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

    /// 取得獲利正負對應的色盤顏色
    ///
    /// - Parameter profit: 訂單的獲利金額
    /// - Returns: 獲利為零或正數時為綠色，負數時為紅色
    func profitColor(for profit: Decimal) -> Color {
        profit >= 0 ? .blGreen : .blRed
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    OrderDetailSummaryView(order: LedgerOrder.sampleOrders[0])
}
