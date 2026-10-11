//
//  OrderDetailRowMenu.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 訂單列共用的合併與刪除操作，資格由詳情狀態提供
struct OrderDetailRowMenu: View {

    // MARK: - Properties

    /// 目前訂單的唯讀詳情狀態
    let detail: OrderDetailFeature.State

    /// 請清單確認刪除
    let onDelete: () -> Void

    /// 請清單開始合併
    let onMerge: () -> Void

    // MARK: - Init

    /// 建立訂單列操作選單，保留合併與刪除的回呼順序
    ///
    /// - Parameters:
    ///   - detail: 訂單的詳情狀態
    ///   - onMerge: 點擊合併時執行的操作
    ///   - onDelete: 點擊刪除時執行的操作
    init(
        detail: OrderDetailFeature.State,
        onMerge: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.detail = detail
        self.onDelete = onDelete
        self.onMerge = onMerge
    }

    // MARK: - Body

    /// 保留訂單列長按選單的原有順序
    var body: some View {
        if detail.canMerge {
            mergeButton
        }

        deleteButton
    }
}

// MARK: - Private Views

private extension OrderDetailRowMenu {

    /// 請清單開始合併目前訂單的按鈕
    var mergeButton: some View {
        Button(action: onMerge) {
            Label("orders.detail.label.mergeOrders", systemImage: "arrow.triangle.merge")
        }
    }

    /// 請清單確認刪除目前訂單的按鈕
    var deleteButton: some View {
        Button(role: .destructive, action: onDelete) {
            Label("orders.detail.label.deleteOrder", systemImage: "trash")
        }
    }
}

// MARK: - Preview

#Preview("訂單列操作") {
    OrderDetailRowMenu(
        detail: OrderDetailFeature.State(
            orderID: LedgerOrder.sampleOrders[0].id,
            orders: SharedReader(value: LedgerOrder.sampleOrders)
        )
    ) {
    } onDelete: {
    }
}
