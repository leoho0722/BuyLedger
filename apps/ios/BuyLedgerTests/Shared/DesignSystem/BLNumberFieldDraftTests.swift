//
//  BLNumberFieldDraftTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/4.
//

import Foundation
import Testing

@testable import BuyLedger

/// `BLNumberFieldDraft` 的單元測試
struct BLNumberFieldDraftTests {

    /// 驗證初始化當下已有格式化文字，首幀不必等候畫面出現
    @Test
    func init_固定兩位小數_首幀顯示格式化金額() {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(2))

        // When
        let draft = BLNumberFieldDraft(value: 2500, format: format)

        // Then
        #expect(draft.text == "2500.00")
    }

    /// 驗證各種既有金額取得焦點後都清空草稿
    ///
    /// - Parameter value: 聚焦前的綁定金額
    @Test(arguments: [Decimal(0), Decimal(2500), Decimal(80000)])
    func setFocused_不同既有金額_清空草稿(value: Decimal) {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: value, format: format)

        // When
        draft.setFocused(true, value: value, format: format)

        // Then
        #expect(draft.text == "")
    }

    /// 驗證聚焦後沒有輸入就刪空時，沒有寫回過就不要求還原
    ///
    /// - Parameter value: 聚焦前的綁定金額
    @Test(arguments: [Decimal(0), Decimal(2500), Decimal(80000)])
    func updateText_聚焦後刪空_未寫回過不要求還原(value: Decimal) {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: value, format: format)
        draft.setFocused(true, value: value, format: format)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == nil)
        #expect(draft.text == "")
    }

    /// 驗證沒有輸入就失焦時恢復原本格式
    ///
    /// - Parameter scenario: 聚焦前的金額與失焦後應顯示的文字
    @Test(arguments: BlurScenario.scenarios)
    func setFocused_未輸入即失焦_還原格式(scenario: BlurScenario) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(2))
        var draft = BLNumberFieldDraft(value: scenario.value, format: format)
        draft.setFocused(true, value: scenario.value, format: format)

        // When
        draft.setFocused(false, value: scenario.value, format: format)

        // Then
        #expect(draft.text == scenario.expectedDisplay)
    }

    /// 驗證失焦後重複收到相同的顯示文字，不要求寫回金額
    ///
    /// - Parameter scenario: 聚焦前的金額與失焦後應顯示的文字
    @Test(arguments: BlurScenario.scenarios)
    func updateText_未輸入即失焦後重複顯示文字_不要求寫回(scenario: BlurScenario) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(2))
        var draft = BLNumberFieldDraft(value: scenario.value, format: format)
        draft.setFocused(true, value: scenario.value, format: format)
        draft.setFocused(false, value: scenario.value, format: format)
        let displayedText = draft.text

        // When
        let requestedValue = draft.updateText(displayedText, format: format)

        // Then
        #expect(requestedValue == nil)
    }

    /// 驗證焦點仍在同一欄時不會再次清空尚未完成的小數輸入
    @Test
    func setFocused_聚焦中再次通知_保留輸入草稿() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("12.", format: format)
        draft.recordWrittenValue(12)

        // When
        draft.setFocused(true, value: 12, format: format)

        // Then
        #expect(draft.text == "12.")
    }

    /// 驗證失焦後再次取得焦點會清空草稿
    @Test
    func setFocused_再次聚焦_清空草稿() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)
        draft.setFocused(false, value: 1, format: format)

        // When
        draft.setFocused(true, value: 1, format: format)

        // Then
        #expect(draft.text == "")
    }

    /// 驗證下一次取得焦點會再次清空，刪空時還原的是新一輪聚焦的金額
    @Test
    func setFocused_再次聚焦_更新刪空時的還原金額() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)
        draft.setFocused(false, value: 1, format: format)
        draft.setFocused(true, value: 1, format: format)
        _ = draft.updateText("2", format: format)
        draft.recordWrittenValue(2)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == 1)
    }

    /// 驗證新一輪聚焦不沿用上一輪的寫回旗標，直接刪空不會要求還原
    @Test
    func setFocused_上一輪曾寫回_新一輪未輸入不要求還原() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)
        draft.setFocused(false, value: 1, format: format)
        draft.setFocused(true, value: 1, format: format)
        _ = draft.updateText("abc", format: format)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == nil)
    }

    /// 驗證欄位重建後沒收到聚焦通知時，失焦仍依格式顯示輸入的金額
    @Test
    func setFocused_未收到聚焦通知就失焦_依格式顯示() {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(2))
        var draft = BLNumberFieldDraft(value: 0, format: format)
        _ = draft.updateText("12.3", format: format)
        draft.recordWrittenValue(Decimal(sign: .plus, exponent: -1, significand: 123))

        // When
        draft.setFocused(
            false,
            value: Decimal(sign: .plus, exponent: -1, significand: 123),
            format: format
        )

        // Then
        #expect(draft.text == "12.30")
    }

    /// 驗證焦點先於外部改值到達時，外部改值之後欄位仍為空
    @Test
    func setFocused_焦點先於外部改值_聚焦後為空() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 150000, format: format)
        draft.setFocused(true, value: 50000, format: format)

        // When
        draft.synchronizeValue(50000, format: format)

        // Then
        #expect(draft.text == "")
    }

    /// 驗證外部改值先於焦點到達時，焦點之後欄位仍為空
    @Test
    func setFocused_外部改值先於焦點_聚焦後為空() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 150000, format: format)
        draft.synchronizeValue(50000, format: format)

        // When
        draft.setFocused(true, value: 50000, format: format)

        // Then
        #expect(draft.text == "")
    }

    /// 驗證整數、小數與無效輸入的情境，解析出預期金額，輸入中保留使用者的原文且不提早格式化
    ///
    /// - Parameter scenario: 原始金額、文字、格式與字面值預期
    @Test(arguments: InputScenario.scenarios)
    func updateText_整數小數與無效輸入_解析出預期金額且保留原文(scenario: InputScenario) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(scenario.fractionLength))
        var draft = BLNumberFieldDraft(value: scenario.initialValue, format: format)
        draft.setFocused(true, value: scenario.initialValue, format: format)

        // When
        let requestedValue = draft.updateText(scenario.input, format: format)

        // Then
        #expect(requestedValue == scenario.expectedValue)
        #expect(draft.text == scenario.input)
    }

    /// 驗證整數、小數與無效輸入的情境寫回讀回值後失焦，欄位依讀回值顯示格式化文字
    ///
    /// - Parameter scenario: 原始金額、文字、格式與字面值預期
    @Test(arguments: InputScenario.scenarios)
    func setFocused_整數小數與無效輸入_寫回讀回值後失焦依讀回值顯示(scenario: InputScenario) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(scenario.fractionLength))
        var draft = BLNumberFieldDraft(value: scenario.initialValue, format: format)
        draft.setFocused(true, value: scenario.initialValue, format: format)
        _ = draft.updateText(scenario.input, format: format)
        if scenario.expectedValue != nil {
            draft.recordWrittenValue(scenario.readBackValue)
        }

        // When
        draft.setFocused(false, value: scenario.readBackValue, format: format)

        // Then
        #expect(draft.text == scenario.expectedDisplay)
    }

    /// 驗證整數、小數與無效輸入的情境寫回讀回值後，系統再送出相同金額時不重設草稿
    ///
    /// - Parameter scenario: 原始金額、文字、格式與字面值預期
    @Test(arguments: InputScenario.scenarios)
    func synchronizeValue_整數小數與無效輸入_讀回值一致不重設(scenario: InputScenario) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(scenario.fractionLength))
        var draft = BLNumberFieldDraft(value: scenario.initialValue, format: format)
        draft.setFocused(true, value: scenario.initialValue, format: format)
        _ = draft.updateText(scenario.input, format: format)
        if scenario.expectedValue != nil {
            draft.recordWrittenValue(scenario.readBackValue)
        }

        // When
        let hasResetDraft = draft.synchronizeValue(scenario.readBackValue, format: format)

        // Then
        #expect(!hasResetDraft)
    }

    /// 驗證尚未完成的小數字串可即時解析，但輸入中保留使用者的小數點
    @Test
    func updateText_輸入中途小數點_保留原文並解析整數() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 0, format: format)
        draft.setFocused(true, value: 0, format: format)

        // When
        let requestedValue = draft.updateText("12.", format: format)

        // Then
        #expect(requestedValue == 12)
        #expect(draft.text == "12.")
    }

    /// 驗證系統重複送出同一草稿時不再次要求寫回金額
    @Test
    func updateText_同一草稿重複寫入_不再次要求寫回() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 0, format: format)
        draft.setFocused(true, value: 0, format: format)
        _ = draft.updateText("1000", format: format)
        draft.recordWrittenValue(1000)

        // When
        let requestedValue = draft.updateText("1000", format: format)

        // Then
        #expect(requestedValue == nil)
        #expect(draft.text == "1000")
    }

    /// 驗證這次聚焦曾寫回數字後，全部刪除會要求還原聚焦當下金額
    @Test
    func updateText_輸入後全部刪除_要求還原聚焦金額() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == 2500)
        #expect(draft.text == "")
    }

    /// 驗證只輸入無法解析的文字再刪空時，沒有寫回過就不要求還原
    @Test
    func updateText_無效輸入後全部刪除_不要求還原() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 80000, format: format)
        draft.setFocused(true, value: 80000, format: format)
        let invalidValue = draft.updateText("abc", format: format)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(invalidValue == nil)
        #expect(requestedValue == nil)
        #expect(draft.text == "")
    }

    /// 驗證刪空還原後，系統再次送出相同空字串不會重複要求還原
    @Test
    func updateText_刪空還原後重複通知_不重複寫回() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)
        _ = draft.updateText("", format: format)
        draft.recordWrittenValue(2500)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == nil)
        #expect(draft.text == "")
    }

    /// 驗證刪空還原後，系統送出與還原金額相同的通知時不重設草稿
    @Test
    func synchronizeValue_刪空還原後同值通知_不重設() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 2500, format: format)
        draft.setFocused(true, value: 2500, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)
        _ = draft.updateText("", format: format)
        draft.recordWrittenValue(2500)

        // When
        let hasResetDraft = draft.synchronizeValue(2500, format: format)

        // Then
        #expect(!hasResetDraft)
        #expect(draft.text == "")
    }

    /// 驗證寫回受到上限限制時，寫回後讀回的金額不同，輸入中仍保留使用者的原文
    @Test
    func recordWrittenValue_上限使讀回值不同_輸入中保留原文() {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(0))
        var draft = BLNumberFieldDraft(value: 500, format: format)
        draft.setFocused(true, value: 500, format: format)
        let requestedValue = draft.updateText("5000", format: format)

        // When
        draft.recordWrittenValue(1000)

        // Then
        #expect(requestedValue == 5000)
        #expect(draft.text == "5000")
    }

    /// 驗證上限讀回值與最後讀回值相同時，外部通知不重設輸入中的原文
    @Test
    func synchronizeValue_上限讀回值與最後讀回值相同_不重設草稿() {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(0))
        var draft = BLNumberFieldDraft(value: 500, format: format)
        draft.setFocused(true, value: 500, format: format)
        _ = draft.updateText("5000", format: format)
        draft.recordWrittenValue(1000)

        // When
        let hasResetDraft = draft.synchronizeValue(1000, format: format)

        // Then
        #expect(!hasResetDraft)
        #expect(draft.text == "5000")
    }

    /// 驗證上限讀回值的欄位失焦後，顯示上限金額
    @Test
    func setFocused_上限讀回值_失焦後顯示上限() {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(0))
        var draft = BLNumberFieldDraft(value: 500, format: format)
        draft.setFocused(true, value: 500, format: format)
        _ = draft.updateText("5000", format: format)
        draft.recordWrittenValue(1000)

        // When
        draft.setFocused(false, value: 1000, format: format)

        // Then
        #expect(draft.text == "1000")
    }

    /// 驗證與最後讀回值相同的通知不會抹掉尚未完成的小數點
    @Test
    func synchronizeValue_與讀回值相同_不重設草稿() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 0, format: format)
        draft.setFocused(true, value: 0, format: format)
        _ = draft.updateText("12.", format: format)
        draft.recordWrittenValue(12)

        // When
        let hasResetDraft = draft.synchronizeValue(12, format: format)

        // Then
        #expect(!hasResetDraft)
        #expect(draft.text == "12.")
    }

    /// 驗證不論是否聚焦，外部不同金額都立即以原格式取代草稿
    ///
    /// - Parameter isFocused: 外部改值時是否正在編輯
    @Test(arguments: [true, false])
    func synchronizeValue_外部改為不同金額_依格式重設草稿(isFocused: Bool) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(2))
        var draft = BLNumberFieldDraft(value: 150000, format: format)
        draft.setFocused(isFocused, value: 150000, format: format)

        // When
        let hasResetDraft = draft.synchronizeValue(50000, format: format)

        // Then
        #expect(hasResetDraft)
        #expect(draft.text == "50000.00")
    }

    /// 驗證同一個外部金額重複通知時，第二次不重設草稿
    ///
    /// - Parameter isFocused: 外部改值時是否正在編輯
    @Test(arguments: [true, false])
    func synchronizeValue_同一外部金額重複通知_不重設草稿(isFocused: Bool) {
        // Given
        let format = Self.numberFormat.precision(.fractionLength(2))
        var draft = BLNumberFieldDraft(value: 150000, format: format)
        draft.setFocused(isFocused, value: 150000, format: format)
        draft.synchronizeValue(50000, format: format)

        // When
        let hasResetAgain = draft.synchronizeValue(50000, format: format)

        // Then
        #expect(!hasResetAgain)
    }

    /// 驗證未曾寫回就收到外部金額後，刪空仍不會要求寫回或還原
    @Test
    func updateText_外部改值前未寫回_刪空不要求還原() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 150000, format: format)
        draft.setFocused(true, value: 150000, format: format)
        draft.synchronizeValue(50000, format: format)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == nil)
        #expect(draft.text == "")
    }

    /// 驗證外部改值不會取代聚焦快照，這輪曾寫回再刪空仍還原最初金額
    @Test
    func updateText_寫回後外部改值_刪空還原聚焦快照() {
        // Given
        let format = Self.numberFormat
        var draft = BLNumberFieldDraft(value: 150000, format: format)
        draft.setFocused(true, value: 150000, format: format)
        _ = draft.updateText("1", format: format)
        draft.recordWrittenValue(1)
        draft.synchronizeValue(50000, format: format)

        // When
        let requestedValue = draft.updateText("", format: format)

        // Then
        #expect(requestedValue == 150000)
    }

    /// 驗證德國格式解析逗號小數，解析結果與小數值相同
    @Test
    func updateText_德國地區逗號小數_解析為相同數值() {
        // Given
        let format = Self.numberFormat.locale(Locale(identifier: "de_DE"))
        var draft = BLNumberFieldDraft(value: 0, format: format)
        draft.setFocused(true, value: 0, format: format)

        // When
        let requestedValue = draft.updateText("22,8", format: format)

        // Then
        #expect(requestedValue == Decimal(sign: .plus, exponent: -1, significand: 228))
    }

    /// 驗證德國格式寫回後失焦，結束編輯仍依傳入格式顯示逗號小數
    @Test
    func setFocused_德國地區逗號小數_失焦後顯示逗號() {
        // Given
        let format = Self.numberFormat.locale(Locale(identifier: "de_DE"))
        let readBackValue = Decimal(sign: .plus, exponent: -1, significand: 228)
        var draft = BLNumberFieldDraft(value: 0, format: format)
        draft.setFocused(true, value: 0, format: format)
        _ = draft.updateText("22,8", format: format)
        draft.recordWrittenValue(readBackValue)

        // When
        draft.setFocused(false, value: readBackValue, format: format)

        // Then
        #expect(draft.text == "22,8")
    }
}

// MARK: - Nested Types

extension BLNumberFieldDraftTests {

    /// 失焦前後的金額與失焦後應顯示的文字
    struct BlurScenario: Sendable {

        /// 失焦測試的金額與顯示文字
        static let scenarios = [
            Self(value: 0, expectedDisplay: "0.00"),
            Self(value: 2500, expectedDisplay: "2500.00"),
        ]

        /// 聚焦前的金額
        let value: Decimal

        /// 失焦後應顯示的格式化文字
        let expectedDisplay: String
    }

    /// 各輸入情境的初始金額、輸入文字、讀回值與字面值預期
    struct InputScenario: Sendable {

        /// 整數、小數、無效輸入、空字串與小數位捨入的輸入情境
        static let scenarios = [
            Self(
                initialValue: 0,
                input: "1000",
                fractionLength: 0...0,
                expectedValue: 1000,
                readBackValue: 1000,
                expectedDisplay: "1000"
            ),
            Self(
                initialValue: 0,
                input: "22.8",
                fractionLength: 0...2,
                expectedValue: Decimal(sign: .plus, exponent: -1, significand: 228),
                readBackValue: Decimal(sign: .plus, exponent: -1, significand: 228),
                expectedDisplay: "22.8"
            ),
            Self(
                initialValue: 80000,
                input: "abc",
                fractionLength: 0...0,
                expectedValue: nil,
                readBackValue: 80000,
                expectedDisplay: "80000"
            ),
            Self(
                initialValue: 80000,
                input: "",
                fractionLength: 0...0,
                expectedValue: nil,
                readBackValue: 80000,
                expectedDisplay: "80000"
            ),
            Self(
                initialValue: 0,
                input: "",
                fractionLength: 0...0,
                expectedValue: nil,
                readBackValue: 0,
                expectedDisplay: "0"
            ),
            Self(
                initialValue: 0,
                input: "12.345",
                fractionLength: 2...2,
                expectedValue: Decimal(sign: .plus, exponent: -3, significand: 12345),
                readBackValue: Decimal(sign: .plus, exponent: -2, significand: 1235),
                expectedDisplay: "12.35"
            ),
            Self(
                initialValue: 0,
                input: "5",
                fractionLength: 2...2,
                expectedValue: 5,
                readBackValue: 5,
                expectedDisplay: "5.00"
            ),
            Self(
                initialValue: 0,
                input: "5",
                fractionLength: 1...1,
                expectedValue: 5,
                readBackValue: 5,
                expectedDisplay: "5.0"
            ),
        ]

        /// 聚焦前的金額
        let initialValue: Decimal

        /// 使用者輸入的完整草稿
        let input: String

        /// 顯示格式保留的小數位範圍
        let fractionLength: ClosedRange<Int>

        /// 解析後應要求寫回的金額，缺值代表不寫回
        let expectedValue: Decimal?

        /// 呼叫端完成捨入或限制後，實際讀回的金額
        let readBackValue: Decimal

        /// 失焦後應顯示的格式化文字
        let expectedDisplay: String
    }
}

// MARK: - Private Method

private extension BLNumberFieldDraftTests {

    /// 固定美式小數點且不加千分位的測試格式
    static var numberFormat: Decimal.FormatStyle {
        .number
            .locale(Locale(identifier: "en_US_POSIX"))
            .grouping(.never)
            .precision(.fractionLength(0...2))
    }
}
