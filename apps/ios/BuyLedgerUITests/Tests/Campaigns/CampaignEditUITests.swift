//
//  CampaignEditUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團編輯與新增流程的 UI 測試
@MainActor
final class CampaignEditUITests: BLUITestCase {

    // MARK: - Properties

    /// 新增開團填入的名稱 (使用者資料，中英兩語言皆可輸入)
    private static let newCampaignName = "測試開團"

    /// 寫入失敗案例填入的開團名稱
    private static let failedCampaignName = "失敗開團"

    /// 驗證空資料庫新增開團後，列表出現名稱相符的開團列
    ///
    /// - Throws: 開團畫面或新增表單未就緒時丟出測試錯誤
    func testSaveButtonTapped_新增開團並輸入名稱_列表出現開團() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let campaigns = try CampaignsScreen.open(in: app)
        let edit = try campaigns.tapAdd()
        try edit.typeName(Self.newCampaignName)

        // When
        try edit.tapSave()

        // Then
        XCTAssertTrue(campaigns.waitUntilReady(), "儲存後開團列表未就緒")
        let newCampaignRow = campaigns.campaignRow(named: Self.newCampaignName)
        XCTAssertTrue(
            newCampaignRow.waitForExistence(timeout: 10),
            "建立開團後列表沒有名稱為「\(Self.newCampaignName)」的開團列"
        )
    }

    /// 驗證開團寫入失敗時表單關閉，並顯示操作失敗提示
    ///
    /// - Throws: 新增表單或失敗提示未就緒時丟出測試錯誤
    func testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示() throws {
        // Given
        let app = try launch(
            LaunchOptions(
                seed: .empty,
                shouldFailCampaignWrites: true,
                shouldKeepViewAnimations: true
            )
        )
        let campaigns = try CampaignsScreen.open(in: app)
        let edit = try campaigns.tapAdd()
        try edit.typeName(Self.failedCampaignName)

        // When
        try edit.tapSave()

        // Then
        XCTAssertTrue(edit.rootElement.waitForDisappearance(), "儲存失敗後表單未關閉")
        try app.assertAlertMessage(contains: "操作失敗")
        try app.assertAlertMessage(contains: "開團儲存失敗")
    }

    /// 驗證關閉開團寫入失敗提示後回到空列表，失敗開團沒有加入列表
    ///
    /// - Throws: 新增表單、失敗提示或空狀態未就緒時丟出測試錯誤
    func testTapAlertButton_開團寫入失敗提示按知道了_回到空列表且不含失敗開團() throws {
        // Given
        let app = try launch(
            LaunchOptions(
                seed: .empty,
                shouldFailCampaignWrites: true,
                shouldKeepViewAnimations: true
            )
        )
        let campaigns = try CampaignsScreen.open(in: app)
        let edit = try campaigns.tapAdd()
        try edit.typeName(Self.failedCampaignName)
        try edit.tapSave()
        try requireCondition(
            edit.rootElement.waitForDisappearance(),
            in: app,
            "儲存失敗後表單未關閉"
        )
        try requireCondition(
            app.alertPresented(),
            in: app,
            "表單關閉後沒有出現操作失敗提示"
        )

        // When
        try app.tapAlertButton(label: "知道了")

        // Then
        try requireCondition(app.alertDismissed(), in: app, "操作失敗提示未關閉")
        try assertEmptyState(BLAccessibilityID.Campaigns.listEmptyState, in: app)
        XCTAssertFalse(
            campaigns.campaignRow(named: Self.failedCampaignName).exists,
            "儲存失敗的「\(Self.failedCampaignName)」不應留在列表"
        )
    }

    /// 驗證新增開團表單的草稿與焦點在轉向後保留，轉回直向仍可續打
    ///
    /// - Throws: 開團分頁或編輯表單未就緒時丟出測試錯誤
    func testDraftName_輸入草稿後轉向往返_名稱與焦點保留且可續打() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let edit = try campaigns.tapAdd()
        let draftName = "測試旋轉草稿團"
        try edit.typeName(draftName)

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(edit.waitUntilReady(), in: app, "橫向後編輯表單未就緒")
        XCTAssertEqual(edit.nameFieldValue(), draftName, "橫向後名稱欄文字不符")
        XCTAssertTrue(edit.isNameFieldFocused(), "橫向後名稱欄失去鍵盤焦點")

        // When
        try rotateToPortrait(app)
        try requireCondition(edit.waitUntilReady(), in: app, "轉回直向後編輯表單未就緒")
        try edit.appendName("續")

        // Then
        XCTAssertEqual(
            edit.nameFieldValue(),
            "測試旋轉草稿團續",
            "續打後未讀回完整名稱"
        )
        XCTAssertTrue(try edit.isSaveEnabled())
    }
}

