//
//  CampaignRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import SwiftUI

/// 開團列表的單列：團名、狀態、筆數／金額與到貨／收款進度
struct CampaignRow: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 對應的開團
    let campaign: Campaign

    /// 按年分組時顯示的開團日期；其他分組為 `nil`
    let dateText: String?

    /// 由訂單投影的彙總
    let summary: CampaignSummary

    // MARK: - Body

    /// 單列的畫面內容，合併成單一朗讀單位
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            if let dateText {
                openDateLabel(dateText)
            }

            titleLine

            ordersSummary

            deliveryProgress

            receiptProgress
        }
        // 開團列合併成單一朗讀單位，VoiceOver 一次讀出主要資訊
        // 否則輔助技術要逐一走過每個子元素
        .accessibilityElement(children: .combine)
        // 應收金額放在 accessibilityValue，讓 UI 測試讀取
        .accessibilityValue(CampaignFormatters.twd(summary.receivables, locale: locale))
    }
}

// MARK: - Private Views

private extension CampaignRow {

    /// 開團狀態與已結團標籤
    var statusPills: some View {
        VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
            BLStatusPill(
                campaign.status.title,
                tone: CampaignStatusStyle.tone(for: campaign.status)
            )

            if campaign.isSettled {
                BLStatusPill("campaigns.list.label.settled", tone: .neutral, showsIndicator: false)
            }
        }
    }

    /// 團名與右側的狀態標籤
    var titleLine: some View {
        HStack(alignment: .top, spacing: BLSpacing.small) {
            Text(campaign.name)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blTextStyle(.headline)

            statusPills
        }
    }

    /// 訂單筆數與應收金額
    var ordersSummary: some View {
        Text(
            AppLanguage.format(
                "common.general.label.ldOrders2",
                summary.orderCount,
                CampaignFormatters.twd(summary.receivables, locale: locale),
                locale: locale
            )
        )
        .blTextStyle(.subhead)
        .foregroundStyle(Color.blSecondaryLabel)
    }

    /// 到貨進度
    var deliveryProgress: some View {
        BLProgressView(
            title: "campaigns.list.label.arrived",
            value: summary.deliveryRatio,
            trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
        )
    }

    /// 收款進度與已收金額
    var receiptProgress: some View {
        BLProgressView(
            title: "orders.detail.label.payment",
            value: summary.receivedRatio,
            tint: palette.green,
            trailingText: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
        )
    }

    /// 按年分組時列上顯示的開團日期
    ///
    /// - Parameter text: 已格式化的開團日期
    /// - Returns: 次要色的日期標籤
    func openDateLabel(_ text: String) -> some View {
        Text(text)
            .blTextStyle(.caption)
            .foregroundStyle(Color.blSecondaryLabel)
    }
}

// MARK: - Private Method

private extension CampaignRow {

    /// 目前畫面使用的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("進行中開團") {
    CampaignRow(
        campaign: Campaign.sampleCampaigns[0],
        dateText: nil,
        summary: CampaignSummary(
            campaignName: Campaign.sampleCampaigns[0].name,
            orders: LedgerOrder.sampleCampaignOrders
        )
    )
    .padding()
}

#Preview("已結團且顯示開團日期") {
    CampaignRow(
        campaign: Campaign.sampleCampaigns[1],
        dateText: "2026年3月1日 週日",
        summary: CampaignSummary(
            campaignName: Campaign.sampleCampaigns[1].name,
            orders: LedgerOrder.sampleCampaignOrders
        )
    )
    .padding()
}
