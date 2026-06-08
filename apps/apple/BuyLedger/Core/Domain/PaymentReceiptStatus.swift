//
//  PaymentReceiptStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//
//  資料形狀 (cases、Identifiable) 由 Generated/PaymentReceiptStatus.generated.swift 產生；
//  本檔僅保留手寫業務邏輯。改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Display Properties

extension PaymentReceiptStatus {

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
