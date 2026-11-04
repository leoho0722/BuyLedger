//
//  OrderRegularAccessibilitySizeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單篩選區在標準與最大輔助字級下的捲動歸屬守門 UI 測試
@MainActor
final class OrderRegularAccessibilitySizeTests: BLUITestCase {

    // MARK: - Properties

    /// 版面不符時略過測試的原因，說明 compact 篩選由 `OrderFilterSheetTests` 覆蓋
    private static let layoutScopeReason = """
    篩選區歸屬只適用 regular 版面
    compact 篩選由 OrderFilterSheetTests 覆蓋
    """

    /// 驗證 regular 版面直向最大輔助字級時，篩選控制項位於清單捲動範圍內，依序排列且彼此不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選控制項越界時丟出測試錯誤
    func testRegularFilters_直向最大輔助字級_篩選區在清單捲動範圍內且不重疊() throws {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = launch(options)
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        try openOrders(in: app)

        // Then
        try assertScrollableFilters(in: app)
    }

    /// 驗證 regular 版面轉為橫向、最大輔助字級時，篩選控制項位於清單捲動範圍內，依序排列且彼此不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選控制項越界時丟出測試錯誤
    func testRegularFilters_橫向最大輔助字級_篩選區在清單捲動範圍內且不重疊() throws {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = launch(options)
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        try openOrders(in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try assertScrollableFilters(in: app)
    }

    /// 驗證 regular 版面標準字級時，篩選區固定在清單捲動範圍上方，清除篩選鈕不進入捲動範圍
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選區進入捲動範圍時丟出測試錯誤
    func testRegularFilters_標準字級_篩選區固定在清單捲動範圍上方() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        try openOrders(in: app)

        // Then
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "訂單清單捲動範圍")
        let clearButton = app
            .descendants(matching: .any)[BLAccessibilityID.Orders.clearFiltersButton]
        let clearFrame = try requireValidFrame(of: clearButton, in: app, context: "清除篩選")
        try requireCondition(
            clearFrame.maxY <= listFrame.minY + 1,
            in: app,
            """
            位置越界：標準字級的清除篩選不在清單捲動範圍上方
            清除篩選 frame = \(clearFrame)，清單捲動範圍 frame = \(listFrame)
            """
        )
    }

    /// 驗證 regular 版面最大輔助字級時，點清單標頭空白處不清除篩選，點清除篩選鈕本身才清除
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選狀態不符時丟出測試錯誤
    func testRegularFilters_最大輔助字級點標頭空白處_篩選不變且清除鈕仍可清除() throws {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = launch(options)
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        try openOrders(in: app)
        let orders = OrdersScreen(app: app)
        orders.selectPaymentMethodInRegularLayout("信用卡")
        try requireCondition(
            pollUntil(timeout: 3) { orders.paymentMethodTriggerLabel.contains("付款方式：信用卡") },
            in: app,
            "前提不成立：付款方式應為信用卡，實際為「\(orders.paymentMethodTriggerLabel)」"
        )

        // When
        try tapHeaderGap(in: app)

        // Then
        let isClearedByGapTap = pollUntil(timeout: 2) {
            orders.paymentMethodTriggerLabel.contains("付款方式：全部")
        }
        XCTAssertFalse(isClearedByGapTap, "點標頭空白處後付款方式應維持信用卡")

        // When
        orders.tapRegularClearFilters()

        // Then
        let isCleared = pollUntil(timeout: 3) {
            orders.paymentMethodTriggerLabel.contains("付款方式：全部")
        }
        XCTAssertTrue(isCleared, "點清除篩選鈕後付款方式應回到全部")
    }
}

// MARK: - Private Method

private extension OrderRegularAccessibilitySizeTests {

    /// 切到訂單分頁並等待清單根容器就緒
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 訂單分頁或清單根容器未就緒時丟出測試錯誤
    func openOrders(in app: XCUIApplication) throws {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "找不到元素：訂單分頁根容器")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "找不到元素：訂單清單根容器")
    }

    /// 逐項確認篩選控制項位於捲動範圍內，且與前一項沒有重疊
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 必要元素缺少、篩選控制項越界或相鄰控制項重疊時丟出測試錯誤
    func assertScrollableFilters(in app: XCUIApplication) throws {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "訂單清單捲動範圍")
        let filters: [(identifier: String, name: String)] = [
            (BLAccessibilityID.Orders.statusChip("all"), "狀態膠囊"),
            (BLAccessibilityID.Orders.dateChip("all"), "全部時間膠囊"),
            (BLAccessibilityID.Orders.paymentMethodMenuButton, "付款方式"),
            (BLAccessibilityID.Orders.categoryFilterButton, "類別"),
            (BLAccessibilityID.Orders.clearFiltersButton, "清除篩選"),
        ]
        var previous: (name: String, frame: CGRect)?
        for (identifier, name) in filters {
            let element = app.descendants(matching: .any)[identifier]
            let frame = try requireValidFrame(of: element, in: app, context: name)
            try requireCondition(
                frame.minY >= listFrame.minY - 1,
                in: app,
                """
                位置越界：\(name) 不在清單捲動範圍內
                \(name) frame = \(frame)，清單捲動範圍 frame = \(listFrame)
                """
            )
            if let previous {
                try requireCondition(
                    previous.frame.maxY <= frame.minY + 1,
                    in: app,
                    """
                    位置越界：\(previous.name) 與 \(name) 重疊
                    \(previous.name) frame = \(previous.frame)，\(name) frame = \(frame)
                    """
                )
            }
            previous = (name, frame)
        }
    }

    /// 點清單標頭內清除篩選鈕右側的空白處；點旁邊篩選按鈕之間的間隙會開到類別選擇器，所以避開間隙
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 必要元素缺少、不可點或右側空白不足時丟出測試錯誤
    func tapHeaderGap(in app: XCUIApplication) throws {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "訂單清單捲動範圍")
        let clearButton = app
            .descendants(matching: .any)[BLAccessibilityID.Orders.clearFiltersButton]
        let clearFrame = try requireHittableFrame(of: clearButton, in: app, context: "清除篩選")
        let blankX = listFrame.maxX - 8
        try requireCondition(
            blankX - clearFrame.maxX >= 20,
            in: app,
            "前提不成立：清除篩選鈕右側空白不足，鈕 frame = \(clearFrame)，清單 frame = \(listFrame)"
        )
        let blankOffset = CGVector(dx: blankX, dy: clearFrame.midY)
        app.coordinate(withNormalizedOffset: .zero).withOffset(blankOffset).tap()
    }
}
