//
//  RootNavigationLaunchUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 根導覽啟動與分頁切換的 UI 測試
@MainActor
final class RootNavigationLaunchUITests: BLUITestCase {

    /// 驗證全新根導覽以原生分頁列顯示五個直接目的地
    ///
    /// - Throws: 根畫面或原生分頁目的地不符合預期時丟出測試錯誤
    func testVisibleRootTabCount_首次啟動_顯示五個原生分頁() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        // When
        let navigator = AppNavigator(app: app)
        let isSidebarMarkerVisible = navigator.isSidebarMarkerVisible
        let actualTabCount = navigator.visibleRootTabCount()

        // Then
        try requireCondition(
            !isSidebarMarkerVisible && actualTabCount == 5,
            in: app,
            "初始 Root.tab.* 可見數=\(actualTabCount)，sidebar marker=\(isSidebarMarkerVisible)"
        )
    }

    /// 驗證原生 More 分頁可點，且系統側邊欄切換後顯示品牌標記與五個入口
    ///
    /// - Throws: 原生 More 分頁或側邊欄入口不符合預期時丟出測試錯誤
    func testTabSelected_原生More與側邊欄切換_顯示品牌標記及五個入口() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(
            layout == .regular,
            "側邊欄只存在於 regular 版面，compact 版面由 testVisibleRootTabCount_首次啟動_顯示五個原生分頁 覆蓋"
        )
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")

        // When
        try navigator.tapRootTab(.more)
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root].firstMatch
        try requireCondition(
            moreRoot.waitForExistence(timeout: 10),
            in: app,
            "點選原生 More 分頁後 More.root 未出現"
        )

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
        let isSidebarMarkerVisible = navigator.waitForRootSidebarMarkerVisible(timeout: 10)
        let visibleTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            isSidebarMarkerVisible && visibleTabCount == 5,
            in: app,
            "切側欄後 Root.tab.* 可見數=\(visibleTabCount)，sidebar marker=\(isSidebarMarkerVisible)"
        )
    }

    /// 驗證從總覽依序切過其他四個分頁時，每次切換後目的地畫面都就緒，切回總覽後總覽畫面也就緒
    ///
    /// - Throws: 根導覽或前四次分頁切換的前置條件不成立，或切回總覽後總覽畫面未就緒時丟出測試錯誤
    /// - Note: 情境流程：依序切過四個分頁，前四次切換放 Given，切回總覽為受測動作
    func testTabSelected_依序切過其他四個分頁後_總覽畫面就緒() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        // 前四次切換當下就確認就緒，失敗時的診斷截圖停在出錯的分頁
        try root.goToOrders()
        try root.goToCampaigns()
        try root.goToInsights()
        try root.goToMore()

        // When
        try root.goToDashboard()

        // Then
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "從更多切回「總覽」分頁後總覽畫面未就緒")
    }
}
