//
//  CampaignListView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 開團列表：顯示每個開團的狀態與彙總進度 (到貨／收款)，點擊進入詳情
struct CampaignListView: View {
    
    // MARK: - View Properties
    
    /// 開團功能 store
    @Bindable var store: StoreOf<CampaignFeature>
    
    /// App 目前選用的顯示語系
    let language: AppLanguage
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 日期區段標題使用的現在時間
    @Dependency(\.date) private var date
    
    /// 開團日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar
    
    /// 篩選與分組圖示
    private var iconName: String {
        store.statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
    }
    
    // MARK: - View Body
    
    /// 開團列表的畫面內容
    var body: some View {
        NavigationStack(path: campaignPath) {
            content
                .rootNavigationTitle("開團", language: language)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        filterMenu
                        addCampaignButton
                    }
                }
                .navigationDestination(for: String.self) { id in
                    CampaignDetailView(store: store, campaignID: id)
                }
        }
        .sheet(
            item: $store.scope(state: \.editCampaign, action: \.editCampaign)
        ) { editStore in
            CampaignEditView(store: editStore)
        }
        // 列表與詳情各自處理刪除確認
        .alert(
            $store.scope(state: \.deletionConfirmation, action: \.deletionConfirmation)
        )
        .alert(
            $store.scope(state: \.noticeAlert, action: \.noticeAlert)
        )
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension CampaignListView {
    
    /// 建立狀態篩選選項 View
    /// - Parameter status: 對應的開團狀態
    /// - Returns: 選項 view
    @ViewBuilder
    func statusFilterOption(_ status: CampaignStatus) -> some View {
        Text(LocalizedStringKey(status.title)).tag(CampaignStatus?.some(status))
    }
    
    /// 工具列的篩選與分組選單；抽成獨立方法的理由同 ``statusFilterOption(_:)``
    @ViewBuilder
    var filterMenu: some View {
        Menu {
            Picker("開團狀態", selection: statusFilterBinding) {
                Text("全部").tag(CampaignStatus?.none)
                ForEach(CampaignStatus.allCases) { status in
                    statusFilterOption(status)
                }
            }
            .pickerStyle(.inline)
            
            Menu("顯示方式") {
                Picker("分組方式", selection: groupingBinding) {
                    ForEach(CampaignGrouping.allCases) { grouping in
                        Text(LocalizedStringKey(grouping.title)).tag(grouping)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Label("篩選與分組", systemImage: iconName)
        }
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.filterMenuButton)
    }
    
    /// 工具列的「新增開團」按鈕；抽成獨立方法的理由同 ``statusFilterOption(_:)``
    @ViewBuilder
    var addCampaignButton: some View {
        Button {
            store.send(.newCampaignTapped)
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel(Text("新增開團"))
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.addButton)
    }
    
    /// 依載入與資料狀態切換載入失敗畫面、列表或空狀態
    @ViewBuilder
    var content: some View {
        switch store.loadState {
        case let .failed(message):
            BLLoadFailureView(
                message: message,
                retryIdentifier: BLAccessibilityID.Campaigns.listLoadFailureRetryButton
            ) {
                store.send(.task)
            }
            .accessibilityIdentifier(BLAccessibilityID.Campaigns.listLoadFailure)
            
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded:
            if store.campaigns.isEmpty {
                ContentUnavailableView(
                    "尚無開團",
                    systemImage: "shippingbox",
                    description: Text("點右上角「＋」建立第一個開團，把訂單歸到團裡即可追蹤進度。")
                )
                .accessibilityIdentifier(BLAccessibilityID.Campaigns.listEmptyState)
            } else {
                let sections = store.state.dateSections(
                    referenceDate: date.now,
                    calendar: calendar,
                    locale: locale
                )
                if sections.isEmpty {
                    ContentUnavailableView(
                        "沒有符合的開團",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("目前的狀態篩選下沒有開團，換個篩選或選「全部」。")
                    )
                } else {
                    // 單次掃描訂單，批次建立各團的畫面投影
                    let campaignNames = sections.flatMap {
                        $0.subgroups.flatMap { $0.campaigns.map(\.name) }
                    }
                    let summaries = CampaignSummary.batch(
                        campaignNames: campaignNames, orders: store.orders)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: BLSpacing.large) {
                            ForEach(sections) { section in
                                sectionView(section, summaries: summaries)
                            }
                        }
                        .padding(.top, BLSpacing.small)
                        .padding(.bottom, BLSpacing.large)
                    }
                    .accessibilityIdentifier(BLAccessibilityID.Campaigns.listRoot)
                }
            }
        }
    }
    
    /// 單一頂層日期區段：頂層標題 (月／年／日) + 其下各子群組
    /// - Parameters:
    ///   - section: 要呈現的頂層區段
    ///   - summaries: 已由 ``content`` 批次投影好的開團名稱到彙總字典
    /// - Returns: 區段 view
    @ViewBuilder
    func sectionView(
        _ section: CampaignDateSection,
        summaries: [String: CampaignSummary]
    ) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(LocalizedStringKey(section.title))
                .font(BLTypographyStyle.subhead.font.weight(.bold))
                .padding(.horizontal, BLSpacing.large)
            
            ForEach(section.subgroups) { subgroup in
                subgroupView(subgroup, summaries: summaries)
            }
        }
    }
    
    /// 單一日期子群組與開團卡片
    /// - Parameters:
    ///   - subgroup: 要呈現的子群組
    ///   - summaries: 已由 ``content`` 批次投影好的開團名稱到彙總字典
    /// - Returns: 子群組 view
    @ViewBuilder
    func subgroupView(_ subgroup: CampaignSubgroup, summaries: [String: CampaignSummary])
    -> some View
    {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            if let subTitle = subgroup.title {
                Text(subTitle)
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(Color.blSecondaryLabel)
                    .padding(.horizontal, BLSpacing.large)
                    .padding(.top, BLSpacing.small)
            }
            
            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(subgroup.campaigns.enumerated()), id: \.element.id) {
                        index, campaign in
                        campaignRowButton(
                            campaign,
                            summary: summaries[campaign.name] ?? CampaignSummary(campaignName: campaign.name, orders: [])
                        )
                        
                        if index < subgroup.campaigns.count - 1 {
                            Divider()
                                .padding(.horizontal, BLSpacing.large)
                        }
                    }
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }
    
    /// 單一開團卡片列：點擊進詳情、長按 (contextMenu) 可編輯／刪除
    /// - Parameters:
    ///   - campaign: 對應的開團
    ///   - summary: 已由 ``content`` 批次投影好的該團彙總
    /// - Returns: 開團列 view
    @ViewBuilder
    func campaignRowButton(_ campaign: Campaign, summary: CampaignSummary) -> some View {
        Button {
            store.send(.campaignSelected(campaign.id))
        } label: {
            CampaignRow(
                campaign: campaign,
                summary: summary,
                dateText: store.grouping == .year ? CampaignFormatters.dayWithWeekday(campaign.openDate, locale: locale) : nil
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
                store.send(.editCampaignTapped(campaign.id))
            } label: {
                Label("編輯", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                store.send(.deleteCampaignTapped(campaign.id))
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Private Method

private extension CampaignListView {
    
    /// 目前開團詳情的導覽路徑
    var campaignPath: Binding<[String]> {
        Binding(
            get: { store.selectedCampaignID.map { [$0] } ?? [] },
            set: { store.send(.campaignSelected($0.last)) }
        )
    }
    
    /// 狀態篩選 binding；選取後送出 statusFilterSelected
    var statusFilterBinding: Binding<CampaignStatus?> {
        Binding(
            get: { store.statusFilter },
            set: { store.send(.statusFilterSelected($0)) }
        )
    }
    
    /// 分組 binding；選取後送出 groupingSelected
    var groupingBinding: Binding<CampaignGrouping> {
        Binding(
            get: { store.grouping },
            set: { store.send(.groupingSelected($0)) }
        )
    }
}

// MARK: - Campaign Row

/// 開團列表的單列：團名、狀態、筆數／金額與到貨／收款進度
private struct CampaignRow: View {
    
    // MARK: - View Properties
    
    /// 對應的開團
    let campaign: Campaign
    
    /// 由訂單投影的彙總
    let summary: CampaignSummary
    
    /// 按月或按年分組時顯示的開團日期；按日分組為 `nil`
    let dateText: String?
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    // MARK: - View Body
    
    /// 單列的畫面內容
    var body: some View {
        let palette = BLPalette()
        
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            if let dateText {
                Text(dateText)
                    .blTextStyle(.caption)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
            
            HStack(alignment: .top, spacing: BLSpacing.small) {
                Text(campaign.name)
                    .blTextStyle(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                    BLStatusPill(
                        campaign.status.title,
                        tone: CampaignStatusStyle.tone(for: campaign.status)
                    )
                    
                    if campaign.isSettled {
                        BLStatusPill("已結團", tone: .neutral, showsIndicator: false)
                    }
                }
            }
            
            Text(
                """
                \(summary.orderCount) 筆 · \
                \(CampaignFormatters.twd(summary.receivables, locale: locale))
                """
            )
            .blTextStyle(.subhead)
            .foregroundStyle(Color.blSecondaryLabel)
            
            BLProgressBar(
                title: "到貨",
                value: summary.deliveryRatio,
                trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
            )
            
            BLProgressBar(
                title: "收款",
                value: summary.receivedRatio,
                tint: palette.green,
                trailingText: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
            )
        }
        // 開團列合併成單一朗讀單位，VoiceOver 一次讀出主要資訊。
        // 否則輔助技術要逐一走過每個子元素
        .accessibilityElement(children: .combine)
        // 應收金額放在 accessibilityValue，讓 UI 測試讀取
        .accessibilityValue(CampaignFormatters.twd(summary.receivables, locale: locale))
    }
}

// MARK: - Preview

#Preview("開團列表") {
    let previewState: CampaignFeature.State = {
        var state = CampaignFeature.State()
        state.orders = LedgerOrder.sampleCampaignOrders
        state.campaigns = Campaign.sampleCampaigns
        state.hasLoaded = true
        return state
    }()
    
    return CampaignListView(
        store: Store(initialState: previewState) {
            CampaignFeature()
        },
        language: .traditionalChinese
    )
}
