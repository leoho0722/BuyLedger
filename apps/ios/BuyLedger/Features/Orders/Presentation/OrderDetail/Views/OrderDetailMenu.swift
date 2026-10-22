//
//  OrderDetailMenu.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 推入詳情與詳情欄共用的狀態、更多操作選單
struct OrderDetailMenu: View {

    // MARK: - Properties

    /// 此處顯示的操作選單
    let kind: Kind

    /// 提供操作選項與委派入口的詳情 store
    let store: StoreOf<OrderDetailFeature>

    // MARK: - Body

    /// 顯示對應分類的操作選單
    var body: some View {
        switch kind {
        case .status:
            statusMenu

        case .more:
            moreMenu
        }
    }
}

// MARK: - Private Views

private extension OrderDetailMenu {

    /// 將目前狀態標記勾號，選取時送出詳情事件
    var statusMenu: some View {
        Menu {
            ForEach(store.selectableStatuses) { status in
                Button {
                    store.send(.view(.statusChanged(status)))
                } label: {
                    if status == store.order?.status {
                        Label(LocalizedStringKey(status.title), systemImage: "checkmark")
                    } else {
                        Text(LocalizedStringKey(status.title))
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .accessibilityLabel("orders.detail.label.updateStatus")
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailStatusMenuButton)
    }

    /// 合併、編輯與刪除共用同一份操作內容
    var moreMenu: some View {
        Menu {
            if store.canMerge {
                Button {
                    store.send(.view(.mergeTapped))
                } label: {
                    Label("orders.detail.label.mergeOrders", systemImage: "arrow.triangle.merge")
                }
                .accessibilityIdentifier(BLAccessibilityID.Orders.detailMergeButton)
            }

            Button {
                store.send(.view(.editTapped))
            } label: {
                Label("common.action.button.edit", systemImage: "pencil")
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailEditButton)

            Divider()

            Button(role: .destructive) {
                store.send(.view(.deleteTapped))
            } label: {
                Label("common.action.button.delete", systemImage: "trash")
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailDeleteButton)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("orders.detail.label.moreActions")
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailMoreButton)
    }
}

// MARK: - Nested Types

extension OrderDetailMenu {

    /// 詳情選單的操作分類
    enum Kind {

        /// 更新訂單狀態
        case status

        /// 合併、編輯與刪除
        case more
    }
}

// MARK: - Preview

#Preview("詳情選單") {
    OrderDetailMenu(
        kind: .more,
        store: Store(
            initialState: OrderDetailFeature.State(
                orderID: LedgerOrder.sampleOrders[0].id,
                orders: SharedReader(value: LedgerOrder.sampleOrders)
            )
        ) {
            OrderDetailFeature()
        }
    )
}
