//
//  CampaignDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 開團詳情的清單容器與編輯、狀態、結團、刪除選單
struct CampaignDetailView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<CampaignDetailFeature>

    // MARK: - Body

    /// 有內容時呈現三個詳情區段，開團不存在時顯示空狀態
    var body: some View {
        Group {
            if let content = store.content {
                detail(for: content)
            } else {
                missingCampaign
            }
        }
        .navigationTitle(Text("開團詳情"))
        .navigationBarTitleDisplayMode(.inline)
        // 結團與刪除確認、寫入與提醒錯誤都由開團容器的 alert 呈現
        // 收款錯誤由 `OrdersView` 的 alert 呈現
    }
}

// MARK: - Private Views

private extension CampaignDetailView {

    /// 開團已不存在時的空狀態
    var missingCampaign: some View {
        ContentUnavailableView("開團不存在", systemImage: "shippingbox")
    }

    /// 開團詳情清單，依序組合資訊、結算與分貨三區段
    ///
    /// - Parameter content: 由詳情 Feature 組好的開團、彙總、可見分貨列與提醒連結
    /// - Returns: 詳情清單與工具列
    func detail(for content: CampaignDetailContent) -> some View {
        List {
            CampaignDetailInfoSection(
                campaign: content.campaign,
                reminderLink: content.reminderLink
            )

            CampaignDetailSettlementSection(summary: content.summary)

            CampaignDetailDistributionSection(
                emptyMessage: store.distributionEmptyMessage,
                isShowingUnpaidOnly: store.isShowingUnpaidOnly,
                onReceiptToggle: {
                    store.send(.view(.receiptToggleTapped($0)))
                },
                onUnpaidOnlyChange: {
                    store.send(.view(.unpaidOnlyToggled($0)))
                },
                rows: content.distribution
            )
        }
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailRoot)
        .toolbar {
            actionsToolbar(for: content)
        }
    }

    /// 工具列的更多選單：編輯、改狀態、結團與刪除
    ///
    /// - Parameter content: 目前的詳情內容
    /// - Returns: 工具列內容
    @ToolbarContentBuilder
    func actionsToolbar(for content: CampaignDetailContent) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    store.send(.view(.editTapped))
                } label: {
                    Label("編輯開團", systemImage: "pencil")
                }
                .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailEditButton)

                Picker("狀態", selection: statusBinding(for: content.campaign)) {
                    ForEach(CampaignStatus.allCases) {
                        Text(LocalizedStringKey($0.title))
                            .tag($0)
                    }
                }

                Button {
                    store.send(.view(.settleTapped))
                } label: {
                    Label {
                        Text(content.settleActionTitle)
                    } icon: {
                        Image(systemName: "checkmark.seal")
                    }
                }
                .disabled(content.campaign.isSettled)
                .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSettleButton)

                Divider()

                // 列表的長按刪除保留，這裡提供不依賴手勢的可見替代入口
                Button(role: .destructive) {
                    store.send(.view(.deleteTapped))
                } label: {
                    Label("刪除開團", systemImage: "trash")
                }
                .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailDeleteButton)
            } label: {
                Label("更多", systemImage: "ellipsis.circle")
            }
            .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailMoreButton)
        }
    }
}

// MARK: - Private Method

private extension CampaignDetailView {

    /// 狀態選擇器的 binding，選取後送出 `statusChanged`
    ///
    /// - Parameter campaign: 目前的開團
    /// - Returns: 對應的狀態 binding
    func statusBinding(for campaign: Campaign) -> Binding<CampaignStatus> {
        Binding {
            campaign.status
        } set: {
            store.send(.view(.statusChanged($0)))
        }
    }
}

// MARK: - Preview

#Preview("開團詳情") {
    let previewState = CampaignDetailFeature.State(
        campaignID: "CMP-SAMPLE-KR-APR",
        campaigns: SharedReader(value: Campaign.sampleCampaigns),
        orders: SharedReader(value: LedgerOrder.sampleCampaignOrders),
        reminderLinks: SharedReader(value: [:]),
        isShowingUnpaidOnly: Shared(value: false)
    )

    return NavigationStack {
        CampaignDetailView(
            store: Store(initialState: previewState) {
                CampaignDetailFeature()
            }
        )
    }
}

#Preview("開團不存在") {
    let previewState = CampaignDetailFeature.State(
        campaignID: "CMP-MISSING",
        campaigns: SharedReader(value: Campaign.sampleCampaigns),
        orders: SharedReader(value: LedgerOrder.sampleCampaignOrders),
        reminderLinks: SharedReader(value: [:]),
        isShowingUnpaidOnly: Shared(value: false)
    )

    return NavigationStack {
        CampaignDetailView(
            store: Store(initialState: previewState) {
                CampaignDetailFeature()
            }
        )
    }
}
