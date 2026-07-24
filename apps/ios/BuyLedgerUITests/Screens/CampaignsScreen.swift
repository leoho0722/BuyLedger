//
//  CampaignsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團列表頁的 Page Object
///
/// 以 accessibility identifier 對外暴露新增與開團列的語意操作，元素查詢細節不外洩給測試檔；
/// compact 分頁列與 regular 側邊欄兩種版面共用同一組 identifier，故 Page Object 不分版面
struct CampaignsScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定開團列表已就緒的根 identifier (列表捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.listRoot
    }

    /// 是否正顯示尚無開團的空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listEmptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignsScreen {

    /// 點工具列的新增開團
    func tapAdd() {
        let button = app.buttons[BLAccessibilityID.Campaigns.addButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 取指定開團 id 的列表卡片列
    ///
    /// 合併朗讀的列歸為 staticText，故以 any 查詢而非 otherElements
    /// - Parameter campaignID: 開團 id 這個業務鍵
    /// - Returns: 對應的列元素
    func campaignRow(campaignID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.row(campaignID: campaignID)]
    }

    /// 點指定開團 id 的列表卡片列進入詳情
    /// - Parameter campaignID: 開團 id 這個業務鍵
    func tapCampaign(campaignID: String) {
        let row = campaignRow(campaignID: campaignID)
        row.waitUntilHittable()
        row.tap()
    }

    /// 列表是否含指定開團 id 的列
    /// - Parameters:
    ///   - campaignID: 開團 id 這個業務鍵
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前該列是否出現
    @discardableResult
    func hasCampaign(campaignID: String, timeout: TimeInterval = 5) -> Bool {
        campaignRow(campaignID: campaignID).waitForExistence(timeout: timeout)
    }
}
