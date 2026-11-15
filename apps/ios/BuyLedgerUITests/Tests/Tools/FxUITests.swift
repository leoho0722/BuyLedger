//
//  FxUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 匯率工具換算、轉向續輸入與鍵盤狀態的 UI 測試
@MainActor
final class FxUITests: BLUITestCase {

    // MARK: - Properties

    /// 換算使用的非預設來源幣別代碼
    private static let selectedCurrency = "USD"

    /// 匯率測試輸入的來源幣別金額
    private static let inputAmount = "1000"

    /// 驗證匯率頁選 USD 後回到匯率頁，輸入 1000 時，換算結果卡片顯示 1 USD，換算結果依固定匯率為 $32,468
    ///
    /// - Throws: 換算結果元素不存在或沒有值時丟出 UITestError.stopped
    func testTypeAmount_選美元後輸入金額_依固定匯率換算() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)
        let picker = try fx.openCurrencyPicker()
        try picker.selectOption(Self.selectedCurrency)
        // 單選點列即套用並自動關閉選擇器，回到匯率頁
        try requireCondition(
            fx.waitUntilReady(),
            in: app,
            "選幣別後匯率頁根 identifier「\(fx.rootIdentifier)」逾時仍未回到前景"
        )

        // When
        try fx.typeAmount(Self.inputAmount)

        // Then
        let summary = try requireValue(fx.conversionSummary(), in: app, "換算結果卡片沒有來源幣別資訊")
        XCTAssertTrue(summary.contains("1 USD"), "匯率頁來源幣別應為 USD，實際為：\(summary)")
        let value = try requireValue(fx.convertedValue(), in: app, "輸入金額後換算結果元素不存在")
        XCTAssertEqual(value, "$32,468", "1000 USD 依 UI 測試固定匯率應換算為 $32,468")
    }

    /// 驗證匯率頁連續輸入兩次相同金額 1000 後，換算結果為單次輸入的 $23，不會計入兩次
    ///
    /// - Throws: 換算結果元素不存在或沒有值時丟出 UITestError.stopped
    func testTypeAmount_重複輸入相同金額_換算結果只計一次() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)
        try fx.typeAmount(Self.inputAmount)

        // When
        try fx.typeAmount(Self.inputAmount)

        // Then
        let value = try requireValue(fx.convertedValue(), in: app, "重複輸入後換算結果元素不存在")
        XCTAssertEqual(value, "$23")
    }

    /// 驗證金額欄輸入後旋轉，再續輸入的數字仍寫回同一欄並保持鍵盤焦點
    ///
    /// - Throws: 金額欄未就緒、旋轉失敗或欄位失去焦點時丟出 UITestError.stopped
    func testAmount_轉向後續輸入_金額寫回同一欄() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)
        try fx.replaceAmountKeepingKeyboard("1")

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(fx.isAmountFieldFocused(), in: app, "旋轉後金額欄失去鍵盤焦點")

        // When
        fx.appendAmount("0")

        // Then
        let value = try requireValue(fx.amountFieldValue(), in: app, "旋轉後金額欄元素不存在")
        XCTAssertEqual(value, "10", "旋轉後續輸入的數字應寫回金額欄")
    }

    /// 驗證金額欄輸入後收起鍵盤再旋轉，金額值保留，鍵盤與金額欄焦點維持收起，不因重排重新彈出
    ///
    /// - Throws: 金額欄未就緒或旋轉失敗時丟出 UITestError.stopped
    func testRotateToLandscape_收鍵盤後轉向_鍵盤保持收起() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)
        try fx.replaceAmountKeepingKeyboard("1")
        try fx.dismissAmountKeyboard()

        // When
        try rotateToLandscape(app)

        // Then
        let value = try requireValue(fx.amountFieldValue(), in: app, "收鍵盤後旋轉金額欄元素不存在")
        XCTAssertEqual(value, "1", "收鍵盤後旋轉，金額欄應保留使用者輸入的值")
        XCTAssertFalse(fx.isAmountFieldFocused(), "使用者收起鍵盤後，旋轉不應把金額欄重新設為焦點")
        if !app.keyboards.firstMatch.waitForNonExistence(timeout: 3) {
            failWithDiagnostics(in: app, "使用者收起鍵盤後旋轉，鍵盤被重新彈出")
        }
    }
}
