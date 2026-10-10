//
//  OrderSelectableRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// 訂單清單多選模式下的可勾選列，供 compact 與 regular 版面共用
struct OrderSelectableRow: View {

    // MARK: - Properties

    /// 要呈現的訂單
    let order: LedgerOrder

    /// 目前外觀使用的色盤
    let palette: BLPalette

    /// 是否顯示訂購日期
    var isShowingDate: Bool = true

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderListFeature>

    // MARK: - Body

    /// 可勾選的訂單列內容
    var body: some View {
        Button {
            store.send(.view(.orderSelectionToggled(order.id)))
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Private Views

private extension OrderSelectableRow {

    /// 顯示目前的勾選狀態，朗讀由整列的選取特徵表達
    var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            // 圖示維持一般字重，覆寫標題樣式預設的半粗體
            .font(BLTypographyStyle.title3.font.weight(.regular))
            .foregroundStyle(isSelected ? palette.accent : palette.tertiaryLabel)
            .accessibilityHidden(true)
    }

    /// 顯示勾選圖示與訂單摘要，整列皆可點擊
    var rowContent: some View {
        HStack(spacing: BLSpacing.medium) {
            selectionIndicator

            OrderRowView(order: order, isShowingDate: isShowingDate)
                .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.extraSmall)
        .contentShape(Rectangle())
    }
}

// MARK: - Private Method

private extension OrderSelectableRow {

    /// 此訂單是否在目前的多選清單中
    var isSelected: Bool {
        store.selectedOrderIDs.contains(order.id)
    }
}

// MARK: - Preview

#Preview("可勾選訂單列") {
    List {
        OrderSelectableRow(
            order: LedgerOrder.sampleOrders[0],
            palette: BLPalette(),
            store: Store(initialState: OrderListFeature.State(orders: SharedReader(value: []))) {
                OrderListFeature()
            }
        )
    }
}
