//
//  XCTestCase+CampaignFlow.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension XCTestCase {

    /// 從開團分頁開啟四月韓國團，確認資料列與詳情已就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的四月韓國團詳情
    /// - Throws: 分頁、開團列或詳情未就緒時丟出測試錯誤
    func openCampaignDetail(_ app: XCUIApplication) throws -> CampaignDetailScreen {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        try requireCondition(
            campaigns.hasCampaign(campaignID: CampaignSeedFixture.koreaCampaignID),
            in: app,
            "四月韓國團資料列不存在"
        )
        campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)
        let detail = CampaignDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "四月韓國團詳情未就緒")
        return detail
    }

    /// 確認篩選前已收款與未收款客戶的分貨列都存在，讓之後的消失斷言有正向對照
    ///
    /// - Parameters:
    ///   - detail: 已就緒的四月韓國團詳情
    ///   - app: 受測 App
    /// - Throws: 任一客戶的分貨列不存在時丟出測試錯誤
    func requireDistributionRowsBeforeFilter(
        _ detail: CampaignDetailScreen,
        in app: XCUIApplication
    ) throws {
        for customerName in CampaignSeedFixture.paidCustomerNames {
            try requireCondition(
                detail.hasDistributionRow(customerName: customerName),
                in: app,
                "篩選前已收款客戶「\(customerName)」的分貨列不存在"
            )
        }
        try requireCondition(
            detail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName),
            in: app,
            "篩選前未收款客戶列不存在"
        )
    }
}
