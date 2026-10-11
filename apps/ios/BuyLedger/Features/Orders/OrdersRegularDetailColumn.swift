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

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrdersFeature>

    // MARK: - Body

    /// 有選取的訂單時顯示詳情，沒有時顯示選擇提示
    var body: some View {
        if let detailStore = store.scope(
            state: \.detail.regularDetail,
            action: \.detail.regularDetail
        ),
           let order = detailStore.order {
            detail(order: order, store: detailStore)
        } else {
            emptyState
        }
    }
}

// MARK: - Private Views

private extension OrdersRegularDetailColumn {

    /// 沒有可顯示的選取訂單時的選擇提示
    var emptyState: some View {
        ContentUnavailableView("orders.edit.label.selectOrders", systemImage: "list.bullet.rectangle")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.background)
    }

    /// 選取訂單的詳情，姓名標題列疊在捲動內容上方
    ///
    /// - Parameters:
    ///   - order: 要顯示的訂單
    ///   - store: 右欄詳情的狀態與互動入口
    /// - Returns: 詳情 view
    func detail(order: LedgerOrder, store: StoreOf<OrderDetailFeature>) -> some View {
        OrderDetailView(store: store, layout: .wide)
            .safeAreaInset(edge: .top, spacing: 0) {
                titleBar(order: order, store: store)
            }
    }

    /// 詳情欄頂部的姓名列，含狀態更新與更多操作選單
    ///
    /// - Parameters:
    ///   - order: 要顯示的訂單
    ///   - store: 右欄詳情的狀態與互動入口
    /// - Returns: 自繪標題列 view
    func titleBar(order: LedgerOrder, store: StoreOf<OrderDetailFeature>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text(order.customer.name)
                .blTextStyle(.title3Bold)
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            OrderDetailMenu(kind: .status, layout: .wide, store: store)

            OrderDetailMenu(kind: .more, layout: .wide, store: store)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 使用系統 bar 材質保留捲動邊緣效果
        .background(.bar)
    }
}

// MARK: - Private Method

private extension OrdersRegularDetailColumn {

    /// 詳情欄背景與標題文字使用的色盤，隨目前外觀取得對應的顏色
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("訂單詳情欄") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        state.list.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        state.detail.syncRegularDetail(selectedOrderID: state.list.selectedOrderID)
        return state
    }()

    OrdersRegularDetailColumn(
        store: Store(initialState: previewState) {
            OrdersFeature()
        }
    )
}
