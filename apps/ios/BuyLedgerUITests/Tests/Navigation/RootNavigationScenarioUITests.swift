//
//  RootNavigationScenarioUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/3.
//

import XCTest

/// 根導覽情境的 UI 測試，涵蓋收合版設定頁左緣拖曳返回與 App 鎖定時的根分頁導覽診斷
@MainActor
final class RootNavigationScenarioUITests: BLUITestCase {

    /// 驗證收合版更多進入設定後，從左緣向右拖曳會經系統導覽返回入口清單，設定頁離開前景
    ///
    /// - Throws: 版面不是收合、設定頁無法開啟，或返回後入口清單與設定頁的前景狀態不符合預期時丟出測試錯誤
    /// - Note: 只在更多的收合導覽執行，寬版並排時設定頁位於詳情欄，沒有返回堆疊可驗證
    func testEntrySelected_收合版設定頁左緣拖曳_返回入口清單() throws {
        // Given
        let app = try launch()
        let root = RootNavigationScreen(app: app)
        try root.goToMore()
        try XCTSkipUnless(
            try moreLayout(in: app) == .compact,
            "左緣返回只在更多的收合導覽中適用，並排時設定頁位於詳情欄"
        )
        let settings = try SettingsScreen.open(in: app)

        // When
        let leadingEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let trailingTarget = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        leadingEdge.press(forDuration: 0.1, thenDragTo: trailingTarget)

        // Then
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        try requireCondition(
            moreRoot.waitForExistence(timeout: 10),
            in: app,
            "左緣拖曳後未回到更多入口清單"
        )
        try requireCondition(
            settings.rootElement.waitForDisappearance(timeout: 10),
            in: app,
            "左緣拖曳後設定頁仍在前景"
        )
    }

    /// 驗證 App 鎖定畫面上根分頁不可用時，選取訂單分頁會記錄診斷失敗，而不是回傳成功或略過
    ///
    /// - Throws: 鎖定畫面未出現、訂單分頁意外可互動或導覽後鎖定畫面消失時丟出測試錯誤
    /// - Note: 以 `XCTExpectFailure` 的嚴格模式包住導覽呼叫，沒有記錄到預期訊息時整個測試失敗
    func testSelectTab_App鎖定時根分頁不可用_記錄診斷失敗() throws {
        // Given
        let app = try launch(LaunchOptions(isAppLockEnabled: true, biometricScenario: .failure))
        let lockScreen = AppLockScreen(app: app)
        try requireCondition(lockScreen.waitUntilReady(), in: app, "帶 App 鎖定啟動後鎖定畫面未出現")
        let navigator = AppNavigator(app: app)
        try requireCondition(
            !navigator.rootTabElement(for: .orders).isHittableOnScreen,
            in: app,
            "鎖定畫面上訂單分頁不應可互動"
        )

        // When
        continueAfterFailure = true
        XCTExpectFailure("App 鎖定時根分頁不可用，selectTab 應記錄診斷失敗", strict: true) {
            do {
                try navigator.selectTab(.orders)
            } catch {
                // 失敗已由 XCTExpectFailure 涵蓋，接住停止訊號後繼續執行 Then
            }
        } issueMatcher: {
            $0.compactDescription.contains("找不到可互動的根分頁")
        }
        continueAfterFailure = false

        // Then
        try requireCondition(lockScreen.isDisplayed, in: app, "選取分頁後鎖定畫面不應消失")
    }
}
