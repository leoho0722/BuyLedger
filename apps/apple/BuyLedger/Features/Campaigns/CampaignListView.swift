//
//  CampaignListView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 開團列表：顯示每個開團的狀態與彙總進度 (到貨／收款)，點擊進入詳情
///
/// 沿用 ``DashboardView`` / ``InsightsView`` 直接吃 ``RootFeature`` store 的作法，以便同時讀取開團 (`store.campaigns`) 與訂單 (`store.orders.orders`)；分貨與進度由 ``CampaignSummary`` 自訂單投影
struct CampaignListView: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// 用於日期區段「今天／昨天」相對標題的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 開團日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar

    // MARK: - View Body

    /// 開團列表的畫面內容
    var body: some View {
        NavigationStack(path: campaignPath) {
            content
                .navigationTitle("開團")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Menu {
                            Picker("開團狀態", selection: statusFilterBinding) {
                                Text("全部").tag(CampaignStatus?.none)
                                ForEach(CampaignStatus.allCases) { status in
                                    Text(status.title).tag(CampaignStatus?.some(status))
                                }
                            }
                            .pickerStyle(.inline)

                            Menu("顯示方式") {
                                Picker("分組方式", selection: groupingBinding) {
                                    ForEach(CampaignGrouping.allCases) { grouping in
                                        Text(grouping.title).tag(grouping)
                                    }
                                }
                                .pickerStyle(.inline)
                            }
                        } label: {
                            Label(
                                "篩選與分組",
                                systemImage: store.campaigns.statusFilter == nil
                                    ? "line.3.horizontal.decrease.circle"
                                    : "line.3.horizontal.decrease.circle.fill"
                            )
                        }

                        Button {
                            store.send(.campaigns(.newCampaignTapped))
                        } label: {
                            Label("新增開團", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(for: String.self) { id in
                    CampaignDetailView(store: store, campaignID: id)
                }
        }
        .sheet(
            item: $store.scope(state: \.campaigns.editCampaign, action: \.campaigns.editCampaign)
        ) { editStore in
            CampaignEditView(store: editStore)
        }
        .alert(
            $store.scope(state: \.campaigns.deletionConfirmation, action: \.campaigns.deletionConfirmation)
        )
        .task {
            await store.send(.campaigns(.task)).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension CampaignListView {

    /// 依載入與資料狀態切換列表、空狀態或載入中
    @ViewBuilder
    var content: some View {
        if store.campaigns.campaigns.isEmpty {
            if store.campaigns.isLoading && !store.campaigns.hasLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "尚無開團",
                    systemImage: "shippingbox",
                    description: Text("點右上角「＋」建立第一個開團，把訂單歸到團裡即可追蹤進度。")
                )
            }
        } else {
            let sections = store.campaigns.dateSections(referenceDate: date.now, calendar: calendar)
            if sections.isEmpty {
                ContentUnavailableView(
                    "沒有符合的開團",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("目前的狀態篩選下沒有開團，換個篩選或選「全部」。")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: BLSpacing.large) {
                        ForEach(sections) { section in
                            sectionView(section)
                        }
                    }
                    .padding(.top, BLSpacing.small)
                    .padding(.bottom, BLSpacing.large)
                }
            }
        }
    }

    /// 單一頂層日期區段：頂層標題 (月／年／日) + 其下各子群組
    /// - Parameter section: 要呈現的頂層區段
    /// - Returns: 區段 view
    @ViewBuilder
    func sectionView(_ section: CampaignDateSection) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(section.title)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, BLSpacing.large)

            ForEach(section.subgroups) { subgroup in
                subgroupView(subgroup)
            }
        }
    }

    /// 單一子群組：可選的日期小標 (完全自繪、可控上下間距) + 該群組的開團卡片
    /// - Parameter subgroup: 要呈現的子群組
    /// - Returns: 子群組 view
    @ViewBuilder
    func subgroupView(_ subgroup: CampaignSubgroup) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            if let subTitle = subgroup.title {
                Text(subTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, BLSpacing.large)
                    .padding(.top, BLSpacing.small)
            }

            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(subgroup.campaigns.enumerated()), id: \.element.id) { index, campaign in
                        campaignRowButton(campaign)

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
    /// - Parameter campaign: 對應的開團
    /// - Returns: 開團列 view
    @ViewBuilder
    func campaignRowButton(_ campaign: Campaign) -> some View {
        Button {
            store.send(.campaigns(.campaignSelected(campaign.id)))
        } label: {
            CampaignRow(
                campaign: campaign,
                summary: CampaignSummary(
                    campaignName: campaign.name,
                    orders: store.orders.orders
                ),
                dateText: store.campaigns.grouping == .year
                    ? CampaignFormatters.dayWithWeekday(campaign.openDate)
                    : nil
            )
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.send(.campaigns(.editCampaignTapped(campaign.id)))
            } label: {
                Label("編輯", systemImage: "pencil")
            }

            Button(role: .destructive) {
                store.send(.campaigns(.deleteCampaignTapped(campaign.id)))
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }

    /// 以 ``CampaignFeature/State/selectedCampaignID`` 驅動的 `NavigationStack` 路徑 (0 或 1 筆)
    ///
    /// 採用原生值導向的 `navigationDestination(for:)` 而非 `navigationDestination(item:)`：後者在低於 iOS 17 的部署目標會解析到 SwiftUINavigation 的 backport overload，導致連結到該符號；改用以開團 id 為值的路徑可避開此相依，並同時支援列表點擊與 Dashboard／Insights 的深連結
    var campaignPath: Binding<[String]> {
        Binding(
            get: { store.campaigns.selectedCampaignID.map { [$0] } ?? [] },
            set: { store.send(.campaigns(.campaignSelected($0.last))) }
        )
    }

    /// 工具列篩選 Menu 用的 binding：選取後送出 ``CampaignFeature/Action/statusFilterSelected(_:)``
    var statusFilterBinding: Binding<CampaignStatus?> {
        Binding(
            get: { store.campaigns.statusFilter },
            set: { store.send(.campaigns(.statusFilterSelected($0))) }
        )
    }

    /// 工具列分組 Menu 用的 binding：選取後送出 ``CampaignFeature/Action/groupingSelected(_:)``
    var groupingBinding: Binding<CampaignGrouping> {
        Binding(
            get: { store.campaigns.grouping },
            set: { store.send(.campaigns(.groupingSelected($0))) }
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

    /// 區段標題粗於「日」時 (按月／按年) 於列上顯示的開團日期；`nil` 表示不顯示 (按日分組時日期已在區段標題)
    let dateText: String?

    // MARK: - View Body

    /// 單列的畫面內容
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            if let dateText {
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: BLSpacing.small) {
                Text(campaign.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                    BLStatusPill(campaign.status.title, tone: CampaignStatusStyle.tone(for: campaign.status))

                    if campaign.isSettled {
                        BLStatusPill("已結團", tone: .neutral, showsIndicator: false)
                    }
                }
            }

            Text("\(summary.orderCount) 筆 · \(CampaignFormatters.twd(summary.receivables))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            BLProgressBar(
                title: "到貨",
                value: summary.deliveryRatio,
                trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
            )

            BLProgressBar(
                title: "收款",
                value: summary.receivedRatio,
                tint: .green,
                trailingText: CampaignFormatters.twd(summary.receivedAmount)
            )
        }
    }
}

// MARK: - Preview

#Preview("開團列表") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleCampaignOrders
        state.orders.hasLoaded = true
        state.campaigns.campaigns = Campaign.sampleCampaigns
        state.campaigns.hasLoaded = true
        return state
    }()

    return CampaignListView(
        store: Store(initialState: previewState) {
            RootFeature()
        }
    )
}
