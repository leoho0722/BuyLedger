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
    /// - Returns: 訂單詳情根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.detailRoot
    }
}

// MARK: - Internal Method

@MainActor
extension OrderDetailScreen {

    /// 讀取指定財務摘要卡的 accessibility value
    /// - Parameter tile: 要讀取的摘要卡種類
    /// - Returns: 該卡的 accessibility value；元素不存在時為空字串
    func summaryValue(_ tile: BLAccessibilityID.Orders.SummaryTile) -> String {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.detailSummaryTile(tile)
        ]
        guard element.waitForExistence(timeout: 10) else {
            return ""
        }
        return (element.value as? String) ?? ""
    }

    /// 開啟「更多」操作選單 (編輯／合併／刪除)
    func openMoreMenu() {
        let button = app.buttons[BLAccessibilityID.Orders.detailMoreButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 開啟狀態更新選單
    func openStatusMenu() {
        let button = app.buttons[BLAccessibilityID.Orders.detailStatusMenuButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點更多選單的編輯
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapEdit() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Orders.detailEditButton)
    }

    /// 點更多選單的合併
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapMerge() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Orders.detailMergeButton)
    }

    /// 點更多選單的刪除
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapDelete() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Orders.detailDeleteButton)
    }

    /// 刪除確認 alert 是否呈現
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func deleteConfirmationExists(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 刪除確認 alert 是否已消失
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    @discardableResult
    func deleteConfirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }

    /// 點刪除確認 alert 的破壞性刪除按鈕
    func confirmDelete() {
        app.tapAlertButton(label: "刪除")
    }

    /// 點刪除確認 alert 的取消按鈕
    func cancelDelete() {
        app.tapAlertButton(label: "取消")
    }
}
