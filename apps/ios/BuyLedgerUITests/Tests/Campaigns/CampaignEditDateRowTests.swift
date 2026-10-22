//
//  CampaignEditDateRowTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 開團編輯資訊區段的日期列，取代該區段的像素比對
final class CampaignEditDateRowTests: BLUITestCase {

    /// 開啟新增開團表單時，顯示開團與結單日期列，提醒未開啟所以沒有提醒時間列
    @MainActor
    func testDateRows_新增開團_顯示開團與結單日期列且無提醒時間列() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let campaigns = openCampaigns(in: app)
        let edit = CampaignEditScreen(app: app)

        // When
        campaigns.tapAdd()

        // Then
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點新增後開團編輯表單未出現")
        }
        if !edit.openDatePicker.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "開團編輯表單的開團日期列未出現")
        }
        if !edit.closeDatePicker.exists {
            failWithDiagnostics(in: app, "開團編輯表單的結單日期列未出現")
        }
        XCTAssertFalse(edit.reminderDatePicker.exists, "提醒未開啟時不應出現提醒時間列")
    }

    /// 打開新增開團表單的訂購提醒後，出現提醒時間列
    @MainActor
    func testReminderDateRow_開啟訂購提醒_出現提醒時間列() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let campaigns = openCampaigns(in: app)
        let edit = CampaignEditScreen(app: app)
        campaigns.tapAdd()
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點新增後開團編輯表單未出現")
        }

        // When
        edit.toggleReminder()

        // Then
        if !edit.reminderDatePicker.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "打開訂購提醒後提醒時間列未出現")
        }
    }
}

// MARK: - Private Method

private extension CampaignEditDateRowTests {

    /// 切到開團分頁
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 開團分頁的 Page Object
    /// - Note: 空資料時列表容器不存在，就緒判斷交給 `goToCampaigns`
    @MainActor
    func openCampaigns(in app: XCUIApplication) -> CampaignsScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒")
        }
        return CampaignsScreen(app: app)
    }
}
