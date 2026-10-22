//
//  CampaignDetailScreen+Toolbar.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/3.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension CampaignDetailScreen {

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
    func isSettleConfirmationPresented(timeout: TimeInterval = 5) -> Bool {
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
    func isDeleteConfirmationPresented(timeout: TimeInterval = 5) -> Bool {
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
    func isConfirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }

    /// 從詳情的導覽列返回開團列表，避免點到 iPad 側邊欄的返回鍵
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapBack(file: StaticString = #filePath, line: UInt = #line) {
        let detailBar = app.navigationBars
            .containing(.button, identifier: BLAccessibilityID.Campaigns.detailMoreButton)
            .firstMatch
        let back = detailBar.buttons[BLAccessibilityID.Common.backButton]
        back.tapAfterWaiting(in: app, file: file, line: line)
    }
}
