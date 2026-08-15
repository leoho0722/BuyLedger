//
//  PaymentReceiptStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 訂單收款狀態
enum PaymentReceiptStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 尚未收款
    case pending

    /// 已收款
    case received

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)
    var id: String { rawValue }
}
