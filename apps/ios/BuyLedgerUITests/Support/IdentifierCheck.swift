//
//  IdentifierCheck.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

/// 識別碼檢查：觀測到的識別碼必須與期望完全相同
enum IdentifierCheck {}

// MARK: - Internal Method

extension IdentifierCheck {

    /// 比對期望與觀測的識別碼
    ///
    /// - Parameters:
    ///   - expected: 期望的識別碼，未選取時為空字串
    ///   - observed: 活體上觀測到的識別碼
    /// - Returns: 兩者相同時為 `.passed`，否則為 `.failed`
    static func verify(expected: String, observed: String) -> CheckOutcome {
        guard expected == observed else {
            return .failed("識別碼不符 (預期：\(expected)，觀測：\(observed))")
        }
        return .passed
    }
}
