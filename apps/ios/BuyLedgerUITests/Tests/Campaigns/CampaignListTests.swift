//
//  CampaignListTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團列表的瀏覽與空狀態流程測試
///
/// 一律以 accessibility identifier 定位、以開團 id 這個業務鍵做結構性斷言，不硬編筆數；找不到 App 元素即附診斷失敗、不 skip。
/// 兩個既知種子開團的 id 不隨語言變動，故中英兩語言皆有效
final class CampaignListTests: BLUITestCase {

    // MARK: - Static Properties

    /// campaignsWithOrders 的四月韓國團開團 id (進行中)
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// campaignsWithOrders 的三月日本團開團 id (已結團)
    private static let japanCampaignID = "CMP-SAMPLE-JP-MAR"

    // MARK: - Tests

    /// 切到開團分頁後列表就緒，且看得到既知的兩個種子開團
    @MainActor
    func testCampaignsListReadyWithSeed() {
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = openCampaignsList(app)

        for campaignID in [Self.koreaCampaignID, Self.japanCampaignID]
        where !campaigns.hasCampaign(campaignID: campaignID) {
            failWithDiagnostics(in: app, "campaignsWithOrders 列表未見既知開團「\(campaignID)」")
        }
    }

    /// 空資料庫時，開團列表顯示尚無開團的空狀態
    @MainActor
    func testEmptySeedShowsEmptyState() {
        let app = launch(LaunchOptions(seed: .empty))

        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒")
        }

        assertEmptyState(BLAccessibilityID.Campaigns.listEmptyState, in: app)
    }
}

// MARK: - Private Method

private extension CampaignListTests {

    /// 切到開團分頁並等列表就緒，回傳開團列表 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的開團列表 Page Object
    @MainActor
    func openCampaignsList(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CampaignsScreen {
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
        return campaigns
    }
}
