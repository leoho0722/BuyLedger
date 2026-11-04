//
//  OrderDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// iPhone 推入詳情與 iPad 詳情欄共用的訂單詳情畫面，提供內容、導覽列標題與工具列
struct OrderDetailView: View {

    // MARK: - Properties

    /// 訂單詳情目前可用的水平尺寸分類
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderDetailFeature>

    // MARK: - Body

    /// 呈現選取訂單的資料、成本拆解與操作入口
    var body: some View {
        content
            .background {
                toolbarCarrier
            }
    }
}

// MARK: - Private Views

private extension OrderDetailView {

    /// 有訂單時顯示詳情內容與客戶名稱標題
    @ViewBuilder
    var content: some View {
        if let order = store.order {
            OrderDetailContentView(
                campaignNamesText: store.campaignNamesText,
                categoriesText: store.categoriesText,
                costComponents: store.costComponents,
                hasCardlessAdjustments: store.hasCardlessAdjustments,
                hasCostBreakdown: store.hasCostBreakdown,
                hasNotes: store.hasNotes,
                order: order,
                orderSourceText: store.orderSourceText
            )
            .navigationTitle(Text(verbatim: order.customer.name))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// 水平尺寸分類改變時重建工具列貢獻者，繞過 SwiftUI 缺陷 FB15300614 並保留詳情內容
    var toolbarCarrier: some View {
        Color.clear
            .toolbar {
                if store.order != nil {
                    OrderDetailToolbarContent(store: store)
                }
            }
            .id(horizontalSizeClass)
    }
}

// MARK: - Preview

#Preview("訂單詳情") {
    NavigationStack {
        OrderDetailView(
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
}

#Preview("訂單詳情 · 詳情欄寬度") {
    NavigationStack {
        OrderDetailView(
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
    .frame(width: 704, height: 768)
}
