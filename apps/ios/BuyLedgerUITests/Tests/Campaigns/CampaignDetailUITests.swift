//
//  CampaignDetailUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團詳情刪除、收款與篩選行為的 UI 測試
@MainActor
final class CampaignDetailUITests: BLUITestCase {

    // MARK: - Properties

    /// 未收款客戶在四月韓國團的訂單唯一識別碼
    private static let unpaidOrderID = "BL-2604-017"

    /// 驗證刪除確認後選取消，確認框收回且仍停留在開團詳情
    ///
    /// - Throws: 開團詳情或刪除確認未就緒時丟出測試錯誤
    func testCancelDelete_刪除確認選取消_停留在開團詳情() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try detail.openMoreMenu()
        try detail.tapDelete()
        try requireCondition(detail.waitForDeleteConfirmation(), in: app, "點刪除後，刪除確認 alert 未呈現")
        try app.assertAlertMessage(contains: "後無法復原")

        // When
        try detail.cancelDelete()

        // Then
        XCTAssertTrue(detail.waitForDeleteConfirmationDismissal(), "點取消後刪除確認 alert 未收回")
        XCTAssertTrue(detail.waitUntilReady(), "取消刪除後詳情頁應仍停留")
    }

    /// 驗證結團確認後選取消，詳情仍停留且開團未結團
    ///
    /// - Throws: 開團詳情或結團確認未就緒時丟出測試錯誤
    func testCancelSettle_結團確認選取消_停留詳情且未結團() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try detail.openMoreMenu()
        try detail.tapSettle()
        try requireCondition(detail.waitForSettleConfirmation(), in: app, "點結團後，結團確認 alert 未呈現")
        try app.assertAlertMessage(contains: "結算")

        // When
        try detail.cancelSettle()

        // Then
        XCTAssertTrue(detail.waitForConfirmationDismissal(), "點取消後結團確認 alert 未收回")
        XCTAssertTrue(detail.waitUntilReady(), "取消結團後詳情頁應仍停留")
        XCTAssertFalse(detail.hasSettledBadge(), "取消結團後開團不應顯示「已結團」狀態")
    }

    /// 驗證刪除開團寫入失敗提示關閉後，再次要求刪除仍會顯示確認框
    ///
    /// - Throws: 開團詳情、刪除確認或失敗提示未就緒時丟出測試錯誤
    func testDeleteTapped_刪除失敗提示關閉後再刪除_確認框仍可開啟() throws {
        // Given
        let app = try launch(
            LaunchOptions(
                seed: .campaignsWithOrders,
                shouldFailCampaignWrites: true,
                shouldKeepViewAnimations: true
            )
        )
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try detail.openMoreMenu()
        try detail.tapDelete()
        try requireCondition(detail.waitForDeleteConfirmation(), in: app, "刪除確認提示未呈現")
        try detail.confirmDelete()
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)
        try app.tapAlertButton(label: "知道了")
        try requireCondition(app.alertDismissed(), in: app, "操作失敗提示未關閉")

        // When
        try detail.openMoreMenu()
        try detail.tapDelete()

        // Then
        XCTAssertTrue(detail.waitForDeleteConfirmation(), "失敗提示關閉後再次刪除沒有出現確認框")
    }

    /// 驗證詳情確認刪除後返回列表，四月韓國團列移除且詳情不再顯示
    ///
    /// - Throws: 開團詳情或刪除後列表未就緒時丟出測試錯誤
    func testConfirmDelete_詳情確認刪除_返回列表並移除該列() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try detail.openMoreMenu()
        try detail.tapDelete()
        try requireCondition(detail.waitForDeleteConfirmation(), in: app, "刪除確認提示未呈現")

        // When
        try detail.confirmDelete()

        // Then
        XCTAssertTrue(campaigns.waitUntilReady(), "刪除後未返回開團列表")
        XCTAssertTrue(
            campaigns.campaignRow(campaignID: CampaignSeedFixture.koreaCampaignID)
                .waitForDisappearance(),
            "刪除後四月韓國團仍顯示在列表"
        )
        XCTAssertFalse(detail.isDisplayed, "刪除後開團詳情仍顯示")
    }

    /// 驗證未收款訂單標記收款後，已收金額更新為 $16,780 且應收維持 $16,780
    ///
    /// - Throws: 開團詳情、基準金額或分貨列未就緒時丟出測試錯誤
    func testReceiptToggleTapped_未收款訂單標記收款_已收更新且應收不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try requireCondition(detail.summaryValue(.receivables) == "$16,780", in: app, "應收基準金額不符")
        try requireCondition(detail.receivedAmount() == "$11,800", in: app, "已收基準金額不符")
        try expandUnpaidOrderRow(detail)

        // When
        try detail.tapReceiptToggle(orderID: Self.unpaidOrderID)
        try detail.revealReceivedAmount()

        // Then
        XCTAssertTrue(detail.waitForReceivedAmount("$16,780"), "標記收款後已收未更新")
        XCTAssertEqual(detail.receivedAmount(), "$16,780")
        XCTAssertEqual(detail.summaryValue(.receivables), "$16,780")
    }

    /// 驗證已收款訂單再次切換後還原為 $11,800，應收維持 $16,780
    ///
    /// - Throws: 開團詳情、分貨列或標記收款後的金額未就緒時丟出測試錯誤
    func testReceiptToggleTapped_已收款再切換_已收還原() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try requireCondition(detail.receivedAmount() == "$11,800", in: app, "已收基準金額不符")
        try expandUnpaidOrderRow(detail)
        try detail.tapReceiptToggle(orderID: Self.unpaidOrderID)
        try detail.revealReceivedAmount()
        try requireCondition(detail.waitForReceivedAmount("$16,780"), in: app, "標記收款後已收未更新")

        // When
        try detail.tapReceiptToggle(orderID: Self.unpaidOrderID)
        try detail.revealReceivedAmount()

        // Then
        XCTAssertTrue(detail.waitForReceivedAmount("$11,800"), "取消收款後已收未恢復")
        XCTAssertEqual(detail.receivedAmount(), "$11,800")
        XCTAssertEqual(detail.summaryValue(.receivables), "$16,780")
    }

    /// 驗證開啟只看未收款後隱藏已收款客戶列，未收款客戶列仍保留
    ///
    /// - Throws: 開團詳情、分貨列或開關未就緒時丟出測試錯誤
    func testUnpaidOnlyToggled_開啟_隱藏已收款客戶列() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try detail.revealDistributionRowsBeforeFilter()
        try detail.revealUnpaidOnlyToggle()
        try requireCondition(!detail.isUnpaidOnlyEnabled, in: app, "未收款篩選應預設關閉")

        // When
        try detail.toggleUnpaidOnly()
        try detail.revealDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName)

        // Then
        XCTAssertTrue(detail.waitForUnpaidOnlyEnabled(), "未收款開關值未變成開啟")
        XCTAssertTrue(
            detail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName)
        )
        for customerName in CampaignSeedFixture.paidCustomerNames {
            XCTAssertTrue(
                detail.distributionRow(customerName: customerName).waitForDisappearance(),
                "篩選後已收款客戶「\(customerName)」的分貨列仍存在"
            )
        }
    }

    /// 驗證返回列表再進入詳情時，未收款篩選仍保留且已收款列仍隱藏
    ///
    /// - Throws: 開團詳情、分貨列或返回後的畫面未就緒時丟出測試錯誤
    func testDetailSelectionChanged_返回後再進入_保留未收款篩選() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try XCTSkipUnless(try campaignLayout(in: app) == .compact, "返回後再進入的案例只適用收合版面")
        try detail.revealDistributionRowsBeforeFilter()
        try detail.toggleUnpaidOnly()
        try requireCondition(detail.waitForUnpaidOnlyEnabled(), in: app, "未收款開關值未變成開啟")
        try detail.tapBack()
        try requireCondition(campaigns.waitUntilReady(), in: app, "返回後開團列表未就緒")

        // When
        let reopenedDetail = try campaigns.openDetail(
            campaignID: CampaignSeedFixture.koreaCampaignID
        )
        try reopenedDetail.revealUnpaidOnlyToggle()
        try reopenedDetail.revealDistributionRow(
            customerName: CampaignSeedFixture.unpaidCustomerName
        )

        // Then
        XCTAssertTrue(reopenedDetail.isUnpaidOnlyEnabled)
        XCTAssertTrue(
            reopenedDetail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName),
            "再次進入詳情後未收款客戶列消失"
        )
        for customerName in CampaignSeedFixture.paidCustomerNames {
            XCTAssertTrue(
                reopenedDetail.distributionRow(customerName: customerName).waitForDisappearance()
            )
        }
    }
}

// MARK: - Private Method

private extension CampaignDetailUITests {

    /// 捲到未收款客戶的分貨列並展開，確認其訂單的收款鍵已出現
    ///
    /// - Parameter detail: 已就緒的四月韓國團詳情
    /// - Throws: 分貨列未捲入畫面或展開後沒有收款鍵時丟出測試錯誤
    func expandUnpaidOrderRow(_ detail: CampaignDetailScreen) throws(UITestError) {
        try detail.revealDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName)
        try detail.expandDistributionRow(
            customerName: CampaignSeedFixture.unpaidCustomerName,
            orderID: Self.unpaidOrderID
        )
    }
}
