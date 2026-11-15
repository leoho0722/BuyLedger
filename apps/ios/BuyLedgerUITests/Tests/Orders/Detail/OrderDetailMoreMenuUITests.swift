//
//  OrderDetailMoreMenuUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/7.
//

import XCTest

/// 訂單詳情更多選單取消編輯、合併與刪除的 UI 測試
@MainActor
final class OrderDetailMoreMenuUITests: BLUITestCase {

    /// 驗證從更多選單開啟編輯後未修改就取消，表單收回且原訂單營收仍為 $1,200
    ///
    /// - Throws: 必要的 UI 操作或原訂單前置不成立時丟出 UITestError.stopped
    func testCancelTapped_由更多選單開啟編輯後取消_返回原訂單詳情() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let detail = try OrdersScreen.open(in: app)
            .tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try assertOriginalDetailIsDisplayed(detail, in: app)
        let edit = try detail.openEdit()

        // When
        try edit.tapCancel()

        // Then
        XCTAssertTrue(edit.rootElement.waitForDisappearance(), "取消編輯後表單未收回")
        try assertOriginalDetailIsDisplayed(detail, in: app)
    }

    /// 驗證從更多選單開啟合併候選後取消，候選畫面收回且原訂單營收仍為 $1,200
    ///
    /// - Throws: 必要的 UI 操作、原訂單或合併候選前置不成立時丟出 UITestError.stopped
    func testCancelTapped_由更多選單開啟合併後取消_返回原訂單詳情() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let detail = try OrdersScreen.open(in: app)
            .tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try assertOriginalDetailIsDisplayed(detail, in: app)
        let merge = try detail.openMerge()
        try requireCondition(
            merge.hasCandidate(orderID: OrdersSeedFixture.mergeCandidateOrderID),
            in: app,
            "合併候選畫面未列出可合併訂單"
        )

        // When
        try merge.tapCancel()

        // Then
        XCTAssertTrue(merge.rootElement.waitForDisappearance(), "取消合併後候選畫面未收回")
        try assertOriginalDetailIsDisplayed(detail, in: app)
    }

    /// 驗證從更多選單點刪除後取消，確認 alert 收回且原訂單營收仍為 $1,200
    ///
    /// - Throws: 必要的 UI 操作、原訂單或刪除確認前置不成立時丟出 UITestError.stopped
    func testCancelDelete_刪除確認選取消_保留原訂單詳情() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let detail = try OrdersScreen.open(in: app)
            .tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try assertOriginalDetailIsDisplayed(detail, in: app)
        try detail.openMoreMenu()
        try detail.tapDelete()
        try requireCondition(detail.waitForDeleteConfirmation(), in: app, "點刪除後確認 alert 未出現")
        try app.assertAlertMessage(contains: "後無法復原")

        // When
        try detail.cancelDelete()

        // Then
        XCTAssertTrue(detail.waitForDeleteConfirmationDismissal(), "取消刪除後確認 alert 未收回")
        try assertOriginalDetailIsDisplayed(detail, in: app)
    }
}

// MARK: - Private Method

private extension OrderDetailMoreMenuUITests {

    /// 確認原訂單詳情仍顯示，且營收維持 $1,200
    ///
    /// - Parameters:
    ///   - detail: 原訂單詳情的 Page Object
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 原訂單未顯示或營收不符時丟出 UITestError.stopped
    func assertOriginalDetailIsDisplayed(
        _ detail: OrderDetailScreen,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireCondition(
            detail.waitUntilReady(),
            in: app,
            "原訂單詳情未顯示",
            file: file,
            line: line
        )
        try requireCondition(
            detail.summaryValue(.revenue) == "$1,200",
            in: app,
            "原訂單詳情應保留營收 $1,200",
            file: file,
            line: line
        )
    }
}
