//
//  CurrencyCode.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 交易幣別的 ISO 4217 三位代碼
struct CurrencyCode: Hashable, Sendable {

    // MARK: - Data Properties

    /// 實際保存的基礎值
    let rawValue: String
}

// MARK: - Identifiable

extension CurrencyCode: Identifiable {

    /// 以實際保存的值作為穩定識別
    var id: String { rawValue }
}
