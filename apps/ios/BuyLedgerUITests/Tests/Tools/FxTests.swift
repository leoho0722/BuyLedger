//
//  FxTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 匯率工具的換算流程 UI 測試
@MainActor
final class FxTests: BLUITestCase {

    // MARK: - Properties

    /// 換算使用的非預設來源幣別代碼
    private static let selectedCurrency = "USD"

    /// 匯率測試輸入的來源幣別金額
    private static let inputAmount = "1000"

    /// UI 測試固定匯率下的預期 TWD 顯示值
    private static let expectedConvertedValue = "$32,468"

    /// 驗證匯率頁選 USD 後回到匯率頁，輸入 1000 時，換算結果卡片顯示 1 USD，換算結果依固定匯率為 $32,468
    ///
    /// - Throws: 換算結果元素不存在或沒有值時丟出測試錯誤
    func testTypeAmount_選美元後輸入金額_依固定匯率換算() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let fx = openFx(app)
        fx.openCurrencyPicker()
        let picker = OptionPickerScreen(app: app)
        if !picker.waitUntilReady() {
            failWithDiagnostics(in: app, "幣別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現")
        }
        picker.selectOption(Self.selectedCurrency)
        // 單選點列即套用並自動關閉選擇器，回到匯率頁
        if !fx.waitUntilReady() {
            failWithDiagnostics(in: app, "選幣別後匯率頁根 identifier「\(fx.rootIdentifier)」逾時仍未回到前景")
        }

        // When
        fx.typeAmount(Self.inputAmount, in: app)

        // Then
        let summary = try requireValue(fx.conversionSummary, in: app, "換算結果卡片沒有來源幣別資訊")
        XCTAssertTrue(summary.contains("1 USD"), "匯率頁來源幣別應為 USD，實際為：\(summary)")
        let value = try requireValue(fx.convertedValue, in: app, "輸入金額後換算結果元素不存在")
        XCTAssertEqual(value, Self.expectedConvertedValue, "1000 USD 依 UI 測試固定匯率應換算為 $32,468")
    }

    /// 驗證匯率頁連續輸入兩次相同金額 1000 後，換算結果為單次輸入的 $23，不會計入兩次
    ///
    /// - Throws: 換算結果元素不存在或沒有值時丟出測試錯誤
    func testTypeAmount_重複輸入相同金額_換算結果只計一次() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let fx = openFx(app)
        fx.typeAmount(Self.inputAmount, in: app)

        // When
        fx.typeAmount(Self.inputAmount, in: app)

        // Then
        let value = try requireValue(fx.convertedValue, in: app, "重複輸入後換算結果元素不存在")
        XCTAssertEqual(value, "$23")
    }
}

// MARK: - Private Method

private extension FxTests {

    /// 從更多分頁導到匯率頁並等就緒，回傳匯率頁 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的匯率頁 Page Object
    func openFx(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FxScreen {
        let fx = FxScreen.open(from: app, file: file, line: line)
        if !fx.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "匯率頁根 identifier「\(fx.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return fx
    }
}
