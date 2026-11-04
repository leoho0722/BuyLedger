//
//  PathCheck.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

/// 路徑檢查：目的地必須仍在導覽路徑中
enum PathCheck {}

// MARK: - Internal Method

extension PathCheck {

    /// 確認導覽路徑保留期望的目的地
    ///
    /// - Parameters:
    ///   - expectedDestination: 期望仍在路徑中的目的地識別碼
    ///   - observedPath: 活體上觀測到的路徑，由根至葉排列
    /// - Returns: 路徑含期望目的地時為 `.passed`；路徑為空或目的地不同時為 `.failed`
    static func verify(expectedDestination: String, observedPath: [String]) -> CheckOutcome {
        guard !observedPath.isEmpty else {
            return .failed("導覽路徑為空，目的地 \(expectedDestination) 已丟失")
        }
        guard observedPath.contains(expectedDestination) else {
            return .failed("導覽路徑 \(observedPath) 不含預期目的地 \(expectedDestination)")
        }
        return .passed
    }
}
