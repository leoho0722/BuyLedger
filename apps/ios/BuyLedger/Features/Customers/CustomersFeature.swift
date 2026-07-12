//
//  CustomersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation

/// 客戶名單畫面顯示用的彙總列
///
/// 由訂單依 ``LedgerOrder/customer`` 的姓名分組彙總而來；本型別不保存任何持久化資料
struct CustomerRow: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 用客戶姓名當識別值 (同名客戶會被聚合成一筆)
    var id: String { name }

    // MARK: - Data Properties

    /// 客戶姓名
    let name: String

    /// 顯示在頭像上的姓名縮寫
    let initials: String

    /// 客戶分級
    let tier: CustomerTier

    /// 已下訂單數
    let orderCount: Int

    /// 累計消費 (NT$)
    let totalSpent: Decimal

    /// 最近一筆訂單的日期
    let lastOrderDate: Date
}

// MARK: - Static Method

extension CustomerRow {

    /// 把訂單依客戶姓名分組彙總成客戶列
    /// - Parameter orders: 目前訂單清單
    /// - Returns: 依累計消費由高到低排序的客戶列
    static func aggregate(orders: [LedgerOrder]) -> [CustomerRow] {
        let grouped = Dictionary(grouping: orders, by: { $0.customer.name })

        return grouped
            .compactMap { name, list -> CustomerRow? in
                guard let first = list.first else { return nil }
                let totalSpent = list.reduce(Decimal.zero) { $0 + $1.summary.revenue }
                let lastDate = list.map(\.date).max() ?? first.date

                return CustomerRow(
                    name: name,
                    initials: first.customer.initials,
                    tier: first.customer.tier,
                    orderCount: list.count,
                    totalSpent: totalSpent,
                    lastOrderDate: lastDate
                )
            }
            .sorted { $0.totalSpent > $1.totalSpent }
    }
}

/// 客戶彙總功能：承載訂單來源投影、衍生出客戶消費彙總
///
/// 狀態完全衍生自 ``RootFeature`` 同步進來的訂單、不維護額外持久化資料；本 feature 目前無自身互動，導覽 (如點擊客戶跳轉訂單頁) 由 ``RootFeature`` 處理，故 Action 為空
@Reducer
struct CustomersFeature {

    // MARK: - State

    /// 客戶彙總功能狀態
    @ObservableState
    struct State: Equatable {

        /// 來源訂單；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []

        /// 依累計消費由高到低排序的客戶彙總列
        var customers: [CustomerRow] {
            CustomerRow.aggregate(orders: orders)
        }
    }

    // MARK: - Action

    /// 客戶彙總功能無自身互動；型別存在僅供 ``RootFeature`` 組合
    @CasePathable
    enum Action: Equatable {}

    // MARK: - Reducer Body

    /// 客戶彙總功能 reducer；無事件需要處理
    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
