//
//  RootNavigationScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 根導覽的 Page Object，供 UI 測試切換分頁並等待目的地就緒
struct RootNavigationScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication

    /// 提供原生根分頁語意操作的導覽器
    private let navigator: AppNavigator

    // MARK: - Init

    /// 保存受測 App，並以它建立導覽分流器
    ///
    /// - Parameter app: 受測 App
    init(app: XCUIApplication) {
        self.app = app
        self.navigator = AppNavigator(app: app)
    }
}

// MARK: - Internal Method

@MainActor
extension RootNavigationScreen {

    /// 切到總覽頁並等待前景就緒
    ///
    /// - Parameters:
    ///   - timeout: 等待總覽頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func goToDashboard(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try go(
            to: .dashboard,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到訂單頁並等待前景就緒
    ///
    /// - Parameters:
    ///   - timeout: 等待訂單頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func goToOrders(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try go(
            to: .orders,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到開團頁並等待前景就緒
    ///
    /// - Parameters:
    ///   - timeout: 等待開團頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func goToCampaigns(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try go(
            to: .campaigns,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到分析頁並等待前景就緒
    ///
    /// - Parameters:
    ///   - timeout: 等待分析頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func goToInsights(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try go(
            to: .insights,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到更多頁並等待前景就緒
    ///
    /// - Parameters:
    ///   - timeout: 等待更多頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func goToMore(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try go(
            to: .more,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 等待指定的一組前景元素或資料列可互動
    ///
    /// - Parameters:
    ///   - identifiers: 可判定目的地就緒的固定 identifier
    ///   - identifierPrefixes: 可判定目的地就緒的資料列 identifier 前綴
    ///   - message: 目的地未就緒時記錄的訊息
    ///   - timeout: 等待前景元素就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 目的地前景未就緒時丟出測試錯誤
    func requireForeground(
        identifiers: [String],
        identifierPrefixes: [String] = [],
        message: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let isReady = Polling.wait(timeout: timeout) {
            hasForegroundElements(identifiers)
                || identifierPrefixes.contains { hasHittableRow(withIdentifierPrefix: $0) }
        }
        guard isReady else {
            try app.stopWithDiagnostics(message, file: file, line: line)
        }
    }
}

// MARK: - ScreenProtocol

extension RootNavigationScreen: ScreenProtocol {

    /// 根導覽就緒判定用的 identifier，取啟動後預設顯示的總覽頁根元素
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Private Method

@MainActor
private extension RootNavigationScreen {

    /// More 根入口、保留的工具頁或寬版未選取提示是否有可互動前景內容
    var isMoreDestinationForegroundReady: Bool {
        hasForegroundElements(MoreDestinationIdentifiers.foreground)
            || MoreDestinationIdentifiers.rowPrefixes.contains {
                hasHittableRow(withIdentifierPrefix: $0)
            }
    }

    /// 切換根目的地後等待該分頁目前的前景內容
    ///
    /// - Parameters:
    ///   - tab: 目標根分頁
    ///   - timeout: 等待前景內容就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func go(
        to tab: AppNavigator.Tab,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) throws(UITestError) {
        if !isForegroundDestinationReady(for: tab) {
            try navigator.tapRootTab(tab, timeout: timeout, file: file, line: line)
        }

        let isReady = Polling.wait(timeout: timeout) {
            isForegroundDestinationReady(for: tab)
        }
        guard isReady else {
            try app.stopWithDiagnostics(
                "根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey)) 前景內容未就緒",
                file: file,
                line: line
            )
        }
    }

    /// 判斷指定根分頁的實際前景內容是否已就緒
    ///
    /// - Parameter tab: 目標根分頁
    /// - Returns: 前景控制項或資料列是否可見且可互動
    func isForegroundDestinationReady(for tab: AppNavigator.Tab) -> Bool {
        switch tab {
        case .dashboard:
            return hasForegroundElements([
                BLAccessibilityID.Dashboard.currentDateSubtitle,
                BLAccessibilityID.Dashboard.kpiTile(.revenue),
                BLAccessibilityID.Dashboard.kpiTile(.netProfit),
                BLAccessibilityID.Dashboard.emptyStateActionButton,
                BLAccessibilityID.Dashboard.loadFailureRetryButton,
            ])

        case .orders:
            return hasHittableRow(withIdentifierPrefix: BLAccessibilityID.Orders.row(orderID: ""))
                || hasForegroundElements([
                    BLAccessibilityID.Orders.addButton,
                    BLAccessibilityID.Orders.listEmptyState,
                    BLAccessibilityID.Orders.detailMoreButton,
                    BLAccessibilityID.Orders.detailSummaryTile(.revenue),
                    BLAccessibilityID.Orders.detailSummaryTile(.cost),
                    BLAccessibilityID.Orders.detailSummaryTile(.profit),
                ])

        case .campaigns:
            return hasHittableRow(
                withIdentifierPrefix: BLAccessibilityID.Campaigns.row(campaignID: "")
            )
                || hasForegroundElements([
                    BLAccessibilityID.Campaigns.addButton,
                    BLAccessibilityID.Campaigns.filterMenuButton,
                    BLAccessibilityID.Campaigns.listLoadFailureRetryButton,
                    BLAccessibilityID.Campaigns.detailMoreButton,
                    BLAccessibilityID.Campaigns.detailEditButton,
                    BLAccessibilityID.Campaigns.detailSettleButton,
                ])

        case .insights:
            return hasForegroundElements([
                BLAccessibilityID.Insights.rangePicker,
                BLAccessibilityID.Insights.trendTotalProfit,
                BLAccessibilityID.Insights.emptyState,
                BLAccessibilityID.Insights.loadFailureRetryButton,
            ])

        case .more:
            return isMoreDestinationForegroundReady
        }
    }

    /// 查詢一組 accessibility ID 中是否有可見且可互動的前景元素
    ///
    /// - Parameter identifiers: 要查詢的語意識別值
    /// - Returns: 至少一個元素是否位於前景且可互動
    func hasForegroundElements(_ identifiers: [String]) -> Bool {
        identifiers.contains { identifier in
            let elements = app.descendants(matching: .any).matching(identifier: identifier)
                .allElementsBoundByIndex
            return elements.contains {
                $0.isHittableOnScreen
            }
        }
    }

    /// 查詢前綴相符的資料列中是否有可見且可互動的前景元素
    ///
    /// - Parameter prefix: 資料列 identifier 的固定前綴
    /// - Returns: 至少一筆相符資料列是否位於前景且可互動
    func hasHittableRow(withIdentifierPrefix prefix: String) -> Bool {
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        )
        return rows.allElementsBoundByIndex.contains { $0.isHittableOnScreen }
    }
}
