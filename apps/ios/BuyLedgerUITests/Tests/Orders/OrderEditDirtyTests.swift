//
//  OrderEditDirtyTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單有未儲存變更時，取消所觸發的捨棄確認流程測試
///
/// 捨棄確認是 TCA `AlertState`、掛不上 identifier，故以「有無 alert 呈現」判定，按鈕以顯示文字定位 (主回歸測試計畫已鎖定 zh-Hant/TW，按鈕文字為決定值)。
/// 兩條分支各驗一次：點「繼續編輯」收回 alert 仍停在表單、點「捨棄變更」離開表單回清單
final class OrderEditDirtyTests: BLUITestCase {

    // MARK: - Static Properties

    /// 造成未儲存變更用的客戶名稱草稿
    private static let draftCustomerName = "草稿客戶"

    /// 捨棄確認 alert 的「繼續編輯」按鈕文字 (``OrderEditFeature`` 的 cancel 角色按鈕)
    private static let continueEditingLabel = "繼續編輯"

    /// 捨棄確認 alert 的「捨棄變更」按鈕文字 (``OrderEditFeature`` 的 destructive 角色按鈕)
    private static let discardLabel = "捨棄變更"

    // MARK: - Tests

    /// 填一點東西後點取消，出現捨棄確認 alert；點「繼續編輯」alert 收回、仍停在表單
    @MainActor
    func testCancelWithChangesThenContinueEditingStaysOnForm() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)

        edit.typeCustomerName(Self.draftCustomerName)
        edit.tapCancel()

        if !app.alertPresented() {
            failWithDiagnostics(in: app, "有未儲存變更時點取消，捨棄確認 alert 未呈現")
        }

        app.tapAlertButton(label: Self.continueEditingLabel)

        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "點「繼續編輯」後捨棄確認 alert 未收回")
        }
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點「繼續編輯」後應仍停留在編輯表單，根 identifier 卻消失")
        }
    }

    /// 填一點東西後點取消，出現捨棄確認 alert；點「捨棄變更」離開表單、回到訂單清單
    @MainActor
    func testCancelWithChangesThenDiscardLeavesForm() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)

        edit.typeCustomerName(Self.draftCustomerName)
        edit.tapCancel()

        if !app.alertPresented() {
            failWithDiagnostics(in: app, "有未儲存變更時點取消，捨棄確認 alert 未呈現")
        }

        app.tapAlertButton(label: Self.discardLabel)

        // 捨棄後表單關閉，回到訂單清單
        let editRoot = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.root]
        if !editRoot.waitForDisappearance() {
            failWithDiagnostics(in: app, "點「捨棄變更」後編輯表單未關閉")
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "捨棄變更後未回到訂單清單，根 identifier 逾時仍未出現")
        }
    }
}

// MARK: - Private Method

private extension OrderEditDirtyTests {

    /// 切到訂單分頁、點新增並等編輯表單就緒，回傳編輯表單 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的訂單編輯 Page Object
    @MainActor
    func openOrderEdit(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderEditScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒", file: file, line: line)
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        orders.tapAddOrder()

        let edit = OrderEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點新增後編輯表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return edit
    }
}
