//
//  OrdersToolbarContent.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// 訂單清單的多選工具列，供 compact 與 regular 版面共用
struct OrdersToolbarContent: ToolbarContent {

    // MARK: - Properties

    /// 目前是否已全選篩選結果，由清單狀態計算後傳入
    let isAllFilteredSelected: Bool

    /// 套用篩選後的訂單識別值，用於顯示筆數
    let filteredIDs: [LedgerOrder.ID]

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderListFeature>

    // MARK: - Body

    /// 顯示多選或一般模式的工具列
    var body: some ToolbarContent {
        if store.isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                selectionButton
            }

            // 批次操作放在頂部，避免可拖曳視窗遮住 `bottomBar`
            // 選取筆數由導覽標題顯示
            ToolbarItemGroup(placement: .primaryAction) {
                batchStatusMenu

                selectionDoneButton
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                orderCount
            }

            ToolbarItemGroup(placement: .primaryAction) {
                moreMenu

                newOrderButton
            }
        }
    }
}

// MARK: - Private Views

private extension OrdersToolbarContent {

    /// 切換為全選目前結果或清除選取
    var selectionButton: some View {
        Button(
            LocalizedStringKey(
                isAllFilteredSelected ? "common.action.button.clear" : "orders.list.label.selectAll"
            )
        ) {
            store.send(.view(isAllFilteredSelected ? .clearSelectionTapped : .selectAllTapped))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.selectAllButton)
    }

    /// 顯示批次狀態選項，未選取訂單時停用
    var batchStatusMenu: some View {
        Menu {
            // 「已合併」僅能由合併流程寫入，批次目標清單一律排除
            ForEach(OrdersBatchOperations.targetStatuses()) { status in
                Button(LocalizedStringKey(status.title)) {
                    store.send(.view(.batchStatusChanged(status)))
                }
            }
        } label: {
            Text("orders.general.label.changeStatus")
        }
        .disabled(store.selectedOrderIDs.isEmpty)
        .accessibilityIdentifier(BLAccessibilityID.Orders.batchStatusMenuButton)
    }

    /// 結束多選並返回一般瀏覽模式
    var selectionDoneButton: some View {
        Button("common.action.button.done") {
            store.send(.view(.selectionModeToggled))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.selectionDoneButton)
    }

    /// 顯示目前篩選結果的訂單筆數
    var orderCount: some View {
        Text(verbatim: "\(filteredIDs.count)")
            .font(BLTypographyStyle.subhead.font.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(.blSecondaryLabel)
            .accessibilityIdentifier(BLAccessibilityID.Orders.orderCountLabel)
    }

    /// 建立目前篩選結果的 AI 總結，沒有結果時停用
    var aiSummaryButton: some View {
        Button {
            store.send(.view(.aiSummaryTapped))
        } label: {
            Label("orders.list.label.aiSummary", systemImage: "sparkles")
        }
        .disabled(filteredIDs.isEmpty)
        .accessibilityIdentifier(BLAccessibilityID.Orders.aiSummaryButton)
    }

    /// 進入訂單多選模式，沒有訂單時停用
    var selectionModeButton: some View {
        Button {
            store.send(.view(.selectionModeToggled))
        } label: {
            Label("orders.list.label.selectOrders", systemImage: "checklist")
        }
        .disabled(store.orders.isEmpty)
        .accessibilityIdentifier(BLAccessibilityID.Orders.selectionModeButton)
    }

    /// 顯示 AI 總結與多選模式入口
    var moreMenu: some View {
        Menu {
            aiSummaryButton

            selectionModeButton
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("orders.detail.label.moreActions")
        .accessibilityIdentifier(BLAccessibilityID.Orders.batchMenuButton)
    }

    /// 開啟新增訂單表單
    var newOrderButton: some View {
        Button {
            store.send(.view(.newOrderTapped))
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("orders.edit.label.addOrder")
        .accessibilityIdentifier(BLAccessibilityID.Orders.addButton)
    }
}

// MARK: - Preview

#Preview("訂單工具列") {
    NavigationStack {
        Color.clear
            .toolbar {
                OrdersToolbarContent(
                    isAllFilteredSelected: false,
                    filteredIDs: [],
                    store: Store(
                        initialState: OrderListFeature.State(orders: SharedReader(value: []))
                    ) {
                        OrderListFeature()
                    }
                )
            }
    }
}
