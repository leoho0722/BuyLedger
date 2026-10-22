//
//  OrderEditDirtyTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單按取消時的關閉與捨棄確認流程測試
final class OrderEditDirtyTests: BLUITestCase {

    // MARK: - Properties

    /// 造成未儲存變更用的客戶名稱草稿
    private static let draftCustomerName = "草稿客戶"

    /// 捨棄確認 alert 的繼續編輯按鈕文字
    private static let continueEditingLabel = "繼續編輯"

    /// 捨棄確認 alert 的捨棄變更按鈕文字
    private static let discardLabel = "捨棄變更"

    /// 進過選擇器再返回且未修改時，取消直接關閉表單並回到清單
    @MainActor
    func testCancel_進過選擇器返回且未修改_關閉表單() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        edit.openSourcePicker()
        let picker = OptionPickerScreen(app: app)
        if !picker.waitUntilReady() {
            failWithDiagnostics(in: app, "選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現")
        }
        picker.tapBack()
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "從選擇器返回後編輯表單未就緒")
        }

        // When
        edit.tapCancel()

        // Then
        if !edit.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "進過選擇器返回後點取消，編輯表單未關閉")
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "取消後未回到訂單清單，根 identifier 逾時仍未出現")
        }
    }

    /// 選擇繼續編輯後，alert 消失且仍在表單
    @MainActor
    func testCancel_有變更後選繼續編輯_停留在表單() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        edit.typeCustomerName(Self.draftCustomerName)
        edit.tapCancel()
        if !app.alertPresented() {
            failWithDiagnostics(in: app, "有未儲存變更時點取消，捨棄確認 alert 未呈現")
        }

        // When
        app.tapAlertButton(label: Self.continueEditingLabel)

        // Then
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "點「繼續編輯」後捨棄確認 alert 未收回")
        }
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點「繼續編輯」後應仍停留在編輯表單，根 identifier 卻消失")
        }
    }

    /// 選擇捨棄變更後離開表單並回到清單
    @MainActor
    func testCancel_有變更後選捨棄變更_關閉表單並回到清單() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        edit.typeCustomerName(Self.draftCustomerName)
        edit.tapCancel()
        if !app.alertPresented() {
            failWithDiagnostics(in: app, "有未儲存變更時點取消，捨棄確認 alert 未呈現")
        }

        // When
        app.tapAlertButton(label: Self.discardLabel)

        // Then
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
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單編輯表單 Page Object
    @MainActor
    func openOrderEdit(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderEditScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到訂單分頁後畫面未就緒",
                file: file,
                line: line
            )
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

        orders.tapAddOrder(file: file, line: line)

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
