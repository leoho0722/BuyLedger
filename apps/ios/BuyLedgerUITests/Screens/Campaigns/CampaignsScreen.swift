//
//  CampaignsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團列表頁的 Page Object
struct CampaignsScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

extension CampaignsScreen {

    /// 是否正顯示尚無開團的空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listEmptyState].exists
    }

    /// 是否正顯示詳情欄未選取提示
    var isDetailEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Common.detailEmptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignsScreen {

    /// 從開團 canonical path marker 讀取選取值；空字串代表未選取，nil 代表 marker 缺失或值不是字串
    ///
    /// - Returns: 目前已選取的開團識別碼，未選取時為空字串；marker 缺失或值不是字串時為 `nil`
    func selectedCampaignID() -> String? {
        let markerID = BLAccessibilityID.Common.selectedItem(.campaigns)
        let marker = app.descendants(matching: .any)[markerID].firstMatch
        guard marker.waitForExistence(timeout: 5) else {
            return nil
        }
        return marker.value as? String
    }

    /// 點工具列的新增開團
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAdd(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Campaigns.addButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點指定開團 id 的列表卡片列進入詳情
    ///
    /// - Parameters:
    ///   - campaignID: 開團 id
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCampaign(campaignID: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = campaignRow(campaignID: campaignID)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 取指定開團 id 的列表卡片列
    ///
    /// - Parameter campaignID: 開團 id
    /// - Returns: 對應的列表卡片列元素
    func campaignRow(campaignID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.row(campaignID: campaignID)]
    }

    /// 等待指定開團 id 的列出現於列表
    ///
    /// - Parameters:
    ///   - campaignID: 開團 id
    ///   - timeout: 等待列表列出現的秒數
    /// - Returns: 開團列是否在逾時前出現
    func hasCampaign(campaignID: String, timeout: TimeInterval = 5) -> Bool {
        campaignRow(campaignID: campaignID).waitForExistence(timeout: timeout)
    }
}

// MARK: - Screen

extension CampaignsScreen: Screen {

    /// 判定開團列表已就緒的根 identifier (列表捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.listRoot
    }
}
