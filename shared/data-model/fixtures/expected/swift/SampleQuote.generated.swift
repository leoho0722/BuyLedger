//
//  SampleQuote.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 範例報價 (示範僅 value-equality、不含其他 trait 的 entity trait 組合)
struct SampleQuote: Equatable, Sendable {

    // MARK: - Data Properties

    /// 報價標籤
    let label: String

    /// 報價金額
    let amount: Decimal
}
