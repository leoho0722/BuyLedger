//
//  OrderStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單目前狀態
enum OrderStatus: String, CaseIterable, Codable, Sendable {

    /// 正在報價
    case quoting

    /// 客戶已確認
    case confirmed

    /// 已完成下單
    case purchased

    /// 運送中
    case shipping

    /// 部分到貨
    case partiallyArrived

    /// 已到貨但未交付客戶
    case arrived

    /// 已交付客戶
    case delivered

    /// 客戶已取貨
    case pickedUp

    /// 已取消
    case cancelled

    /// 已合併到其他訂單
    case merged

    // MARK: - Properties

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
    var title: LocalizedStringResource {
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

// MARK: - Identifiable

extension OrderStatus: Identifiable {

    /// 穩定識別值，即實際保存的原始字串
    var id: String {
        rawValue
    }
}
