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

    /// 區段骨架，單次求值各團彙總後交給卡片呈現
    var body: some View {
        campaignsCard(rows: rows)
    }
}

// MARK: - Private Views

private extension DashboardOngoingCampaignsSection {

    /// 區段標題與裝著各團列的卡片
    ///
    /// - Parameter rows: 進行中的開團與各自的訂單彙總
    /// - Returns: 區段 view；沒有進行中的開團時為空
    @ViewBuilder
    func campaignsCard(rows: [Row]) -> some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("進行中的開團")
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
    func rowList(rows: [Row]) -> some View {
        VStack(spacing: BLSpacing.medium) {
            ForEach(Array(rows.enumerated()), id: \.element.campaign.id) { index, entry in
                Button {
                    store.send(.delegate(.campaignTapped(entry.campaign.name)))
                } label: {
                    campaignRow(campaign: entry.campaign, summary: entry.summary)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)

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
    ///   - summary: 由 `rows` 一次算好的該團彙總
    /// - Returns: 單列 view
    func campaignRow(campaign: Campaign, summary: CampaignSummary) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            HStack(spacing: BLSpacing.small) {
                Text(campaign.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(
                    """
                    \(summary.orderCount) 筆 · \
                    \(CampaignFormatters.twd(summary.receivables, locale: locale))
                    """
                )
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)
                .monospacedDigit()
            }

            BLProgressView(
                title: "到貨",
                value: summary.deliveryRatio,
                trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
            )

            BLProgressView(
                title: "收款",
                value: summary.receivedRatio,
                tint: palette.green,
                trailingText: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
            )
        }
    }
}

// MARK: - Nested Types

extension DashboardOngoingCampaignsSection {

    /// 區段內的一列資料：進行中的開團與它的訂單彙總
    struct Row {

        /// 進行中的開團
        let campaign: Campaign

        /// 該團的訂單彙總
        let summary: CampaignSummary
    }
}

// MARK: - Private Method

private extension DashboardOngoingCampaignsSection {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 進行中的開團與各自的訂單彙總
    var rows: [Row] {
        // 單次掃描訂單，批次建立各團的畫面投影
        let ongoingCampaigns = store.campaigns.filter { $0.status == .ongoing }
        let summaries = CampaignSummary.batch(
            campaignNames: ongoingCampaigns.map(\.name),
            orders: store.orders
        )

        return ongoingCampaigns.map {
            Row(
                campaign: $0,
                summary: summaries[$0.name] ?? CampaignSummary(campaignName: $0.name, orders: [])
            )
        }
    }
}

// MARK: - Preview

#Preview("進行中的開團") {
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
