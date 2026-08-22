//
//  OrderDetailTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單詳情的進入、財務摘要與刪除流程測試
final class OrderDetailTests: BLUITestCase {

    // MARK: - Static Properties

    /// fullOrders 中用於詳情測試的訂單編號
    private static let sampleOrderID = "BL-2604-018"

    /// paymentMethodCorrection 中用於回溯重算驗收的訂單編號
    private static let paymentMethodCorrectionOrderID = "UITEST-PMC-001"

    /// 回溯重算驗收所使用的付款方式名稱
    private static let paymentMethodCorrectionName = "信用卡"

    /// 詳情財務摘要卡的三個種類
    private static let summaryTiles: [BLAccessibilityID.Orders.SummaryTile] = [
        .revenue, .cost, .profit,
    ]

    // MARK: - Tests

    /// 從清單點一筆訂單進詳情，詳情根就緒
    @MainActor
    func testTapOrderOpensDetail() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let detail = openOrderDetail(app)

        _ = detail
    }

    /// 詳情財務摘要卡三個數值可各自讀到且非空
    @MainActor
    func testDetailSummaryTilesHaveValues() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let detail = openOrderDetail(app)

        for tile in Self.summaryTiles where detail.summaryValue(tile).isEmpty {
            failWithDiagnostics(
                in: app,
                "財務摘要卡「\(tile.rawValue)」的 accessibility value 為空"
            )
        }
    }

    /// 補勾貨到付款後獲利改變，重啟 App 後仍保留新的獲利數字
    @MainActor
    func testCashOnDeliveryCorrectionPersistsAfterRelaunch() {
        var initialOptions = LaunchOptions(seed: .paymentMethodCorrection)
        initialOptions.persistenceMode = .persistent
        initialOptions.resetPersistentStore = true

        let app = launch(initialOptions)
        let before = profitValue(
            for: Self.paymentMethodCorrectionOrderID,
            in: app
        )

        let root = RootNavigationScreen(app: app)
        if !root.goToMore() {
            failWithDiagnostics(in: app, "切到更多分頁後畫面未就緒")
        }

        let paymentMethodsRow = app.descendants(matching: .any)[
            BLAccessibilityID.More.row(.paymentMethods)
        ]
        if !paymentMethodsRow.waitUntilHittable() {
            failWithDiagnostics(in: app, "付款方式主檔入口未出現")
        }
        paymentMethodsRow.tap()

        let managementRoot = app.descendants(matching: .any)[
            BLAccessibilityID.LookupManagement.root
        ]
        if !managementRoot.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "付款方式管理頁面未出現")
        }

        let paymentMethodRow = app.descendants(matching: .any)[
            BLAccessibilityID.LookupManagement.row(Self.paymentMethodCorrectionName)
        ]
        if !paymentMethodRow.waitUntilHittable() {
            failWithDiagnostics(in: app, "信用卡付款方式列未出現")
        }
        paymentMethodRow.swipeLeft()

        let editButton = app.buttons[
            BLAccessibilityID.LookupManagement.editButton(Self.paymentMethodCorrectionName)
        ]
        if !editButton.waitUntilHittable() {
            failWithDiagnostics(in: app, "信用卡付款方式的編輯按鈕未出現")
        }
        editButton.tap()

        let cashOnDeliveryToggle = app.switches[
            BLAccessibilityID.LookupManagement.paymentMethodCashOnDeliveryToggle
        ]
        if !cashOnDeliveryToggle.waitUntilHittable() {
            let editorRoot = app.descendants(matching: .any)[
                BLAccessibilityID.LookupManagement.paymentMethodEditorRoot
            ]
            if !app.scrollToHittable(cashOnDeliveryToggle, within: editorRoot, maxSwipes: 6) {
                failWithDiagnostics(in: app, "貨到付款旗標未出現或仍在畫面外")
            }
        }
        XCTAssertNotEqual(
            cashOnDeliveryToggle.value as? String,
            "1",
            "回溯驗收的初始付款方式不應已標記為貨到付款"
        )
        let cashOnDeliveryLabel = app.staticTexts["標記為「貨到付款」付款方式"]
        let cashOnDeliveryCell = app.cells.containing(
            .switch,
            identifier: BLAccessibilityID.LookupManagement.paymentMethodCashOnDeliveryToggle
        ).firstMatch
        if cashOnDeliveryCell.waitUntilHittable(timeout: 2) {
            cashOnDeliveryCell.coordinate(
                withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
            ).tap()
        } else if cashOnDeliveryLabel.waitUntilHittable(timeout: 2) {
            cashOnDeliveryLabel.tap()
        } else {
            cashOnDeliveryToggle.tap()
        }

        let saveButton = app.buttons[
            BLAccessibilityID.LookupManagement.paymentMethodSaveButton
        ]
        if !saveButton.waitUntilHittable() {
            failWithDiagnostics(in: app, "付款方式儲存按鈕未出現")
        }
        saveButton.tap()

        app.assertAlertMessage(contains: "1", timeout: 15)
        app.tapAlertButton(label: "確認更正")
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "回溯重算確認 alert 未收回")
        }

        if !app.staticTexts["貨到付款"].waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "付款方式更新成功後，貨到付款分類徽章未出現")
        }

        app.terminate()

        var relaunchOptions = initialOptions
        relaunchOptions.resetPersistentStore = false
        let relaunchedApp = launch(relaunchOptions)
        let persisted = profitValue(
            for: Self.paymentMethodCorrectionOrderID,
            in: relaunchedApp
        )

        XCTAssertFalse(before.isEmpty, "回溯前獲利數字不可為空")
        XCTAssertFalse(persisted.isEmpty, "重啟後獲利數字不可為空")
        XCTAssertNotEqual(before, persisted, "補勾貨到付款後獲利應該改變並持久化")
    }

    /// 刪除流程：更多 → 刪除 → 確認 alert → 取消；alert 收回且訂單未被刪除
    @MainActor
    func testDeleteFlowCancelKeepsOrder() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let detail = openOrderDetail(app)

        detail.openMoreMenu()
        if !detail.tapDelete() {
            failWithDiagnostics(in: app, "更多選單的刪除項目未出現或不可點")
        }

        if !detail.deleteConfirmationExists() {
            failWithDiagnostics(in: app, "點刪除後，刪除確認 alert 未呈現")
        }

        detail.cancelDelete()

        // 取消後 alert 應收回，且訂單未被刪除、詳情仍停留
        if !detail.deleteConfirmationDismissed() {
            failWithDiagnostics(in: app, "點取消後，刪除確認 alert 未收回")
        }
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消刪除後詳情頁應仍停留，根 identifier 卻消失")
        }
    }
}

// MARK: - Private Method

private extension OrderDetailTests {

    /// 切到訂單分頁、點種子訂單進詳情並等就緒，回傳詳情 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單詳情 Page Object
    @MainActor
    func openOrderDetail(
        _ app: XCUIApplication,
        orderID: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderDetailScreen {
        let targetOrderID = orderID ?? Self.sampleOrderID
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

        orders.tapOrder(orderID: targetOrderID)

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點訂單「\(targetOrderID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return detail
    }

    /// 讀取指定訂單詳情的獲利 accessibility value
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - app: 受測 App
    /// - Returns: 獲利卡的 accessibility value
    @MainActor
    func profitValue(for orderID: String, in app: XCUIApplication) -> String {
        openOrderDetail(app, orderID: orderID).summaryValue(.profit)
    }
}
