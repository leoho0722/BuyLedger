//
//  CampaignDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 開團詳情：開團資訊、結團結算 (收款面與損益面)、客戶分貨清單與逐筆收款勾稽
///
/// 吃 ``RootFeature`` store：開團本身取自 `store.campaigns`，分貨與結算由 ``CampaignSummary`` 自 `store.orders.orders` 投影
struct CampaignDetailView: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 要顯示的開團識別值
    let campaignID: Campaign.ID

    /// 目前顯示的開團；若已被刪除則為 `nil`
    private var campaign: Campaign? {
        store.campaigns.campaigns.first { $0.id == campaignID }
    }

    // MARK: - View Body

    /// 開團詳情的畫面內容
    var body: some View {
        Group {
            if let campaign {
                detail(for: campaign)
            } else {
                ContentUnavailableView("開團不存在", systemImage: "shippingbox")
            }
        }
        .navigationTitle(Text("開團詳情"))
        .navigationBarTitleDisplayMode(.inline)
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
                                Text(LocalizedStringKey(status.title)).tag(status)
                            }
                        }

                        Button {
                            store.send(.campaigns(.settleTapped(campaign.id)))
                        } label: {
                            Label(
                                LocalizedStringKey(campaign.isSettled ? "已結團" : "結團結算"),
                                systemImage: "checkmark.seal"
                            )
                        }
                        .disabled(campaign.isSettled)

                        Divider()

                        // 列表的長按刪除保留，這裡提供不依賴手勢的可見替代入口
                        Button(role: .destructive) {
                            store.send(.campaigns(.deleteCampaignTapped(campaign.id)))
                        } label: {
                            Label("刪除開團", systemImage: "trash")
                        }
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

    /// 開團詳情主體
    /// - Parameter campaign: 目前的開團
    /// - Returns: 詳情 list view
    @ViewBuilder
    func detail(for campaign: Campaign) -> some View {
        let summary = CampaignSummary(campaignName: campaign.name, orders: store.orders.orders)
        List {
            infoSection(campaign: campaign)
            settlementSection(summary)
            distributionSection(summary)
        }
    }

    /// 開團資訊區段
    /// - Parameter campaign: 目前的開團
    /// - Returns: 資訊區段 view
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

            LabeledContent("開團日期", value: CampaignFormatters.shortDate(campaign.openDate, locale: locale))

            if let closeDate = campaign.closeDate {
                LabeledContent("結單日期", value: CampaignFormatters.shortDate(closeDate, locale: locale))
            }

            if let settledDate = campaign.settledDate {
                LabeledContent("結團日期", value: CampaignFormatters.shortDate(settledDate, locale: locale))
            }

            if let reminderLink = store.campaigns.reminderLinks[campaign.id] {
                // 純顯示：有新增提醒時才顯示其日期與提示時間 (新增/移除/改時間走「編輯開團」)
                LabeledContent("訂購提醒", value: CampaignFormatters.reminderTimestamp(reminderLink.reminderTimestamp, locale: locale))
            }

            if !campaign.notes.isEmpty {
                Text(campaign.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 結團結算區段：收款面與損益面
    /// - Parameter summary: 由 ``detail(for:)`` 一次算好的開團彙總
    /// - Returns: 結算區段 view
    @ViewBuilder
    func settlementSection(_ summary: CampaignSummary) -> some View {
        Section("結團結算") {
            LabeledContent("應收", value: CampaignFormatters.twd(summary.receivables, locale: locale))
            LabeledContent("已收", value: CampaignFormatters.twd(summary.receivedAmount, locale: locale))
            LabeledContent("未收", value: CampaignFormatters.twd(summary.outstandingAmount, locale: locale))

            BLProgressBar(
                title: "收款進度",
                value: summary.receivedRatio,
                tint: .green,
                trailingText: percentString(summary.receivedRatio)
            )

            BLProgressBar(
                title: "到貨進度",
                value: summary.deliveryRatio,
                trailingText: "\(summary.arrivedCount)/\(summary.activeCount)"
            )

            LabeledContent("總成本", value: CampaignFormatters.twd(summary.totalCost, locale: locale))
            LabeledContent("毛利", value: CampaignFormatters.twd(summary.profit, locale: locale))
            LabeledContent(
                "利潤率",
                value: summary.margin.formatted(.percent.precision(.fractionLength(1)).locale(locale))
            )
        }
    }

    /// 客戶分貨區段：可切換只看未收款，每列可展開檢視品項與逐筆收款
    /// - Parameter summary: 由 ``detail(for:)`` 一次算好的開團彙總
    /// - Returns: 分貨區段 view
    @ViewBuilder
    func distributionSection(_ summary: CampaignSummary) -> some View {
        let showsUnpaidOnly = store.campaigns.showsUnpaidOnly
        let rows = showsUnpaidOnly ? summary.unpaidDistribution : summary.distribution

        Section {
            Toggle("只看未收款", isOn: unpaidOnlyBinding)

            if rows.isEmpty {
                Text(LocalizedStringKey(
                    showsUnpaidOnly ? "全部已收款。" : "尚無歸屬此開團的訂單。"
                ))
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

    /// 分貨列標題：客戶、件數、金額與收款標記
    /// - Parameter row: 分貨列
    /// - Returns: 標題 view
    @ViewBuilder
    func distributionLabel(_ row: CampaignDistributionRow) -> some View {
        HStack(spacing: BLSpacing.small) {
            Image(systemName: row.isFullyReceived ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(row.isFullyReceived ? Color.green : Color.secondary)

            Text(row.customerName)
                .font(.subheadline.weight(.medium))

            Spacer(minLength: 0)

            Text("\(row.totalQuantity) 件 · \(CampaignFormatters.twd(row.totalAmount, locale: locale))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    /// 分貨列展開後的單筆訂單：品項摘要與收款狀態切換
    /// - Parameter order: 該客戶在此開團的訂單
    /// - Returns: 訂單列 view
    @ViewBuilder
    func orderRow(_ order: LedgerOrder) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(order.id)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(order.itemSummary)
                .font(.footnote)

            HStack {
                Text(CampaignFormatters.twd(order.chargedAmount, locale: locale))
                    .font(.footnote.weight(.medium))
                    .monospacedDigit()

                Spacer(minLength: 0)

                Button {
                    store.send(.orders(.receiptStatusChanged(
                        order.id,
                        order.paymentReceiptStatus == .received ? .pending : .received
                    )))
                } label: {
                    Label {
                        Text(LocalizedStringKey(order.paymentReceiptStatus.title))
                    } icon: {
                        Image(systemName: order.paymentReceiptStatus == .received ? "checkmark.circle.fill" : "circle")
                    }
                    .font(.caption)
                    .foregroundStyle(order.paymentReceiptStatus == .received ? Color.green : Color.accentColor)
                    // 這顆會改資料且無確認，命中區宣告在標籤內部撐到 44pt；視覺尺寸不變
                    .frame(minHeight: BLHitTarget.minimum)
                    .contentShape(.rect)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.leading, BLSpacing.small)
    }
}

// MARK: - Private Method

private extension CampaignDetailView {

    /// 狀態 Picker 的 binding：選取後送出 ``CampaignFeature/Action/statusChanged(_:_:)``
    /// - Parameter campaign: 目前的開團
    /// - Returns: 對應的狀態 binding
    func statusBinding(for campaign: Campaign) -> Binding<CampaignStatus> {
        Binding(
            get: { campaign.status },
            set: { store.send(.campaigns(.statusChanged(campaign.id, $0))) }
        )
    }

    /// 「只看未收款」Toggle 的 binding：切換後送出 ``CampaignFeature/Action/unpaidOnlyToggled(_:)``
    var unpaidOnlyBinding: Binding<Bool> {
        Binding(
            get: { store.campaigns.showsUnpaidOnly },
            set: { store.send(.campaigns(.unpaidOnlyToggled($0))) }
        )
    }

    /// 依 App 選定 locale 將比例格式化為百分比字串
    /// - Parameter value: 介於 0 與 1 之間的比例
    /// - Returns: 含整數百分比的字串
    func percentString(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)).locale(locale))
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
