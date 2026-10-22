//
//  CampaignDetailSettlementSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import SwiftUI

/// 開團詳情的結算區段：收款金額、到貨進度、成本與損益
struct CampaignDetailSettlementSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 由詳情 Feature 組好的開團彙總
    let summary: CampaignSummary

    // MARK: - Body

    /// 依序呈現收款、進度與損益的各列
    var body: some View {
        Section("campaigns.detail.label.campaignSettlement") {
            receivablesRow

            receivedRow

            outstandingRow

            receiptProgress

            deliveryProgress

            costRow

            profitRow

            marginRow
        }
    }
}

// MARK: - Private Views

private extension CampaignDetailSettlementSection {

    /// 應收金額，合併朗讀並提供 UI 測試讀取的金額
    var receivablesRow: some View {
        LabeledContent(
            "campaigns.detail.label.receivable",
            value: CampaignFormatters.twd(summary.receivables, locale: locale)
        )
        .accessibilityElement(children: .combine)
        .accessibilityValue(CampaignFormatters.twd(summary.receivables, locale: locale))
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSummary(.receivables))
    }

    /// 已收金額，合併朗讀並提供 UI 測試讀取的金額
    var receivedRow: some View {
        LabeledContent(
            "orders.edit.label.paid",
            value: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
        )
        .accessibilityElement(children: .combine)
        .accessibilityValue(CampaignFormatters.twd(summary.receivedAmount, locale: locale))
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSummary(.received))
    }

    /// 尚未收款的金額
    var outstandingRow: some View {
        LabeledContent(
            "campaigns.detail.label.unpaid",
            value: CampaignFormatters.twd(summary.outstandingAmount, locale: locale)
        )
    }

    /// 收款進度與整數百分比
    var receiptProgress: some View {
        BLProgressView(
            tint: .blGreen,
            title: "campaigns.detail.label.paymentProgress",
            trailingText: CampaignFormatters.receivedRatioText(
                summary.receivedRatio,
                locale: locale
            ),
            value: summary.receivedRatio
        )
    }

    /// 已到貨筆數與未取消且未合併的訂單筆數
    var deliveryProgress: some View {
        BLProgressView(
            title: "campaigns.detail.label.arrivalProgress",
            trailingText: CampaignFormatters.deliveryProgress(
                arrived: summary.arrivedCount,
                active: summary.activeCount
            ),
            value: summary.deliveryRatio
        )
    }

    /// 開團總成本
    var costRow: some View {
        LabeledContent(
            "orders.detail.label.totalCost",
            value: CampaignFormatters.twd(summary.totalCost, locale: locale)
        )
    }

    /// 開團毛利
    var profitRow: some View {
        LabeledContent(
            "orders.detail.label.grossProfit",
            value: CampaignFormatters.twd(summary.profit, locale: locale)
        )
    }

    /// 以實際收款為分母的利潤率
    var marginRow: some View {
        LabeledContent(
            "campaigns.detail.label.profitMargin",
            value: BLFormatters.percent(summary.margin, locale: locale)
        )
    }
}

// MARK: - Preview

#Preview("campaigns.detail.label.campaignSettlement") {
    List {
        CampaignDetailSettlementSection(
            summary: CampaignSummary(
                campaignName: Campaign.sampleCampaigns[0].name,
                orders: LedgerOrder.sampleCampaignOrders
            )
        )
    }
}
