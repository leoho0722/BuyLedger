//
//  MergeFlowInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 合併候選搜尋重新聚焦後文字接續的 UI 測試
@MainActor
final class MergeFlowInputFocusUITests: BLUITestCase {

    /// 驗證合併候選搜尋欄收鍵盤後保留既有「林書宇」，從左側重新聚焦輸入「小」，欄位值為「林書宇小」，不因點擊位置而插進中間
    ///
    /// - Throws: 搜尋欄不可互動時丟出 UITestError.stopped
    func testTapLeftToFocus_合併候選搜尋既有林書宇輸入小_接續在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        try OrdersScreen.open(in: app).tapOrder(orderID: OrdersSeedFixture.mergeOrderID).openMerge()
        let field = try app.hittableSearchField()
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("林書宇")
        try app.dismissSearchKeyboard(keeping: "林書宇", in: field)

        // When
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("小")

        // Then
        _ = Polling.wait(timeout: 3) {
            field.value as? String == "林書宇小"
        }
        XCTAssertEqual(field.value as? String, "林書宇小", "合併候選搜尋應從尾端接續輸入")
    }
}
