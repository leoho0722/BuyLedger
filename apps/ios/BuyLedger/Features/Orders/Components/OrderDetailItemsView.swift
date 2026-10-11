//
//  OrderDetailItemsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 詳情的商品明細，保留窄欄與寬欄的卡片標題
struct OrderDetailItemsView: View {

    // MARK: - Properties

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 詳情採用的窄欄或寬欄版面
    let layout: OrderDetailView.OrderDetailLayout

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 詳情區段的畫面骨架
    var body: some View {
        switch layout {
        case .compact:
            compactItemList

        case .wide:
            wideItemsCard
        }
    }
}

// MARK: - Private Views

private extension OrderDetailItemsView {

    /// 窄欄版面使用的商品明細卡片
    @ViewBuilder
    var compactItemList: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("orders.detail.label.itemDetails")
                .blTextStyle(.headline)

            itemsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 寬欄版面使用的商品明細卡片，含標題
    @ViewBuilder
    var wideItemsCard: some View {
        BLCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("orders.detail.label.itemDetails")
                    .padding(.horizontal, BLSpacing.large)
                    .padding(.top, BLSpacing.large)
                    .padding(.bottom, BLSpacing.small)
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(Color.blSecondaryLabel)
                    .textCase(.uppercase)

                itemRows
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 商品列卡片 (窄欄版面用，內含 BLCard 包覆)
    @ViewBuilder
    var itemsCard: some View {
        BLCard(padding: 0) {
            itemRows
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 商品列序列，不含外層卡片
    @ViewBuilder
    var itemRows: some View {
        VStack(spacing: 0) {
            ForEach(order.items) { item in
                itemRow(item)

                if item.id != order.items.last?.id {
                    Divider()
                }
            }
        }
    }

    /// 顯示一項商品的名稱、數量與小計
    ///
    /// - Parameter item: 要顯示的商品
    /// - Returns: 商品明細列
    func itemRow(_ item: LedgerOrderItem) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                Text(item.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))

                Text(AppLanguage.format("orders.detail.label.quantity", item.quantity, locale: locale))
                    .blTextStyle(.caption)
                    .foregroundStyle(Color.blSecondaryLabel)
            }

            Spacer()

            Text(OrderFormatters.currency(item.subtotal, currency: order.currency, locale: locale))
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .monospacedDigit()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    OrderDetailItemsView(layout: .compact, order: LedgerOrder.sampleOrders[0])
}
