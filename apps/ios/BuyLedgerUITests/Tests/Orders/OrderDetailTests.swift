//
//  OrderDetailTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單詳情的財務摘要與付款方式回溯重算測試
final class OrderDetailTests: BLUITestCase {

    // MARK: - Properties

    /// `fullOrders` 中用於詳情測試的訂單編號
    private static let sampleOrderID = "BL-2604-018"

    /// `paymentMethodCorrection` 中用於回溯重算驗收的訂單編號
    private static let paymentMethodCorrectionOrderID = "UITEST-PMC-001"

    /// 回溯重算驗收所使用的付款方式名稱
    private static let paymentMethodCorrectionName = "信用卡"

    /// 詳情財務摘要卡的三個種類
    private static let summaryTiles: [BLAccessibilityID.Orders.SummaryTile] = [
        .revenue,
        .cost,
        .profit,
    ]

    /// `fullOrders` 種子資料的營收、成本與獲利顯示值
    private static let expectedSummaryValues = ["$11,800", "$9,069", "+$2,731"]

    /// 詳情財務摘要卡顯示 `fullOrders` 種子資料的營收、成本與獲利
    ///
    /// - Throws: 財務摘要卡值不存在時拋出測試錯誤
    @MainActor
    func testOpenDetail_完整資料訂單_摘要卡顯示營收成本與獲利() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))

        // When
        let detail = openOrderDetail(app)

        // Then
        var values: [String] = []
        for tile in Self.summaryTiles {
            let value = try requireValue(
                detail.summaryValue(tile),
                in: app,
                "財務摘要卡「\(tile.rawValue)」的元素不存在"
            )
            values.append(value)
        }
        XCTAssertEqual(values, Self.expectedSummaryValues)
    }

    /// 付款方式補勾貨到付款並確認更正後重啟 App，重新讀取的訂單獲利與更正前不同
    ///
    /// - Throws: 任何必要的獲利或付款方式元素不存在，或前置條件不成立時拋出測試錯誤
    @MainActor
    func testRelaunch_補勾貨到付款後重啟_獲利與更正前不同() throws(any Error) {
        // Given
        var initialOptions = LaunchOptions(seed: .paymentMethodCorrection)
        initialOptions.persistenceMode = .persistent
        initialOptions.shouldResetPersistentStore = true

        let app = launch(initialOptions)
        let before = try requireValue(
            profitValue(for: Self.paymentMethodCorrectionOrderID, in: app),
            in: app,
            "回溯前獲利卡的元素不存在"
        )
        try requireCondition(!before.isEmpty, in: app, "回溯前獲利卡的 accessibility value 為空")

        let root = RootNavigationScreen(app: app)
        if !root.goToMore() {
            failWithDiagnostics(in: app, "切到更多分頁後畫面未就緒")
        }

        let paymentMethodsRow = app.descendants(matching: .any)[
            BLAccessibilityID.More.row(.paymentMethods)
        ]
        paymentMethodsRow.tapAfterWaiting(in: app, elementName: "付款方式主檔入口")

        let managementRoot = app.descendants(matching: .any)[
            BLAccessibilityID.LookupManagement.root
        ]
        if !managementRoot.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "付款方式管理頁面未出現")
        }

        let paymentMethodRow = app.descendants(matching: .any)[
            BLAccessibilityID.LookupManagement.row(Self.paymentMethodCorrectionName)
        ]
        try requireCondition(paymentMethodRow.waitUntilHittable(), in: app, "信用卡付款方式列未出現")
        paymentMethodRow.swipeLeft()

        let editButton = app.buttons[
            BLAccessibilityID.LookupManagement.editButton(Self.paymentMethodCorrectionName)
        ]
        editButton.tapAfterWaiting(in: app, elementName: "信用卡付款方式的編輯按鈕")

        let cashOnDeliveryToggle = app.switches[
            BLAccessibilityID.LookupManagement.paymentMethodCashOnDeliveryToggle
        ]
        if !cashOnDeliveryToggle.waitUntilHittable() {
            let editorRoot = app.descendants(matching: .any)[
                BLAccessibilityID.LookupManagement.paymentMethodEditorRoot
            ]
            try requireCondition(
                app.scrollToHittable(cashOnDeliveryToggle, within: editorRoot, maxSwipes: 6),
                in: app,
                "貨到付款旗標未出現或仍在畫面外"
            )
        }
        try requireCondition(
            (cashOnDeliveryToggle.value as? String) != "1",
            in: app,
            "回溯驗收的初始付款方式不應已標記為貨到付款"
        )
        // `Form` 內的開關要點內層開關，點外層列的中心會落在標題文字上
        cashOnDeliveryToggle.switches.firstMatch.tapAfterWaiting(in: app)
        try requireCondition(
            cashOnDeliveryToggle.wait(for: NSPredicate(format: "value == %@", "1"), timeout: 5),
            in: app,
            "點擊後貨到付款旗標未切換為開啟"
        )

        let saveButton = app.buttons[
            BLAccessibilityID.LookupManagement.paymentMethodSaveButton
        ]
        saveButton.tapAfterWaiting(in: app, elementName: "付款方式儲存按鈕")

        let correctionAlertMessage = "重算 1 筆"
        app.assertAlertMessage(contains: correctionAlertMessage, timeout: 15)
        app.tapAlertButton(label: "確認更正")
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "回溯重算確認 alert 未收回")
        }

        if !app.staticTexts["貨到付款"].waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "付款方式更新成功後，貨到付款分類徽章未出現")
        }

        app.terminate()

        var relaunchOptions = initialOptions
        relaunchOptions.shouldResetPersistentStore = false

        // When
        let relaunchedApp = launch(relaunchOptions)
        let persisted = try requireValue(
            profitValue(for: Self.paymentMethodCorrectionOrderID, in: relaunchedApp),
            in: relaunchedApp,
            "重啟後獲利卡的元素不存在"
        )
        try requireCondition(
            !persisted.isEmpty,
            in: relaunchedApp,
            "重啟後獲利卡的 accessibility value 為空"
        )

        // Then
        XCTAssertNotEqual(before, persisted, "補勾貨到付款後獲利應該改變並持久化")
    }
}

// MARK: - Private Method

private extension OrderDetailTests {

    /// 切到訂單分頁、點種子訂單進詳情並等就緒，回傳詳情 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - orderID: 要開啟的訂單編號；`nil` 時開啟 `sampleOrderID`
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

        orders.tapOrder(orderID: targetOrderID, file: file, line: line)

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
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - app: 受測 App
    /// - Returns: 獲利卡的 accessibility value
    @MainActor
    func profitValue(for orderID: String, in app: XCUIApplication) -> String? {
        openOrderDetail(app, orderID: orderID).summaryValue(.profit)
    }
}
