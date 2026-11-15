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

@MainActor
extension CampaignsScreen {

    /// 是否正顯示詳情欄未選取提示
    var isDetailEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Common.detailEmptyState].exists
    }

    /// 開團分頁目前的前景根容器
    var destinationContainer: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Common.selectedItem(.campaigns)]
            .firstMatch
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignsScreen {

    /// 切到開團分頁，等待目前的前景內容、空狀態或載入失敗就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已進入前景的開團畫面
    /// - Throws: 分頁無法切換或目的地未就緒時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CampaignsScreen {
        try RootNavigationScreen(app: app).goToCampaigns(file: file, line: line)
        return CampaignsScreen(app: app)
    }

    /// 開啟指定識別值的開團詳情，等待詳情畫面就緒
    ///
    /// - Parameters:
    ///   - campaignID: 開團識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的開團詳情
    /// - Throws: 開團列或詳情未就緒時丟出測試錯誤
    @discardableResult
    func openDetail(
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CampaignDetailScreen {
        try tapCampaign(campaignID: campaignID, file: file, line: line)
        let detail = CampaignDetailScreen(app: app)
        try detail.requireReady(file: file, line: line)
        return detail
    }

    /// 從開團 canonical path marker 讀取選取值
    ///
    /// - Returns: 選取的開團識別碼；未選取時為空字串，值無效時為 `nil`
    func selectedCampaignID() -> String? {
        let container = destinationContainer
        guard container.waitForExistence(timeout: 5) else {
            return nil
        }
        return container.value as? String
    }

    /// 等待開團清單顯示載入失敗
    ///
    /// - Parameter timeout: 等待失敗訊息出現的秒數
    /// - Returns: 載入失敗訊息是否在逾時前出現
    func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listLoadFailure]
            .waitForExistence(timeout: timeout)
    }

    /// 等待開團清單載入失敗分支的重試按鈕可點
    ///
    /// - Parameter timeout: 等待按鈕可點的秒數
    /// - Returns: 重試按鈕是否在逾時前可點
    func waitForRetryButton(timeout: TimeInterval = 10) -> Bool {
        app.buttons[BLAccessibilityID.Campaigns.listLoadFailureRetryButton]
            .waitUntilHittable(timeout: timeout)
    }

    /// 點開團清單載入失敗分支的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 重試按鈕無法點擊時丟出測試錯誤
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Campaigns.listLoadFailureRetryButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的新增開團並等待編輯畫面就緒
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的開團編輯畫面
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapAdd(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CampaignEditScreen {
        let button = app.buttons[BLAccessibilityID.Campaigns.addButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
        let editor = CampaignEditScreen(app: app)
        try editor.requireReady(file: file, line: line)
        return editor
    }

    /// 點指定開團 id 的列表卡片列進入詳情
    ///
    /// - Parameters:
    ///   - campaignID: 開團 id
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapCampaign(
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = campaignRow(campaignID: campaignID)
        try row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 取指定開團 id 的列表卡片列
    ///
    /// - Parameter campaignID: 開團 id
    /// - Returns: 對應的列表卡片列元素
    func campaignRow(campaignID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Campaigns.row(campaignID: campaignID)]
    }

    /// 依列 identifier 前綴與開團名稱尋找列表卡片列
    ///
    /// - Parameter name: 開團名稱
    /// - Returns: 名稱相符的列；尚未出現時為不存在的元素
    func campaignRow(named name: String) -> XCUIElement {
        let prefix = BLAccessibilityID.Campaigns.row(campaignID: "")
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        )
        return rows.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
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

// MARK: - ScreenProtocol

extension CampaignsScreen: ScreenProtocol {

    /// 判定開團列表已就緒的根 identifier (列表捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Campaigns.listRoot
    }
}
