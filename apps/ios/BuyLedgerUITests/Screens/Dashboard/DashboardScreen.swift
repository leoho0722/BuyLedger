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

@MainActor
extension DashboardScreen {

    /// 是否正顯示尚無資料的引導空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.emptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension DashboardScreen {

    /// 載入總覽版面所需元素並回傳同一快照要讀取的 identifier
    ///
    /// - Parameters:
    ///   - campaignID: 固定種子的開團識別值
    ///   - orderID: 固定種子的近期訂單識別值
    /// - Returns: 版面測試必須出現在快照中的 identifier
    func prepareLayoutSnapshot(campaignID: String, orderID: String) -> [String] {
        let identifiers = [
            BLAccessibilityID.Dashboard.currentDateSubtitle,
            BLAccessibilityID.Dashboard.kpiTile(.netProfit),
            BLAccessibilityID.Dashboard.kpiTile(.revenue),
            BLAccessibilityID.Dashboard.kpiTile(.cost),
            BLAccessibilityID.Dashboard.kpiTile(.grossMargin),
            BLAccessibilityID.Dashboard.kpiTile(.activeOrders),
            BLAccessibilityID.Dashboard.ongoingCampaignRow(campaignID: campaignID),
            BLAccessibilityID.Dashboard.recentOrderRow(orderID: orderID),
        ]
        app.loadMissingElements(with: identifiers, within: rootElement)
        return identifiers
    }

    /// 將總覽日期子標捲入可視區後讀取框線
    ///
    /// - Returns: 日期副標框線；元素尚未出現或無有效框線時為 `nil`
    func currentDateSubtitleFrame() -> CGRect? {
        frame(for: BLAccessibilityID.Dashboard.currentDateSubtitle)
    }

    /// 將指定 KPI 卡捲入可視區後讀取框線
    ///
    /// - Parameter kpi: KPI 種類
    /// - Returns: KPI 卡框線；元素尚未出現或無有效框線時為 `nil`
    func kpiTileFrame(_ kpi: BLAccessibilityID.Dashboard.KPI) -> CGRect? {
        frame(for: BLAccessibilityID.Dashboard.kpiTile(kpi))
    }

    /// 將首頁開團卡中指定開團列捲入可視區後讀取框線
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 開團列框線；元素尚未出現或無有效框線時為 `nil`
    func ongoingCampaignRowFrame(campaignID: String) -> CGRect? {
        frame(for: BLAccessibilityID.Dashboard.ongoingCampaignRow(campaignID: campaignID))
    }

    /// 將近期訂單中指定訂單列捲入可視區後讀取框線
    ///
    /// - Parameter orderID: 訂單識別值
    /// - Returns: 訂單列框線；元素尚未出現或無有效框線時為 `nil`
    func recentOrderRowFrame(orderID: String) -> CGRect? {
        frame(for: BLAccessibilityID.Dashboard.recentOrderRow(orderID: orderID))
    }

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

    /// 等待首頁載入失敗畫面消失
    ///
    /// - Parameter timeout: 等待失敗畫面消失的秒數
    /// - Returns: 載入失敗畫面是否在逾時前消失
    func waitForLoadFailureDismissal(timeout: TimeInterval = 5) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loadFailure]
            .waitForDisappearance(timeout: timeout)
    }

    /// 等待指定開團列出現於首頁開團卡，並捲入可見範圍
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
    /// - Note: 卡片尚未建立時會向下捲動首頁，讓 `LazyVGrid` 載入目標卡
    /// - Note: 連續讀取多張 KPI 時，呼叫順序須由畫面上方往下方
    func kpiValue(_ kpi: BLAccessibilityID.Dashboard.KPI) -> String? {
        // 合併朗讀的卡片在 XCUITest 歸為 `staticText`，故以 `any` 查詢而非 `otherElements`
        let identifier = BLAccessibilityID.Dashboard.kpiTile(kpi)
        let tile = app.descendants(matching: .any)[identifier].firstMatch
        app.loadMissingElements(with: [identifier], within: rootElement)
        guard tile.waitForExistence(timeout: 1) else {
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

    /// 判定總覽頁已就緒的根元素 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Private Method

@MainActor
private extension DashboardScreen {

    /// 將語意識別碼對應元素捲入可視區後讀取穩定框線
    ///
    /// - Parameter identifier: accessibility identifier
    /// - Returns: 元素穩定且可見的框線；元素不存在或無效時為 `nil`
    func frame(for identifier: String) -> CGRect? {
        let element = app.descendants(matching: .any)[identifier]
        return app.stableVisibleFrame(of: element, within: rootElement)
    }
}
