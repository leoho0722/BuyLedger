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

    /// 分隔線的高度，列內距保留此高度給卡片內分隔線
    @Environment(\.pixelLength) private var pixelLength

    /// 區段標題格式化使用的日期脈絡，用來判斷「今天」「昨天」
    let dateContext: CampaignDateContext

    /// 是否在每列顯示開團日期，按年分組時為 `true`
    let isShowingOpenDate: Bool

    /// 長按選單刪除開團的動作
    let onDelete: (Campaign.ID) -> Void

    /// 長按選單編輯開團的動作
    let onEdit: (Campaign.ID) -> Void

    /// 要呈現的頂層日期區段，依日期由新到舊排序
    let sections: [CampaignDateSection]

    /// 目前選取的開團識別值綁定，供原生分欄導覽使用
    let selection: Binding<Campaign.ID?>

    /// 依開團名稱取得列彙總的查詢，已由呼叫端批次投影
    let summaries: CampaignListFeature.RowSummaries

    // MARK: - Body

    /// 依序呈現各頂層區段的列表容器；標題為無背景的列，每筆開團為原生選取列並承載卡片外觀
    var body: some View {
        List(selection: selection) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in
                sectionTitleRow(section, isFirst: sectionIndex == 0)

                ForEach(
                    Array(section.subgroups.enumerated()),
                    id: \.element.id
                ) { subgroupIndex, subgroup in
                    if let title = subgroup.title {
                        subgroupTitleRow(title, isFirst: subgroupIndex == 0)
                    }

                    ForEach(
                        Array(subgroup.campaigns.enumerated()),
                        id: \.element.id
                    ) { index, campaign in
                        campaignRow(
                            campaign,
                            position: BLCardRowPosition(
                                index: index,
                                count: subgroup.campaigns.count
                            )
                        )
                    }
                }
            }
        }
        .contentMargins(
            .vertical,
            EdgeInsets(
                top: BLSpacing.small,
                leading: 0,
                bottom: BLSpacing.large - BLCardRowMetrics.edgeRoom,
                trailing: 0
            ),
            for: .scrollContent
        )
        // 不讓系統最小列高撐高較矮的標題列
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.listRoot)
        .navigationLinkIndicatorVisibility(.hidden)
    }
}

// MARK: - Private Views

private extension CampaignSectionList {

    /// 建立頂層區段的標題列，與其下第一個元素之間的間距由列內距維持
    ///
    /// - Parameters:
    ///   - section: 要呈現的頂層區段
    ///   - isFirst: 是否為清單的第一個區段
    /// - Returns: 區段標題列
    func sectionTitleRow(_ section: CampaignDateSection, isFirst: Bool) -> some View {
        titleText(section.title)
            .padding(.horizontal, BLSpacing.large)
            .font(BLTypographyStyle.subhead.font.weight(.bold))
            .listRowInsets(
                EdgeInsets(
                    top: isFirst ? 0 : BLSpacing.large - BLCardRowMetrics.edgeRoom,
                    leading: 0,
                    bottom: sectionTitleBottomInset(section),
                    trailing: 0
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// 依日期脈絡與 `locale` 格式化區段與子群組的標題文字
    ///
    /// - Parameter title: 尚未格式化的標題內容
    /// - Returns: 本地化 key 或依 `locale` 格式化的日期文字
    func titleText(_ title: CampaignSectionTitle) -> Text {
        Text(
            LocalizedStringKey(
                CampaignFormatters.sectionTitle(title, context: dateContext, locale: locale)
            )
        )
    }

    /// 建立子群組標題列，與其下卡片之間的間距由列內距維持
    ///
    /// - Parameters:
    ///   - title: 子群組標題
    ///   - isFirst: 是否緊接在頂層區段標題之後
    /// - Returns: 子群組標題列
    func subgroupTitleRow(_ title: CampaignSectionTitle, isFirst: Bool) -> some View {
        titleText(title)
            .padding(.horizontal, BLSpacing.large)
            .padding(.top, BLSpacing.small)
            .font(BLTypographyStyle.footnote.font.weight(.semibold))
            .foregroundStyle(.blSecondaryLabel)
            .listRowInsets(
                EdgeInsets(
                    top: isFirst ? 0 : BLSpacing.small - BLCardRowMetrics.edgeRoom,
                    leading: 0,
                    bottom: BLSpacing.small - BLCardRowMetrics.edgeRoom,
                    trailing: 0
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// 建立單一開團列，點擊更新原生選取，長按可編輯或刪除；卡片外觀由列背景承擔
    ///
    /// - Parameters:
    ///   - campaign: 對應的開團
    ///   - position: 開團在子群組卡片中的位置
    /// - Returns: 開團列 view
    func campaignRow(_ campaign: Campaign, position: BLCardRowPosition) -> some View {
        let isSelected = selection.wrappedValue == campaign.id

        return NavigationLink(value: campaign.id) {
            rowContent(campaign, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.row(campaignID: campaign.id))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .contextMenu {
            rowContextMenu(campaignID: campaign.id)
        }
        .listRowInsets(position.cardRowInsets(dividerHeight: pixelLength))
        .listRowSeparator(.hidden)
        .listRowBackground(
            BLCardRowBackground(
                dividerLeadingInset: BLSpacing.large,
                dividerTrailingInset: BLSpacing.large,
                horizontalInset: BLCardRowMetrics.horizontalInset,
                position: position
            )
        )
    }

    /// 建立開團列卡片內部內容，目前詳情的開團在內容後方以淺藍圓角底標示
    ///
    /// - Parameters:
    ///   - campaign: 對應的開團
    ///   - isSelected: 是否為目前詳情對應的開團
    /// - Returns: 開團列內容 view
    func rowContent(_ campaign: Campaign, isSelected: Bool) -> some View {
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
        .background {
            if isSelected {
                // 與訂單列同色同圓角，內縮後角落不超出卡片圓角
                RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous)
                    .inset(by: BLSpacing.extraSmall)
                    .fill(.blAccent.opacity(0.12))
            }
        }
        .contentShape(Rectangle())
    }

    /// 建立開團列長按選單
    ///
    /// - Parameter campaignID: 對應的開團識別值
    /// - Returns: 長按選單 view
    @ViewBuilder
    func rowContextMenu(campaignID: Campaign.ID) -> some View {
        Button {
            onEdit(campaignID)
        } label: {
            Label("common.action.button.edit", systemImage: "pencil")
        }

        Button(role: .destructive) {
            onDelete(campaignID)
        } label: {
            Label("common.action.button.delete", systemImage: "trash")
        }
    }
}

// MARK: - Private Method

private extension CampaignSectionList {

    /// 計算區段標題列的底部內距；下方緊接子標題時卡片的外緣留白已由子標題的內距承擔
    ///
    /// - Parameter section: 要呈現的頂層區段
    /// - Returns: 區段標題列的底部內距
    func sectionTitleBottomInset(_ section: CampaignDateSection) -> CGFloat {
        let isFollowedBySubgroupTitle = section.subgroups.first?.title != nil
        return isFollowedBySubgroupTitle
            ? BLSpacing.small
            : BLSpacing.small - BLCardRowMetrics.edgeRoom
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
            sections: CampaignDateSectionBuilder.sections(
                for: Campaign.sampleCampaigns,
                statusFilter: nil,
                grouping: .day,
                calendar: calendar
            ),
            selection: .constant(nil),
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
            sections: CampaignDateSectionBuilder.sections(
                for: Campaign.sampleCampaigns,
                statusFilter: nil,
                grouping: .year,
                calendar: calendar
            ),
            selection: .constant(nil),
            summaries: CampaignListFeature.RowSummaries(
                byName: CampaignSummary.batch(
                    campaignNames: Campaign.sampleCampaigns.map(\.name),
                    orders: LedgerOrder.sampleCampaignOrders
                )
            )
        )
    }
}
