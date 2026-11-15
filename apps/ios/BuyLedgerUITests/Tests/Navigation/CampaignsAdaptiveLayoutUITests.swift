//
//  CampaignsAdaptiveLayoutUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 開團清單與詳情並排時的選取列自適應版面 UI 測試
@MainActor
final class CampaignsAdaptiveLayoutUITests: BLUITestCase {

    /// 驗證開團清單與詳情並排時，選取四月韓國團後詳情就緒，且清單中對應的開團列帶選取特徵
    ///
    /// - Throws: 版面不適用、必要元素缺少或選取特徵不符時丟出測試錯誤
    /// - Note: 選取列只在開團並排時與詳情同時可見
    func testDetailSelectionChanged_並排選取開團_目前開團列帶選取特徵() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        try XCTSkipUnless(try campaignLayout(in: app) == .regular, "選取列只在開團並排時與詳情同時可見")

        // When
        try campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)

        // Then
        let detail = CampaignDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "四月韓國團詳情未就緒")
        let row = campaigns.campaignRow(campaignID: CampaignSeedFixture.koreaCampaignID)
        try requireCondition(row.isSelected, in: app, "目前開團列應帶選取特徵")
    }
}
