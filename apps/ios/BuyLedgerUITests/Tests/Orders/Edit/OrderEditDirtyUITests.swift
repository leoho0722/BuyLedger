//
//  OrderEditDirtyUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單取消與捨棄未儲存變更的 UI 測試
@MainActor
final class OrderEditDirtyUITests: BLUITestCase {

    // MARK: - Properties

    /// 造成未儲存變更用的客戶名稱草稿
    private static let draftCustomerName = "草稿客戶"

    /// 捨棄確認 alert 的繼續編輯按鈕文字
    private static let continueEditingLabel = "繼續編輯"

    /// 捨棄確認 alert 的捨棄變更按鈕文字
    private static let discardLabel = "捨棄變更"

    /// 驗證未修改表單時開啟來源選擇器再返回，按取消會直接關閉表單並回到清單
    ///
    /// - Throws: 必要的 UI 操作或返回表單前置不成立時丟出 UITestError.stopped
    func testCancelTapped_進過選擇器返回且未修改_關閉表單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        let picker = try edit.openSourcePicker()
        try picker.tapBack()
        try requireCondition(edit.waitUntilReady(), in: app, "從選擇器返回後編輯表單未就緒")

        // When
        try edit.tapCancel()

        // Then
        XCTAssertTrue(edit.rootElement.waitForDisappearance(), "進過選擇器返回後點取消，編輯表單未關閉")
        XCTAssertTrue(OrdersScreen(app: app).waitUntilReady(), "取消後未回到訂單清單")
    }

    /// 驗證未儲存變更時取消並選繼續編輯，捨棄確認收回且表單仍保留
    ///
    /// - Throws: 必要的 UI 操作或捨棄確認未呈現時丟出 UITestError.stopped
    func testTapAlertButton_有變更後取消選繼續編輯_停留在表單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.typeCustomerName(Self.draftCustomerName)
        try edit.tapCancel()
        try requireCondition(app.alertPresented(), in: app, "有未儲存變更時點取消，捨棄確認 alert 未呈現")

        // When
        try app.tapAlertButton(label: Self.continueEditingLabel)

        // Then
        XCTAssertTrue(app.alertDismissed(), "點「繼續編輯」後捨棄確認 alert 未收回")
        XCTAssertTrue(edit.waitUntilReady(), "點「繼續編輯」後應仍停留在編輯表單")
    }

    /// 驗證未儲存變更時取消並選捨棄變更，表單關閉並回到訂單清單
    ///
    /// - Throws: 必要的 UI 操作或捨棄確認未呈現時丟出 UITestError.stopped
    func testDiscard_有變更後取消選捨棄變更_關閉表單並回到清單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.typeCustomerName(Self.draftCustomerName)
        try edit.tapCancel()
        try requireCondition(app.alertPresented(), in: app, "有未儲存變更時點取消，捨棄確認 alert 未呈現")

        // When
        try app.tapAlertButton(label: Self.discardLabel)

        // Then
        XCTAssertTrue(edit.rootElement.waitForDisappearance(), "點「捨棄變更」後編輯表單未關閉")
        XCTAssertTrue(OrdersScreen(app: app).waitUntilReady(), "捨棄變更後未回到訂單清單")
    }
}
