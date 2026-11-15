//
//  XCTestCase+OrdersAssertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import XCTest

// MARK: - 訂單內容斷言

/// 跨資料夾共用的訂單清單與詳情斷言
@MainActor
extension XCTestCase {

    /// 斷言清單實際列出的訂單編號與預期集合相同
    ///
    /// - Parameters:
    ///   - expected: 預期列出的訂單編號
    ///   - orders: 訂單清單的 Page Object
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 清單訂單編號與預期不符時丟出測試錯誤
    func assertListedOrderIDs(
        _ expected: Set<String>,
        _ orders: OrdersScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let listed = orders.collectListedOrderIDs()
        guard listed == expected else {
            try orders.app.stopWithDiagnostics(
                "清單應列出 \(expected.sorted())，實際為 \(listed.sorted())",
                file: file,
                line: line
            )
        }
    }
}
