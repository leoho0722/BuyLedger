//
//  InsightsCampaignProfitCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import SwiftUI

/// 分析頁的每團毛利排行卡，點擊一列會通知呼叫端查看該開團
struct InsightsCampaignProfitCard: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 點擊排行列的動作，帶開團名稱
    let onCampaignTapped: (String) -> Void

    /// 依毛利由高到低排列的開團排行
    let ranks: [CampaignProfitRank]

    // MARK: - Body

    /// 卡片骨架，由上而下是標題與每個開團一列的毛利進度
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                title

                rankRows
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension InsightsCampaignProfitCard {

    /// 固定顯示「每團毛利排行」的卡片標題
    var title: some View {
        Text("insights.chart.label.campaignProfitRanking")
            .font(BLTypographyStyle.subhead.font.weight(.semibold))
            .foregroundStyle(palette.label)
    }

    /// 每個開團一列可點擊的毛利進度
    var rankRows: some View {
        ForEach(ranks) {
            rankRow($0)
        }
    }

    /// 單一開團的可點擊排行列
    ///
    /// - Parameter rank: 開團的毛利排行資料
    /// - Returns: 排行列
    func rankRow(_ rank: CampaignProfitRank) -> some View {
        Button {
            onCampaignTapped(rank.campaignName)
        } label: {
            BLProgressView(
                title: String(rank.rank) + ". " + rank.campaignName,
                value: rank.ratio,
                tint: palette.accent,
                trailingText: CampaignFormatters.twd(rank.profit, locale: locale)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(AppLanguage.format("insights.chart.accessibility.viewDetails", rank.campaignName, locale: locale)))
        .accessibilityValue(Text(CampaignFormatters.twd(rank.profit, locale: locale)))
        .accessibilityIdentifier(BLAccessibilityID.Insights.campaignRankRow(campaignID: rank.id))
    }
}

// MARK: - Private Method

private extension InsightsCampaignProfitCard {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("insights.chart.label.campaignProfitRanking") {
    InsightsCampaignProfitCard(
        onCampaignTapped: { _ in
        },
        ranks: [
            CampaignProfitRank(
                id: "campaign-1",
                rank: 1,
                campaignName: "日韓美妝團",
                profit: 12_800,
                ratio: 1
            ),
            CampaignProfitRank(
                id: "campaign-2",
                rank: 2,
                campaignName: "東京零食團",
                profit: 7_900,
                ratio: 0.62
            ),
        ]
    )
    .padding()
}
