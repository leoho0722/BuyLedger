//
//  CampaignDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftUI

/// 開團詳情、結算與客戶分貨清單
struct CampaignDetailView: View {
    
    // MARK: - View Properties
    
    /// 開團功能 store
    @Bindable var store: StoreOf<CampaignFeature>
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 要顯示的開團識別值
    let campaignID: Campaign.ID
    
    /// 目前顯示的開團；若已被刪除則為 `nil`
    private var campaign: Campaign? {
        store.campaigns.first { $0.id == campaignID }
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
                            store.send(.editCampaignTapped(campaign.id))
                        } label: {
                            Label("編輯開團", systemImage: "pencil")
                        }
                        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailEditButton)
                        
                        Picker("狀態", selection: statusBinding(for: campaign)) {
                            ForEach(CampaignStatus.allCases) { status in
                                Text(LocalizedStringKey(status.title)).tag(status)
                            }
                        }
                        
                        Button {
                            store.send(.settleTapped(campaign.id))
                        } label: {
                            Label(
                                LocalizedStringKey(campaign.isSettled ? "已結團" : "結團結算"),
                                systemImage: "checkmark.seal"
                            )
                        }
                        .disabled(campaign.isSettled)
                        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSettleButton)
                        
                        Divider()
                        
                        // 列表的長按刪除保留，這裡提供不依賴手勢的可見替代入口
                        Button(role: .destructive) {
                            store.send(.detailDeleteCampaignTapped(campaign.id))
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
        // 詳情頁的結團與刪除 alert 必須掛在最上層
        .alert(
            $store.scope(state: \.settleConfirmation, action: \.settleConfirmation)
        )
        .alert(
            $store.scope(state: \.detailDeletionConfirmation, action: \.detailDeletionConfirmation)
        )
        // 詳情頁的寫入與提醒錯誤都顯示在這個插槽
        .alert(
            $store.scope(state: \.detailNoticeAlert, action: \.detailNoticeAlert)
        )
        // 收款錯誤由 OrdersView 的 alert 呈現
    }
}

// MARK: - ViewBuilder

private extension CampaignDetailView {
    
    /// 開團詳情主體
    /// - Parameter campaign: 目前的開團
    /// - Returns: 詳情 list view
    @ViewBuilder
    func detail(for campaign: Campaign) -> some View {
        let summary = CampaignSummary(campaignName: campaign.name, orders: store.orders)
        List {
            infoSection(campaign: campaign)
            settlementSection(summary)
            distributionSection(summary)
        }
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailRoot)
    }
    
    /// 開團資訊區段
    /// - Parameter campaign: 目前的開團
    /// - Returns: 資訊區段 view
    @ViewBuilder
    func infoSection(campaign: Campaign) -> some View {
        Section("開團資訊") {
            Text(campaign.name)
                .font(BLTypographyStyle.body.font.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LabeledContent("狀態") {
                HStack(spacing: BLSpacing.extraSmall) {
                    BLStatusPill(
                        campaign.status.title, tone: CampaignStatusStyle.tone(for: campaign.status))
                    if campaign.isSettled {
                        BLStatusPill("已結團", tone: .neutral, showsIndicator: false)
                    }
                }
            }
            
            LabeledContent(
                "開團日期",
                value: CampaignFormatters.shortDate(campaign.openDate, locale: locale)
            )
            
            if let closeDate = campaign.closeDate {
                LabeledContent(
                    "結單日期",
                    value: CampaignFormatters.shortDate(closeDate, locale: locale)
                )
            }
            
            if let settledDate = campaign.settledDate {
                LabeledContent(
                    "結團日期",
                    value: CampaignFormatters.shortDate(settledDate, locale: locale)
                )
            }
            
            if let reminderLink = store.reminderLinks[campaign.id] {
                // 有提醒時顯示日期與時間。
                LabeledContent(
                    "訂購提醒",
                    value: CampaignFormatters.reminderTimestamp(
                        reminderLink.reminderTimestamp,
                        locale: locale
                    )
                )
            }
            
            if !campaign.notes.isEmpty {
                Text(campaign.notes)
                    .blTextStyle(.subhead)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
        }
    }
    
    /// 結團結算區段：收款面與損益面
    /// - Parameter summary: 由 ``detail(for:)`` 一次算好的開團彙總
    /// - Returns: 結算區段 view
    @ViewBuilder
    func settlementSection(_ summary: CampaignSummary) -> some View {
        let palette = BLPalette()
        
        Section("結團結算") {
            // 把金額放在 accessibilityValue，讓 UI 測試讀取
            LabeledContent("應收", value: CampaignFormatters.twd(summary.receivables, locale: locale))
                .accessibilityElement(children: .combine)
                .accessibilityValue(CampaignFormatters.twd(summary.receivables, locale: locale))
                .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSummary(.receivables))
            LabeledContent(
                "已收", value: CampaignFormatters.twd(summary.receivedAmount, locale: locale)
            )
            .accessibilityElement(children: .combine)
            .accessibilityValue(CampaignFormatters.twd(summary.receivedAmount, locale: locale))
            .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSummary(.received))
            LabeledContent(
                "未收",
                value: CampaignFormatters.twd(
                    summary.outstandingAmount,
                    locale: locale
                )
            )
            
            BLProgressBar(
                title: "收款進度",
                value: summary.receivedRatio,
                tint: palette.green,
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
                value: BLFormatters.percent(summary.margin, locale: locale)
            )
        }
    }
    
    /// 客戶分貨區段：可切換只看未收款，每列可展開檢視品項與逐筆收款
    /// - Parameter summary: 由 ``detail(for:)`` 一次算好的開團彙總
    /// - Returns: 分貨區段 view
    @ViewBuilder
    func distributionSection(_ summary: CampaignSummary) -> some View {
        let showsUnpaidOnly = store.showsUnpaidOnly
        let rows = showsUnpaidOnly ? summary.unpaidDistribution : summary.distribution
        
        Section {
            Toggle("只看未收款", isOn: unpaidOnlyBinding)
                .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailUnpaidToggle)
            
            if rows.isEmpty {
                Text(
                    LocalizedStringKey(
                        showsUnpaidOnly ? "全部已收款。" : "尚無歸屬此開團的訂單。"
                    )
                )
                .blTextStyle(.subhead)
                .foregroundStyle(Color.blSecondaryLabel)
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
        let palette = BLPalette()
        
        HStack(spacing: BLSpacing.small) {
            Image(systemName: row.isFullyReceived ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(row.isFullyReceived ? palette.green : Color.blSecondaryLabel)
            
            Text(row.customerName)
                .font(BLTypographyStyle.subhead.font.weight(.medium))
            
            Spacer(minLength: 0)
            
            Text(
                """
                \(row.totalQuantity) 件 · \
                \(CampaignFormatters.twd(row.totalAmount, locale: locale))
                """
            )
            .blTextStyle(.caption)
            .foregroundStyle(Color.blSecondaryLabel)
            .monospacedDigit()
        }
    }
    
    /// 分貨列展開後的單筆訂單：品項摘要與收款狀態切換
    /// - Parameter order: 該客戶在此開團的訂單
    /// - Returns: 訂單列 view
    @ViewBuilder
    func orderRow(_ order: LedgerOrder) -> some View {
        let palette = BLPalette()
        
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(order.displayID)
                .blTextStyle(.caption2)
                .foregroundStyle(.tertiary)
            
            Text(order.itemSummary)
                .blTextStyle(.footnote)
            
            HStack {
                Text(CampaignFormatters.twd(order.chargedAmount, locale: locale))
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                    .monospacedDigit()
                
                Spacer(minLength: 0)
                
                Button {
                    store.send(
                        .receiptStatusToggled(
                            order.id,
                            order.paymentReceiptStatus == .received ? .pending : .received
                        ))
                } label: {
                    Label {
                        Text(LocalizedStringKey(order.paymentReceiptStatus.title))
                    } icon: {
                        Image(
                            systemName: order.paymentReceiptStatus == .received
                            ? "checkmark.circle.fill" : "circle")
                    }
                    .blTextStyle(.caption)
                    .foregroundStyle(
                        order.paymentReceiptStatus == .received ? palette.green : palette.accent
                    )
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
    
    /// 狀態選擇器的 binding；選取後送出 statusChanged
    /// - Parameter campaign: 目前的開團
    /// - Returns: 對應的狀態 binding
    func statusBinding(for campaign: Campaign) -> Binding<CampaignStatus> {
        Binding(
            get: { campaign.status },
            set: { store.send(.statusChanged(campaign.id, $0)) }
        )
    }
    
    /// 未收款篩選的 binding；切換後送出 unpaidOnlyToggled
    var unpaidOnlyBinding: Binding<Bool> {
        Binding(
            get: { store.showsUnpaidOnly },
            set: { store.send(.unpaidOnlyToggled($0)) }
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
    let previewState: CampaignFeature.State = {
        var state = CampaignFeature.State()
        state.orders = LedgerOrder.sampleCampaignOrders
        state.campaigns = Campaign.sampleCampaigns
        state.hasLoaded = true
        return state
    }()
    
    return NavigationStack {
        CampaignDetailView(
            store: Store(initialState: previewState) {
                CampaignFeature()
            },
            campaignID: "CMP-SAMPLE-KR-APR"
        )
    }
}
