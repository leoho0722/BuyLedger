//
//  FxRateSnapshot.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import Foundation

/// 單一基準幣別在某個時間點的所有匯率快照。
///
/// rates 以「1 單位 base = X 單位 target」表示；多筆快照可串成匯率歷史走勢。
struct FxRateSnapshot: Equatable, Sendable {

    // MARK: - Data Properties

    /// 報價時間。
    let date: Date

    /// 基準幣別。
    let base: CurrencyCode

    /// 對其他幣別的匯率 (key 為目標幣別，value 為「1 base = value target」)。
    let rates: [CurrencyCode: Decimal]
}
