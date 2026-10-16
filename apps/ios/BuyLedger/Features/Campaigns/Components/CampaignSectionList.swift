//
//  CampaignSectionList.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import SwiftUI

/// 開團列表的日期區段清單：區段標題、子群組標題與卡片內可點擊的開團列
struct CampaignSectionList: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 區段標題格式化使用的日期脈絡，用來判斷「今天」「昨天」
    let dateContext: CampaignDateContext

    /// 是否在每列顯示開團日期，按年分組時為 `true`
    let isShowingOpenDate: Bool

    /// 長按選單刪除開團的動作
    let onDelete: (Campaign.ID) -> Void

    /// 長按選單編輯開團的動作
    let onEdit: (Campaign.ID) -> Void

    /// 點擊開團列的動作
    let onSelect: (Campaign.ID) -> Void

    /// 要呈現的頂層日期區段，依日期由新到舊排序
    let sections: [CampaignDateSection]

    /// 依開團名稱取得列彙總的查詢，已由呼叫端批次投影
    let summaries: CampaignListFeature.RowSummaries

    // MARK: - Body

    /// 以捲動容器依序呈現各頂層區段
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: BLSpacing.large) {
                ForEach(sections) {
                    dateSection($0)
                }
            }
            .padding(.top, BLSpacing.small)
            .padding(.bottom, BLSpacing.large)
        }
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.listRoot)
    }
}

// MARK: - Private Views

private extension CampaignSectionList {

    /// 組出單一頂層日期區段，含標題與其下各子群組
    ///
    /// - Parameter section: 要呈現的頂層區段
    /// - Returns: 區段 view
    func dateSection(_ section: CampaignDateSection) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            titleText(section.title)
                .padding(.horizontal, BLSpacing.large)
                .font(BLTypographyStyle.subhead.font.weight(.bold))

            ForEach(section.subgroups) {
                subgroupCard($0)
            }
        }
    }

    /// 依日期脈絡與 locale 格式化區段與子群組的標題文字
    ///
    /// - Parameter title: 尚未格式化的標題內容
    /// - Returns: 本地化 key 或依 locale 格式化的日期文字
    func titleText(_ title: CampaignSectionTitle) -> Text {
        Text(
            LocalizedStringKey(
                CampaignFormatters.sectionTitle(title, context: dateContext, locale: locale)
            )
        )
    }

    /// 組出單一日期子群組，含子標題與裝著開團列的卡片
    ///
    /// - Parameter subgroup: 要呈現的子群組
    /// - Returns: 子群組 view
    func subgroupCard(_ subgroup: CampaignSubgroup) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            if let title = subgroup.title {
                titleText(title)
                    .padding(.horizontal, BLSpacing.large)
                    .padding(.top, BLSpacing.small)
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)
            }

            BLCard(padding: 0) {
                rows(of: subgroup.campaigns)
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }

    /// 依序排列卡片內的開團列，列與列之間以分隔線隔開
    ///
    /// - Parameter campaigns: 子群組內的開團
    /// - Returns: 開團列 view
    func rows(of campaigns: [Campaign]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(campaigns.enumerated()), id: \.element.id) { index, campaign in
                rowButton(campaign)

                if index < campaigns.count - 1 {
                    Divider()
                        .padding(.horizontal, BLSpacing.large)
                }
            }
        }
    }

    /// 組出單一開團卡片列，點擊進詳情，長按可編輯或刪除
    ///
    /// - Parameter campaign: 對應的開團
    /// - Returns: 開團列 view
    func rowButton(_ campaign: Campaign) -> some View {
        Button {
            onSelect(campaign.id)
        } label: {
            CampaignRow(
                campaign: campaign,
                dateText: CampaignFormatters.openDateText(
                    campaign.openDate,
                    isShowing: isShowingOpenDate,
                    locale: locale
                ),
                summary: summaries.summary(forCampaignNamed: campaign.name)
            )
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.row(campaignID: campaign.id))
        .contextMenu {
            Button {
                onEdit(campaign.id)
            } label: {
                Label("common.action.button.edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete(campaign.id)
            } label: {
                Label("common.action.button.delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview("依日分組") {
    let calendar = Calendar(identifier: .gregorian)

    NavigationStack {
        CampaignSectionList(
            dateContext: CampaignDateContext(
                now: Campaign.sampleCampaigns[0].openDate,
                calendar: calendar
            ),
            isShowingOpenDate: false,
            onDelete: { _ in
            },
            onEdit: { _ in
            },
            onSelect: { _ in
            },
            sections: CampaignDateSectionBuilder.sections(
                for: Campaign.sampleCampaigns,
                statusFilter: nil,
                grouping: .day,
                calendar: calendar
            ),
            summaries: CampaignListFeature.RowSummaries(
                byName: CampaignSummary.batch(
                    campaignNames: Campaign.sampleCampaigns.map(\.name),
                    orders: LedgerOrder.sampleCampaignOrders
                )
            )
        )
    }
}

#Preview("依年分組顯示開團日期") {
    let calendar = Calendar(identifier: .gregorian)

    NavigationStack {
        CampaignSectionList(
            dateContext: CampaignDateContext(
                now: Campaign.sampleCampaigns[0].openDate,
                calendar: calendar
            ),
            isShowingOpenDate: true,
            onDelete: { _ in
            },
            onEdit: { _ in
            },
            onSelect: { _ in
            },
            sections: CampaignDateSectionBuilder.sections(
                for: Campaign.sampleCampaigns,
                statusFilter: nil,
                grouping: .year,
                calendar: calendar
            ),
            summaries: CampaignListFeature.RowSummaries(
                byName: CampaignSummary.batch(
                    campaignNames: Campaign.sampleCampaigns.map(\.name),
                    orders: LedgerOrder.sampleCampaignOrders
                )
            )
        )
    }
}
