//
//  CampaignCrudTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團新增與刪除流程的 UI 測試
@MainActor
final class CampaignCrudTests: BLUITestCase {

    // MARK: - Properties

    /// 新增開團填入的名稱 (使用者資料，中英兩語言皆可輸入)
    private static let newCampaignName = "測試開團"

    /// `campaignsWithOrders` 情境的四月韓國團開團 id (進行中)
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 驗證空資料庫新增開團並輸入名稱後儲存，開團列表出現名稱符合的開團列
    ///
    /// - Note: 情境流程：切到開團分頁、點新增並輸入名稱放 Given，點儲存為受測動作
    /// - Note: 以列 identifier 前綴加上名稱定位該列
    func testTapSave_新增開團並輸入名稱_列表出現開團() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒")
        }
        let campaigns = CampaignsScreen(app: app)
        let edit = CampaignEditScreen(app: app)
        campaigns.tapAdd()
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點新增後編輯表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現")
        }
        edit.typeName(Self.newCampaignName)

        // When
        edit.tapSave()

        // Then
        if !campaigns.waitUntilReady() {
            failWithDiagnostics(in: app, "儲存後開團列表根 identifier「\(campaigns.rootIdentifier)」逾時仍未出現")
        }
        let prefix = BLAccessibilityID.Campaigns.row(campaignID: "")
        let newCampaignRow = app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
                    prefix,
                    Self.newCampaignName
                )
            )
            .firstMatch
        if !newCampaignRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "建立開團後列表沒有名稱為「\(Self.newCampaignName)」的開團列")
        }
    }

    /// 驗證開團詳情點刪除後，確認 alert 訊息含「後無法復原」，選取消後 alert 消失且詳情頁仍停留
    ///
    /// - Note: 情境流程：更多 → 刪除 → 確認 alert 放 Given，點取消為受測動作
    func testCancelDelete_刪除確認選取消_停留在開團詳情() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = openCampaignDetail(app, campaignID: Self.koreaCampaignID)
        detail.openMoreMenu()
        if !detail.tapDelete() {
            failWithDiagnostics(in: app, "更多選單的刪除項目未出現或不可點")
        }
        if !detail.isDeleteConfirmationPresented() {
            failWithDiagnostics(in: app, "點刪除後，刪除確認 alert 未呈現")
        }
        app.assertAlertMessage(contains: "後無法復原", timeout: 5)

        // When
        detail.cancelDelete()

        // Then
        if !detail.isConfirmationDismissed() {
            failWithDiagnostics(in: app, "點取消後，刪除確認 alert 未收回")
        }
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消刪除後詳情頁應仍停留，根 identifier 卻消失")
        }
    }
}

// MARK: - Private Method

private extension CampaignCrudTests {

    /// 切到開團分頁、點指定開團進詳情並等就緒，回傳詳情 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - campaignID: 要開啟的開團識別值
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的開團詳情 Page Object
    func openCampaignDetail(
        _ app: XCUIApplication,
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CampaignDetailScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到開團分頁後畫面未就緒",
                file: file,
                line: line
            )
        }

        let campaigns = CampaignsScreen(app: app)
        if !campaigns.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "開團列表根 identifier「\(campaigns.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        campaigns.tapCampaign(campaignID: campaignID, file: file, line: line)

        let detail = CampaignDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點開團「\(campaignID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return detail
    }
}
