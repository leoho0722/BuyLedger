//
//  OrdersRegularAccessibilitySizeUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單篩選區在標準與最大輔助字級下的捲動歸屬守門 UI 測試
@MainActor
final class OrdersRegularAccessibilitySizeUITests: BLUITestCase {

    /// 驗證直向最大輔助字級時，regular 篩選控制項在清單內且依序排列
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選控制項越界時丟出測試錯誤
    func testTask_直向最大輔助字級_篩選區在清單捲動範圍內且不重疊() throws {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = try launch(options)

        // When
        _ = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )

        // Then
        try assertScrollableFilters(in: app)
    }

    /// 驗證最大輔助字級轉為橫向時，regular 篩選控制項依序排列且不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選控制項越界時丟出測試錯誤
    func testRotateToLandscape_最大輔助字級_篩選區在清單捲動範圍內且不重疊()
    throws {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = try launch(options)
        _ = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )

        // When
        try rotateToLandscape(app)

        // Then
        try assertScrollableFilters(in: app)
    }

    /// 驗證 regular 版面標準字級時，篩選區固定在清單捲動範圍上方
    ///
    /// - Throws: 版面不適用、元素缺少或篩選區進入捲動範圍時丟出測試錯誤
    func testTask_標準字級_篩選區固定在清單捲動範圍上方() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )

        // When
        let listFrame = try requireValidFrame(
            of: orders.rootElement,
            in: app,
            context: "訂單清單捲動範圍"
        )
        let clearFrame = try requireValidFrame(
            of: orders.regularClearFiltersButton,
            in: app,
            context: "清除篩選"
        )

        // Then
        try requireCondition(
            clearFrame.maxY <= listFrame.minY + 1,
            in: app,
            "位置越界：標準字級的清除篩選不在清單捲動範圍上方，"
                + "清除篩選 frame = \(clearFrame)，清單捲動範圍 frame = \(listFrame)"
        )
    }

    /// 驗證 regular 版面最大輔助字級時，點標頭空白處不改變付款方式篩選
    ///
    /// - Throws: 版面不適用、元素缺少或付款方式篩選改變時丟出測試錯誤
    func testTapRegularHeaderGap_最大輔助字級點標頭空白處_篩選條件不變() throws {
        // Given
        let app = try launch(
            LaunchOptions(
                seed: .categoryFilter,
                contentSizeCategory: .accessibilityExtraExtraExtraLarge
            )
        )
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try selectCreditCardFilter(on: orders, in: app)

        // When
        try orders.tapRegularHeaderGap()

        // Then
        try requireCondition(
            Polling.wait(timeout: 2) {
                orders.paymentMethodTriggerLabel().contains("付款方式：信用卡")
            },
            in: app,
            "點標頭空白處後付款方式應維持信用卡"
        )
    }

    /// 驗證最大輔助字級時點標頭空白處不改變篩選，且清除鈕仍可清除
    ///
    /// - Throws: 版面不適用、元素缺少或清除篩選結果不符時丟出測試錯誤
    func testClearFiltersTapped_最大輔助字級點標頭空白處後_清除鈕仍可清除()
    throws {
        // Given
        let app = try launch(
            LaunchOptions(
                seed: .categoryFilter,
                contentSizeCategory: .accessibilityExtraExtraExtraLarge
            )
        )
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try selectCreditCardFilter(on: orders, in: app)
        try orders.tapRegularHeaderGap()
        try requireCondition(
            orders.paymentMethodTriggerLabel().contains("付款方式：信用卡"),
            in: app,
            "點標頭空白處後付款方式應維持信用卡"
        )

        // When
        try orders.tapRegularClearFilters()

        // Then
        try requireCondition(
            Polling.wait(timeout: 3) {
                orders.paymentMethodTriggerLabel().contains("付款方式：全部")
            },
            in: app,
            "點清除篩選鈕後付款方式應回到全部"
        )
    }

    /// 驗證最大輔助字級時，選取起始位置在欄外的本月日期膠囊
    ///
    /// - Throws: 版面不適用、日期膠囊位置不符或選取未生效時丟出測試錯誤
    func testDatePeriodSelected_最大輔助字級_選取欄外日期膠囊() throws {
        // Given
        let app = try launch(
            LaunchOptions(
                seed: .categoryFilter,
                contentSizeCategory: .accessibilityExtraExtraExtraLarge
            )
        )
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try requireCondition(
            !orders.dateChip("thisMonth").isHittableOnScreen,
            in: app,
            "前提不成立：最大輔助字級時本月日期膠囊起始位置應在可見寬度之外"
        )

        // When
        try orders.selectRegularDateChip("thisMonth")

        // Then
        try requireCondition(
            orders.isRegularDateChipSelected("thisMonth"),
            in: app,
            "本月日期膠囊應呈選取狀態"
        )
    }
}

// MARK: - Private Method

private extension OrdersRegularAccessibilitySizeUITests {

    /// 逐項確認篩選控制項位於捲動範圍內，且與前一項沒有重疊
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 元素缺少、控制項越界或相鄰項目重疊時丟出測試錯誤
    func assertScrollableFilters(in app: XCUIApplication) throws {
        let orders = OrdersScreen(app: app)
        let listFrame = try requireValidFrame(
            of: orders.rootElement,
            in: app,
            context: "訂單清單捲動範圍"
        )
        let filters: [(XCUIElement, String)] = [
            (orders.statusChip("all"), "狀態膠囊"),
            (orders.dateChip("all"), "全部時間膠囊"),
            (orders.paymentMethodTrigger, "付款方式"),
            (orders.categoryTrigger, "類別"),
            (orders.regularClearFiltersButton, "清除篩選"),
        ]
        var previous: (name: String, frame: CGRect)?
        for (element, name) in filters {
            let frame = try requireValidFrame(of: element, in: app, context: name)
            try requireCondition(
                frame.minY >= listFrame.minY - 1,
                in: app,
                "位置越界：\(name) 不在清單捲動範圍內，"
                    + "\(name) frame = \(frame)，清單捲動範圍 frame = \(listFrame)"
            )
            if let previous {
                try requireCondition(
                    previous.frame.maxY <= frame.minY + 1,
                    in: app,
                    "位置越界：\(previous.name) 與 \(name) 重疊，"
                        + "\(previous.name) frame = \(previous.frame)，\(name) frame = \(frame)"
                )
            }
            previous = (name, frame)
        }
    }

    /// 選取信用卡付款方式並確認前置狀態
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    /// - Throws: 付款方式選取未生效時丟出測試錯誤
    func selectCreditCardFilter(on orders: OrdersScreen, in app: XCUIApplication) throws {
        try orders.selectPaymentMethodInRegularLayout("信用卡")
        try requireCondition(
            Polling.wait(timeout: 3) {
                orders.paymentMethodTriggerLabel().contains("付款方式：信用卡")
            },
            in: app,
            "前提不成立：付款方式應為信用卡，實際為「"
                + "\(orders.paymentMethodTriggerLabel())」"
        )
    }
}
