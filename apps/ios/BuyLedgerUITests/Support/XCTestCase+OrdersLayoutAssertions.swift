//
//  XCTestCase+OrdersLayoutAssertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

// MARK: - 訂單版面斷言

@MainActor
extension XCTestCase {

    /// 確認 Orders 前景呈現並排或收合其中一種可辨識模式
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要前景錨點缺失或版面模式無法辨識時丟出測試錯誤
    func assertOrdersLayoutIsRecognized(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let _ = try ordersLayout(in: app, file: file, line: line)
    }

    /// 確認方向變更後只存在一張編輯表單且草稿仍在欄位中
    ///
    /// - Parameters:
    ///   - edit: 編輯表單 Page Object
    ///   - customerField: 編輯中的客戶欄位
    ///   - expectedDraft: 欄位應保留的草稿
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 表單根數量、草稿或欄位可互動性不符時丟出測試錯誤
    func assertSingleEditSheet(
        _ edit: OrderEditScreen,
        customerField: XCUIElement,
        expectedDraft: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireCondition(
            edit.waitUntilReady(),
            in: app,
            "方向改變後編輯表單未就緒",
            file: file,
            line: line
        )
        try requireCondition(
            edit.presentedRootCount == 1,
            in: app,
            "方向改變後編輯 sheet 數量應為一",
            file: file,
            line: line
        )
        try requireCondition(
            customerField.waitUntilHittable(timeout: 10),
            in: app,
            "方向改變後客戶欄位不可互動",
            file: file,
            line: line
        )
        try requireCondition(
            customerField.value as? String == expectedDraft,
            in: app,
            "轉向後草稿不符預期",
            file: file,
            line: line
        )
    }
}
