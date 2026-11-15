//
//  CampaignEditDateRowUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 開團編輯資訊區段日期列的 UI 測試，以可及性元素驗證版面
@MainActor
final class CampaignEditDateRowUITests: BLUITestCase {

    /// 驗證新增表單顯示開團與結單日期列，提醒未開啟時沒有提醒時間列
    ///
    /// - Throws: 開團分頁或編輯表單未就緒時丟出測試錯誤
    func testNewCampaignTapped_新增開團_顯示開團與結單日期列且無提醒時間列()
        throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let campaigns = try CampaignsScreen.open(in: app)

        // When
        let edit = try campaigns.tapAdd()

        // Then
        XCTAssertTrue(edit.openDatePicker.waitForExistence(timeout: 10), "開團日期列未出現")
        XCTAssertTrue(edit.closeDatePicker.exists, "結單日期列未出現")
        XCTAssertFalse(
            edit.reminderDatePicker.exists,
            "提醒未開啟時不應出現提醒時間列"
        )
    }

    /// 驗證在新增開團表單開啟訂購提醒後，出現提醒時間列
    ///
    /// - Throws: 開團分頁、編輯表單或提醒時間列未就緒時丟出測試錯誤
    func testToggleReminder_開啟訂購提醒_出現提醒時間列() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let campaigns = try CampaignsScreen.open(in: app)
        let edit = try campaigns.tapAdd()

        // When
        try edit.toggleReminder()

        // Then
        XCTAssertTrue(
            edit.reminderDatePicker.waitForExistence(timeout: 10),
            "打開訂購提醒後提醒時間列未出現"
        )
    }
}

