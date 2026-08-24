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
    /// - Returns: 開團詳情根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.detailRoot
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignDetailScreen {

    /// 讀取指定結團結算數值列的 accessibility value
    /// - Parameter kind: 要讀取的結算數值種類
    /// - Returns: 該列的 accessibility value；元素不存在時為空字串
    func summaryValue(_ kind: BLAccessibilityID.Campaigns.DetailSummary) -> String {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Campaigns.detailSummary(kind)
        ]
        guard element.waitForExistence(timeout: 10) else {
            return ""
        }
        return (element.value as? String) ?? ""
    }

    /// 開啟「更多」操作選單 (編輯／結團／刪除)
    func openMoreMenu() {
        let button = app.buttons[BLAccessibilityID.Campaigns.detailMoreButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點更多選單的編輯開團
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapEdit() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailEditButton)
    }

    /// 點更多選單的結團結算 (不可逆)
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapSettle() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailSettleButton)
    }

    /// 點更多選單的刪除開團 (破壞性)
    /// - Returns: 是否在逾時前點到項目
    @discardableResult
    func tapDelete() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailDeleteButton)
    }

    /// 結團確認 alert 是否呈現
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func settleConfirmExists(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點結團確認 alert 的結團按鈕
    func confirmSettle() {
        app.tapAlertButton(label: "結團")
    }

    /// 點結團確認 alert 的取消按鈕
    func cancelSettle() {
        app.tapAlertButton(label: "取消")
    }

    /// 刪除確認 alert 是否呈現
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    @discardableResult
    func deleteConfirmExists(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 點刪除確認 alert 的破壞性刪除按鈕
    func confirmDelete() {
        app.tapAlertButton(label: "刪除")
    }

    /// 點刪除確認 alert 的取消按鈕
    func cancelDelete() {
        app.tapAlertButton(label: "取消")
    }

    /// 確認 alert 是否已消失
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    @discardableResult
    func confirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }
}
