//
//  KPIPresenceCheck.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

/// KPI 種類檢查：必要種類缺任一即失敗
enum KPIPresenceCheck {}

// MARK: - Internal Method

extension KPIPresenceCheck {

    /// 確認觀測到的 KPI 涵蓋所有必要種類
    ///
    /// - Parameters:
    ///   - required: 必須出現的 KPI 種類
    ///   - observed: 活體上實際出現的 KPI 種類
    /// - Returns: 必要種類全數出現時為 `.passed`，缺任一即為 `.failed` 並列出缺少的種類
    static func verify<Kind: Hashable>(required: [Kind], observed: Set<Kind>) -> CheckOutcome {
        let missing = required.filter { !observed.contains($0) }
        guard missing.isEmpty else {
            let names = missing.map { String(describing: $0) }.joined(separator: ", ")
            return .failed("必要 KPI 缺失：\(names)")
        }
        return .passed
    }
}
