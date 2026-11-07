//
//  EditorTextInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 開團與主檔編輯表單取得焦點時的游標位置測試
@MainActor
final class EditorTextInputFocusUITests: BLUITestCase {

    /// 驗證開團名稱「四月韓國團」失焦後從左側重新聚焦輸入「新」，欄位值為「四月韓國團新」，游標在名稱尾端
    func testFocusCampaignNameFromLeft_既有開團名稱接續輸入_新增文字接在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        guard let edit = openCampaignEdit(in: app, campaignID: "CMP-SAMPLE-KR-APR") else {
            return
        }
        XCTAssertEqual(edit.nameFieldValue(), "四月韓國團", "前置開團名稱應符合種子")
        guard edit.dismissNameKeyboard() else {
            return
        }
        XCTAssertFalse(edit.isNameFieldFocused(), "點左側前名稱欄應已失焦")
        XCTAssertEqual(edit.nameFieldValue(), "四月韓國團", "失焦不應改動原文")

        // When
        guard edit.focusFromLeft(edit.nameField, isScrollingDown: false) else {
            return
        }
        edit.nameField.typeText("新")

        // Then
        _ = pollUntil(timeout: 3) {
            edit.nameFieldValue() == "四月韓國團新"
        }
        XCTAssertEqual(edit.nameFieldValue(), "四月韓國團新", "新增文字應接在開團名稱尾端")
    }

    /// 驗證測試輸入的兩行開團備註失焦後點第一行，新增文字接在第二行尾端
    func testFocusCampaignNotesFromFirstLine_多行備註接續輸入_新增文字接在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        guard let edit = openCampaignEdit(in: app, campaignID: "CMP-SAMPLE-JP-MAR") else {
            return
        }
        XCTAssertEqual(edit.nameFieldValue(), "三月日本團", "前置開團名稱應為三月日本團")
        guard edit.dismissNameKeyboard(),
              edit.focusFromLeft(edit.notesField, isScrollingDown: true) else {
            return
        }
        edit.notesField.typeText("第一行")
        edit.notesField.typeText(XCUIKeyboardKey.return.rawValue)
        edit.notesField.typeText("第二行")
        XCTAssertEqual(edit.notesValue, "第一行\n第二行", "前置備註應包含兩行原文")
        guard edit.focusFromLeft(edit.nameField, isScrollingDown: false),
              edit.dismissNameKeyboard() else {
            return
        }
        XCTAssertFalse(
            NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: edit.notesField),
            "點第一行前備註欄應已失焦"
        )
        XCTAssertEqual(edit.notesValue, "第一行\n第二行", "切換焦點不應改動原文")

        // When
        guard edit.focusNotesFromFirstLine() else {
            return
        }
        edit.notesField.typeText("X")

        // Then
        _ = pollUntil(timeout: 3) {
            edit.notesValue == "第一行\n第二行X"
        }
        XCTAssertEqual(edit.notesValue, "第一行\n第二行X", "新增文字應接在第二行尾端")
    }

    /// 驗證分類名稱「服飾」失焦後從左側重新聚焦輸入「類」，欄位值為「服飾類」，游標在名稱尾端
    func testFocusLookupNameFromLeft_既有主檔名稱接續輸入_新增文字接在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let management = LookupManagementScreen(app: app)
        management.openCategoryManagement()
        management.beginRename(from: "服飾")
        XCTAssertEqual(management.nameFieldValue, "服飾", "前置主檔名稱應符合種子")
        guard management.dismissKeyboard(for: management.nameField) else {
            return
        }
        XCTAssertFalse(management.isNameFieldFocused(), "點左側前名稱欄應已失焦")
        XCTAssertEqual(management.nameFieldValue, "服飾", "失焦不應改動原文")

        // When
        guard management.nameField.tapLeftToFocus(in: app) else {
            return
        }
        management.nameField.typeText("類")

        // Then
        _ = pollUntil(timeout: 3) {
            management.nameField.value as? String == "服飾類"
        }
        XCTAssertEqual(management.nameField.value as? String, "服飾類", "新增文字應接在主檔名稱尾端")
    }

    /// 驗證付款方式「信用卡」失焦後從左側重新聚焦輸入「新」，欄位值為「信用卡新」，游標在名稱尾端
    func testFocusPaymentMethodNameFromLeft_既有付款方式接續輸入_新增文字接在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let management = LookupManagementScreen(app: app)
        management.openPaymentMethodManagement()
        management.beginEditPaymentMethod(named: "信用卡")
        let field = management.paymentMethodNameField
        XCTAssertEqual(field.value as? String, "信用卡", "前置付款方式名稱應符合種子")
        guard management.dismissKeyboard(for: field) else {
            return
        }
        XCTAssertFalse(
            NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: field),
            "點左側前付款方式名稱欄應已失焦"
        )
        XCTAssertEqual(field.value as? String, "信用卡", "失焦不應改動原文")

        // When
        guard field.tapLeftToFocus(in: app) else {
            return
        }
        field.typeText("新")

        // Then
        _ = pollUntil(timeout: 3) {
            field.value as? String == "信用卡新"
        }
        XCTAssertEqual(field.value as? String, "信用卡新", "新增文字應接在付款方式名稱尾端")
    }
}

// MARK: - Private Method

private extension EditorTextInputFocusUITests {

    /// 開啟既有開團的編輯表單並等待就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - campaignID: 要編輯的開團識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的編輯表單，導航失敗時為 `nil`
    func openCampaignEdit(
        in app: XCUIApplication,
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CampaignEditScreen? {
        guard RootNavigationScreen(app: app).goToCampaigns(file: file, line: line) else {
            app.failWithDiagnostics("切到開團分頁後畫面未就緒", file: file, line: line)
            return nil
        }
        let campaigns = CampaignsScreen(app: app)
        guard campaigns.waitUntilReady() else {
            app.failWithDiagnostics("開團列表未就緒", file: file, line: line)
            return nil
        }
        campaigns.tapCampaign(campaignID: campaignID, file: file, line: line)
        let detail = CampaignDetailScreen(app: app)
        guard detail.waitUntilReady() else {
            app.failWithDiagnostics("既有開團詳情未出現", file: file, line: line)
            return nil
        }
        detail.openMoreMenu(file: file, line: line)
        guard detail.tapEdit(file: file, line: line) else {
            return nil
        }
        let edit = CampaignEditScreen(app: app)
        guard edit.waitUntilReady() else {
            app.failWithDiagnostics("既有開團編輯表單未出現", file: file, line: line)
            return nil
        }
        return edit
    }
}
