//
//  OrderDetailScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單詳情頁的 Page Object
struct OrderDetailScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    ///
    /// - Returns: 訂單詳情根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.detailRoot
    }
}

// MARK: - Internal Method

@MainActor
extension OrderDetailScreen {

    /// 讀取指定財務摘要卡的 accessibility value
    ///
    /// - Parameter tile: 要讀取的摘要卡種類
    /// - Returns: 該卡的 accessibility value；元素不存在時為 `nil`
    func summaryValue(_ tile: BLAccessibilityID.Orders.SummaryTile) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.detailSummaryTile(tile)
        ]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 開啟「更多」操作選單 (編輯／合併／刪除)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openMoreMenu(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.detailMoreButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 開啟狀態更新選單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openStatusMenu(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.detailStatusMenuButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點更多選單的編輯
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapEdit(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Orders.detailEditButton, file: file, line: line)
    }

    /// 點更多選單的合併
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapMerge(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Orders.detailMergeButton, file: file, line: line)
    }

    /// 點更多選單的刪除
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapDelete(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        app.tapMenuItem(BLAccessibilityID.Orders.detailDeleteButton, file: file, line: line)
    }

    /// 刪除確認 alert 是否呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func deleteConfirmationExists(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 刪除確認 alert 是否已消失
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    @discardableResult
    func deleteConfirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
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
}
