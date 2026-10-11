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

    // MARK: - Properties

    /// 開團列表的狀態與事件來源，由父層以 `store.scope` 傳入
    @Bindable var store: StoreOf<CampaignListFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 依載入狀態切換內容，並掛上根標題、工具列與載入任務
    var body: some View {
        content
            .task {
                // 載入結果由多個分頁共用，不隨列表消失而取消
                store.send(.view(.task))
            }
            .rootNavigationTitle("orders.detail.title.campaigns", language: language)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    filterMenu

                    addCampaignButton
                }
            }
    }
}

// MARK: - Private Views

private extension CampaignListView {

    /// 工具列的篩選與分組選單
    var filterMenu: some View {
        Menu {
            Picker("campaigns.list.label.campaignStatus", selection: statusFilterBinding) {
                Text("common.action.label.all")
                    .tag(nil as CampaignStatus?)

                ForEach(CampaignStatus.allCases) {
                    statusFilterOption($0)
                }
            }
            .pickerStyle(.inline)

            Menu("campaigns.list.label.display") {
                Picker("campaigns.list.label.group", selection: groupingBinding) {
                    ForEach(CampaignGrouping.allCases) {
                        Text(LocalizedStringKey($0.title))
                            .tag($0)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Label("orders.list.label.filterGroup", systemImage: iconName)
        }
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.filterMenuButton)
    }

    /// 工具列的「新增開團」按鈕
    var addCampaignButton: some View {
        Button {
            store.send(.view(.newCampaignTapped))
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel(Text("campaigns.list.label.addCampaign"))
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.addButton)
    }

    /// 完全沒有開團時的空狀態
    var emptyState: some View {
        ContentUnavailableView(
            "orders.edit.label.campaigns",
            systemImage: "shippingbox",
            description: Text("campaigns.list.message.tapTopright")
        )
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.listEmptyState)
    }

    /// 有開團但目前狀態篩選下沒有符合者時的空狀態
    var filteredEmptyState: some View {
        ContentUnavailableView(
            "campaigns.list.label.matchingCampaigns",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("campaigns.list.message.campaignsMatchCurrent")
        )
    }

    /// 載入完成後依有無開團與篩選結果，顯示空狀態或區段清單
    @ViewBuilder
    var loadedContent: some View {
        if store.campaigns.isEmpty {
            emptyState
        } else {
            let sections = store.dateSections

            if let dateContext = store.dateContext, !sections.isEmpty {
                sectionList(sections, dateContext: dateContext)
            } else {
                filteredEmptyState
            }
        }
    }

    /// 依載入狀態切換載入失敗畫面、載入中指示或載入完成的內容
    @ViewBuilder
    var content: some View {
        switch store.loadState {
        case .failed(let message):
            loadFailure(message: message)

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            loadedContent
        }
    }

    /// 狀態篩選選項
    ///
    /// - Parameter status: 對應的開團狀態
    /// - Returns: 選項 view
    func statusFilterOption(_ status: CampaignStatus) -> some View {
        Text(LocalizedStringKey(status.title))
            .tag(CampaignStatus?.some(status))
    }

    /// 載入失敗畫面與重試鍵
    ///
    /// - Parameter message: 持續顯示的失敗訊息
    /// - Returns: 載入失敗 view
    func loadFailure(message: String) -> some View {
        BLLoadFailureView(
            message: message,
            retryIdentifier: BLAccessibilityID.Campaigns.listLoadFailureRetryButton
        ) {
            store.send(.view(.retryTapped))
        }
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.listLoadFailure)
    }

    /// 依日期區段呈現開團，操作一律轉成列表的 view action
    ///
    /// - Parameters:
    ///   - sections: 已依篩選與分組算好的日期區段
    ///   - dateContext: 列表記錄的現在時間與行事曆
    /// - Returns: 區段清單 view
    func sectionList(
        _ sections: [CampaignDateSection],
        dateContext: CampaignDateContext
    ) -> some View {
        CampaignSectionList(
            dateContext: dateContext,
            onDelete: {
                store.send(.view(.deleteCampaignTapped($0)))
            },
            onEdit: {
                store.send(.view(.editCampaignTapped($0)))
            },
            onSelect: {
                store.send(.view(.campaignTapped($0)))
            },
            sections: sections,
            showsOpenDate: store.grouping == .year,
            summaries: store.rowSummaries
        )
    }
}

// MARK: - Private Method

private extension CampaignListView {

    /// 篩選與分組選單的圖示，有套用狀態篩選時改用實心圖示
    var iconName: String {
        store.statusFilter == nil
            ? "line.3.horizontal.decrease.circle"
            : "line.3.horizontal.decrease.circle.fill"
    }

    /// 狀態篩選 binding；選取後送出 `statusFilterSelected`
    var statusFilterBinding: Binding<CampaignStatus?> {
        Binding {
            store.statusFilter
        } set: {
            store.send(.view(.statusFilterSelected($0)))
        }
    }

    /// 分組 binding；選取後送出 `groupingSelected`
    var groupingBinding: Binding<CampaignGrouping> {
        Binding {
            store.grouping
        } set: {
            store.send(.view(.groupingSelected($0)))
        }
    }
}

// MARK: - Preview

#Preview("開團列表") {
    var state = CampaignListFeature.State(
        campaigns: SharedReader(value: Campaign.sampleCampaigns),
        orders: SharedReader(value: LedgerOrder.sampleCampaignOrders)
    )
    state.$hasLoaded = SharedReader(value: true)
    state.dateContext = CampaignDateContext(
        now: Campaign.sampleCampaigns.first?.openDate ?? .distantPast,
        calendar: Calendar(identifier: .gregorian)
    )

    return NavigationStack {
        CampaignListView(
            store: Store(initialState: state) {
                CampaignListFeature()
            },
            language: .traditionalChinese
        )
    }
}

#Preview("開團列表載入中") {
    let state = CampaignListFeature.State(
        campaigns: SharedReader(value: []),
        orders: SharedReader(value: [])
    )

    return NavigationStack {
        CampaignListView(
            store: Store(initialState: state) {
                EmptyReducer()
            },
            language: .traditionalChinese
        )
    }
}

#Preview("開團列表空狀態") {
    let state = CampaignListFeature.State(
        campaigns: SharedReader(value: []),
        orders: SharedReader(value: [])
    )
    state.$hasLoaded = SharedReader(value: true)

    return NavigationStack {
        CampaignListView(
            store: Store(initialState: state) {
                EmptyReducer()
            },
            language: .traditionalChinese
        )
    }
}

#Preview("開團列表載入失敗") {
    let state = CampaignListFeature.State(
        campaigns: SharedReader(value: []),
        orders: SharedReader(value: [])
    )
    state.$errorMessage = SharedReader(value: "campaigns.list.message.campaignsLoadedTry")

    return NavigationStack {
        CampaignListView(
            store: Store(initialState: state) {
                EmptyReducer()
            },
            language: .traditionalChinese
        )
    }
}
