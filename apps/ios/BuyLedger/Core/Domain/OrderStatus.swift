//
//  OrderStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Properties

extension OrderStatus {

    /// 視為「已實現」的訂單狀態集合，為收益統計的單一事實來源
    static let realizedStatuses: Set<OrderStatus> = [
        .confirmed,
        .purchased,
        .shipping,
        .partiallyArrived,
        .arrived,
        .delivered,
        .pickedUp,
    ]

    /// 視為「已到貨」的訂單狀態集合，為開團到貨進度的單一事實來源
    static let deliveryStatuses: Set<OrderStatus> = [
        .arrived,
        .delivered,
        .pickedUp,
    ]
}

// MARK: - Computed Properties

extension OrderStatus {

    /// 顯示在介面中的狀態名稱
    var title: String {
        switch self {
        case .quoting:
            "customers.list.label.quoting"
        case .confirmed:
            "orders.detail.label.confirmed"
        case .purchased:
            "common.general.label.purchased"
        case .shipping:
            "orders.list.label.consolidating"
        case .partiallyArrived:
            "common.general.label.partiallyArrived"
        case .arrived:
            "campaigns.detail.status.arrived"
        case .delivered:
            "common.general.label.delivered"
        case .pickedUp:
            "common.general.label.pickedUp"
        case .cancelled:
            "orders.merge.label.canceled"
        case .merged:
            "orders.list.label.merged"
        }
    }
}
