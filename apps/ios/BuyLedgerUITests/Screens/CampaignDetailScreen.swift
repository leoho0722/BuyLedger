//
//  CampaignDetailScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情頁的 Page Object
struct CampaignDetailScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    ///
    /// - Returns: 開團詳情根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.detailRoot
    }
}

// MARK: - Status Queries

extension CampaignDetailScreen {

    /// 是否在逾時前看到已結團狀態
    ///
    /// - Parameter timeout: 等待狀態膠囊出現的秒數
    /// - Returns: 狀態膠囊是否在逾時前出現
    func hasSettledBadge(timeout: TimeInterval = 2) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.detailSettledBadge]
            .waitForExistence(timeout: timeout)
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignDetailScreen {

    /// 讀取指定結團結算數值列的 accessibility value
    ///
    /// - Parameter kind: 要讀取的結算數值種類
    /// - Returns: 該列的 accessibility value；元素不存在時為 `nil`
    func summaryValue(_ kind: BLAccessibilityID.Campaigns.DetailSummary) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Campaigns.detailSummary(kind)
        ]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 開啟「更多」操作選單 (編輯／結團／刪除)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openMoreMenu(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailMoreButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點更多選單的編輯開團
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapEdit(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailEditButton, file: file, line: line)
    }

    /// 點更多選單的結團結算 (不可逆)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapSettle(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailSettleButton, file: file, line: line)
    }

    /// 點更多選單的刪除開團 (破壞性)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapDelete(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailDeleteButton, file: file, line: line)
    }

    /// 結團確認 alert 是否呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func settleConfirmExists(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點結團確認 alert 的結團按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func confirmSettle(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "結團", file: file, line: line)
    }

    /// 點結團確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func cancelSettle(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "取消", file: file, line: line)
    }

    /// 刪除確認 alert 是否呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func deleteConfirmExists(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點刪除確認 alert 的破壞性刪除按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func confirmDelete(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "刪除", file: file, line: line)
    }

    /// 點刪除確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func cancelDelete(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "取消", file: file, line: line)
    }

    /// 確認 alert 是否已消失
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    @discardableResult
    func confirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }
}
