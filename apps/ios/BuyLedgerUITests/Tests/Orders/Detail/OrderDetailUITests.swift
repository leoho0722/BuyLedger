//
//  OrderDetailUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單詳情財務摘要與付款方式回溯重算持久化的 UI 測試
@MainActor
final class OrderDetailUITests: BLUITestCase {

    // MARK: - Properties

    /// `fullOrders` 中用於詳情測試的訂單編號
    private static let sampleOrderID = "BL-2604-018"

    /// `paymentMethodCorrection` 中用於回溯重算驗收的訂單編號
    private static let paymentMethodCorrectionOrderID = "UITEST-PMC-001"

    /// 回溯重算驗收所使用的付款方式名稱
    private static let paymentMethodCorrectionName = "信用卡"

    /// 詳情財務摘要卡的三個種類，依序為營收、成本與獲利
    private static let summaryTiles: [BLAccessibilityID.Orders.SummaryTile] = [
        .revenue,
        .cost,
        .profit,
    ]

    /// `fullOrders` 種子資料的營收、成本與獲利顯示值
    private static let expectedSummaryValues = ["$11,800", "$9,069", "+$2,731"]

    /// 驗證開啟完整資料的訂單詳情時，財務摘要卡的營收、成本與獲利依序為 $11,800、$9,069 與 +$2,731
    ///
    /// - Throws: 詳情無法開啟或摘要卡值不存在時丟出 UITestError.stopped
    func testDetailSelectionChanged_完整資料訂單_摘要卡顯示營收成本與獲利() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))

        // When
        let detail = try OrdersScreen.open(in: app).tapOrder(orderID: Self.sampleOrderID)

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

    /// 驗證補勾貨到付款並確認回溯更正後，重啟讀到的獲利為 +$510，三種運費已持久化
    ///
    /// - Throws: 必要的 UI 操作、讀值或回溯更正前置不成立時丟出 UITestError.stopped
    func testLaunch_補勾貨到付款後重啟_獲利持久化為五百一十元() throws {
        // Given
        var initialOptions = LaunchOptions(seed: .paymentMethodCorrection)
        initialOptions.persistenceMode = .persistent
        initialOptions.shouldResetPersistentStore = true

        let app = try launch(initialOptions)
        let profitBefore = try profitValue(for: Self.paymentMethodCorrectionOrderID, in: app)
        let before = try requireValue(profitBefore, in: app, "回溯前獲利卡的元素不存在")
        try requireCondition(before == "+$970", in: app, "回溯前獲利應為 +$970，實際為 \(before)")

        let management = try LookupManagementScreen.open(.paymentMethods, in: app)
        let editor = try management.beginEditPaymentMethod(named: Self.paymentMethodCorrectionName)
        try editor.revealCashOnDeliveryToggle()
        let isCashOnDeliveryOn = editor.isCashOnDeliveryOn
        try requireCondition(!isCashOnDeliveryOn, in: app, "回溯驗收的初始付款方式不應已標記為貨到付款")
        try editor.toggleCashOnDelivery()
        let isCashOnDeliveryEnabled = editor.isCashOnDeliveryOn
        try requireCondition(isCashOnDeliveryEnabled, in: app, "點擊後貨到付款旗標未切換為開啟")
        try editor.tapSave()

        try app.assertAlertMessage(contains: "重算 1 筆", timeout: 15)
        try app.tapAlertButton(label: "確認更正")
        try requireCondition(app.alertDismissed(), in: app, "回溯重算確認 alert 未收回")
        let hasCashOnDeliveryClassification = Polling.wait(timeout: 10) {
            management.paymentMethodClassification(named: Self.paymentMethodCorrectionName)
                == "貨到付款"
        }
        try requireCondition(hasCashOnDeliveryClassification, in: app, "付款方式更新成功後，完整分類值未顯示貨到付款")

        app.terminate()
        var relaunchOptions = initialOptions
        relaunchOptions.shouldResetPersistentStore = false

        // When
        let relaunchedApp = try launch(relaunchOptions)
        let persistedProfit = try profitValue(
            for: Self.paymentMethodCorrectionOrderID,
            in: relaunchedApp
        )

        // Then
        let persisted = try requireValue(persistedProfit, in: relaunchedApp, "重啟後獲利卡的元素不存在")
        XCTAssertEqual(persisted, "+$510", "補勾貨到付款後獲利應扣除三種運費並持久化")
    }
}

// MARK: - Private Method

private extension OrderDetailUITests {

    /// 讀取指定訂單詳情的獲利 accessibility value
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 獲利卡的 accessibility value
    /// - Throws: 訂單詳情無法開啟時丟出 UITestError.stopped
    func profitValue(
        for orderID: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> String? {
        try OrdersScreen.open(in: app, file: file, line: line)
            .tapOrder(orderID: orderID, file: file, line: line).summaryValue(.profit)
    }
}
