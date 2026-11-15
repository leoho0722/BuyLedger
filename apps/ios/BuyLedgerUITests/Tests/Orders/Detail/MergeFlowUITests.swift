//
//  MergeFlowUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單合併確認表單未修改時下滑關閉的 UI 測試
@MainActor
final class MergeFlowUITests: BLUITestCase {

    /// 驗證未修改的合併確認表單下滑時直接關閉，不顯示捨棄確認並回到來源訂單詳情
    ///
    /// - Throws: 必要的 UI 操作或合併確認前置不成立時丟出 UITestError.stopped
    func testDismissSheetBySwipe_合併確認未修改_關閉表單並回到詳情() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let merge = try OrdersScreen.open(in: app)
            .tapOrder(orderID: OrdersSeedFixture.mergeOrderID).openMerge()
        let edit = try merge.tapCandidate(orderID: OrdersSeedFixture.mergeCandidateOrderID)
        try edit.submitCustomerName()

        // When
        try app.dismissSheetBySwipe(edit.rootElement)

        // Then
        XCTAssertFalse(app.alerts.firstMatch.exists, "未修改的合併確認下滑後不應顯示捨棄確認")
        let detail = OrderDetailScreen(app: app)
        XCTAssertTrue(detail.waitUntilReady(), "下滑關閉合併確認後未回到來源訂單詳情")
    }
}
