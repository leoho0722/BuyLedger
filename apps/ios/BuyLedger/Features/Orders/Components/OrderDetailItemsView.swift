//
//  OrderDetailItemsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 訂單詳情的商品明細區段，標題置於卡片外
struct OrderDetailItemsView: View {

    // MARK: - Properties

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 呈現商品名稱、數量與小計，並以分隔線區分各項商品
    var body: some View {
        itemList
    }
}

// MARK: - Private Views

private extension OrderDetailItemsView {

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

    /// 包覆商品明細列的卡片
    @ViewBuilder
    var itemsCard: some View {
        BLCard(padding: 0) {
            itemRows
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 顯示區段標題與商品明細卡片
    @ViewBuilder
    var itemList: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("orders.detail.label.itemDetails")
                .blTextStyle(.headline)

            itemsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

                Text(
                    AppLanguage.format(
                        "orders.detail.label.quantity",
                        item.quantity,
                        locale: locale
                    )
                )
                .blTextStyle(.caption)
                .foregroundStyle(.blSecondaryLabel)
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
    OrderDetailItemsView(order: LedgerOrder.sampleOrders[0])
}
