//
//  CampaignDetailDistributionSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import SwiftUI

/// 開團詳情的客戶分貨區段：未收款篩選、可展開的客戶列與逐筆收款鍵
struct CampaignDetailDistributionSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 分貨區沒有可見客戶時的空狀態文案
    let emptyMessage: LocalizedStringResource

    /// 是否只顯示尚未全部收款的客戶
    let isShowingUnpaidOnly: Bool

    /// 點擊指定訂單收款鍵的動作
    let onReceiptToggle: (LedgerOrder.ID) -> Void

    /// 切換只看未收款的動作
    let onUnpaidOnlyChange: (Bool) -> Void

    /// 由詳情 Feature 篩選好的可見分貨列
    let rows: [CampaignDistributionRow]

    // MARK: - Body

    /// 呈現未收款開關與可見分貨列，沒有資料時顯示空狀態
    var body: some View {
        Section {
            unpaidOnlyToggle

            if rows.isEmpty {
                emptyState
            } else {
                distributionRows
            }
        } header: {
            sectionHeader
        }
    }
}

// MARK: - Private Views

private extension CampaignDetailDistributionSection {

    /// 分貨區段標題
    var sectionHeader: some View {
        Text("campaigns.detail.label.customerAllocation")
    }

    /// 只看未收款開關，切換意圖交由呼叫端處理
    var unpaidOnlyToggle: some View {
        Toggle("campaigns.detail.label.unpaidOnly", isOn: unpaidOnlyBinding)
            .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailUnpaidToggle)
    }

    /// 依篩選開關呈現分貨空狀態
    var emptyState: some View {
        Text(emptyMessage)
            .blTextStyle(.subhead)
            .foregroundStyle(.blSecondaryLabel)
    }

    /// 每個客戶的分貨列可展開為該客戶的訂單清單
    var distributionRows: some View {
        ForEach(rows) { row in
            DisclosureGroup {
                ForEach(row.orders) {
                    orderRow($0)
                }
            } label: {
                distributionLabel(row)
            }
        }
    }

    /// 組出分貨列標題，含客戶、件數、金額與收款標記
    ///
    /// - Parameter row: 分貨列
    /// - Returns: 客戶分貨列的標題
    func distributionLabel(_ row: CampaignDistributionRow) -> some View {
        HStack(spacing: BLSpacing.small) {
            Image(systemName: row.isFullyReceived ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(row.isFullyReceived ? .blGreen : .blSecondaryLabel)
                .accessibilityLabel(Text(row.receiptAccessibilityLabel))

            Text(row.customerName)
                .font(BLTypographyStyle.subhead.font.weight(.medium))
                .accessibilityIdentifier(
                    BLAccessibilityID.Campaigns.detailDistributionRow(
                        customerName: row.customerName
                    )
                )

            Spacer(minLength: 0)

            Text(
                AppLanguage.format(
                    "campaigns.detail.label.quantityWithAmount",
                    row.totalQuantity,
                    CampaignFormatters.twd(row.totalAmount, locale: locale),
                    locale: locale
                )
            )
            .blTextStyle(.caption)
            .foregroundStyle(.blSecondaryLabel)
            .monospacedDigit()
        }
    }

    /// 組出分貨列展開後的單筆訂單列，含品項摘要、金額與收款鍵
    ///
    /// - Parameter order: 該客戶在此開團的訂單
    /// - Returns: 訂單列
    func orderRow(_ order: LedgerOrder) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text(order.displayID)
                .blTextStyle(.caption2)
                .foregroundStyle(.blTertiaryLabel)

            Text(order.itemSummary)
                .blTextStyle(.footnote)

            HStack {
                Text(CampaignFormatters.twd(order.chargedAmount, locale: locale))
                    .font(BLTypographyStyle.footnote.font.weight(.medium))
                    .monospacedDigit()

                Spacer(minLength: 0)

                receiptButton(for: order)
            }
        }
        .padding(.leading, BLSpacing.small)
    }

    /// 組出逐筆收款鍵，標籤內撐到 44pt 命中區
    ///
    /// - Parameter order: 要切換收款狀態的訂單
    /// - Returns: 收款鍵
    func receiptButton(for order: LedgerOrder) -> some View {
        Button {
            onReceiptToggle(order.id)
        } label: {
            Label {
                Text(LocalizedStringKey(order.paymentReceiptStatus.title))
            } icon: {
                Image(
                    systemName: order.paymentReceiptStatus == .received
                        ? "checkmark.circle.fill"
                        : "circle"
                )
            }
            // 命中區放在標籤內部撐到 44pt，不增加視覺尺寸
            .frame(minHeight: BLHitTarget.minimum)
            .blTextStyle(.caption)
            .foregroundStyle(order.paymentReceiptStatus == .received ? .blGreen : .blAccent)
            .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailReceiptToggle(orderID: order.id))
    }
}

// MARK: - Private Method

private extension CampaignDetailDistributionSection {

    /// 未收款篩選的 binding，讀取傳入值並回報切換意圖
    var unpaidOnlyBinding: Binding<Bool> {
        Binding {
            isShowingUnpaidOnly
        } set: {
            onUnpaidOnlyChange($0)
        }
    }
}

// MARK: - Preview

#Preview("campaigns.detail.label.customerAllocation") {
    List {
        CampaignDetailDistributionSection(
            emptyMessage: "campaigns.detail.message.ordersAssignedCampaign",
            isShowingUnpaidOnly: false,
            onReceiptToggle: { _ in
            },
            onUnpaidOnlyChange: { _ in
            },
            rows: CampaignSummary(
                campaignName: Campaign.sampleCampaigns[0].name,
                orders: LedgerOrder.sampleCampaignOrders
            )
            .distribution
        )
    }
}

#Preview("客戶分貨空狀態") {
    List {
        CampaignDetailDistributionSection(
            emptyMessage: "campaigns.detail.message.ordersAssignedCampaign",
            isShowingUnpaidOnly: false,
            onReceiptToggle: { _ in
            },
            onUnpaidOnlyChange: { _ in
            },
            rows: []
        )
    }
}
