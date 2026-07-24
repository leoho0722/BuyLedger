//
//  CampaignDetailScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情頁的 Page Object
///
/// 以 accessibility identifier 對外暴露結團結算數值列、更多操作選單、結團與刪除確認的語意操作；
/// compact push 詳情與 regular detail 欄共用同一組 identifier，故 Page Object 不分版面
struct CampaignDetailScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.detailRoot
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignDetailScreen {

    /// 讀取指定結團結算數值列的 accessibility value
    ///
    /// 數值列是 `LabeledContent` 合併朗讀的單一元素，主要數值放在該元素的 value；元素歸為 staticText，故以 any 查詢而非 otherElements
    /// - Parameter kind: 目標數值列種類 (應收／已收)
    /// - Returns: 該列 value 字串，元素不存在時回傳空字串
    func summaryValue(_ kind: BLAccessibilityID.Campaigns.DetailSummary) -> String {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Campaigns.detailSummary(kind)]
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
    /// - Returns: 逾時前是否點到項目
    @discardableResult
    func tapEdit() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailEditButton)
    }

    /// 點更多選單的結團結算 (不可逆)
    /// - Returns: 逾時前是否點到項目
    @discardableResult
    func tapSettle() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailSettleButton)
    }

    /// 點更多選單的刪除開團 (破壞性)
    /// - Returns: 逾時前是否點到項目
    @discardableResult
    func tapDelete() -> Bool {
        app.tapMenuItem(BLAccessibilityID.Campaigns.detailDeleteButton)
    }

    /// 結團確認 alert 是否呈現
    ///
    /// 結團確認是 `AlertState`、掛不上 identifier，以「有無 alert 呈現」判定
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否出現
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
    ///
    /// 刪除確認是 `AlertState`、掛不上 identifier，以「有無 alert 呈現」判定
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否出現
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
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否消失
    @discardableResult
    func confirmationDismissed(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }
}
