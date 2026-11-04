//
//  OrderDetailContentView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 訂單詳情的捲動內容，由上而下排列標頭、來源、財務摘要、無卡明細、成本拆解、商品明細與備註
struct OrderDetailContentView: View {

    // MARK: - Properties

    /// 目前的動態字級，用來在輔助字級堆疊標頭資訊
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 文字內容的最大可讀寬度，隨字級縮放
    @ScaledMetric(relativeTo: .body)
    private var readableWidth = BLReadableContentType.text.candidateMaximumWidth

    /// 開團名稱的顯示文字，沒有有效開團時為 `nil`，畫面改顯示未歸團
    let campaignNamesText: String?

    /// 商品類別的顯示文字，沒有有效類別時為空狀態符號
    let categoriesText: String

    /// 詳情 State 提供的成本項目
    let costComponents: [OrderCostBreakdown.Component]

    /// 是否有卡折抵或補款金額，決定是否顯示無卡明細卡片
    let hasCardlessAdjustments: Bool

    /// 總成本是否大於零，決定是否顯示成本拆解
    let hasCostBreakdown: Bool

    /// 訂單是否有備註，有備註時顯示備註卡片
    let hasNotes: Bool

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    /// 訂單來源的顯示文字，空白時為空狀態符號
    let orderSourceText: String

    // MARK: - Body

    /// 訂單資料與依內容顯示的選擇性明細卡片
    var body: some View {
        content
    }
}

// MARK: - Private Views

private extension OrderDetailContentView {

    /// 由上而下排列詳情區段的捲動內容，寬度不超過可讀上限
    var content: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.large) {
                    header
                        .frame(maxWidth: .infinity, alignment: .leading)

                    OrderDetailSourceView(
                        campaignNamesText: campaignNamesText,
                        categoriesText: categoriesText,
                        orderSourceText: orderSourceText
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    OrderDetailSummaryView(order: order)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasCardlessAdjustments {
                        OrderDetailCardlessView(order: order)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if hasCostBreakdown {
                        OrderDetailCostView(components: costComponents, order: order)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    OrderDetailItemsView(order: order)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasNotes {
                        OrderDetailNotesView(order: order)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.large)
                .frame(width: min(max(proxy.size.width, 0), readableWidth), alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(.blBackground)
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailRoot)
            // 以顯示中的訂單識別碼作為詳情根的值，供 UI 測試核對目前路徑
            .accessibilityValue(Text(verbatim: order.id))
        }
        .background(.blBackground)
    }

    /// 訂單編號、狀態、日期與幣別的標頭
    var header: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(order.displayID)
                .font(BLTypographyStyle.footnote.font.monospacedDigit())
                .foregroundStyle(.blSecondaryLabel)

            headerMetadataLayout {
                BLStatusPill(order.status.title, tone: order.status.tone)

                HStack(spacing: BLSpacing.small) {
                    Text(OrderFormatters.shortDate(order.date, locale: locale))
                        .fixedSize(horizontal: false, vertical: true)
                        .blTextStyle(.footnote)
                        .foregroundStyle(.blSecondaryLabel)

                    Text(verbatim: "·")
                        .foregroundStyle(.blSecondaryLabel)

                    Text(
                        CurrencyDisplayName.text(
                            code: order.currency.rawValue,
                            language: AppLanguage(locale: locale)
                        )
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blSecondaryLabel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Private Method

private extension OrderDetailContentView {

    /// 標準字級橫排、輔助字級直向的標頭資訊版面
    var headerMetadataLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: BLSpacing.small))
            : AnyLayout(HStackLayout(alignment: .center, spacing: BLSpacing.small))
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    let detail = OrderDetailFeature.State(
        orderID: LedgerOrder.sampleOrders[0].id,
        orders: SharedReader(value: LedgerOrder.sampleOrders)
    )

    OrderDetailContentView(
        campaignNamesText: detail.campaignNamesText,
        categoriesText: detail.categoriesText,
        costComponents: detail.costComponents,
        hasCardlessAdjustments: detail.hasCardlessAdjustments,
        hasCostBreakdown: detail.hasCostBreakdown,
        hasNotes: detail.hasNotes,
        order: LedgerOrder.sampleOrders[0],
        orderSourceText: detail.orderSourceText
    )
}
