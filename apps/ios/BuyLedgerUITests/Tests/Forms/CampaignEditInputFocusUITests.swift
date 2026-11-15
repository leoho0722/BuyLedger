//
//  CampaignEditInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 開團名稱與多行備註重新聚焦後游標位置的 UI 測試
@MainActor
final class CampaignEditInputFocusUITests: BLUITestCase {

    /// 驗證開團名稱「四月韓國團」失焦後從左側重新聚焦輸入「新」，欄位值為「四月韓國團新」，游標在名稱尾端
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFromLeft_既有開團名稱接續輸入_新增文字接在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)
        try detail.openMoreMenu()
        let edit = try detail.tapEdit()
        try requireCondition(
            edit.nameFieldValue() == "四月韓國團",
            in: app,
            "前置開團名稱應符合種子 (實際：\(String(describing: edit.nameFieldValue())))"
        )
        try edit.dismissNameKeyboard()
        try requireCondition(!edit.isNameFieldFocused(), in: app, "點左側前名稱欄應已失焦")
        try requireCondition(
            edit.nameFieldValue() == "四月韓國團",
            in: app,
            "失焦不應改動原文 (實際：\(String(describing: edit.nameFieldValue())))"
        )

        // When
        try edit.focusFromLeft(edit.nameField, isSwipingUp: false)
        edit.nameField.typeText("新")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.nameFieldValue() == "四月韓國團新"
        }
        XCTAssertEqual(edit.nameFieldValue(), "四月韓國團新", "新增文字應接在開團名稱尾端")
    }

    /// 驗證測試輸入的兩行開團備註失焦後點第一行，新增文字接在第二行尾端
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusNotesFromFirstLine_開團多行備註接續輸入_新增文字接在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let campaigns = try CampaignsScreen.open(in: app)
        let detail = try campaigns.openDetail(campaignID: "CMP-SAMPLE-JP-MAR")
        try detail.openMoreMenu()
        let edit = try detail.tapEdit()
        try requireCondition(
            edit.nameFieldValue() == "三月日本團",
            in: app,
            "前置開團名稱應為三月日本團 (實際：\(String(describing: edit.nameFieldValue())))"
        )
        try edit.dismissNameKeyboard()
        try edit.focusFromLeft(edit.notesField, isSwipingUp: true)
        edit.notesField.typeText("第一行")
        edit.notesField.typeText(XCUIKeyboardKey.return.rawValue)
        edit.notesField.typeText("第二行")
        try requireCondition(
            edit.notesValue == "第一行\n第二行",
            in: app,
            "前置備註應包含兩行原文 (實際：\(String(describing: edit.notesValue)))"
        )
        try edit.focusFromLeft(edit.nameField, isSwipingUp: false)
        try edit.dismissNameKeyboard()
        try requireCondition(!edit.notesField.hasKeyboardFocus, in: app, "點第一行前備註欄應已失焦")
        try requireCondition(
            edit.notesValue == "第一行\n第二行",
            in: app,
            "切換焦點不應改動原文 (實際：\(String(describing: edit.notesValue)))"
        )

        // When
        try edit.focusNotesFromFirstLine()
        edit.notesField.typeText("X")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.notesValue == "第一行\n第二行X"
        }
        XCTAssertEqual(edit.notesValue, "第一行\n第二行X", "新增文字應接在第二行尾端")
    }
}
