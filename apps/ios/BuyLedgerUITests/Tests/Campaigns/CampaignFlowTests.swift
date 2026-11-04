//
//  CampaignFlowTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/2.
//

import XCTest

/// 開團載入失敗重試、寫入失敗提示、刪除、收款切換與只看未收款的 UI 流程測試，以 Page Object 逐步操作畫面
@MainActor
final class CampaignFlowTests: BLUITestCase {

    // MARK: - Properties

    /// 未收款客戶在四月韓國團的訂單唯一識別碼
    private static let unpaidOrderID = "BL-2604-017"

    /// 驗證開團每次載入都失敗時，按下重試後仍顯示載入失敗畫面與可點的重試鍵，App 維持前景執行
    ///
    /// - Throws: 開團分頁、載入失敗畫面或重試入口未就緒時丟出測試錯誤
    func testRetryTapped_每次載入皆失敗_仍顯示失敗畫面與重試鍵() throws {
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

        // Then
        XCTAssertTrue(failure.waitForExistence(timeout: 10))
        XCTAssertTrue(retry.waitUntilHittable())
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// 驗證開團載入失敗並重試後，分頁導覽仍可運作
    ///
    /// - Throws: 開團分頁、載入失敗畫面或重試入口未就緒時丟出測試錯誤
    /// - Note: 重試後連續切出再返回，才能確認同次重試未卡住導覽，也未讓開團失敗畫面遺失
    func testRetryTapped_重試後_分頁仍可切換() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders, loadFailure: .campaigns))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let failure = app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listLoadFailure]
        let retry = app.buttons[BLAccessibilityID.Campaigns.listLoadFailureRetryButton]
        try requireCondition(retry.waitUntilHittable(), in: app, "載入失敗畫面沒有可點的重試鍵")
        retry.tapAfterWaiting(in: app)
        try requireCondition(retry.waitUntilHittable(), in: app, "重試後重試鍵不可點")

        // When
        let isDashboardReached = root.goToDashboard()
        let isCampaignsReached = root.goToCampaigns()

        // Then
        XCTAssertTrue(isDashboardReached, "重試後無法切到總覽，App 可能卡住")
        XCTAssertTrue(isCampaignsReached, "重試後無法再次進入開團分頁")
        XCTAssertTrue(failure.waitForExistence(timeout: 10))
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// 驗證新增開團寫入失敗時，表單先關閉並顯示「操作失敗」提示，關閉提示後回到空列表
    ///
    /// - Throws: 新增入口、表單、提示或空狀態未就緒時丟出測試錯誤
    /// - Note: 關閉同次儲存失敗的提示後才看得到列表，後續檢查用來確認失敗開團未被加入
    func testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty, shouldFailCampaignWrites: true))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let add = app.buttons[BLAccessibilityID.Campaigns.addButton]
        try requireCondition(add.waitUntilHittable(), in: app, "空開團列表沒有新增入口")
        let campaigns = CampaignsScreen(app: app)
        let edit = CampaignEditScreen(app: app)
        let campaignName = "失敗開團"
        campaigns.tapAdd()
        try requireCondition(edit.waitUntilReady(), in: app, "新增開團表單未就緒")
        edit.typeName(campaignName)

        // When
        edit.tapSave()

        // Then
        try requireCondition(edit.rootElement.waitForDisappearance(), in: app, "儲存失敗後表單未關閉")
        try requireCondition(app.alertPresented(), in: app, "表單關閉後沒有出現操作失敗提示")
        let alertTexts = app.alerts.firstMatch.staticTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertTrue(alertTexts.contains("操作失敗"))
        XCTAssertTrue(alertTexts.contains { $0.contains("開團儲存失敗") })

        // When
        app.tapAlertButton(label: "知道了")

        // Then
        try requireCondition(app.alertDismissed(), in: app, "操作失敗提示未關閉")
        let emptyState = app.descendants(matching: .any)[BLAccessibilityID.Campaigns.listEmptyState]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10), "失敗後未返回空開團列表")
        let failedCampaignRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", campaignName))
            .firstMatch
        XCTAssertFalse(failedCampaignRow.exists, "儲存失敗的「\(campaignName)」不應留在列表")
    }

    /// 驗證刪除寫入失敗提示關閉後，再次要求刪除仍會顯示確認框
    ///
    /// - Throws: 開團詳情、刪除確認或失敗提示未就緒時丟出測試錯誤
    func testConfirmDelete_失敗提示關閉後再次刪除_確認框仍可開啟() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders, shouldFailCampaignWrites: true))
        let detail = try openCampaignDetail(app)
        detail.openMoreMenu()
        try requireCondition(detail.tapDelete(), in: app, "詳情更多選單沒有刪除項目")
        try requireCondition(detail.isDeleteConfirmationPresented(), in: app, "刪除確認提示未呈現")

        // When
        detail.confirmDelete()

        // Then
        try requireCondition(app.alertPresented(timeout: 10), in: app, "刪除失敗後沒有出現操作失敗提示")
        let alertTexts = app.alerts.firstMatch.staticTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertTrue(alertTexts.contains("操作失敗"))

        // When
        app.tapAlertButton(label: "知道了")
        try requireCondition(app.alertDismissed(), in: app, "操作失敗提示未關閉")
        detail.openMoreMenu()
        try requireCondition(detail.tapDelete(), in: app, "失敗提示關閉後無法再次選擇刪除開團")

        // Then
        try requireCondition(detail.isDeleteConfirmationPresented(), in: app, "失敗提示關閉後再次刪除沒有出現確認框")
        detail.cancelDelete()
        try requireCondition(app.alertDismissed(), in: app, "取消刪除後確認框未關閉")
    }

    /// 驗證在詳情確認刪除後，畫面返回開團列表，四月韓國團的列隨之移除且詳情不再顯示
    ///
    /// - Throws: 詳情、刪除確認或刪除後的列表未就緒時丟出測試錯誤
    func testConfirmDelete_詳情確認刪除_返回列表並移除該列() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        let campaigns = CampaignsScreen(app: app)
        detail.openMoreMenu()
        try requireCondition(detail.tapDelete(), in: app, "詳情更多選單沒有刪除項目")
        try requireCondition(detail.isDeleteConfirmationPresented(), in: app, "刪除確認提示未呈現")

        // When
        detail.confirmDelete()

        // Then
        try requireCondition(campaigns.waitUntilReady(), in: app, "刪除後未返回開團列表")
        XCTAssertTrue(
            campaigns
                .campaignRow(campaignID: CampaignSeedFixture.koreaCampaignID)
                .waitForDisappearance()
        )
        XCTAssertFalse(detail.isDisplayed)
    }

    /// 驗證未收款訂單標記收款後，已收金額從 $11,800 更新為 $16,780，應收維持 $16,780
    ///
    /// - Throws: 詳情、基準金額或分貨列未就緒時丟出測試錯誤
    func testReceiptToggleTapped_未收款訂單標記收款_已收更新且應收不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        try requireCondition(detail.summaryValue(.receivables) == "$16,780", in: app, "應收基準金額不符")
        try requireCondition(detail.receivedAmount() == "$11,800", in: app, "已收基準金額不符")
        try expandUnpaidOrderRow(detail, in: app)

        // When
        detail.tapReceiptToggle(orderID: Self.unpaidOrderID)

        // Then
        XCTAssertTrue(detail.waitForReceivedAmount("$16,780"), "標記收款後已收未更新")
        XCTAssertEqual(detail.receivedAmount(), "$16,780")
        XCTAssertEqual(detail.summaryValue(.receivables), "$16,780")
    }

    /// 驗證已標記收款的訂單再切換一次，已收金額還原為 $11,800，應收維持 $16,780
    ///
    /// - Throws: 詳情、基準金額、分貨列或標記收款後的金額未就緒時丟出測試錯誤
    func testReceiptToggleTapped_已收款再切換_已收還原() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        try requireCondition(detail.receivedAmount() == "$11,800", in: app, "已收基準金額不符")
        try expandUnpaidOrderRow(detail, in: app)
        detail.tapReceiptToggle(orderID: Self.unpaidOrderID)
        try requireCondition(detail.waitForReceivedAmount("$16,780"), in: app, "標記收款後已收未更新")

        // When
        detail.tapReceiptToggle(orderID: Self.unpaidOrderID)

        // Then
        XCTAssertTrue(detail.waitForReceivedAmount("$11,800"), "取消收款後已收未恢復")
        XCTAssertEqual(detail.receivedAmount(), "$11,800")
        XCTAssertEqual(detail.summaryValue(.receivables), "$16,780")
    }

    /// 驗證開啟只看未收款後，已收款客戶的分貨列消失，未收款客戶的分貨列保留
    ///
    /// - Throws: 詳情、分貨列或開關未就緒時丟出測試錯誤
    func testUnpaidOnlyToggled_開啟_隱藏已收款客戶列() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        try requireDistributionRowsBeforeFilter(detail, in: app)
        try requireCondition(!detail.isUnpaidOnlyEnabled(), in: app, "未收款篩選應預設關閉")

        // When
        detail.toggleUnpaidOnly()

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

    /// 驗證只看未收款的篩選在返回列表後仍保留，再進入詳情時開關仍開啟且已收款客戶列仍隱藏
    ///
    /// - Throws: 詳情、分貨列、篩選結果或返回後的畫面未就緒時丟出測試錯誤
    /// - Note: 並排版面沒有原生返回鍵，本案例只在收合版面執行
    func testTapCampaign_返回後再進入_保留未收款篩選() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let detail = try openCampaignDetail(app)
        try XCTSkipUnless(isCampaignCompactLayout(app), "返回後再進入的案例只適用收合版面")
        let campaigns = CampaignsScreen(app: app)
        try requireDistributionRowsBeforeFilter(detail, in: app)
        detail.toggleUnpaidOnly()
        try requireCondition(detail.waitForUnpaidOnlyEnabled(), in: app, "未收款開關值未變成開啟")

        detail.tapBack()
        try requireCondition(campaigns.waitUntilReady(), in: app, "返回後開團列表未就緒")

        // When
        campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)

        // Then
        try requireCondition(detail.waitUntilReady(), in: app, "再次進入開團詳情未就緒")
        XCTAssertTrue(detail.isUnpaidOnlyEnabled())
        XCTAssertTrue(
            detail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName),
            "再次進入詳情後未收款客戶列消失"
        )
        for customerName in CampaignSeedFixture.paidCustomerNames {
            XCTAssertTrue(detail.distributionRow(customerName: customerName).waitForDisappearance())
        }
    }

    /// 驗證收合版面選取開團進入詳情後，原生返回清空選取，展開為並排版面時詳情欄顯示未選取提示
    ///
    /// - Throws: 開團分頁、列表或詳情未就緒時丟出測試錯誤；版面無法依案例前提建立時略過
    /// - Note: 對應驗收矩陣 N3
    /// - Note: 原生返回鍵只存在於收合版面，並排版面不適用返回案例
    func testBackTapped_收合版面返回後清空選取_展開顯示空詳情提示() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        defer {
            try? rotateToPortrait(app) // 失敗可忽略，因為下一個測試的 launch 會再次轉為直向
        }
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        // 原生返回鍵只存在於收合版面，並排時先以直向建立收合版面
        if !isCampaignCompactLayout(app) {
            try rotateToPortrait(app)
        }
        try XCTSkipUnless(isCampaignCompactLayout(app), "原生返回鍵只存在於收合版面，此裝置無法建立收合版面")
        try requireCondition(campaigns.selectedCampaignID() != nil, in: app, "初次載入沒有選取標記")
        // 初次載入未選取任何開團，標記存在且值為空
        try requireCondition(campaigns.selectedCampaignID() == "", in: app, "初次載入不應已選取開團")

        // When
        campaigns.tapCampaign(campaignID: CampaignSeedFixture.koreaCampaignID)

        // Then
        let detail = CampaignDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "四月韓國團詳情未就緒")
        try requireCondition(
            campaigns.selectedCampaignID() == "CMP-SAMPLE-KR-APR",
            in: app,
            "收合版面的選取標記未指向四月韓國團"
        )

        // When
        detail.tapBack()

        // Then
        try requireCondition(campaigns.waitUntilReady(), in: app, "返回後開團列表未就緒")
        XCTAssertEqual(campaigns.selectedCampaignID(), "", "原生返回後選取標記應清空")

        // When
        try rotateToLandscape(app)
        try XCTSkipUnless(isCampaignRegularLayout(app), "此裝置無法展開為並排版面，略過展開後的未選取提示驗證")

        // Then
        XCTAssertTrue(campaigns.isDetailEmptyStateShown, "展開後詳情欄未顯示未選取提示")
        XCTAssertEqual(campaigns.selectedCampaignID(), "", "展開後選取標記應維持為空")
    }

    /// 驗證新增開團表單輸入草稿後旋轉裝置，名稱欄的文字與鍵盤焦點保留，轉回直向後可續打並讀回完整文字
    ///
    /// - Throws: 開團表單或旋轉後的版面未就緒時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N6
    func testRotated_輸入草稿後_名稱與焦點保留且可續打() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToCampaigns(), in: app, "開團分頁未就緒")
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(campaigns.waitUntilReady(), in: app, "開團列表未就緒")
        campaigns.tapAdd()
        let edit = CampaignEditScreen(app: app)
        try requireCondition(edit.waitUntilReady(), in: app, "開團新增表單未就緒")
        let draftName = "測試旋轉草稿團"
        edit.typeName(draftName)

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(edit.waitUntilReady(), in: app, "橫向後編輯表單未就緒")
        XCTAssertEqual(edit.nameFieldValue(), "測試旋轉草稿團", "橫向後名稱欄文字不符")
        XCTAssertTrue(edit.isNameFieldFocused(), "橫向後名稱欄失去鍵盤焦點")

        // When
        try rotateToPortrait(app)
        try requireCondition(edit.waitUntilReady(), in: app, "轉回直向後編輯表單未就緒")
        edit.appendName("續")

        // Then
        XCTAssertEqual(edit.nameFieldValue(), "測試旋轉草稿團續", "續打後未讀回完整名稱")
        XCTAssertTrue(edit.isSaveEnabled())
    }
}

// MARK: - Private Method

private extension CampaignFlowTests {

    /// 捲到未收款客戶的分貨列並展開，確認其訂單的收款鍵已出現
    ///
    /// - Parameters:
    ///   - detail: 已就緒的四月韓國團詳情
    ///   - app: 受測 App
    /// - Throws: 分貨列未捲入畫面或展開後沒有收款鍵時丟出測試錯誤
    func expandUnpaidOrderRow(_ detail: CampaignDetailScreen, in app: XCUIApplication) throws {
        try requireCondition(
            detail.hasDistributionRow(customerName: CampaignSeedFixture.unpaidCustomerName),
            in: app,
            "未收款客戶的分貨列未捲入畫面"
        )
        try requireCondition(
            detail.expandDistributionRow(
                customerName: CampaignSeedFixture.unpaidCustomerName,
                orderID: Self.unpaidOrderID
            ),
            in: app,
            "展開客戶分貨列後未出現收款鍵"
        )
    }
}
