//
//  FxTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 匯率工具的進入、狀態橫幅與換算流程測試
///
/// 一律以 accessibility identifier 定位、對換算結果做非空的結構性斷言，不硬編精確金額 (匯率走固定快照 stub);
/// 找不到 App 元素即附診斷失敗、不 skip。幣別原始值是業務鍵、不隨語言變動，故中英兩語言皆有效
final class FxTests: BLUITestCase {

    // MARK: - Static Properties

    /// 換算時選用的來源幣別原始值 (``BLAccessibilityID/OptionPicker/optionRow(_:)`` 的 key)
    private static let selectedCurrency = "KRW"

    // MARK: - Tests

    /// 從更多分頁進匯率頁後就緒，且載入狀態橫幅存在 (固定快照)
    @MainActor
    func testFxReadyWithStatusBanner() {
        let app = launch(LaunchOptions(seed: .empty))
        let fx = openFx(app)

        if !fx.statusBannerExists {
            failWithDiagnostics(
                in: app,
                "匯率頁狀態橫幅「\(BLAccessibilityID.Fx.statusBanner)」未出現"
            )
        }
    }

    /// 開幣別選擇器選 KRW 後回匯率頁，輸入金額後換算結果有值
    @MainActor
    func testFxConvertsAfterSelectingCurrencyAndAmount() {
        let app = launch(LaunchOptions(seed: .empty))
        let fx = openFx(app)

        fx.openCurrencyPicker()

        let picker = OptionPickerScreen(app: app)
        if !picker.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "幣別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現"
            )
        }
        picker.selectOption(Self.selectedCurrency)

        // 單選點列即套用並自動關閉選擇器，回到匯率頁
        if !fx.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "選幣別後匯率頁根 identifier「\(fx.rootIdentifier)」逾時仍未回到前景"
            )
        }

        fx.typeAmount("1000", in: app)

        if fx.convertedValue.isEmpty {
            failWithDiagnostics(
                in: app,
                "輸入金額後換算結果「\(BLAccessibilityID.Fx.convertedValue)」的 value 仍為空"
            )
        }
    }
}

// MARK: - Private Method

private extension FxTests {

    /// 從更多分頁導到匯率頁並等就緒，回傳匯率頁 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的匯率頁 Page Object
    @MainActor
    func openFx(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FxScreen {
        let fx = FxScreen.open(from: app)
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
