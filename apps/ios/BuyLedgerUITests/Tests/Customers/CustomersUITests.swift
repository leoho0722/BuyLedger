//
//  CustomersUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 客戶名單空狀態的 UI 測試
@MainActor
final class CustomersUITests: BLUITestCase {

    /// 驗證空資料時進入客戶名單，顯示尚無客戶的空狀態
    ///
    /// - Throws: 客戶頁或空狀態未就緒時丟出測試錯誤
    func testTask_空資料_顯示空狀態() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))

        // When
        _ = try CustomersScreen.open(in: app)

        // Then
        try assertEmptyState(BLAccessibilityID.Customers.listEmptyState, in: app)
    }
}

