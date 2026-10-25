//
//  CampaignEditDateRowTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 開團編輯資訊區段日期列的 UI 測試，以可及性元素斷言取代該區段的像素比對
@MainActor
final class CampaignEditDateRowTests: BLUITestCase {

    /// 驗證按下新增後，表單顯示開團與結單日期列，且提醒未開啟時不出現提醒時間列
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

    /// 驗證在新增開團表單開啟訂購提醒後，出現提醒時間列
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
    func openCampaigns(in app: XCUIApplication) -> CampaignsScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToCampaigns() {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒")
        }
        return CampaignsScreen(app: app)
    }
}
