//
//  OrderStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Static Properties

extension OrderStatus {

    /// 視為「已實現」的訂單狀態集合，為收益統計的單一事實來源
    /// 「已合併」與「已取消」「報價中」同樣不屬於已實現，避免合併後重複計算收益
    static let realizedStatuses: Set<OrderStatus> = [
        .confirmed,
        .purchased,
        .shipping,
        .partiallyArrived,
        .arrived,
        .delivered,
        .pickedUp,
    ]
}

// MARK: - Display Properties

extension OrderStatus {

    /// 顯示在介面中的狀態名稱
    var title: String {
        switch self {
        case .quoting:
            "報價中"
        case .confirmed:
            "已確認"
        case .purchased:
            "已下單"
        case .shipping:
            "集運中"
        case .partiallyArrived:
            "部分到貨"
        case .arrived:
            "已到貨"
        case .delivered:
            "已交付"
        case .pickedUp:
            "已取貨"
        case .cancelled:
            "已取消"
        case .merged:
            "已合併"
        }
    }
}
