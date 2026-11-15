//
//  OptionPickerInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 選項選擇器搜尋聚焦與不呈現搜尋欄的 UI 測試
@MainActor
final class OptionPickerInputFocusUITests: BLUITestCase {

    /// 驗證設定頁預設幣別的搜尋欄收鍵盤後保留既有「新台」，從左側重新聚焦輸入「幣」，欄位值為「新台幣」
    ///
    /// - Throws: 搜尋欄不可互動或選擇器未就緒時丟出 UITestError.stopped
    func testTapLeftToFocus_選項搜尋既有新台輸入幣_接續在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly, language: .traditionalChinese))
        let settings = try SettingsScreen.open(in: app)
        try settings.openDefaultCurrency()
        let field = try app.hittableSearchField()
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("新台")
        try app.dismissSearchKeyboard(keeping: "新台", in: field)

        // When
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("幣")

        // Then
        _ = Polling.wait(timeout: 3) {
            field.value as? String == "新台幣"
        }
        XCTAssertEqual(field.value as? String, "新台幣", "選項選擇器搜尋應從尾端接續輸入")
    }

    /// 驗證訂單來源選擇器呈現後不出現搜尋欄，等待有上限後才判定不存在
    ///
    /// - Throws: 訂單編輯表單或選擇器未就緒時丟出 UITestError.stopped
    func testOrderSourcePickerTapped_訂單來源選擇器_不呈現搜尋欄() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()

        // When
        try edit.openSourcePicker()

        // Then
        let hasSearchField = Polling.wait(timeout: 2) {
            app.hasHittableSearchField
        }
        XCTAssertFalse(hasSearchField, "訂單來源選擇器不應呈現搜尋欄")
    }
}
