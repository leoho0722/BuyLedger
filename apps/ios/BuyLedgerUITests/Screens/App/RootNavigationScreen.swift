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

    /// 切到總覽頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待總覽頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 總覽頁是否在逾時前就緒
    @discardableResult
    func goToDashboard(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .dashboard,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到訂單頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待訂單頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 訂單頁是否在逾時前就緒
    @discardableResult
    func goToOrders(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .orders,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到開團頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待開團頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 開團頁是否在逾時前就緒
    @discardableResult
    func goToCampaigns(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .campaigns,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到分析頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待分析頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 分析頁是否在逾時前就緒
    @discardableResult
    func goToInsights(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .insights,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到更多頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待更多頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 更多頁是否在逾時前就緒
    @discardableResult
    func goToMore(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .more,
            timeout: timeout,
            file: file,
            line: line
        )
    }
}

// MARK: - Screen

extension RootNavigationScreen: Screen {

    /// 根導覽就緒判定用的 identifier，取總覽頁根元素 (啟動後預設停在總覽頁)
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Private Method

@MainActor
private extension RootNavigationScreen {

    /// More 的根入口、目前保留的工具頁或寬版未選取提示是否有可互動前景內容
    var isMoreDestinationForegroundReady: Bool {
        hasForegroundElements([
            BLAccessibilityID.Common.detailEmptyState,
            BLAccessibilityID.More.row(.fx),
            BLAccessibilityID.More.row(.customers),
            BLAccessibilityID.More.row(.quote),
            BLAccessibilityID.More.row(.orderSources),
            BLAccessibilityID.More.row(.categories),
            BLAccessibilityID.More.row(.paymentMethods),
            BLAccessibilityID.More.row(.reconciliationStatuses),
            BLAccessibilityID.More.row(.settings),
            BLAccessibilityID.Settings.languagePicker,
            BLAccessibilityID.Settings.defaultCurrencyRow,
            BLAccessibilityID.Settings.monthlyGoalField,
            BLAccessibilityID.Settings.aiSummaryToggle,
            BLAccessibilityID.Settings.appLockToggle,
            BLAccessibilityID.Fx.amountField,
            BLAccessibilityID.Fx.currencyPickerButton,
            BLAccessibilityID.Quote.principalField,
            BLAccessibilityID.Quote.currencyPickerButton,
            BLAccessibilityID.Quote.retryButton,
            BLAccessibilityID.LookupManagement.addButton,
            BLAccessibilityID.LookupManagement.nameField,
            BLAccessibilityID.LookupManagement.paymentMethodNameField,
            BLAccessibilityID.LookupManagement.paymentMethodSaveButton,
            BLAccessibilityID.OptionPicker.addButton,
            BLAccessibilityID.OptionPicker.doneButton,
        ])
            || hasHittableRow(
                withIdentifierPrefix: BLAccessibilityID.Customers.row(customerName: "")
            )
            || hasHittableRow(
                withIdentifierPrefix: BLAccessibilityID.Customers.topCard(customerName: "")
            )
            || hasHittableRow(withIdentifierPrefix: BLAccessibilityID.LookupManagement.row(""))
            || hasHittableRow(withIdentifierPrefix: BLAccessibilityID.OptionPicker.optionRow(""))
            || hasForegroundElements([
                BLAccessibilityID.Customers.listEmptyState,
                BLAccessibilityID.Customers.listLoadFailureRetryButton,
                BLAccessibilityID.Customers.listLoading,
                BLAccessibilityID.Fx.convertedValue,
                BLAccessibilityID.Fx.statusBanner,
                BLAccessibilityID.Quote.suggestedPriceValue,
                BLAccessibilityID.Quote.statusBanner,
                BLAccessibilityID.LookupManagement.loadFailureMessage,
                BLAccessibilityID.LookupManagement.paymentMethodEditorRoot,
            ])
    }

    /// 切換根目的地後等待該分頁目前的前景內容
    ///
    /// - Parameters:
    ///   - tab: 目標根分頁
    ///   - timeout: 等待前景內容就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 根控制項與目的地前景是否都已就緒
    func go(
        to tab: AppNavigator.Tab,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) -> Bool {
        if !isForegroundDestinationReady(for: tab) {
            guard navigator.tapRootTab(tab, timeout: timeout) else {
                app.failWithDiagnostics(
                    "找不到或無法點擊根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey))",
                    file: file,
                    line: line
                )
                return false
            }
        }

        let deadline = Date.now.addingTimeInterval(timeout)
        while true {
            if isForegroundDestinationReady(for: tab) {
                return true
            }
            guard Date.now < deadline else {
                break
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }

        app.failWithDiagnostics(
            "切換至根分頁 \(BLAccessibilityID.Root.tab(tab.identifierKey)) 後前景內容未就緒",
            file: file,
            line: line
        )
        return false
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
