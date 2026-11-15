//
//  PaymentReceiptStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 訂單的收款進度 (待收款或已收款)，可在訂單編輯表單與開團詳情中切換
enum PaymentReceiptStatus: String, CaseIterable, Codable, Sendable {

    /// 尚未收款
    case pending

    /// 已收款
    case received
}

// MARK: - Computed Properties

extension PaymentReceiptStatus {

    /// 顯示在介面中的狀態名稱
    var title: LocalizedStringResource {
        switch self {
        case .pending:
            "orders.filter.status.pendingPayment"

        case .received:
            "orders.general.status.received"
        }
    }
}

// MARK: - Identifiable

extension PaymentReceiptStatus: Identifiable {

    /// 穩定識別值，即實際保存的原始字串
    var id: String {
        rawValue
    }
}
