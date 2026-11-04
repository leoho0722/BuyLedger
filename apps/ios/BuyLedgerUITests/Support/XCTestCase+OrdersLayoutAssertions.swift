//
//  XCTestCase+OrdersLayoutAssertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension XCTestCase {

    /// 確認 Orders 前景呈現並排或收合其中一種可辨識模式
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 必要前景錨點缺失或版面模式無法辨識時丟出測試錯誤
    func assertOrdersLayoutIsRecognized(in app: XCUIApplication) throws {
        let isSideBySide = isRegularLayout(app)
        let isCollapsed = isCompactLayout(app)
        try requireCondition(isSideBySide != isCollapsed, in: app, "Orders 前景應恰有一種可辨識的並排或收合模式")
    }

    /// 確認方向變更後只存在一張編輯表單且草稿仍在欄位中
    ///
    /// - Parameters:
    ///   - edit: 編輯表單 Page Object
    ///   - customerField: 編輯中的客戶欄位
    ///   - expectedDraft: 欄位應保留的草稿
    ///   - app: 受測 App
    /// - Throws: 表單根數量、草稿或欄位可互動性不符時丟出測試錯誤
    func assertSingleEditSheet(
        _ edit: OrderEditScreen,
        customerField: XCUIElement,
        expectedDraft: String,
        in app: XCUIApplication
    ) throws {
        try requireCondition(edit.waitUntilReady(), in: app, "方向改變後編輯表單未就緒")
        let editRoots = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.OrderEdit.root)
        try requireCondition(editRoots.count == 1, in: app, "方向改變後編輯 sheet 數量應為一")
        try requireCondition(customerField.waitUntilHittable(timeout: 10), in: app, "方向改變後客戶欄位不可互動")
        try requireCondition(customerField.value as? String == expectedDraft, in: app, "轉向後草稿不符預期")
    }
}
