//
//  CampaignFlowTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/2.
//

import XCTest

/// 開團的載入失敗重試、寫入失敗提示、刪除、收款切換與只看未收款流程測試
final class CampaignFlowTests: BLUITestCase {

    // MARK: - Properties

    /// `campaignsWithOrders` 中應收 $16,780、已收 $11,800 的四月韓國團
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 每次載入開團都失敗時保留重試入口，重試後仍能操作分頁
    ///
    /// - Throws: 載入失敗畫面、重試入口或分頁導覽未就緒時拋出測試錯誤
    @MainActor
    func testRetryTapped_每次載入皆失敗_仍顯示失敗畫面與重試鍵() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders, loadFailure: .campaigns))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let failure = app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listLoadFailure]
        let retry = app.buttons[BLAccessibilityID.Campaigns.listLoadFailureRetryButton]
        try requireCondition(failure.waitForExistence(timeout: 10), in: app, "未出現開團載入失敗畫面")
        try requireCondition(retry.waitUntilHittable(), in: app, "載入失敗畫面沒有可點的重試鍵")

        // When
        retry.tapAfterWaiting(in: app)

        try requireCondition(failure.waitForExistence(timeout: 10), in: app, "重試後載入失敗畫面消失")
        try requireCondition(retry.waitUntilHittable(), in: app, "重試後重試鍵不可點")
        try requireCondition(root.goToDashboard(), in: app, "重試後無法返回總覽，App 可能卡住")
        try requireCondition(root.goToCampaigns(), in: app, "重試後無法再次進入開團分頁")

        // Then
        XCTAssertTrue(failure.waitForExistence(timeout: 10))
        XCTAssertTrue(retry.waitUntilHittable())
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// 新增開團寫入失敗時先關閉表單，再顯示可關閉的失敗提示且不新增資料列
    ///
    /// - Throws: 新增入口、表單、提示或空狀態未就緒時拋出測試錯誤
    @MainActor
    func testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .empty, shouldFailCampaignWrites: true))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let add = app.buttons[BLAccessibilityID.Campaigns.addButton]
        try requireCondition(add.waitUntilHittable(), in: app, "空開團列表沒有新增入口")
        let campaigns = CampaignsScreen(app: app)
        let edit = CampaignEditScreen(app: app)
        let campaignName = "失敗開團"

        // When
        campaigns.tapAdd()
        try requireCondition(edit.waitUntilReady(), in: app, "新增開團表單未就緒")
        edit.typeName(campaignName)
        edit.tapSave()

        try requireCondition(edit.rootElement.waitForDisappearance(), in: app, "儲存失敗後表單未關閉")
        try requireCondition(app.alertPresented(), in: app, "表單關閉後沒有出現操作失敗提示")
        let alertTexts = app.alerts.firstMatch.staticTexts.allElementsBoundByIndex.map { $0.label }
        app.tapAlertButton(label: "知道了")
        try requireCondition(app.alertDismissed(), in: app, "操作失敗提示未關閉")
        let emptyState = app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listEmptyState]
        try requireCondition(emptyState.waitForExistence(timeout: 10), in: app, "失敗後未返回空開團列表")
        let rowPrefix = BLAccessibilityID.Campaigns.row(campaignID: "")
        let campaignRows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", rowPrefix))

        // Then
        XCTAssertTrue(alertTexts.contains("操作失敗"))
        XCTAssertTrue(alertTexts.contains { $0.contains("開團儲存失敗") })
        XCTAssertEqual(campaignRows.count, 0, "儲存失敗的「\(campaignName)」不應留在列表")
        XCTAssertFalse(edit.isDisplayed)
    }

    /// 詳情選單確認刪除後返回列表，並移除原本存在的開團列
    ///
    /// - Throws: 詳情、刪除確認或刪除後的列表未就緒時拋出測試錯誤
    @MainActor
    func testConfirmDelete_詳情確認刪除_返回列表並移除該列() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        let campaigns = CampaignsScreen(app: app)

        // When
        detail.openMoreMenu()
        try requireCondition(detail.tapDelete(), in: app, "詳情更多選單沒有刪除項目")
        try requireCondition(detail.isDeleteConfirmationPresented(), in: app, "刪除確認提示未呈現")
        detail.confirmDelete()

        // Then
        try requireCondition(campaigns.waitUntilReady(), in: app, "刪除後未返回開團列表")
        XCTAssertTrue(
            campaigns.campaignRow(campaignID: Self.koreaCampaignID).waitForDisappearance()
        )
        XCTAssertFalse(detail.isDisplayed)
    }

    /// 未收款訂單切換收款後更新已收金額，再次切換恢復原值且應收不變
    ///
    /// - Throws: 詳情、基準金額或收款後的金額未就緒時拋出測試錯誤
    @MainActor
    func testReceiptToggleTapped_未收款訂單切換兩次_已收更新後還原() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        let customerName = "Mika 周"
        let orderID = "BL-2604-017"
        try requireCondition(detail.summaryValue(.receivables) == "$16,780", in: app, "應收基準金額不符")
        try requireCondition(detail.receivedAmount() == "$11,800", in: app, "已收基準金額不符")

        // When
        try requireCondition(
            detail.hasDistributionRow(customerName: customerName),
            in: app,
            "未收款客戶的分貨列未捲入畫面"
        )
        try requireCondition(
            detail.expandDistributionRow(customerName: customerName, orderID: orderID),
            in: app,
            "展開客戶分貨列後未出現收款鍵"
        )
        detail.tapReceiptToggle(orderID: orderID)
        try requireCondition(detail.waitForReceivedAmount("$16,780"), in: app, "標記收款後已收未更新")
        let receivedAfterPayment = detail.receivedAmount()
        let receivablesAfterPayment = detail.summaryValue(.receivables)
        detail.tapReceiptToggle(orderID: orderID)
        try requireCondition(detail.waitForReceivedAmount("$11,800"), in: app, "取消收款後已收未恢復")

        // Then
        XCTAssertEqual(receivedAfterPayment, "$16,780")
        XCTAssertEqual(receivablesAfterPayment, "$16,780")
        XCTAssertEqual(detail.receivedAmount(), "$11,800")
        XCTAssertEqual(detail.summaryValue(.receivables), "$16,780")
    }

    /// 只看未收款隱藏全部已收款的客戶，返回列表再進詳情仍保留開關與篩選
    ///
    /// - Throws: 分貨列、篩選結果或返回後的畫面未就緒時拋出測試錯誤
    @MainActor
    func testUnpaidOnlyToggled_返回列表再進詳情_保留開關與篩選() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        let paidCustomerNames = ["林書宇", "Joyce 黃"]
        let unpaidCustomerName = "Mika 周"
        for customerName in paidCustomerNames {
            try requireCondition(
                detail.hasDistributionRow(customerName: customerName),
                in: app,
                "篩選前已收款客戶「\(customerName)」的分貨列不存在"
            )
        }
        try requireCondition(
            detail.hasDistributionRow(customerName: unpaidCustomerName),
            in: app,
            "篩選前未收款客戶列不存在"
        )
        try requireCondition(!detail.isUnpaidOnlyEnabled(), in: app, "未收款篩選應預設關閉")

        // When
        detail.toggleUnpaidOnly()
        try requireCondition(detail.waitForUnpaidOnlyEnabled(), in: app, "未收款開關值未變成開啟")
        try requireCondition(
            detail.hasDistributionRow(customerName: unpaidCustomerName),
            in: app,
            "篩選後未收款客戶列消失"
        )
        for customerName in paidCustomerNames {
            try requireCondition(
                detail.distributionRow(customerName: customerName).waitForDisappearance(),
                in: app,
                "篩選後已收款客戶「\(customerName)」的分貨列仍存在"
            )
        }
        try requireCondition(detail.isUnpaidOnlyEnabled(), in: app, "未收款篩選未開啟")
        detail.tapBack()
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "返回後開團列表未就緒")
        campaigns.tapCampaign(campaignID: Self.koreaCampaignID)
        try requireCondition(detail.waitUntilReady(), in: app, "再次進入開團詳情未就緒")

        // Then
        XCTAssertTrue(detail.isUnpaidOnlyEnabled())
        try requireCondition(
            detail.hasDistributionRow(customerName: unpaidCustomerName),
            in: app,
            "再次進入詳情後未收款客戶列消失"
        )
        for customerName in paidCustomerNames {
            XCTAssertTrue(detail.distributionRow(customerName: customerName).waitForDisappearance())
        }
    }
}

// MARK: - Private Method

private extension CampaignFlowTests {

    /// 從開團分頁開啟四月韓國團，確認資料列與詳情已就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的四月韓國團詳情
    /// - Throws: 分頁、開團列或詳情未就緒時拋出測試錯誤
    @MainActor
    func openCampaignDetail(_ app: XCUIApplication) throws(any Error) -> CampaignDetailScreen {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        try requireCondition(
            campaigns.hasCampaign(campaignID: Self.koreaCampaignID),
            in: app,
            "四月韓國團資料列不存在"
        )
        campaigns.tapCampaign(campaignID: Self.koreaCampaignID)
        let detail = CampaignDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "四月韓國團詳情未就緒")
        return detail
    }
}
