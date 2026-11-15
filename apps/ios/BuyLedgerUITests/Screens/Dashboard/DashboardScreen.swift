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

    /// 切到總覽分頁，等待目前的前景內容、空狀態或載入失敗就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已進入前景的總覽畫面
    /// - Throws: 分頁無法切換或目的地未就緒時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> DashboardScreen {
        try RootNavigationScreen(app: app).goToDashboard(file: file, line: line)
        return DashboardScreen(app: app)
    }

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

    /// 等待首頁載入失敗畫面出現
    ///
    /// - Parameter timeout: 等待失敗畫面出現的秒數
    /// - Returns: 載入失敗畫面是否在逾時前出現
    func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loadFailure]
            .waitForExistence(timeout: timeout)
    }

    /// 等待總覽頁顯示載入中
    ///
    /// - Parameter timeout: 等待載入指示器出現的秒數
    /// - Returns: 載入指示器是否在逾時前出現
    func waitForLoading(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loading]
            .waitForExistence(timeout: timeout)
    }

    /// 點載入失敗畫面的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Dashboard.loadFailureRetryButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待首頁載入失敗畫面消失
    ///
    /// - Parameter timeout: 等待失敗畫面消失的秒數
    /// - Returns: 載入失敗畫面是否在逾時前消失
    func waitForLoadFailureDismissal(timeout: TimeInterval = 5) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loadFailure]
            .waitForDisappearance(timeout: timeout)
    }

    /// 等待指定開團列出現於首頁開團卡
    ///
    /// - Parameters:
    ///   - campaignID: 開團編號
    ///   - timeout: 等待開團列出現的秒數，立即判斷時傳 0
    /// - Returns: 開團列是否在逾時前出現
    /// - Note: 不捲動；需要先捲入可見範圍時由呼叫端先呼叫 `revealOngoingCampaign`
    func hasOngoingCampaign(campaignID: String, timeout: TimeInterval = 10) -> Bool {
        ongoingCampaignRow(campaignID: campaignID).waitForExistence(timeout: timeout)
    }

    /// 等待指定開團列出現於首頁開團卡，並捲入可見範圍
    ///
    /// - Parameters:
    ///   - campaignID: 開團編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 開團列未出現或無法捲入可見範圍時丟出測試錯誤
    func revealOngoingCampaign(
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try revealRow(
            ongoingCampaignRow(campaignID: campaignID),
            name: "進行中開團列「\(campaignID)」",
            file: file,
            line: line
        )
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

    /// 點空狀態的「建立第一筆訂單」，等待訂單編輯表單就緒
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的訂單編輯表單
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapCreateFirstOrder(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        try emptyStateActionButton.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OrderEditScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 等待空狀態行動按鈕出現並讀取其標籤
    ///
    /// - Parameter timeout: 等待按鈕出現的秒數
    /// - Returns: 按鈕的 accessibility label；按鈕未出現時為 `nil`
    func emptyStateActionLabel(timeout: TimeInterval = 10) -> String? {
        let button = emptyStateActionButton
        guard button.waitForExistence(timeout: timeout) else {
            return nil
        }
        return button.label
    }

    /// 等待總覽頁的日期副標出現並讀取其標籤
    ///
    /// - Parameter timeout: 等待日期副標出現的秒數
    /// - Returns: 日期副標的 accessibility label；元素未出現時為 `nil`
    func currentDateSubtitle(timeout: TimeInterval = 10) -> String? {
        let subtitle = app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.currentDateSubtitle
        ]
        guard subtitle.waitForExistence(timeout: timeout) else {
            return nil
        }
        return subtitle.label
    }

    /// 讀取指定 KPI 卡的 `value`
    ///
    /// - Parameter kpi: 要讀取的 KPI 種類
    /// - Returns: KPI 卡的 `value`；元素不存在時為 `nil`
    /// - Note: 卡片尚未建立時會向下捲動首頁，讓 `LazyVGrid` 載入目標卡
    /// - Note: 連續讀取多張 KPI 時，呼叫順序須由畫面上方往下方
    func kpiValue(_ kpi: BLAccessibilityID.Dashboard.KPI) -> String? {
        let identifier = BLAccessibilityID.Dashboard.kpiTile(kpi)
        let tile = kpiTile(kpi)
        app.loadMissingElements(with: [identifier], within: rootElement)
        guard tile.waitForExistence(timeout: 1) else {
            return nil
        }
        return tile.value as? String
    }

    /// 取指定 KPI 卡片元素
    ///
    /// - Parameter kpi: KPI 種類
    /// - Returns: 對應的 KPI 卡片元素
    func kpiTile(_ kpi: BLAccessibilityID.Dashboard.KPI) -> XCUIElement {
        // 合併朗讀卡片在 XCUITest 歸為 `staticText`，故以 `any` 查詢
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.kpiTile(kpi)].firstMatch
    }

    /// 取近期訂單中指定訂單編號的列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的近期訂單列元素
    func recentOrderRow(orderID: String) -> XCUIElement {
        // 合併朗讀列在 XCUITest 歸為 `staticText`，故以 `any` 查詢
        app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.recentOrderRow(orderID: orderID)
        ]
    }

    /// 等待近期訂單中指定訂單編號的列出現，並捲入可見範圍
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 近期訂單列未出現或無法捲入可見範圍時丟出測試錯誤
    func revealRecentOrder(
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try revealRow(
            recentOrderRow(orderID: orderID),
            name: "近期訂單列「\(orderID)」",
            file: file,
            line: line
        )
    }
}

// MARK: - ScreenProtocol

extension DashboardScreen: ScreenProtocol {

    /// 判定總覽頁已就緒的根元素 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Private Method

@MainActor
private extension DashboardScreen {

    /// 空狀態的主要行動按鈕
    var emptyStateActionButton: XCUIElement {
        app.buttons[BLAccessibilityID.Dashboard.emptyStateActionButton]
    }

    /// 等待首頁列出現後捲入可見範圍
    ///
    /// - Parameters:
    ///   - row: 要露出的首頁列
    ///   - name: 失敗診斷中的列描述
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 列未出現或無法捲入可見範圍時丟出測試錯誤
    func revealRow(
        _ row: XCUIElement,
        name: String,
        file: StaticString,
        line: UInt
    ) throws(UITestError) {
        guard row.waitForExistence(timeout: 10) else {
            try app.stopWithDiagnostics("找不到\(name)", file: file, line: line)
        }
        guard app.waitUntilHittableByScrolling(row, within: rootElement) else {
            try app.stopWithDiagnostics("\(name)無法捲入可見範圍", file: file, line: line)
        }
    }
}

