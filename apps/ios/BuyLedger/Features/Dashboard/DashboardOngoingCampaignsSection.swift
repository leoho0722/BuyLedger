//
//  DashboardOngoingCampaignsSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// 總覽的「進行中的開團」區段：各團的筆數、金額與到貨／收款進度，沒有進行中的開團時不顯示
struct DashboardOngoingCampaignsSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<DashboardFeature>

    // MARK: - Body

    /// 區段骨架，把 State 算好的各團列交給卡片呈現
    var body: some View {
        campaignsCard(rows: store.ongoingCampaignRows)
    }
}

// MARK: - Private Views

private extension DashboardOngoingCampaignsSection {

    /// 區段標題與裝著各團列的卡片
    ///
    /// - Parameter rows: 進行中的開團與各自的訂單彙總
    /// - Returns: 區段 view；沒有進行中的開團時為空
    @ViewBuilder
    func campaignsCard(rows: [DashboardFeature.State.OngoingCampaignRow]) -> some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("dashboard.overview.label.activeCampaigns")
                    .blTextStyle(.headline)
                    .foregroundStyle(palette.label)

                BLCard {
                    rowList(rows: rows)
                }
            }
        }
    }

    /// 卡片內依序排列的可點擊開團列，列與列之間以分隔線隔開
    ///
    /// - Parameter rows: 進行中的開團與各自的訂單彙總
    /// - Returns: 開團列 view
    func rowList(rows: [DashboardFeature.State.OngoingCampaignRow]) -> some View {
        VStack(spacing: BLSpacing.medium) {
            ForEach(Array(rows.enumerated()), id: \.element.campaign.id) { index, entry in
                Button {
                    store.send(.view(.campaignTapped(entry.campaign.name)))
                } label: {
                    campaignRow(campaign: entry.campaign, summary: entry.summary)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    BLAccessibilityID.Dashboard.ongoingCampaignRow(campaignID: entry.campaign.id)
                )

                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
    }

    /// 單列：團名、筆數／金額與到貨／收款進度
    ///
    /// - Parameters:
    ///   - campaign: 進行中的開團
    ///   - summary: 由 `DashboardFeature.State.ongoingCampaignRows` 算好的該團彙總
    /// - Returns: 單列 view
    func campaignRow(campaign: Campaign, summary: CampaignSummary) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            HStack(spacing: BLSpacing.small) {
                Text(campaign.name)
                    .lineLimit(1)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)

                Spacer(minLength: 0)

                Text(
                    AppLanguage.format(
                        "dashboard.overview.label.campaignOrderSummary",
                        summary.orderCount,
                        CampaignFormatters.twd(summary.receivables, locale: locale),
                        locale: locale
                    )
                )
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)
                .monospacedDigit()
            }

            BLProgressView(
                title: "campaigns.list.label.arrived",
                value: summary.deliveryRatio,
                trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
            )

            BLProgressView(
                title: "orders.detail.label.payment",
                value: summary.receivedRatio,
                tint: palette.green,
                trailingText: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
            )
        }
    }
}

// MARK: - Private Method

private extension DashboardOngoingCampaignsSection {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("dashboard.overview.label.activeCampaigns") {
    let previewState: DashboardFeature.State = {
        var state = DashboardFeature.State()
        state.orders = LedgerOrder.sampleCampaignOrders
        state.campaigns = Campaign.sampleCampaigns
        state.loadState = .loaded
        return state
    }()

    DashboardOngoingCampaignsSection(
        store: Store(initialState: previewState) {
            DashboardFeature()
        }
    )
    .padding()
}
