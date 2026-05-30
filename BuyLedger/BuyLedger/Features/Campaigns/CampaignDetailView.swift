//
//  CampaignDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 開團詳情：開團資訊、結團結算 (收款面與損益面)、客戶分貨清單與逐筆收款勾稽。
///
/// 吃 ``RootFeature`` store：開團本身取自 `store.campaigns`，分貨與結算由 ``CampaignSummary`` 自 `store.orders.orders` 投影。
struct CampaignDetailView: View {

    // MARK: - View Properties

    /// App 根層級 store。
    @Bindable var store: StoreOf<RootFeature>

    /// 要顯示的開團識別值。
    let campaignID: Campaign.ID

    /// 是否只顯示未收款的分貨列。
    @State private var showsUnpaidOnly = false

    // MARK: - Computed Properties

    /// 目前顯示的開團；若已被刪除則為 `nil`。
    private var campaign: Campaign? {
        store.campaigns.campaigns.first { $0.id == campaignID }
    }

    /// 由訂單投影的彙總。
    private var summary: CampaignSummary {
        CampaignSummary(campaignName: campaign?.name ?? "", orders: store.orders.orders)
    }

    // MARK: - View Body

    /// 開團詳情的畫面內容。
    var body: some View {
        Group {
            if let campaign {
                detail(for: campaign)
            } else {
                ContentUnavailableView("開團不存在", systemImage: "shippingbox")
            }
        }
        .navigationTitle("開團詳情")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            if let campaign {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            store.send(.campaigns(.editCampaignTapped(campaign.id)))
                        } label: {
                            Label("編輯開團", systemImage: "pencil")
                        }

                        Picker("狀態", selection: statusBinding(for: campaign)) {
                            ForEach(CampaignStatus.allCases) { status in
                                Text(status.title).tag(status)
                            }
                        }

                        Button {
                            store.send(.campaigns(.settleTapped(campaign.id)))
                        } label: {
                            Label(campaign.isSettled ? "已結團" : "結團結算", systemImage: "checkmark.seal")
                        }
                        .disabled(campaign.isSettled)
                    } label: {
                        Label("更多", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - ViewBuilder

private extension CampaignDetailView {

    /// 開團詳情主體。
    /// - Parameter campaign: 目前的開團。
    /// - Returns: 詳情 list view。
    func detail(for campaign: Campaign) -> some View {
        List {
            infoSection(campaign: campaign)
            settlementSection
            distributionSection
        }
    }

    /// 開團資訊區段。
    /// - Parameter campaign: 目前的開團。
    /// - Returns: 資訊區段 view。
    @ViewBuilder
    func infoSection(campaign: Campaign) -> some View {
        Section("開團資訊") {
            Text(campaign.name)
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            LabeledContent("狀態") {
                HStack(spacing: BLSpacing.extraSmall) {
                    BLStatusPill(campaign.status.title, tone: CampaignStatusStyle.tone(for: campaign.status))
                    if campaign.isSettled {
                        BLStatusPill("已結團", tone: .neutral, showsIndicator: false)
                    }
                }
            }

            LabeledContent("開團日期", value: CampaignFormatters.shortDate(campaign.openDate))

            if let closeDate = campaign.closeDate {
                LabeledContent("結單日期", value: CampaignFormatters.shortDate(closeDate))
            }

            if let settledDate = campaign.settledDate {
                LabeledContent("結團日期", value: CampaignFormatters.shortDate(settledDate))
            }

            if !campaign.notes.isEmpty {
                Text(campaign.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 結團結算區段：收款面與損益面。
    var settlementSection: some View {
        Section("結團結算") {
            LabeledContent("應收", value: CampaignFormatters.twd(summary.receivables))
            LabeledContent("已收", value: CampaignFormatters.twd(summary.receivedAmount))
            LabeledContent("未收", value: CampaignFormatters.twd(summary.outstandingAmount))

            BLProgressBar(
                title: "收款進度",
                value: summary.receivedRatio,
                tint: .green,
                trailingText: percentString(summary.receivedRatio)
            )

            BLProgressBar(
                title: "到貨進度",
                value: summary.deliveryRatio,
                trailingText: "\(summary.deliveredCount)/\(summary.activeCount)"
            )

            LabeledContent("總成本", value: CampaignFormatters.twd(summary.totalCost))
            LabeledContent("毛利", value: CampaignFormatters.twd(summary.profit))
            LabeledContent("利潤率", value: summary.margin.formatted(.percent.precision(.fractionLength(1))))
        }
    }

    /// 客戶分貨區段：可切換只看未收款，每列可展開檢視品項與逐筆收款。
    @ViewBuilder
    var distributionSection: some View {
        let rows = showsUnpaidOnly ? summary.unpaidDistribution : summary.distribution

        Section {
            Toggle("只看未收款", isOn: $showsUnpaidOnly)

            if rows.isEmpty {
                Text(showsUnpaidOnly ? "全部已收款。" : "尚無歸屬此開團的訂單。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows) { row in
                    DisclosureGroup {
                        ForEach(row.orders) { order in
                            orderRow(order)
                        }
                    } label: {
                        distributionLabel(row)
                    }
                }
            }
        } header: {
            Text("客戶分貨")
        }
    }

    /// 分貨列標題：客戶、件數、金額與收款標記。
    /// - Parameter row: 分貨列。
    /// - Returns: 標題 view。
    func distributionLabel(_ row: CampaignDistributionRow) -> some View {
        HStack(spacing: BLSpacing.small) {
            Image(systemName: row.isFullyReceived ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(row.isFullyReceived ? Color.green : Color.secondary)

            Text(row.customerName)
                .font(.subheadline.weight(.medium))

            Spacer(minLength: 0)

            Text("\(row.totalQuantity) 件 · \(CampaignFormatters.twd(row.totalAmount))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    /// 分貨列展開後的單筆訂單：品項摘要與收款狀態切換。
    /// - Parameter order: 該客戶在此開團的訂單。
    /// - Returns: 訂單列 view。
    func orderRow(_ order: LedgerOrder) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(order.id)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(order.itemSummary)
                .font(.footnote)

            HStack {
                Text(CampaignFormatters.twd(order.chargedAmount))
                    .font(.footnote.weight(.medium))
                    .monospacedDigit()

                Spacer(minLength: 0)

                Button {
                    store.send(.orders(.receiptStatusChanged(
                        order.id,
                        order.paymentReceiptStatus == .received ? .pending : .received
                    )))
                } label: {
                    Label(
                        order.paymentReceiptStatus.title,
                        systemImage: order.paymentReceiptStatus == .received ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.caption)
                    .foregroundStyle(order.paymentReceiptStatus == .received ? Color.green : Color.accentColor)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.leading, BLSpacing.small)
    }
}

// MARK: - Private Method

private extension CampaignDetailView {

    /// 狀態 Picker 的 binding：選取後送出 ``CampaignFeature/Action/statusChanged(_:_:)``。
    /// - Parameter campaign: 目前的開團。
    /// - Returns: 對應的狀態 binding。
    func statusBinding(for campaign: Campaign) -> Binding<CampaignStatus> {
        Binding(
            get: { campaign.status },
            set: { store.send(.campaigns(.statusChanged(campaign.id, $0))) }
        )
    }

    /// 將比例格式化為百分比字串。
    /// - Parameter value: 介於 0 與 1 之間的比例。
    /// - Returns: 含整數百分比的字串。
    func percentString(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}

// MARK: - Preview

#Preview("開團詳情") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleCampaignOrders
        state.orders.hasLoaded = true
        state.campaigns.campaigns = Campaign.sampleCampaigns
        state.campaigns.hasLoaded = true
        return state
    }()

    return NavigationStack {
        CampaignDetailView(
            store: Store(initialState: previewState) {
                RootFeature()
            },
            campaignID: "CMP-SAMPLE-KR-APR"
        )
    }
}
