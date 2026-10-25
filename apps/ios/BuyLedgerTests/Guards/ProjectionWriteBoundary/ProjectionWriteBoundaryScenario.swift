//
//  ProjectionWriteBoundaryScenario.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

/// 共享訂單投影守門案例的資料，每筆為一段原始碼與其預期違規筆數
struct ProjectionWriteBoundaryScenario: Sendable {

    // MARK: - Properties

    /// 相對於 App 原始碼根目錄的路徑
    let relativePath: String

    /// 待判定的原始碼
    let source: String

    /// 兩條守門規則合計的違規筆數
    let expectedCount: Int
}
