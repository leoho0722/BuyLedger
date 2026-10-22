//
//  DashboardScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 總覽頁的 Page Object
struct DashboardScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

extension DashboardScreen {

    /// 是否正顯示尚無資料的引導空狀態
    ///
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.emptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension DashboardScreen {

    /// 等待首頁載入失敗畫面出現
    ///
    /// - Parameter timeout: 等待失敗畫面出現的秒數
    /// - Returns: 載入失敗畫面是否在逾時前出現
    func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loadFailure]
            .waitForExistence(timeout: timeout)
    }

    /// 點載入失敗畫面的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Dashboard.loadFailureRetryButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待首頁載入失敗畫面收回
    ///
    /// - Parameter timeout: 等待失敗畫面消失的秒數
    /// - Returns: 載入失敗畫面是否在逾時前消失
    func waitForLoadFailureDismissal(timeout: TimeInterval = 5) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loadFailure]
            .waitForDisappearance(timeout: timeout)
    }

    /// 確認首頁開團卡列出指定開團，並將該列捲入可見範圍
    ///
    /// - Parameters:
    ///   - campaignID: 開團編號
    ///   - timeout: 等待開團列出現的秒數
    /// - Returns: 開團列是否出現且可見
    func hasOngoingCampaign(campaignID: String, timeout: TimeInterval = 10) -> Bool {
        let row = ongoingCampaignRow(campaignID: campaignID)
        guard row.waitForExistence(timeout: timeout) else {
            return false
        }
        return app.scrollToHittable(row, within: rootElement)
    }

    /// 取首頁開團卡中指定編號的進行中開團列
    ///
    /// - Parameter campaignID: 開團編號
    /// - Returns: 對應的首頁開團列元素
    func ongoingCampaignRow(campaignID: String) -> XCUIElement {
        app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.ongoingCampaignRow(campaignID: campaignID)
        ]
    }

    /// 點空狀態的「建立第一筆訂單」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCreateFirstOrder(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Dashboard.emptyStateActionButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 讀取指定 KPI 卡的 `value`
    ///
    /// - Parameter kpi: 要讀取的 KPI 種類
    /// - Returns: KPI 卡的 `value`；元素不存在時為 `nil`
    func kpiValue(_ kpi: BLAccessibilityID.Dashboard.KPI) -> String? {
        // 合併朗讀的卡片在 XCUITest 歸為 `staticText`，故以 `any` 查詢而非 `otherElements`
        let tile = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.kpiTile(kpi)]
        guard tile.waitForExistence(timeout: 10) else {
            return nil
        }
        return tile.value as? String
    }

    /// 點近期訂單的「查看全部」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapSeeAllRecentOrders(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Dashboard.recentOrdersSeeAllButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點近期訂單中指定訂單編號的列
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRecentOrder(orderID: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = recentOrderRow(orderID: orderID)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 取近期訂單中指定訂單編號的列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的近期訂單列元素
    func recentOrderRow(orderID: String) -> XCUIElement {
        // 合併朗讀的列在 XCUITest 歸為 `staticText`，故以 `any` 查詢而非 `otherElements`
        app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.recentOrderRow(orderID: orderID)
        ]
    }
}

// MARK: - Screen

extension DashboardScreen: Screen {

    /// 以 `BLAccessibilityID.Dashboard.root` 指定總覽頁的根元素
    ///
    /// - Returns: 總覽頁根元素的 `identifier`
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}
