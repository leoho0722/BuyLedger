//
//  PaymentReceiptStatus.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 訂單的收款狀態
///
/// 固定二元語意 (待收款／已收款)，作為開團分貨清單與結團結算判定「已收款」的唯一來源；因此固定為內建二元值、不開放自訂，避免新增第三種值後讓「已收款金額」的彙總無法穩定判定
enum PaymentReceiptStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 待收款 (預設)
    case pending

    /// 已收款
    case received

    // MARK: - Identifiable Properties

    /// 穩定識別值 (以 rawValue 表示)
    var id: String { rawValue }
}
