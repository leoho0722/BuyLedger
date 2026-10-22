//
//  CampaignDetailTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情的結團流程測試
final class CampaignDetailTests: BLUITestCase {

    // MARK: - Properties

    /// `campaignsWithOrders` 的四月韓國團開團 id (進行中，未結團故結團項目可點)
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 結團流程：更多 → 結團 → 確認 alert → 取消；alert 收回、詳情仍停留且開團未被結團
    ///
    /// - Note: 在正在進行且含訂單的開團詳情頁操作
    @MainActor
    func testCancelSettle_結團確認選取消_停留詳情且未結團() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = openCampaignDetail(app, campaignID: Self.koreaCampaignID)
        detail.openMoreMenu()
        if !detail.tapSettle() {
            failWithDiagnostics(in: app, "更多選單的結團項目未出現或不可點")
        }
        if !detail.isSettleConfirmationPresented() {
            failWithDiagnostics(in: app, "點結團後，結團確認 alert 未呈現")
        }
        app.assertAlertMessage(contains: "結算", timeout: 5)

        // When
        detail.cancelSettle()

        // Then
        if !detail.isConfirmationDismissed() {
            failWithDiagnostics(in: app, "點取消後，結團確認 alert 未收回")
        }
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消結團後詳情頁應仍停留，根 identifier 卻消失")
        }
        if detail.hasSettledBadge() {
            failWithDiagnostics(in: app, "取消結團後開團不應顯示「已結團」狀態")
        }
    }
}

// MARK: - Private Method

private extension CampaignDetailTests {

    /// 切到開團分頁、點指定開團進詳情並等就緒，回傳詳情 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - campaignID: 要開啟的開團識別值
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的開團詳情 Page Object
    @MainActor
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
