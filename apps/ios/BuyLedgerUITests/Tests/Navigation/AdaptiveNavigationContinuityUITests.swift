//
//  AdaptiveNavigationContinuityUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 跨功能的自適應導覽連續性 UI 測試，涵蓋根導覽、訂單、更多、開團與總覽在版面切換後的狀態保留，以及框線與可見值檢查
///
/// - Note: 對應驗收矩陣 N1 至 N6 與 L1 至 L4 的可自動化部分
@MainActor
final class AdaptiveNavigationContinuityUITests: BLUITestCase {

    /// 驗證 iPad 根導覽初始為分頁列，直向 overlay 切換目的地後收起，橫向保留側邊欄偏好與目的地
    ///
    /// - Throws: 根畫面、原生分頁、側邊欄標記或轉向條件不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N1
    func testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try requireValue(
            navigator.rootLayout,
            in: app,
            "根導覽版面無法判定 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )
        try XCTSkipUnless(layout == .regular, "根側邊欄只存在於 regular 版面，compact 版面沒有側邊欄偏好可驗")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        let isSidebarMarkerInitiallyVisible = navigator.isSidebarMarkerVisible
        let initialTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            !isSidebarMarkerInitiallyVisible && initialTabCount == 5,
            in: app,
            "初始狀態應為分頁列 (可見數=\(initialTabCount)，sidebar marker=\(isSidebarMarkerInitiallyVisible))"
        )

        // When
        let sidebarToggle = try requireValue(
            navigator.rootSidebarToggle(),
            in: app,
            "找不到唯一可辨識的原生側邊欄按鈕 ToggleSideBar 或 ToggleSidebar"
        )
        try requireCondition(
            sidebarToggle.waitUntilHittable(timeout: 10),
            in: app,
            "原生側邊欄切換按鈕已存在但不可點"
        )
        sidebarToggle.tap()

        // Then
        let isSidebarMarkerVisibleAfterToggle = navigator.waitForRootSidebarMarkerVisible(
            timeout: 10
        )
        let tabCountAfterToggle = navigator.visibleRootTabCount()
        try requireCondition(
            isSidebarMarkerVisibleAfterToggle && tabCountAfterToggle == 5,
            in: app,
            "切換側邊欄後標記未顯示或目的地數不為 5 (marker 可見=\(isSidebarMarkerVisibleAfterToggle)，可見數=\(tabCountAfterToggle))"
        )

        let ordersTabInPortraitSidebar = navigator.rootTabElement(for: .orders)
        try requireCondition(
            ordersTabInPortraitSidebar.label.hasSuffix(", 4"),
            in: app,
            "直向側邊欄中訂單分頁標籤應以「, 4」結尾 (實際為：\"\(ordersTabInPortraitSidebar.label)\")"
        )

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "直向側邊欄切換至訂單分頁失敗")

        // Then
        let isSidebarMarkerDismissed = waitForSidebarMarkerHidden(navigator: navigator, timeout: 10)
        let tabCountAfterDismiss = navigator.visibleRootTabCount()
        try requireCondition(
            isSidebarMarkerDismissed && tabCountAfterDismiss == 5,
            in: app,
            "直向 overlay 點選目的地後未收起回到分頁列 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(tabCountAfterDismiss))"
        )

        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "直向收起側邊欄後訂單清單根未就緒")
        let order018 = ordersScreen.orderRow(orderID: "BL-2604-018")
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "直向收起側邊欄後訂單列 BL-2604-018 不可互動"
        )

        let ordersTab = navigator.rootTabElement(for: .orders)
        try requireCondition(ordersTab.isSelected, in: app, "回到分頁列後訂單分頁未處於選取狀態")

        // When
        try rotateToLandscape(app)

        if !navigator.waitForRootSidebarMarkerVisible(timeout: 5) {
            let landscapeToggle = try requireValue(
                navigator.rootSidebarToggle(),
                in: app,
                "橫向時找不到原生側邊欄切換按鈕"
            )
            try requireCondition(
                landscapeToggle.waitUntilHittable(timeout: 10),
                in: app,
                "橫向原生側邊欄切換按鈕不可點"
            )
            landscapeToggle.tap()
            try requireCondition(
                navigator.waitForRootSidebarMarkerVisible(timeout: 10),
                in: app,
                "橫向開啟側邊欄後標記未顯示"
            )
        }

        // Then
        try requireCondition(
            navigator.isSidebarMarkerVisible && navigator.visibleRootTabCount() == 5,
            in: app,
            "橫向側邊欄狀態未確立 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )

        let ordersTabInLandscape = navigator.rootTabElement(for: .orders)
        try requireCondition(
            ordersTabInLandscape.label.hasSuffix(", 4"),
            in: app,
            "橫向側邊欄中訂單分頁標籤應以「, 4」結尾 (實際為：\"\(ordersTabInLandscape.label)\")"
        )

        // When
        try requireCondition(navigator.tapRootTab(.more), in: app, "橫向側邊欄切換至更多分頁失敗")
        let settingsID = BLAccessibilityID.More.row(.settings)
        let settingsRowInMore = app.descendants(matching: .any)[settingsID].firstMatch
        try requireCondition(
            settingsRowInMore.waitUntilHittable(timeout: 10),
            in: app,
            "切換至更多分頁後設定入口列不可互動"
        )

        // Then
        try requireCondition(
            navigator.isSidebarMarkerVisible && navigator.visibleRootTabCount() == 5,
            in: app,
            "橫向切到 More 後側邊欄偏好未保留 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "橫向側邊欄切回訂單分頁失敗")

        // Then
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "橫向切回訂單分頁後訂單列 BL-2604-018 不可互動"
        )
        try requireCondition(
            navigator.isSidebarMarkerVisible && navigator.visibleRootTabCount() == 5,
            in: app,
            "橫向切回訂單分頁後側邊欄偏好未保留 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )

        // When
        try rotateToPortrait(app)

        // Then
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "橫向轉直向後訂單清單根未就緒")
        let markerStabilizationDeadline = Date.now.addingTimeInterval(3)
        var lastMarkerSample: MarkerVisibilitySample = .unknown
        var isSidebarMarkerVisibleAfterPortraitRotate = navigator.isSidebarMarkerVisible
        while Date.now < markerStabilizationDeadline {
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
            let currentSample: MarkerVisibilitySample = navigator.isSidebarMarkerVisible
                ? .visible
                : .hidden
            if lastMarkerSample == currentSample {
                isSidebarMarkerVisibleAfterPortraitRotate = currentSample == .visible
                break
            }
            lastMarkerSample = currentSample
        }
        let portraitTabsAfterRotate = navigator.visibleRootTabCount()
        try requireCondition(
            portraitTabsAfterRotate == 5,
            in: app,
            "橫向轉直向後可見目的地數不為 5 (實際為 \(portraitTabsAfterRotate)，marker 可見=\(isSidebarMarkerVisibleAfterPortraitRotate))"
        )

        // When
        // 直向 overlay 開啟時點選訂單分頁收起，未開啟時不需操作
        var isOverlayDismissed = true
        if isSidebarMarkerVisibleAfterPortraitRotate {
            try requireCondition(
                navigator.tapRootTab(.orders),
                in: app,
                "直向 overlay 點選訂單分頁失敗 (分頁數=\(portraitTabsAfterRotate)，marker=\(isSidebarMarkerVisibleAfterPortraitRotate))"
            )
            isOverlayDismissed = waitForSidebarMarkerHidden(navigator: navigator, timeout: 10)
        }

        // Then
        try requireCondition(isOverlayDismissed, in: app, "直向點選訂單後側邊欄 overlay 未收起")
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "橫向轉直向後訂單列 BL-2604-018 不可互動 (分頁數=\(portraitTabsAfterRotate)，marker=\(isSidebarMarkerVisibleAfterPortraitRotate))"
        )

        // When
        try rotateToLandscape(app)

        // Then
        let isSidebarMarkerVisibleAfterLandscapeReturn = navigator.waitForRootSidebarMarkerVisible(
            timeout: 10
        )
        let landscapeTabsAfterReturn = navigator.visibleRootTabCount()
        try requireCondition(
            isSidebarMarkerVisibleAfterLandscapeReturn && landscapeTabsAfterReturn == 5,
            in: app,
            "轉回橫向後側邊欄偏好或目的地數未保留 (marker 可見=\(isSidebarMarkerVisibleAfterLandscapeReturn)，分頁數=\(landscapeTabsAfterReturn))"
        )
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "轉回橫向後訂單列 BL-2604-018 不可互動"
        )

        // When
        let sidebarToggleBack = try requireValue(
            navigator.rootSidebarToggle(),
            in: app,
            "找不到切回分頁列的原生側邊欄按鈕"
        )
        try requireCondition(
            sidebarToggleBack.waitUntilHittable(timeout: 10),
            in: app,
            "切回分頁列的原生按鈕不可點"
        )
        sidebarToggleBack.tap()

        // Then
        let isSidebarMarkerDismissedBack = waitForSidebarMarkerHidden(
            navigator: navigator,
            timeout: 10
        )
        try requireCondition(
            isSidebarMarkerDismissedBack && navigator.visibleRootTabCount() == 5,
            in: app,
            "切回分頁列後側邊欄標記未消失或可見目的地數不為 5 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "切回分頁列後訂單列 BL-2604-018 不可互動"
        )
    }

    /// 驗證已套用付款方式與類別篩選後，原生根 sidebar 顯示時五個目的地仍在，Orders path 與篩選列值不變
    ///
    /// - Throws: 根 sidebar、Orders path、篩選列或前景欄位模式不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N1
    /// - Note: 根樣式變化不應重建功能狀態
    func testRootStyleChangeKeepsOrders_側邊欄展開_訂單選取與篩選不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try requireValue(navigator.rootLayout, in: app, "根導覽版面無法判定，無法界定 sidebar 案例")
        try XCTSkipUnless(layout == .regular, "原生根 sidebar 只適用 regular 根導覽")
        let initialTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            !navigator.isSidebarMarkerVisible && initialTabCount == 5,
            in: app,
            "sidebar 案例應從五個原生根 Tabs 開始，實際數量=\(initialTabCount)"
        )
        try requireCondition(navigator.tapRootTab(.orders), in: app, "無法切到訂單分頁")

        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        // 先套用非預設的付款方式與類別篩選，前後比較才抓得到篩選被重設
        let picker = OrderCategoryPickerScreen(app: app)
        orders.selectPaymentMethodInRegularLayout("信用卡")
        orders.openCategoryPicker()
        picker.tapPickerCategory("美妝")
        picker.tapPickerDone()
        orders.tapOrder(orderID: "BL-2604-018")
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        let paymentMethodButton = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.paymentMethodMenuButton
        ]
        let categoryButton = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.categoryFilterButton
        ]
        try requireCondition(
            paymentMethodButton.waitForExistence(timeout: 10),
            in: app,
            "找不到付款方式篩選鈕"
        )
        try requireCondition(categoryButton.waitForExistence(timeout: 10), in: app, "找不到類別篩選鈕")
        try requireCondition(
            paymentMethodButton.wait(
                for: NSPredicate(format: "label CONTAINS %@", "信用卡"),
                timeout: 10
            ),
            in: app,
            "套用付款方式篩選後篩選列值未含「信用卡」，實際為「\(orders.paymentMethodTriggerLabel)」"
        )
        try requireCondition(
            categoryButton.wait(for: NSPredicate(format: "label CONTAINS %@", "美妝"), timeout: 10),
            in: app,
            "套用類別篩選後篩選列值未含「美妝」，實際為「\(orders.categoryTriggerLabel)」"
        )
        let paymentMethodLabelBefore = orders.paymentMethodTriggerLabel
        let categoryLabelBefore = orders.categoryTriggerLabel

        // When
        try requireCondition(navigator.revealSidebarIfCollapsed(), in: app, "無法顯示原生根 sidebar")

        // Then
        try requireCondition(navigator.isSidebarMarkerVisible, in: app, "原生根 sidebar 標記未出現")
        try requireCondition(navigator.visibleRootTabCount() == 5, in: app, "根 sidebar 模式未保留五個目的地")
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try requireCondition(
            paymentMethodButton.waitForExistence(timeout: 10),
            in: app,
            "根樣式切換後找不到付款方式篩選鈕"
        )
        try requireCondition(
            orders.paymentMethodTriggerLabel == paymentMethodLabelBefore,
            in: app,
            "根樣式切換後付款方式篩選列值應維持「\(paymentMethodLabelBefore)」，實際為「\(orders.paymentMethodTriggerLabel)」"
        )
        try requireCondition(
            categoryButton.waitForExistence(timeout: 10),
            in: app,
            "根樣式切換後找不到類別篩選鈕"
        )
        try requireCondition(
            orders.categoryTriggerLabel == categoryLabelBefore,
            in: app,
            "根樣式切換後類別篩選列值應維持「\(categoryLabelBefore)」，實際為「\(orders.categoryTriggerLabel)」"
        )
        try assertOrdersLayoutIsRecognized(in: app)
        try requireCondition(
            OrderDetailScreen(app: app).waitUntilReady(),
            in: app,
            "根 sidebar 切換後訂單詳情未保留"
        )
    }

    /// 驗證 iPad 同一訂單在並排與收合之間旋轉時，路徑與詳情內容都保持為當前訂單
    ///
    /// - Throws: 根導覽、訂單清單、路徑標記或詳情內容不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N2
    /// - Note: 只驗證 iPad 同 ID 保留
    func testSelectionSurvivesLayoutChange_並排且已選取_路徑與詳情同為當前訂單() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try rotateToLandscape(app)
        let layout = try requireValue(navigator.rootLayout, in: app, "橫向根導覽版面無法判定")
        try XCTSkipUnless(layout == .regular, "需 iPad regular 根導覽")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        try XCTSkipUnless(isRegularLayout(app), "需 Orders 清單與詳情並排")

        // When
        orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try rotateToPortrait(app)

        // Then
        try XCTSkipUnless(!isRegularLayout(app), "直向仍為並排版面，此裝置直向不會收合")
        try requireCondition(isCompactLayout(app), in: app, "直向後 Orders 應為收合版面")
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(isRegularLayout(app), in: app, "回到橫向後 Orders 應為並排版面")
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        orders.tapOrder(orderID: "BL-2604-015")

        // Then
        try requireSelectedOrder("BL-2604-015", in: orders, app: app)
        try requireDetailShows("BL-2604-015", excluding: "BL-2604-017", in: app)

        // When
        try rotateToPortrait(app)

        // Then
        try requireCondition(isCompactLayout(app), in: app, "直向後 Orders 應為收合版面")
        try requireSelectedOrder("BL-2604-015", in: orders, app: app)
        try requireDetailShows("BL-2604-015", excluding: "BL-2604-017", in: app)
    }

    /// 驗證首次進入訂單時沒有自動選取，旋轉後仍未選取
    ///
    /// - Throws: 訂單清單、路徑標記、提示或返回路徑不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N3
    /// - Note: 寬版以未選取提示判定，收合版以清單可見判定
    /// - Note: 收合版的原生返回與返回後未選取由 `testOrders_選取訂單詳情與原生返回_Mika周017營收4980且path清空` 覆蓋
    func testOrdersStartUnselected_首次進入訂單_旋轉後仍未選取() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        let orders = OrdersScreen(app: app)

        // When
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        try assertOrdersLayoutIsRecognized(in: app)

        // Then
        try requireOrdersUnselected(orders, in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try assertOrdersLayoutIsRecognized(in: app)
        try requireOrdersUnselected(orders, in: app)

        // When
        orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireDetailShows("BL-2604-017", in: app)
    }

    /// 驗證首次進入更多時沒有目前工具，寬版顯示未選取提示且設定列未選取，收合版顯示入口列
    ///
    /// - Throws: 更多前景模式、提示、入口列或幾何防護不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N3
    /// - Note: 版面以 `isMoreRegularLayout` 與 `isMoreCompactLayout` 判定，不以根導覽代替
    /// - Note: 收合分支以入口列寬度排除並排但缺提示的情況
    func testMoreStartsUnselected_首次進入更多_寬版顯示提示且收合版顯示入口列() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        // When
        try rotateToLandscape(app)
        try requireCondition(root.goToMore(), in: app, "切換至更多分頁後畫面未就緒")

        // Then
        if isMoreRegularLayout(app) {
            let prompt = app.descendants(matching: .any)[BLAccessibilityID.Common.detailEmptyState]
                .firstMatch
            try requireCondition(
                prompt.waitUntilHittable(timeout: 10),
                in: app,
                "寬版首次進入更多頁時未顯示未選取提示"
            )
            let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
                .firstMatch
            try requireCondition(!settingsRow.isSelected, in: app, "寬版首次進入更多頁時設定入口列不應已選取")
            let observed = try requireMoreSelection(in: app)
            try requireCheckPassed(
                IdentifierCheck.verify(expected: "", observed: observed),
                in: app
            )
        } else {
            try requireCondition(isMoreCompactLayout(app), in: app, "更多前景應為並排或收合其中之一")
            let fxRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)].firstMatch
            try requireCondition(fxRow.waitUntilHittable(timeout: 10), in: app, "收合版首次進入更多頁時入口列不可見")
            let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
            let rowFrame = try requireValidFrame(of: fxRow, in: app, context: "收合版入口列框線")
            try requireCondition(
                rowFrame.width > window.width * 0.6,
                in: app,
                "收合版入口列寬度應大於視窗寬度的 60%，實際為 \(rowFrame.width) / \(window.width)"
            )
        }
    }

    /// 驗證搜尋仍命中已選訂單時保留選取與詳情，排除時清空路徑且搜尋恢復後不自動選取
    ///
    /// - Throws: 搜尋、路徑標記、詳情或無選取提示不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N4
    /// - Note: 排除段的斷言與 `testOrders_搜尋排除詳情後清除path_恢復結果不自動選取` 相同
    func testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        try XCTSkipUnless(isRegularLayout(app), "同步搜尋與詳情需 Orders 欄位並排")

        // When
        orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try orders.search("Mika")

        // Then
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try orders.search("ZZZ-NO-SUCH-ORDER")

        // Then
        let emptySelection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "排除搜尋後 Orders path 標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "", observed: emptySelection),
            in: app
        )
        try assertUnselectedPromptVisible(in: app)

        // When
        try orders.search("Mika")

        // Then
        let restoredSelection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "搜尋恢復後 Orders path 標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "", observed: restoredSelection),
            in: app
        )
        try requireCondition(orders.hasOrder(orderID: "BL-2604-017"), in: app, "搜尋結果未恢復")
    }

    /// 驗證從更多進入設定後切換至訂單並切換根樣式，切回更多時直接保留設定頁目的地，原生返回可退回更多入口
    ///
    /// - Throws: 畫面元素未出現、分頁切換失敗或導覽連續性不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N5A
    func testMoreSettingsSurvivesRoundTrip_更多設定頁前景_設定頁保留() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders, monthlyProfitGoalTWD: 90000))
        let navigator = AppNavigator(app: app)
        let layout = try requireValue(
            navigator.rootLayout,
            in: app,
            "根導覽版面無法判定 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )
        try XCTSkipUnless(layout == .regular, "根樣式切換只存在於 regular 版面")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        try requireCondition(navigator.tapRootTab(.more), in: app, "點選原生 More 分頁失敗")
        let settingsID = BLAccessibilityID.More.row(.settings)
        let settingsRow = app.descendants(matching: .any)[settingsID].firstMatch
        try requireCondition(
            settingsRow.waitUntilHittable(timeout: 10),
            in: app,
            "More 中的設定入口列未就緒或不可點"
        )
        settingsRow.tap()

        let settingsRootID = BLAccessibilityID.Settings.root
        let settingsRoot = app.descendants(matching: .any)[settingsRootID].firstMatch
        try requireCondition(
            settingsRoot.waitForExistence(timeout: 10),
            in: app,
            "點選設定入口後 Settings.root 未出現"
        )
        let goalFieldID = BLAccessibilityID.Settings.monthlyGoalField
        let monthlyGoalField = app.textFields[goalFieldID].firstMatch
        try requireCondition(
            monthlyGoalField.waitUntilHittable(timeout: 10),
            in: app,
            "設定頁中的每月目標欄位未進入可互動狀態"
        )
        let initialGoal = try requireValue(
            monthlyGoalField.value as? String,
            in: app,
            "設定頁每月目標欄位之 value 為 nil"
        )
        try requireCondition(
            initialGoal == "90000",
            in: app,
            "設定頁每月目標初始數值非預期的 90000 (實際為：\(initialGoal))"
        )

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "從設定頁切換至訂單分頁失敗")
        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "切換至訂單分頁後清單根未就緒")
        let order018 = ordersScreen.orderRow(orderID: "BL-2604-018")
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "訂單列 BL-2604-018 未就緒"
        )

        let isMarkerVisibleBefore = navigator.isSidebarMarkerVisible
        let tabCountBefore = navigator.visibleRootTabCount()
        try requireCondition(
            !isMarkerVisibleBefore && tabCountBefore == 5,
            in: app,
            "切換根樣式前應為分頁列模式 (marker 可見=\(isMarkerVisibleBefore)，分頁數=\(tabCountBefore))"
        )

        let sidebarToggle = try requireValue(navigator.rootSidebarToggle(), in: app, "找不到原生側邊欄切換按鈕")
        try requireCondition(sidebarToggle.waitUntilHittable(timeout: 10), in: app, "原生側邊欄切換按鈕不可點")
        sidebarToggle.tap()

        // Then
        try requireCondition(
            navigator.waitForRootSidebarMarkerVisible(timeout: 10),
            in: app,
            "切換後側邊欄品牌標記未出現"
        )

        // When
        try requireCondition(navigator.tapRootTab(.more), in: app, "從側邊欄切回 More 分頁失敗")

        // Then
        try requireCondition(
            monthlyGoalField.waitUntilHittable(timeout: 10),
            in: app,
            "切回 More 後設定頁每月目標欄位不可互動，未能保留設定頁前景"
        )
        let goalAfterSidebar = try requireValue(
            monthlyGoalField.value as? String,
            in: app,
            "切回 More 後每月目標欄位之 value 為 nil"
        )
        try requireCondition(
            goalAfterSidebar == "90000",
            in: app,
            "切回 More 後每月目標數值未保留 (預期：90000，實際：\(goalAfterSidebar))"
        )
        if isMoreCompactLayout(app) {
            try requireCondition(
                !settingsRow.isHittableOnScreen,
                in: app,
                "切回 More 後 More 入口列不應處於前景可點狀態"
            )
        } else {
            try requireCondition(settingsRow.isSelected, in: app, "寬版切回 More 後設定入口列應維持已選取")
        }

        // When
        // 切回分頁列樣式：先依 `isSidebarMarkerVisible` 判斷目前樣式再操作，不可盲點切換鈕
        let isSidebarMarkerDismissed: Bool
        if navigator.isSidebarMarkerVisible {
            let sidebarToggleBack = try requireValue(
                navigator.rootSidebarToggle(),
                in: app,
                "找不到切回分頁列的原生按鈕"
            )
            try requireCondition(
                sidebarToggleBack.waitUntilHittable(timeout: 10),
                in: app,
                "切回分頁列的原生按鈕不可點"
            )
            sidebarToggleBack.tap()
            isSidebarMarkerDismissed = waitForSidebarMarkerHidden(navigator: navigator, timeout: 10)
        } else {
            isSidebarMarkerDismissed = waitForSidebarMarkerHidden(navigator: navigator, timeout: 5)
        }

        // Then
        try requireCondition(
            isSidebarMarkerDismissed && navigator.visibleRootTabCount() == 5,
            in: app,
            "切回分頁列後側邊欄品牌標記仍存在或分頁數不為 5 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切換至訂單分頁失敗")
        try requireCondition(order018.waitUntilHittable(timeout: 10), in: app, "訂單清單列未就緒")
        try requireCondition(navigator.tapRootTab(.more), in: app, "切回 More 分頁失敗")

        // Then
        try requireCondition(
            monthlyGoalField.waitUntilHittable(timeout: 10),
            in: app,
            "切回分頁列後再經訂單來回，More 仍應停留在設定頁前景"
        )
        let goalAfterTabsRoundTrip = try requireValue(
            monthlyGoalField.value as? String,
            in: app,
            "再次切回 More 後每月目標欄位之 value 為 nil"
        )
        try requireCondition(
            goalAfterTabsRoundTrip == "90000",
            in: app,
            "再次切回 More 後每月目標數值未保留 (預期：90000，實際：\(goalAfterTabsRoundTrip))"
        )

        // When
        let isCompactBeforeBack = isMoreCompactLayout(app)
        if isCompactBeforeBack {
            try app.tapUniqueNativeBackButton()
        }

        // Then
        if isCompactBeforeBack {
            try requireCondition(
                settingsRoot.waitForDisappearance(timeout: 5),
                in: app,
                "點擊原生返回後設定頁目的地未退出"
            )
            try requireCondition(
                settingsRow.waitUntilHittable(timeout: 10),
                in: app,
                "點擊原生返回後 More 入口列表未恢復可互動狀態"
            )
        }

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "返回 More 入口後切換至訂單分頁失敗")
        try requireCondition(order018.waitUntilHittable(timeout: 10), in: app, "訂單清單列未就緒")
        try requireCondition(navigator.tapRootTab(.more), in: app, "從訂單切回 More 分頁失敗")

        // Then
        if isMoreCompactLayout(app) {
            try requireCondition(
                settingsRow.waitUntilHittable(timeout: 10),
                in: app,
                "返回後跨分頁切換回 More 應維持 More 入口可互動"
            )
            try requireCondition(!settingsRoot.exists, in: app, "跨分頁切換回 More 不應再進入設定頁")
        } else {
            try requireCondition(
                settingsRoot.waitForExistence(timeout: 5),
                in: app,
                "寬版跨分頁切換回 More 後設定詳情應保留"
            )
            let morePath = try observedMorePath(in: app)
            try requireCheckPassed(
                PathCheck.verify(expectedDestination: "settings", observedPath: morePath),
                in: app
            )
        }
    }

    /// 驗證從更多進入客戶名單並選取真實客戶後導向訂單搜尋，切換根樣式後兩側目的地與搜尋結果各自保留，返回後 More 維持入口
    ///
    /// - Throws: 畫面元素未出現、客戶或訂單列不存在、或導覽連續性不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N5B
    func testMoreCustomerSurvivesRoundTrip_更多客戶頁已選取客戶_客戶頁與搜尋保留() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try requireValue(
            navigator.rootLayout,
            in: app,
            "根導覽版面無法判定 (marker 可見=\(navigator.isSidebarMarkerVisible)，分頁數=\(navigator.visibleRootTabCount()))"
        )
        try XCTSkipUnless(layout == .regular, "根樣式切換只存在於 regular 版面")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        try requireCondition(navigator.tapRootTab(.more), in: app, "點選原生 More 分頁失敗")
        let customersID = BLAccessibilityID.More.row(.customers)
        let customersRow = app.descendants(matching: .any)[customersID].firstMatch
        try requireCondition(
            customersRow.waitUntilHittable(timeout: 10),
            in: app,
            "More 中的客戶名單入口列未就緒或不可點"
        )
        customersRow.tap()

        let listRootID = BLAccessibilityID.Customers.listRoot
        let customersListRoot = app.descendants(matching: .any)[listRootID].firstMatch
        try requireCondition(
            customersListRoot.waitForExistence(timeout: 10),
            in: app,
            "點選客戶名單入口後 Customers.listRoot 未出現"
        )
        let emptyStateID = BLAccessibilityID.Customers.listEmptyState
        let emptyState = app.descendants(matching: .any)[emptyStateID].firstMatch
        try requireCondition(!emptyState.exists, in: app, "客戶名單不應處於空資料狀態")

        let expectedCustomerName = "林書宇"
        let customerLinID = BLAccessibilityID.Customers.row(customerName: expectedCustomerName)
        let customerRowLin = app.descendants(matching: .any)[customerLinID].firstMatch
        try requireCondition(
            customerRowLin.waitUntilHittable(timeout: 10),
            in: app,
            "客戶名單中林書宇列未就緒或不可互動"
        )
        let initialCustomerLabel = customerRowLin.label
        try requireCondition(
            initialCustomerLabel.contains("林書宇"),
            in: app,
            "客戶列標籤「\(initialCustomerLabel)」未包含預期客戶名稱「林書宇」"
        )

        // When
        let customersScreen = CustomersScreen(app: app)
        customersScreen.tapCustomer(customerName: expectedCustomerName)

        // Then
        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "選取客戶後訂單清單未就緒")
        let orderListRoots = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.Orders.listRoot)
        try requireCondition(orderListRoots.count == 1, in: app, "深連結後訂單清單根應只出現一次，不重複建立目的地")
        let orderDetailRoots = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.Orders.detailRoot)
        try requireCondition(orderDetailRoots.count <= 1, in: app, "深連結後訂單詳情根不應重複建立")

        let searchField = try ordersScreen.hittableSearchField()
        let searchValue = try requireValue(
            searchField.value as? String,
            in: app,
            "搜尋欄 accessibility value 為 nil"
        )
        try requireCondition(searchValue == "林書宇", in: app, "搜尋文字「\(searchValue)」非預期的「林書宇」")

        let row018 = ordersScreen.orderRow(orderID: "BL-2604-018")
        let row012 = ordersScreen.orderRow(orderID: "BL-2604-012")
        let row017 = ordersScreen.orderRow(orderID: "BL-2604-017")
        try requireCondition(row018.waitForExistence(timeout: 5), in: app, "找不到林書宇的訂單 BL-2604-018")
        try requireCondition(row012.waitForExistence(timeout: 5), in: app, "找不到林書宇的訂單 BL-2604-012")
        try requireCondition(!row017.exists, in: app, "搜尋林書宇不應出現 Mika 的訂單 BL-2604-017")

        let countLabelID = BLAccessibilityID.Orders.orderCountLabel
        let countLabel = app.descendants(matching: .any)[countLabelID].firstMatch
        try requireCondition(countLabel.waitUntilHittable(timeout: 10), in: app, "訂單筆數標籤不存在或不可見")
        let countText1 = countLabel.label
        try requireCondition(
            countText1 == "2" || (countLabel.value as? String) == "2",
            in: app,
            "訂單筆數「\(countText1)」非預期的 2"
        )

        // When
        let sidebarToggle = try requireValue(navigator.rootSidebarToggle(), in: app, "找不到原生側邊欄切換按鈕")
        try requireCondition(sidebarToggle.waitUntilHittable(timeout: 10), in: app, "原生側邊欄切換按鈕不可點")
        sidebarToggle.tap()

        // Then
        try requireCondition(
            navigator.waitForRootSidebarMarkerVisible(timeout: 10),
            in: app,
            "切換後側邊欄品牌標記未出現"
        )

        // When
        try requireCondition(navigator.tapRootTab(.more), in: app, "從側邊欄切回 More 分頁失敗")

        // Then
        try requireCondition(
            customerRowLin.waitUntilHittable(timeout: 10),
            in: app,
            "切回 More 後客戶名單中林書宇列未呈現可互動狀態"
        )
        let customerLabelAfterSidebar = customerRowLin.label
        try requireCondition(
            customerLabelAfterSidebar.contains("林書宇"),
            in: app,
            "切回 More 後客戶列標籤未包含「林書宇」 (實際為：\"\(customerLabelAfterSidebar)\")"
        )
        if isMoreCompactLayout(app) {
            try requireCondition(
                !customersRow.isHittableOnScreen,
                in: app,
                "切回 More 後不應退回 More 入口列表"
            )
        } else {
            try requireCondition(customersRow.isSelected, in: app, "寬版切回 More 後客戶入口列應維持已選取")
        }

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切回訂單分頁失敗")

        // Then
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單未就緒")

        let searchFieldAfter = try ordersScreen.hittableSearchField()
        let searchValueAfter = try requireValue(
            searchFieldAfter.value as? String,
            in: app,
            "搜尋欄 accessibility value 為 nil"
        )
        try requireCondition(searchValueAfter == "林書宇", in: app, "切換後搜尋文字未保留：\(searchValueAfter)")
        try requireCondition(
            row018.exists && row012.exists && !row017.exists,
            in: app,
            "搜尋結果 018/012 未保留或 017 意外出現"
        )

        let countLabel2 = app.descendants(matching: .any)[countLabelID].firstMatch
        try requireCondition(
            countLabel2.waitUntilHittable(timeout: 10),
            in: app,
            "第二次進入訂單時筆數標籤不存在或不可見"
        )
        let countText2 = countLabel2.label
        try requireCondition(
            countText2 == "2" || (countLabel2.value as? String) == "2",
            in: app,
            "第二次進入訂單時筆數「\(countText2)」非預期的 2"
        )

        // When
        try requireCondition(navigator.tapRootTab(.more), in: app, "再次切回 More 分頁失敗")

        // Then
        try requireCondition(
            customerRowLin.waitUntilHittable(timeout: 10),
            in: app,
            "再次切回 More 後林書宇客戶列未保持可互動狀態"
        )
        let customerLabelAfterReturn = customerRowLin.label
        try requireCondition(
            customerLabelAfterReturn.contains("林書宇"),
            in: app,
            "再次切回 More 後客戶列標籤未包含「林書宇」 (實際為：\"\(customerLabelAfterReturn)\")"
        )

        // When
        let isCompactBeforeBack = isMoreCompactLayout(app)
        if isCompactBeforeBack {
            try app.tapUniqueNativeBackButton()
        }

        // Then
        if isCompactBeforeBack {
            try requireCondition(
                customersListRoot.waitForDisappearance(timeout: 5),
                in: app,
                "點擊原生返回後客戶名單未退出"
            )
            try requireCondition(
                customersRow.waitUntilHittable(timeout: 10),
                in: app,
                "點擊原生返回後 More 入口列表未恢復可互動狀態"
            )
        }

        // When
        try requireCondition(navigator.tapRootTab(.orders), in: app, "返回 More 入口後切換至訂單分頁失敗")
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單根未就緒")
        try requireCondition(navigator.tapRootTab(.more), in: app, "從訂單切回 More 分頁失敗")

        // Then
        if isMoreCompactLayout(app) {
            try requireCondition(
                customersRow.waitUntilHittable(timeout: 10),
                in: app,
                "返回後跨分頁切換回 More 應維持 More 入口列表"
            )
            try requireCondition(!customersListRoot.exists, in: app, "跨分頁切換回 More 不應再進入客戶名單頁面")
        } else {
            try requireCondition(
                customersListRoot.waitForExistence(timeout: 5),
                in: app,
                "寬版跨分頁切換回 More 後客戶名單詳情應保留"
            )
            let morePath = try observedMorePath(in: app)
            try requireCheckPassed(
                PathCheck.verify(expectedDestination: "customers", observedPath: morePath),
                in: app
            )
        }
    }

    /// 驗證切到訂單再切回開團時，開團詳情與未收款篩選維持原樣
    ///
    /// - Throws: 詳情、分頁或篩選結果未就緒時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N5
    func testCampaignFilterSurvivesTabSwitch_開團詳情已套用未收款篩選_未收款篩選保留() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        let root = RootNavigationScreen(app: app)
        try requireDistributionRowsBeforeFilter(detail, in: app)
        detail.toggleUnpaidOnly()
        try requireCondition(detail.waitForUnpaidOnlyEnabled(), in: app, "未收款開關值未變成開啟")

        // When
        try requireCondition(root.goToOrders(), in: app, "切換至訂單分頁失敗")
        try requireCondition(root.goToCampaigns(), in: app, "切換回開團分頁失敗")

        // Then
        try requireCondition(detail.waitUntilReady(), in: app, "切回開團後詳情未就緒")
        try requireCondition(detail.isUnpaidOnlyEnabled(), in: app, "切回開團後未收款開關未維持開啟")
        try requireCondition(
            detail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName),
            in: app,
            "切回開團後未收款客戶列消失"
        )
    }

    /// 驗證新增訂單草稿旋轉後仍保留欄位焦點與文字，續輸入寫回同一欄位，且始終只有一張表單
    ///
    /// - Throws: 訂單清單、新增表單或旋轉後的草稿與 sheet 數量不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N6
    /// - Note: 編輯草稿、開團草稿與主檔草稿由既有案例覆蓋
    func testDraftSurvivesRotation_新增訂單草稿已輸入_同欄且單一sheet() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        orders.tapAddOrder()
        let edit = OrderEditScreen(app: app)
        try requireCondition(edit.waitUntilReady(), in: app, "新增訂單表單未就緒")
        edit.typeCustomerName("DuoDraft")
        let customerField = app.textFields[BLAccessibilityID.OrderEdit.customerField].firstMatch
        let keyboard = app.keyboards.firstMatch
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "客戶欄位鍵盤未出現")
        try requireCondition(customerField.value as? String == "DuoDraft", in: app, "新增草稿初始值非預期")

        // When
        try rotateToLandscape(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: customerField,
            expectedDraft: "DuoDraft",
            in: app
        )
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "轉向後新增表單鍵盤未保留")

        // When
        customerField.appendText("X", in: app)

        // Then
        try requireCondition(
            customerField.value as? String == "DuoDraftX",
            in: app,
            "轉向後客戶欄位未保留焦點並接續輸入"
        )

        // When
        try rotateToPortrait(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: customerField,
            expectedDraft: "DuoDraftX",
            in: app
        )

        // When
        edit.tapCancel()

        // Then
        try requireCondition(
            app.alerts.firstMatch.waitForExistence(timeout: 10),
            in: app,
            "取消新增草稿後未顯示既有捨棄確認"
        )
    }

    /// 驗證同一份資料在標準與輔助字級下，總覽四項 KPI 數值一致且成本指標存在
    ///
    /// - Throws: 總覽 KPI 未就緒、數值為空白、成本缺失或數值不一致時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L1
    /// - Note: 兩次啟動使用相同 seed
    func testDashboardKPIMatchesAcrossSizes_標準與輔助字級_四項數值一致且成本存在() throws {
        // Given
        let requiredKPIs: [BLAccessibilityID.Dashboard.KPI] = [
            .revenue,
            .cost,
            .grossMargin,
            .activeOrders,
        ]
        let standardApp = launch(LaunchOptions(seed: .fullOrders))
        let standardValues = try readDashboardKPIValues(in: standardApp, required: requiredKPIs)

        // When
        standardApp.terminate()
        let accessibilityApp = launch(
            LaunchOptions(
                seed: .fullOrders,
                contentSizeCategory: .accessibilityExtraExtraExtraLarge
            )
        )
        let accessibilityValues = try readDashboardKPIValues(
            in: accessibilityApp,
            required: requiredKPIs
        )

        // Then
        for kpi in requiredKPIs {
            try requireCondition(
                standardValues[kpi] == accessibilityValues[kpi],
                in: accessibilityApp,
                "\(kpi.rawValue) 輔助字級數值「\(accessibilityValues[kpi] ?? "nil")」與標準字級「\(standardValues[kpi] ?? "nil")」不一致"
            )
        }
    }

    /// 驗證 iPad 側邊欄展開時，訂單篩選膠囊與新增按鈕的框線落在視窗內且避開側邊欄保留區；收合後兩者仍在視窗內
    ///
    /// - Throws: 根導覽、訂單清單或框線不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L2
    /// - Note: 側邊欄右緣以品牌標記的右緣近似，側邊欄欄位本身沒有可讀取的 identifier
    func testSidebarReservedRegion_橫向訂單前景_膠囊與新增鈕在保留區外() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try rotateToLandscape(app)
        let layout = try requireValue(navigator.rootLayout, in: app, "橫向根導覽版面無法判定")
        try XCTSkipUnless(layout == .regular, "側邊欄保留區只存在於 regular 根導覽")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")

        // When
        try requireCondition(navigator.revealSidebarIfCollapsed(), in: app, "無法展開原生根側邊欄")

        // Then
        try requireCondition(navigator.isSidebarMarkerVisible, in: app, "展開後側邊欄標記未出現")
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let sidebarMarker = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
            .firstMatch
        let markerFrame = try requireValidFrame(of: sidebarMarker, in: app, context: "側邊欄品牌標記框線")
        let sidebarRegion = CGRect(
            x: window.minX,
            y: window.minY,
            width: markerFrame.maxX - window.minX,
            height: window.height
        )

        let chip = app.descendants(matching: .any)[BLAccessibilityID.Orders.statusChip("all")]
            .firstMatch
        let chipFrame = try requireValue(
            app.stableVisibleFrame(of: chip, within: app.windows.firstMatch),
            in: app,
            "篩選膠囊框線不可用"
        )
        let addButton = app.descendants(matching: .any)[BLAccessibilityID.Orders.addButton]
            .firstMatch
        let addFrame = try requireValue(
            app.stableVisibleFrame(of: addButton, within: app.windows.firstMatch),
            in: app,
            "新增按鈕框線不可用"
        )
        try requireCheckPassed(
            BoundsCheck.verify(
                frame: chipFrame,
                container: window,
                reservedRegions: [sidebarRegion]
            ),
            in: app
        )
        try requireCheckPassed(
            BoundsCheck.verify(
                frame: addFrame,
                container: window,
                reservedRegions: [sidebarRegion]
            ),
            in: app
        )

        // When
        let sidebarToggle = try requireValue(
            navigator.rootSidebarToggle(),
            in: app,
            "找不到唯一可辨識的原生側邊欄切換鈕"
        )
        sidebarToggle.tap()

        // Then
        try requireCondition(
            waitForSidebarMarkerHidden(navigator: navigator, timeout: 10),
            in: app,
            "收合側邊欄後品牌標記仍可見"
        )
        let collapsedChipFrame = try requireValue(
            app.stableVisibleFrame(of: chip, within: app.windows.firstMatch),
            in: app,
            "收合後篩選膠囊框線不可用"
        )
        let collapsedAddFrame = try requireValue(
            app.stableVisibleFrame(of: addButton, within: app.windows.firstMatch),
            in: app,
            "收合後新增按鈕框線不可用"
        )
        try requireCheckPassed(
            BoundsCheck.verify(frame: collapsedChipFrame, container: window, reservedRegions: []),
            in: app
        )
        try requireCheckPassed(
            BoundsCheck.verify(frame: collapsedAddFrame, container: window, reservedRegions: []),
            in: app
        )
    }

    /// 驗證 iPhone 收合版的訂單篩選膠囊可捲動點選，點選後膠囊框線不進入底部分頁列與狀態列
    ///
    /// - Throws: 根導覽、膠囊列或框線不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L2
    /// - Note: 收合版的系統保留區以底部分頁列與狀態列判定
    func testCapsuleReachable_iPhone收合版_膠囊可捲動點選且不進入系統列() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try requireValue(navigator.rootLayout, in: app, "根導覽版面無法判定")
        try XCTSkipUnless(layout == .compact, "膠囊可捲動點選的保留區案例只適用底部分頁列的 compact 版面")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")

        // When
        orders.selectStatusChip(filterID: "shipping")
        let isChipRevealed = orders.revealStatusChipFully(
            filterID: "shipping",
            in: app.windows.firstMatch
        )

        // Then
        try requireCondition(
            orders.isRegularStatusChipSelected("shipping"),
            in: app,
            "捲動點選後狀態膠囊未選中"
        )
        try requireCondition(isChipRevealed, in: app, "狀態膠囊無法捲入視窗可視範圍")
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let chip = app.descendants(matching: .any)[BLAccessibilityID.Orders.statusChip("shipping")]
            .firstMatch
        let chipFrame = try requireValue(
            app.stableVisibleFrame(of: chip, within: app.windows.firstMatch),
            in: app,
            "狀態膠囊框線不可用"
        )
        let tabBarFrame = try requireValidFrame(
            of: app.tabBars.firstMatch,
            in: app,
            context: "底部分頁列框線"
        )
        var reservedRegions = [tabBarFrame]
        let statusBar = app.statusBars.firstMatch
        if statusBar.exists {
            let statusBarFrame = try requireValidFrame(of: statusBar, in: app, context: "狀態列框線")
            reservedRegions.append(statusBarFrame)
        }
        try requireCheckPassed(
            BoundsCheck.verify(
                frame: chipFrame,
                container: window,
                reservedRegions: reservedRegions
            ),
            in: app
        )
    }

    /// 驗證訂單在根樣式切換與方向改變後保留選取；並排時清單與詳情框線互不重疊，收合時仍可辨識版面模式
    ///
    /// - Throws: 路徑標記、詳情或版面判定不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L3
    /// - Note: 分欄範圍依訂單前景模式判定
    func testOrdersLayoutCombination_訂單已選取_路徑保留且並排框線不重疊() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        let navigator = AppNavigator(app: app)
        let initialTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            !navigator.isSidebarMarkerVisible && initialTabCount == 5,
            in: app,
            "初始根導覽應為五個原生 Tabs，實際數量=\(initialTabCount)"
        )
        try requireCondition(navigator.tapRootTab(.orders), in: app, "無法切到原生訂單分頁")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        orders.tapOrder(orderID: "BL-2604-018")
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        if isRegularLayout(app) {
            try assertOrdersSplitGeometry(in: app)
        } else {
            try requireCondition(isCompactLayout(app), in: app, "收合版面應可辨識為收合")
        }

        // When
        try rotateToLandscape(app)

        // Then
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        if isRegularLayout(app) {
            try assertOrdersSplitGeometry(in: app)
        } else {
            try requireCondition(isCompactLayout(app), in: app, "收合版面應可辨識為收合")
        }
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "橫向後訂單詳情未保留")

        // When
        try rotateToPortrait(app)

        // Then
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        if isRegularLayout(app) {
            try assertOrdersSplitGeometry(in: app)
        } else {
            try requireCondition(isCompactLayout(app), in: app, "收合版面應可辨識為收合")
        }
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "直向後訂單詳情未保留")
    }

    /// 驗證開團並排時，目前詳情對應的開團列帶選取特徵
    ///
    /// - Throws: 版面不適用、必要元素缺少或選取特徵不符時丟出測試錯誤
    func testCampaignRowSelected_並排選取開團_目前開團列帶選取特徵() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "切到開團分頁後畫面未就緒")
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        try XCTSkipUnless(isCampaignRegularLayout(app), "選取列只在開團並排時與詳情同時可見")

        // When
        campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)

        // Then
        let detail = CampaignDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "四月韓國團詳情未就緒")
        let identifier = BLAccessibilityID.Campaigns.row(
            campaignID: CampaignSeedFixture.koreaCampaignID
        )
        let row = app.descendants(matching: .any)[identifier].firstMatch
        try requireCondition(row.isSelected, in: app, "目前開團列應帶選取特徵")
    }

    /// 驗證開團與更多在方向改變後保留各自的目的地
    ///
    /// - Throws: 目的地未保留或功能版面模式無法辨識時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L3
    /// - Note: 開團與更多各自以功能模式判定，不以根導覽推測
    func testCampaignAndMoreKeepTarget_開團與更多已選取目的地_目的地保留() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "切到開團分頁後畫面未就緒")
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)
        let detail = CampaignDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "四月韓國團詳情未就緒")

        // When
        try rotateToLandscape(app)

        // Then
        let selectedCampaign = try requireValue(
            campaigns.selectedCampaignID(),
            in: app,
            "開團選取標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "CMP-SAMPLE-KR-APR", observed: selectedCampaign),
            in: app
        )
        try requireCondition(
            isCampaignRegularLayout(app) != isCampaignCompactLayout(app),
            in: app,
            "開團版面模式應恰有一種可辨識結果"
        )
        try requireCondition(detail.waitUntilReady(), in: app, "橫向後開團詳情未保留")

        // When
        try requireCondition(root.goToMore(), in: app, "切到更多分頁後畫面未就緒")
        let settings = SettingsScreen.navigate(in: app)

        // Then
        try requireCondition(settings.waitUntilReady(), in: app, "進入設定後設定頁未就緒")

        // When
        try rotateToPortrait(app)

        // Then
        try requireCondition(settings.waitUntilReady(), in: app, "直向後設定頁未保留")
        try requireCondition(
            isMoreRegularLayout(app) != isMoreCompactLayout(app),
            in: app,
            "更多版面模式應恰有一種可辨識結果"
        )
        let morePath = try observedMorePath(in: app)
        try requireCheckPassed(
            PathCheck.verify(expectedDestination: "settings", observedPath: morePath),
            in: app
        )
    }

    /// 驗證寬版總覽的內容寬度小於可用寬度，且左右邊距一致，即閱讀區存在並置中
    ///
    /// - Throws: 根導覽、總覽 KPI 框線或置中條件不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L4
    /// - Note: 只斷言內容寬度受限與左右置中
    func testReadableRegionCentered_寬版總覽_內容未佔滿且左右等距() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try requireValue(navigator.rootLayout, in: app, "根導覽版面無法判定")
        try XCTSkipUnless(layout == .regular, "閱讀區上限只適用 regular 根導覽的寬版視窗")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToDashboard(), in: app, "切到總覽分頁後畫面未就緒")
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "總覽畫面未就緒")

        // When
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let kpis: [BLAccessibilityID.Dashboard.KPI] = [.revenue, .cost, .grossMargin, .activeOrders]
        let tileFrames = try kpis.map { kpi in
            let tile = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.kpiTile(kpi)]
                .firstMatch
            return try requireValue(
                app.stableVisibleFrame(of: tile, within: dashboard.rootElement),
                in: app,
                "KPI 卡 \(kpi.rawValue) 框線不可用"
            )
        }

        // Then
        let contentMinX = try requireValue(tileFrames.map(\.minX).min(), in: app, "寬版總覽 KPI 卡框線為空")
        let contentMaxX = try requireValue(tileFrames.map(\.maxX).max(), in: app, "寬版總覽 KPI 卡框線為空")
        try requireCondition(
            contentMaxX - contentMinX < window.width,
            in: app,
            "寬版總覽內容寬度未受限，已佔滿視窗 (內容 \(contentMaxX - contentMinX)，視窗 \(window.width))"
        )
        let leadingMargin = contentMinX - window.minX
        let trailingMargin = window.maxX - contentMaxX
        try requireCondition(
            abs(leadingMargin - trailingMargin) <= 1,
            in: app,
            "寬版總覽內容未置中 (左邊距 \(leadingMargin)，右邊距 \(trailingMargin))"
        )
    }
}

// MARK: - Nested Types

private extension AdaptiveNavigationContinuityUITests {

    /// 側邊欄品牌標記的可見狀態採樣值
    enum MarkerVisibilitySample {

        /// 尚未採樣
        case unknown

        /// 標記隱藏
        case hidden

        /// 標記可見
        case visible
    }
}

// MARK: - Private Method

private extension AdaptiveNavigationContinuityUITests {

    /// 在指定逾時內等待側邊欄品牌標記消失或移出視窗
    ///
    /// - Parameters:
    ///   - navigator: 導覽輔助物件
    ///   - timeout: 等待逾時秒數
    /// - Returns: 標記是否已在逾時前消失
    func waitForSidebarMarkerHidden(navigator: AppNavigator, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if !navigator.isSidebarMarkerVisible {
                return true
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
        return !navigator.isSidebarMarkerVisible
    }

    /// 確認 Orders 導覽路徑標記與期望的訂單識別碼一致
    ///
    /// - Parameters:
    ///   - orderID: 期望的訂單識別碼
    ///   - orders: 訂單清單 Page Object
    ///   - app: 受測 App
    /// - Throws: 路徑標記缺失或識別碼不符時丟出測試錯誤
    func requireSelectedOrder(
        _ orderID: String,
        in orders: OrdersScreen,
        app: XCUIApplication
    ) throws {
        let actual = try requireValue(orders.pathProjectedOrderID, in: app, "Orders 導覽路徑標記不存在")
        try requireCheckPassed(IdentifierCheck.verify(expected: orderID, observed: actual), in: app)
    }

    /// 確認詳情欄在逾時內呈現指定訂單的內容，且不含指定的舊訂單編號
    ///
    /// - Parameters:
    ///   - orderID: 詳情應呈現的訂單編號
    ///   - staleOrderID: 不應再出現的舊訂單編號
    ///   - app: 受測 App
    /// - Throws: 逾時仍未呈現指定訂單，或仍顯示舊訂單時丟出測試錯誤
    func requireDetailShows(
        _ orderID: String,
        excluding staleOrderID: String? = nil,
        in app: XCUIApplication
    ) throws {
        let detailRoot = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
            .firstMatch
        let orderLabel = detailRoot.staticTexts
            .matching(NSPredicate(format: "label == %@", orderID))
            .firstMatch
        if !orderLabel.waitForExistence(timeout: 10) {
            let visibleLabels = detailRoot.staticTexts.allElementsBoundByIndex.map(\.label)
            try requireCondition(false, in: app, "訂單詳情逾時仍未呈現編號 \(orderID) (可見標籤：\(visibleLabels))")
        }
        if let staleOrderID {
            let staleLabel = detailRoot.staticTexts
                .matching(NSPredicate(format: "label == %@", staleOrderID))
                .firstMatch
            try requireCondition(!staleLabel.exists, in: app, "訂單詳情仍顯示舊訂單 \(staleOrderID)")
        }
    }

    /// 確認訂單未選取，且版面對應的未選取呈現可見
    ///
    /// - Parameters:
    ///   - orders: 訂單清單 Page Object
    ///   - app: 受測 App
    /// - Throws: 路徑標記缺失、已有選取，或版面對應的未選取呈現不可見時丟出測試錯誤
    func requireOrdersUnselected(_ orders: OrdersScreen, in app: XCUIApplication) throws {
        let selection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "Orders path 選取標記不存在"
        )
        try requireCheckPassed(IdentifierCheck.verify(expected: "", observed: selection), in: app)
        if isRegularLayout(app) {
            try assertUnselectedPromptVisible(in: app)
        } else {
            try requireCondition(orders.hasOrder(orderID: "BL-2604-017"), in: app, "收合版未選取時訂單清單應可見")
        }
    }

    /// 確認寬版詳情欄顯示未選取提示
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 提示未出現或沒有有效框線時丟出測試錯誤
    func assertUnselectedPromptVisible(in app: XCUIApplication) throws {
        let prompt = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailEmptyState]
            .firstMatch
        try requireCondition(
            prompt.waitForExistence(timeout: 10) && prompt.snapshotFrame != nil,
            in: app,
            "寬版未選取時未顯示詳情選取提示"
        )
    }

    /// 讀取更多頁目前目的地的識別值，標記缺失或沒有數值時失敗
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 目前目的地的識別值，未選取時為空字串
    /// - Throws: 選取標記不存在或沒有數值時丟出測試錯誤
    func requireMoreSelection(in app: XCUIApplication) throws -> String {
        let marker = app.descendants(matching: .any)[BLAccessibilityID.Common.selectedItem(.more)]
            .firstMatch
        try requireCondition(marker.exists, in: app, "更多頁選取標記不存在")
        return try requireValue(marker.value as? String, in: app, "更多頁選取標記沒有數值")
    }

    /// 將更多頁目前目的地組成導覽路徑，未選取時為空路徑
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 由目前目的地識別值組成的路徑；未選取時為空陣列
    /// - Throws: 選取標記不存在或沒有數值時丟出測試錯誤
    func observedMorePath(in app: XCUIApplication) throws -> [String] {
        let selection = try requireMoreSelection(in: app)
        return selection.isEmpty ? [] : [selection]
    }

    /// 進入總覽並讀取指定 KPI 的顯示值，數值為空白或必要種類缺失時讓測試失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - required: 必須出現的 KPI 種類
    /// - Returns: 各 KPI 種類對應的顯示值
    /// - Throws: 總覽未就緒、數值為空白或必要 KPI 缺失時丟出測試錯誤
    func readDashboardKPIValues(
        in app: XCUIApplication,
        required: [BLAccessibilityID.Dashboard.KPI]
    ) throws -> [BLAccessibilityID.Dashboard.KPI: String] {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToDashboard(), in: app, "切到總覽分頁後畫面未就緒")
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "總覽畫面未就緒")
        var values: [BLAccessibilityID.Dashboard.KPI: String] = [:]
        for kpi in required {
            if let value = dashboard.kpiValue(kpi) {
                try requireCondition(
                    !value.allSatisfy(\.isWhitespace),
                    in: app,
                    "KPI \(kpi.rawValue) 顯示值為空白"
                )
                values[kpi] = value
            }
        }
        try requireCheckPassed(
            KPIPresenceCheck.verify(required: required, observed: Set(values.keys)),
            in: app
        )
        return values
    }

    /// 確認並排時詳情內容錨點與清單框線不重疊，非並排時失敗
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 非並排、詳情錨點缺席或與清單框線重疊時丟出測試錯誤
    /// - Note: 詳情根容器在 iPadOS 27 會延伸到清單欄底下，因此以摘要格、更多按鈕或空狀態提示判定詳情欄位置
    func assertOrdersSplitGeometry(in app: XCUIApplication) throws {
        try requireCondition(isRegularLayout(app), in: app, "並排框線檢查需要 Orders 清單與詳情並排")
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let listFrame = try requireValidFrame(
            of: app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot],
            in: app,
            context: "並排訂單清單框線"
        )
        let detailFrame = try requireValue(
            foregroundOrdersDetailFrame(in: app),
            in: app,
            "找不到並排訂單詳情內容錨點"
        )
        try requireCheckPassed(
            BoundsCheck.verify(frame: detailFrame, container: window, reservedRegions: [listFrame]),
            in: app
        )
    }
}
