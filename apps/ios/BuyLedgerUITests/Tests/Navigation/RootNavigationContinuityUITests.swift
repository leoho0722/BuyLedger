//
//  RootNavigationContinuityUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 根導覽在側邊欄展開、分頁切換與轉向後的連續性 UI 測試，涵蓋目的地、訂單篩選、更多的設定與客戶頁、開團詳情的保留，以及側邊欄保留區的框線
///
/// - Note: 對應驗收矩陣 N1、N3、N5 與 L2、L3 中以根導覽為受測的部分
@MainActor
final class RootNavigationContinuityUITests: BLUITestCase {

    /// 驗證 iPad 根導覽初始為分頁列，直向 overlay 切換目的地後收起，橫向保留側邊欄偏好與目的地
    ///
    /// - Throws: 根畫面、原生分頁、側邊欄標記或轉向條件不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N1
    func testTabSelected_側邊欄展開後切分頁與轉向_樣式目的地與徽章正確() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
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
            """
            切換側邊欄後標記未顯示或目的地數不為 5 (\
            marker 可見=\(isSidebarMarkerVisibleAfterToggle)，\
            可見數=\(tabCountAfterToggle))
            """
        )

        let ordersTabInPortraitSidebar = navigator.rootTabElement(for: .orders)
        try requireCondition(
            ordersTabInPortraitSidebar.label.hasSuffix(", 4"),
            in: app,
            "直向側邊欄中訂單分頁標籤應以「, 4」結尾 (實際為：\"\(ordersTabInPortraitSidebar.label)\")"
        )

        // When
        try navigator.tapRootTab(.orders)

        // Then
        let isSidebarMarkerDismissed = waitForSidebarMarkerHidden(navigator: navigator, timeout: 10)
        let tabCountAfterDismiss = navigator.visibleRootTabCount()
        try requireCondition(
            isSidebarMarkerDismissed && tabCountAfterDismiss == 5,
            in: app,
            """
            直向 overlay 點選目的地後未收起回到分頁列 (\
            marker 可見=\(navigator.isSidebarMarkerVisible)，\
            分頁數=\(tabCountAfterDismiss))
            """
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
            """
            橫向側邊欄狀態未確立 (\
            marker 可見=\(navigator.isSidebarMarkerVisible)，\
            分頁數=\(navigator.visibleRootTabCount()))
            """
        )

        let ordersTabInLandscape = navigator.rootTabElement(for: .orders)
        try requireCondition(
            ordersTabInLandscape.label.hasSuffix(", 4"),
            in: app,
            "橫向側邊欄中訂單分頁標籤應以「, 4」結尾 (實際為：\"\(ordersTabInLandscape.label)\")"
        )

        // When
        try navigator.tapRootTab(.more)
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
            """
            橫向切到 More 後側邊欄偏好未保留 (\
            marker 可見=\(navigator.isSidebarMarkerVisible)，\
            分頁數=\(navigator.visibleRootTabCount()))
            """
        )

        // When
        try navigator.tapRootTab(.orders)

        // Then
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            "橫向切回訂單分頁後訂單列 BL-2604-018 不可互動"
        )
        try requireCondition(
            navigator.isSidebarMarkerVisible && navigator.visibleRootTabCount() == 5,
            in: app,
            """
            橫向切回訂單分頁後側邊欄偏好未保留 (\
            marker 可見=\(navigator.isSidebarMarkerVisible)，\
            分頁數=\(navigator.visibleRootTabCount()))
            """
        )

        // When
        try rotateToPortrait(app)

        // Then
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "橫向轉直向後訂單清單根未就緒")
        var lastMarkerSample: MarkerVisibilitySample = .unknown
        var isSidebarMarkerVisibleAfterPortraitRotate = navigator.isSidebarMarkerVisible
        // 轉向後標記會短暫變化，連續兩次取樣相同才視為穩定，3 秒內未穩定時沿用轉向後的第一次讀值
        _ = Polling.wait(timeout: 3) {
            let currentSample: MarkerVisibilitySample = navigator.isSidebarMarkerVisible
                ? .visible
                : .hidden
            if lastMarkerSample == currentSample {
                isSidebarMarkerVisibleAfterPortraitRotate = currentSample == .visible
                return true
            }
            lastMarkerSample = currentSample
            return false
        }
        let portraitTabsAfterRotate = navigator.visibleRootTabCount()
        try requireCondition(
            portraitTabsAfterRotate == 5,
            in: app,
            """
            橫向轉直向後可見目的地數不為 5 (\
            實際為 \(portraitTabsAfterRotate)，\
            marker 可見=\(isSidebarMarkerVisibleAfterPortraitRotate))
            """
        )

        // When
        // 直向 overlay 開啟時點選訂單分頁收起，未開啟時不需操作
        var isOverlayDismissed = true
        if isSidebarMarkerVisibleAfterPortraitRotate {
            try navigator.tapRootTab(.orders)
            isOverlayDismissed = waitForSidebarMarkerHidden(navigator: navigator, timeout: 10)
        }

        // Then
        try requireCondition(isOverlayDismissed, in: app, "直向點選訂單後側邊欄 overlay 未收起")
        try requireCondition(
            order018.waitUntilHittable(timeout: 10),
            in: app,
            """
            橫向轉直向後訂單列 BL-2604-018 不可互動 (\
            分頁數=\(portraitTabsAfterRotate)，\
            marker=\(isSidebarMarkerVisibleAfterPortraitRotate))
            """
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
            """
            轉回橫向後側邊欄偏好或目的地數未保留 (\
            marker 可見=\(isSidebarMarkerVisibleAfterLandscapeReturn)，\
            分頁數=\(landscapeTabsAfterReturn))
            """
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
            """
            切回分頁列後側邊欄標記未消失或可見目的地數不為 5 (\
            marker 可見=\(navigator.isSidebarMarkerVisible)，\
            分頁數=\(navigator.visibleRootTabCount()))
            """
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
    func testRevealSidebarIfCollapsed_訂單已選取並套用篩選_選取與篩選不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .regular, "原生根 sidebar 只適用 regular 根導覽")
        let initialTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            !navigator.isSidebarMarkerVisible && initialTabCount == 5,
            in: app,
            "sidebar 案例應從五個原生根 Tabs 開始，實際數量=\(initialTabCount)"
        )
        try navigator.tapRootTab(.orders)

        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        // 先套用非預設的付款方式與類別篩選，前後比較才抓得到篩選被重設
        try orders.selectPaymentMethodInRegularLayout("信用卡")
        let picker = try orders.openCategoryPicker()
        try picker.tapPickerCategory("美妝")
        try picker.tapPickerDone()
        try orders.tapOrder(orderID: "BL-2604-018")
        let selectedOrderBefore = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "選取訂單後 Orders 導覽路徑標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "BL-2604-018", observed: selectedOrderBefore),
            in: app
        )
        try assertOrdersLayoutIsRecognized(in: app)
        try requireCondition(
            orders.paymentMethodTrigger.waitForExistence(timeout: 10),
            in: app,
            "找不到付款方式篩選鈕"
        )
        try requireCondition(
            orders.categoryTrigger.waitForExistence(timeout: 10),
            in: app,
            "找不到類別篩選鈕"
        )
        try requireCondition(
            orders.paymentMethodTrigger.wait(
                for: NSPredicate(format: "label CONTAINS %@", "信用卡"),
                timeout: 10
            ),
            in: app,
            "套用付款方式篩選後篩選列值未含「信用卡」，實際為「\(orders.paymentMethodTriggerLabel())」"
        )
        try requireCondition(
            orders.categoryTrigger.wait(
                for: NSPredicate(format: "label CONTAINS %@", "美妝"),
                timeout: 10
            ),
            in: app,
            "套用類別篩選後篩選列值未含「美妝」，實際為「\(orders.categoryTriggerLabel())」"
        )
        let paymentMethodLabelBefore = orders.paymentMethodTriggerLabel()
        let categoryLabelBefore = orders.categoryTriggerLabel()

        // When
        try navigator.revealSidebarIfCollapsed()

        // Then
        try requireCondition(navigator.isSidebarMarkerVisible, in: app, "原生根 sidebar 標記未出現")
        try requireCondition(navigator.visibleRootTabCount() == 5, in: app, "根 sidebar 模式未保留五個目的地")
        let selectedOrderAfter = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "根樣式切換後 Orders 導覽路徑標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "BL-2604-018", observed: selectedOrderAfter),
            in: app
        )
        try requireCondition(
            orders.paymentMethodTrigger.waitForExistence(timeout: 10),
            in: app,
            "根樣式切換後找不到付款方式篩選鈕"
        )
        try requireCondition(
            orders.paymentMethodTriggerLabel() == paymentMethodLabelBefore,
            in: app,
            """
            根樣式切換後付款方式篩選列值應維持「\(paymentMethodLabelBefore)」，\
            實際為「\(orders.paymentMethodTriggerLabel())」
            """
        )
        try requireCondition(
            orders.categoryTrigger.waitForExistence(timeout: 10),
            in: app,
            "根樣式切換後找不到類別篩選鈕"
        )
        try requireCondition(
            orders.categoryTriggerLabel() == categoryLabelBefore,
            in: app,
            "根樣式切換後類別篩選列值應維持「\(categoryLabelBefore)」，實際為「\(orders.categoryTriggerLabel())」"
        )
        try assertOrdersLayoutIsRecognized(in: app)
        try requireCondition(
            OrderDetailScreen(app: app).waitUntilReady(),
            in: app,
            "根 sidebar 切換後訂單詳情未保留"
        )
    }

    /// 驗證首次進入更多時沒有目前工具，寬版顯示未選取提示且設定列未選取，收合版顯示入口列
    ///
    /// - Throws: 更多前景模式、提示、入口列或幾何防護不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N3
    /// - Note: 版面以 `moreLayout(in:)` 回傳的列舉值判定，不以根導覽代替
    /// - Note: 收合分支以入口列寬度排除並排但缺提示的情況
    func testTabSelected_首次進入更多_寬版顯示提示且收合版顯示入口列() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        // When
        try rotateToLandscape(app)
        try root.goToMore()

        // Then
        if try moreLayout(in: app) == .regular {
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
            try requireCondition(try moreLayout(in: app) == .compact, in: app, "更多前景應為並排或收合其中之一")
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

    /// 驗證從更多進入設定後切換至訂單並切換根樣式，切回更多時直接保留設定頁目的地，原生返回可退回更多入口
    ///
    /// - Throws: 畫面元素未出現、分頁切換失敗或導覽連續性不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N5A
    func testTabSelected_更多設定頁在前景時往返分頁_設定頁保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders, monthlyProfitGoalTWD: 90000))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .regular, "根樣式切換只存在於 regular 版面")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        try navigator.tapRootTab(.more)
        let settingsID = BLAccessibilityID.More.row(.settings)
        let settingsRow = app.descendants(matching: .any)[settingsID].firstMatch
        try requireCondition(
            settingsRow.waitUntilHittable(timeout: 10),
            in: app,
            "More 中的設定入口列未就緒或不可點"
        )
        settingsRow.tap()

        let settings = SettingsScreen(app: app)
        try requireCondition(settings.waitUntilReady(), in: app, "點選設定入口後 Settings.root 未出現")
        try requireCondition(
            settings.monthlyGoalField.waitUntilHittable(timeout: 10),
            in: app,
            "設定頁中的每月目標欄位未進入可互動狀態"
        )
        let initialGoal = try requireValue(
            settings.monthlyGoalFieldValue(),
            in: app,
            "設定頁每月目標欄位之 value 為 nil"
        )
        try requireCondition(
            initialGoal == "90000",
            in: app,
            "設定頁每月目標初始數值非預期的 90000 (實際為：\(initialGoal))"
        )

        // When
        try navigator.tapRootTab(.orders)
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
        try navigator.tapRootTab(.more)

        // Then
        try requireCondition(
            settings.monthlyGoalField.waitUntilHittable(timeout: 10),
            in: app,
            "切回 More 後設定頁每月目標欄位不可互動，未能保留設定頁前景"
        )
        let goalAfterSidebar = try requireValue(
            settings.monthlyGoalFieldValue(),
            in: app,
            "切回 More 後每月目標欄位之 value 為 nil"
        )
        try requireCondition(
            goalAfterSidebar == "90000",
            in: app,
            "切回 More 後每月目標數值未保留 (預期：90000，實際：\(goalAfterSidebar))"
        )
        if try moreLayout(in: app) == .compact {
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
            """
            切回分頁列後側邊欄品牌標記仍存在或分頁數不為 5 (\
            marker 可見=\(navigator.isSidebarMarkerVisible)，\
            分頁數=\(navigator.visibleRootTabCount()))
            """
        )

        // When
        try navigator.tapRootTab(.orders)
        try requireCondition(order018.waitUntilHittable(timeout: 10), in: app, "訂單清單列未就緒")
        try navigator.tapRootTab(.more)

        // Then
        try requireCondition(
            settings.monthlyGoalField.waitUntilHittable(timeout: 10),
            in: app,
            "切回分頁列後再經訂單來回，More 仍應停留在設定頁前景"
        )
        let goalAfterTabsRoundTrip = try requireValue(
            settings.monthlyGoalFieldValue(),
            in: app,
            "再次切回 More 後每月目標欄位之 value 為 nil"
        )
        try requireCondition(
            goalAfterTabsRoundTrip == "90000",
            in: app,
            "再次切回 More 後每月目標數值未保留 (預期：90000，實際：\(goalAfterTabsRoundTrip))"
        )

        // When
        let isCompactBeforeBack = try moreLayout(in: app) == .compact
        if isCompactBeforeBack {
            try app.tapUniqueNativeBackButton()
        }

        // Then
        if isCompactBeforeBack {
            try requireCondition(
                settings.rootElement.waitForDisappearance(timeout: 5),
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
        try navigator.tapRootTab(.orders)
        try requireCondition(order018.waitUntilHittable(timeout: 10), in: app, "訂單清單列未就緒")
        try navigator.tapRootTab(.more)

        // Then
        if try moreLayout(in: app) == .compact {
            try requireCondition(
                settingsRow.waitUntilHittable(timeout: 10),
                in: app,
                "返回後跨分頁切換回 More 應維持 More 入口可互動"
            )
            try requireCondition(!settings.isDisplayed, in: app, "跨分頁切換回 More 不應再進入設定頁")
        } else {
            try requireCondition(
                settings.waitUntilReady(timeout: 5),
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
    func testTabSelected_更多客戶頁已選取客戶時往返分頁_客戶頁與搜尋保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .regular, "根樣式切換只存在於 regular 版面")
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        try navigator.tapRootTab(.more)
        let customersID = BLAccessibilityID.More.row(.customers)
        let customersRow = app.descendants(matching: .any)[customersID].firstMatch
        try requireCondition(
            customersRow.waitUntilHittable(timeout: 10),
            in: app,
            "More 中的客戶名單入口列未就緒或不可點"
        )
        customersRow.tap()

        let customersScreen = CustomersScreen(app: app)
        try requireCondition(
            customersScreen.waitUntilReady(),
            in: app,
            "點選客戶名單入口後 Customers.listRoot 未出現"
        )
        try requireCondition(!customersScreen.hasEmptyState(timeout: 0), in: app, "客戶名單不應處於空資料狀態")

        let expectedCustomerName = "林書宇"
        let initialCustomerLabel = try requireValue(
            customersScreen.customerRowLabel(customerName: expectedCustomerName),
            in: app,
            "客戶名單中林書宇列未就緒或不可互動"
        )
        try requireCondition(
            initialCustomerLabel.contains("林書宇"),
            in: app,
            "客戶列標籤「\(initialCustomerLabel)」未包含預期客戶名稱「林書宇」"
        )

        // When
        try customersScreen.tapCustomer(customerName: expectedCustomerName)

        // Then
        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "選取客戶後訂單清單未就緒")
        try requireCondition(ordersScreen.listRootCount == 1, in: app, "深連結後訂單清單根應只出現一次，不重複建立目的地")
        try requireCondition(ordersScreen.detailRootCount <= 1, in: app, "深連結後訂單詳情根不應重複建立")

        let searchField = try app.hittableSearchField()
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

        let countLabel = ordersScreen.orderCountLabel
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
        try navigator.tapRootTab(.more)

        // Then
        let customerLabelAfterSidebar = try requireValue(
            customersScreen.customerRowLabel(customerName: expectedCustomerName),
            in: app,
            "切回 More 後客戶名單中林書宇列未呈現可互動狀態"
        )
        try requireCondition(
            customerLabelAfterSidebar.contains("林書宇"),
            in: app,
            "切回 More 後客戶列標籤未包含「林書宇」 (實際為：\"\(customerLabelAfterSidebar)\")"
        )
        if try moreLayout(in: app) == .compact {
            try requireCondition(
                !customersRow.isHittableOnScreen,
                in: app,
                "切回 More 後不應退回 More 入口列表"
            )
        } else {
            try requireCondition(customersRow.isSelected, in: app, "寬版切回 More 後客戶入口列應維持已選取")
        }

        // When
        try navigator.tapRootTab(.orders)

        // Then
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單未就緒")

        let searchFieldAfter = try app.hittableSearchField()
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

        let countLabel2 = ordersScreen.orderCountLabel
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
        try navigator.tapRootTab(.more)

        // Then
        let customerLabelAfterReturn = try requireValue(
            customersScreen.customerRowLabel(customerName: expectedCustomerName),
            in: app,
            "再次切回 More 後林書宇客戶列未保持可互動狀態"
        )
        try requireCondition(
            customerLabelAfterReturn.contains("林書宇"),
            in: app,
            "再次切回 More 後客戶列標籤未包含「林書宇」 (實際為：\"\(customerLabelAfterReturn)\")"
        )

        // When
        let isCompactBeforeBack = try moreLayout(in: app) == .compact
        if isCompactBeforeBack {
            try app.tapUniqueNativeBackButton()
        }

        // Then
        if isCompactBeforeBack {
            try requireCondition(
                customersScreen.rootElement.waitForDisappearance(timeout: 5),
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
        try navigator.tapRootTab(.orders)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單根未就緒")
        try navigator.tapRootTab(.more)

        // Then
        if try moreLayout(in: app) == .compact {
            try requireCondition(
                customersRow.waitUntilHittable(timeout: 10),
                in: app,
                "返回後跨分頁切換回 More 應維持 More 入口列表"
            )
            try requireCondition(!customersScreen.isDisplayed, in: app, "跨分頁切換回 More 不應再進入客戶名單頁面")
        } else {
            try requireCondition(
                customersScreen.waitUntilReady(timeout: 5),
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
    func testTabSelected_開團詳情已套用未收款篩選_往返分頁後篩選保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try CampaignsScreen.open(in: app)
            .openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        let root = RootNavigationScreen(app: app)
        try detail.revealDistributionRowsBeforeFilter()
        try detail.toggleUnpaidOnly()
        try requireCondition(detail.waitForUnpaidOnlyEnabled(), in: app, "未收款開關值未變成開啟")

        // When
        try root.goToOrders()
        try root.goToCampaigns()
        try detail.revealUnpaidOnlyToggle()
        try detail.revealDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName)

        // Then
        try requireCondition(detail.waitUntilReady(), in: app, "切回開團後詳情未就緒")
        try requireCondition(detail.isUnpaidOnlyEnabled, in: app, "切回開團後未收款開關未維持開啟")
        try requireCondition(
            detail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName),
            in: app,
            "切回開團後未收款客戶列消失"
        )
    }

    /// 驗證 iPad 側邊欄展開時，訂單篩選膠囊與新增按鈕的框線落在視窗內且避開側邊欄保留區；收合後兩者仍在視窗內
    ///
    /// - Throws: 根導覽、訂單清單或框線不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L2
    /// - Note: 側邊欄右緣以品牌標記的右緣近似，側邊欄欄位本身沒有可讀取的 identifier
    func testRevealSidebarIfCollapsed_橫向訂單前景_膠囊與新增鈕在保留區外() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try rotateToLandscape(app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .regular, "側邊欄保留區只存在於 regular 根導覽")
        let root = RootNavigationScreen(app: app)
        try root.goToOrders()
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")

        // When
        try navigator.revealSidebarIfCollapsed()

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

        let chip = orders.statusChip("all")
        let chipFrame = try requireValue(
            app.stableVisibleFrame(of: chip, within: app.windows.firstMatch),
            in: app,
            "篩選膠囊框線不可用"
        )
        let addButton = orders.addButton
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

    /// 驗證開團與更多在方向改變後各自保留已選取的目的地
    ///
    /// - Throws: 目的地未保留或功能版面模式無法辨識時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L3
    /// - Note: 開團與更多各自以功能模式判定，不以根導覽推測
    func testRotateToLandscape_開團與更多已選取目的地轉向往返_目的地保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try root.goToCampaigns()
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        try campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)
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
        // 版面無法辨識時丟出錯誤，能回傳即恰有一種可辨識結果
        _ = try campaignLayout(in: app)
        try requireCondition(detail.waitUntilReady(), in: app, "橫向後開團詳情未保留")

        // When
        try root.goToMore()
        let settings = try SettingsScreen.open(in: app)

        // Then
        try requireCondition(settings.waitUntilReady(), in: app, "進入設定後設定頁未就緒")

        // When
        try rotateToPortrait(app)

        // Then
        try requireCondition(settings.waitUntilReady(), in: app, "直向後設定頁未保留")
        // 版面無法辨識時丟出錯誤，能回傳即恰有一種可辨識結果
        _ = try moreLayout(in: app)
        let morePath = try observedMorePath(in: app)
        try requireCheckPassed(
            PathCheck.verify(expectedDestination: "settings", observedPath: morePath),
            in: app
        )
    }
}

// MARK: - Nested Types

private extension RootNavigationContinuityUITests {

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

private extension RootNavigationContinuityUITests {

    /// 在指定逾時內等待側邊欄品牌標記消失或移出視窗
    ///
    /// - Parameters:
    ///   - navigator: 導覽輔助物件
    ///   - timeout: 等待逾時秒數
    /// - Returns: 標記是否已在逾時前消失
    func waitForSidebarMarkerHidden(navigator: AppNavigator, timeout: TimeInterval = 10) -> Bool {
        Polling.wait(timeout: timeout, interval: 0.1) {
            !navigator.isSidebarMarkerVisible
        }
    }

    /// 讀取更多頁目前目的地的識別值，標記缺失或沒有數值時失敗
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 目前目的地的識別值，未選取時為空字串
    /// - Throws: 選取標記不存在或沒有數值時丟出測試錯誤
    func requireMoreSelection(in app: XCUIApplication) throws(UITestError) -> String {
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
    func observedMorePath(in app: XCUIApplication) throws(UITestError) -> [String] {
        let selection = try requireMoreSelection(in: app)
        return selection.isEmpty ? [] : [selection]
    }
}
