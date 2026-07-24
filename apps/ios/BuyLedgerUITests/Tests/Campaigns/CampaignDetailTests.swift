//
//  CampaignDetailTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情的進入、結團結算數值與結團流程測試
///
/// 一律以 accessibility identifier 定位，數值由合併列的 accessibility value 讀取；找不到 App 元素即附診斷失敗、不 skip。
/// 結團是不可逆操作，流程走「取消」分支只驗確認 alert 有出現又能收回、開團未被結團，不真的結團
final class CampaignDetailTests: BLUITestCase {

    // MARK: - Static Properties

    /// campaignsWithOrders 的四月韓國團開團 id (進行中，未結團故結團項目可點)
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 結團結算的兩個數值列種類
    private static let summaries: [BLAccessibilityID.Campaigns.DetailSummary] = [.receivables, .received]

    // MARK: - Tests

    /// 進四月韓國團詳情，詳情根就緒且應收／已收數值可各自讀到且非空
    @MainActor
    func testDetailReadyWithSummaryValues() {
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = openCampaignDetail(app, campaignID: Self.koreaCampaignID)

        for kind in Self.summaries where detail.summaryValue(kind).isEmpty {
            failWithDiagnostics(
                in: app,
                "結團結算數值列「\(kind.rawValue)」的 accessibility value 為空"
            )
        }
    }

    /// 結團流程：更多 → 結團 → 確認 alert → 取消；alert 收回且開團未被結團
    @MainActor
    func testSettleFlowCancelDoesNotSettle() {
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = openCampaignDetail(app, campaignID: Self.koreaCampaignID)

        detail.openMoreMenu()
        if !detail.tapSettle() {
            failWithDiagnostics(in: app, "更多選單的結團項目未出現或不可點")
        }

        if !detail.settleConfirmExists() {
            failWithDiagnostics(in: app, "點結團後，結團確認 alert 未呈現")
        }

        detail.cancelSettle()

        // 取消後 alert 應收回，且開團未被結團、詳情仍停留
        if !detail.confirmationDismissed() {
            failWithDiagnostics(in: app, "點取消後，結團確認 alert 未收回")
        }
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消結團後詳情頁應仍停留，根 identifier 卻消失")
        }
    }
}

// MARK: - Private Method

private extension CampaignDetailTests {

    /// 切到開團分頁、點指定開團進詳情並等就緒，回傳詳情 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - campaignID: 要進入詳情的開團 id
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的開團詳情 Page Object
    @MainActor
    func openCampaignDetail(
        _ app: XCUIApplication,
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CampaignDetailScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒", file: file, line: line)
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

        campaigns.tapCampaign(campaignID: campaignID)

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
