//
//  FxRateSnapshot.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 某個時間點的匯率快照
struct FxRateSnapshot: Equatable, Sendable {

    // MARK: - Data Properties

    /// 匯率時間
    let date: Date

    /// 計算匯率的基準幣別
    let base: CurrencyCode

    /// 各目標幣別的匯率，表示 1 單位基準幣別可換多少目標幣別
    let rates: [CurrencyCode: Decimal]
}
