//
//  OrdersRegularDetailColumn.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// 寬版 (iPad 全螢幕) 訂單瀏覽的詳情欄，顯示選取訂單的詳情與姓名標題列
struct OrdersRegularDetailColumn: View {

    // MARK: - Properties

    /// 已套用篩選的訂單，由父層單次求值後傳入；詳情欄只顯示其中選取的一筆
    let orders: [LedgerOrder]

    /// 畫面的狀態與事件來源，由父層傳入
    let store: StoreOf<OrdersFeature>

    // MARK: - Body

    /// 有選取的訂單時顯示詳情，沒有時顯示選擇提示
    var body: some View {
        if let order = selectedOrder {
            detail(order: order)
        } else {
            emptyState
        }
    }
}

// MARK: - Private Views

private extension OrdersRegularDetailColumn {

    /// 沒有可顯示的選取訂單時的選擇提示
    var emptyState: some View {
        ContentUnavailableView("選擇訂單", systemImage: "list.bullet.rectangle")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.background)
    }

    /// 選取訂單的詳情，姓名標題列疊在捲動內容上方
    ///
    /// - Parameter order: 要顯示的訂單
    /// - Returns: 詳情 view
    func detail(order: LedgerOrder) -> some View {
        OrderDetailView(order: order, layout: .wide)
            .safeAreaInset(edge: .top, spacing: 0) {
                titleBar(order: order)
            }
    }

    /// 詳情欄頂部的姓名列，含狀態更新與更多操作選單
    ///
    /// - Parameter order: 要顯示的訂單
    /// - Returns: 自繪標題列 view
    func titleBar(order: LedgerOrder) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text(order.customer.name)
                .blTextStyle(.title3Bold)
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            statusUpdateMenu(order: order)

            moreActionsMenu(order: order)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 使用系統 bar 材質保留捲動邊緣效果
        .background(.bar)
    }

    /// 狀態更新選單，目前的狀態前面打勾
    ///
    /// - Parameter order: 對應訂單
    /// - Returns: 選單 view
    @ViewBuilder
    func statusUpdateMenu(order: LedgerOrder) -> some View {
        // 已合併只能由合併流程寫入，僅當訂單目前已是已合併時保留該選項
        let statuses = OrderStatus.allCases.filter { $0 != .merged || order.status == .merged }

        Menu {
            ForEach(statuses) { status in
                Button {
                    store.send(.statusChanged(order.id, status))
                } label: {
                    if status == order.status {
                        Label(LocalizedStringKey(status.title), systemImage: "checkmark")
                    } else {
                        Text(LocalizedStringKey(status.title))
                    }
                }
            }
        } label: {
            Label("更新狀態", systemImage: "arrow.triangle.2.circlepath")
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailStatusMenuButton)
    }

    /// 右上角的合併、編輯與刪除選單
    ///
    /// - Parameter order: 對應訂單
    /// - Returns: 選單 view
    func moreActionsMenu(order: LedgerOrder) -> some View {
        Menu {
            if order.status != .merged, order.status != .cancelled {
                Button {
                    store.send(.mergeOrderTapped(order.id))
                } label: {
                    Label("合併訂單", systemImage: "arrow.triangle.merge")
                }
                .accessibilityIdentifier(BLAccessibilityID.Orders.detailMergeButton)
            }

            Button {
                store.send(.editOrderTapped(order.id))
            } label: {
                Label("編輯", systemImage: "pencil")
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailEditButton)

            Divider()

            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除", systemImage: "trash")
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailDeleteButton)
        } label: {
            Label("更多", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .accessibilityLabel("更多操作")
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailMoreButton)
    }
}

// MARK: - Private Method

private extension OrdersRegularDetailColumn {

    /// 詳情欄背景與標題文字使用的色盤，隨目前外觀取得對應的顏色
    var palette: BLPalette {
        BLPalette()
    }

    /// 目前選取的訂單；沒有選取時取篩選結果的第一筆，選取的訂單不在篩選結果時為 `nil`
    var selectedOrder: LedgerOrder? {
        guard let selectedOrderID = store.selectedOrderID else {
            return orders.first
        }
        return orders.first { $0.id == selectedOrderID }
    }
}

// MARK: - Preview

#Preview("訂單詳情欄") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        state.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        return state
    }()

    OrdersRegularDetailColumn(
        orders: LedgerOrder.sampleOrders,
        store: Store(initialState: previewState) {
            OrdersFeature()
        }
    )
}
