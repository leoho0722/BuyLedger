//
//  PaymentReceiptStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 訂單的收款狀態。
///
/// 固定二元語意 (待收款／已收款)，作為開團分貨清單與結團結算判定「已收款」的唯一來源；因此不接 ``LookupKind`` 自訂主檔，避免使用者新增第三種值後讓「已收款金額」的彙總無法穩定判定。
enum PaymentReceiptStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 待收款 (預設)。
    case pending

    /// 已收款。
    case received

    // MARK: - Identifiable Properties

    /// 狀態的穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在介面中的狀態名稱。
    var title: String {
        switch self {
        case .pending:
            "待收款"
        case .received:
            "已收款"
        }
    }
}
