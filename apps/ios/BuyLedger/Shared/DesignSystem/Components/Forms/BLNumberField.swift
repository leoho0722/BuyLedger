//
//  BLNumberField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/4.
//

import SwiftUI

/// 數字輸入欄，每次取得焦點先清空草稿，只有使用者輸入才寫回金額
///
/// - Note: 焦點由呼叫端持有，格式、鍵盤與對齊方式由呼叫端提供
struct BLNumberField<FocusValue: Hashable>: View {

    // MARK: - Properties

    /// 畫面上的文字與這次編輯的寫回紀錄
    @State private var draft: BLNumberFieldDraft

    /// 呼叫端持有的金額，寫回後可能受到捨入或上限調整
    @Binding private var value: Decimal

    /// 呼叫端的焦點狀態
    private let focus: FocusState<FocusValue>.Binding

    /// 此欄位對應的焦點值
    private let focusMatch: FocusValue

    /// 顯示與解析金額時使用的原有格式
    private let format: Decimal.FormatStyle

    /// 草稿為空時顯示的提示文字
    private let prompt: Text?

    /// 欄位標題，同時作為無障礙名稱
    private let titleKey: LocalizedStringKey

    // MARK: - Init

    /// 建立以布林值表示焦點的數字欄位，首幀即顯示格式化金額
    ///
    /// - Parameters:
    ///   - titleKey: 欄位標題
    ///   - value: 呼叫端持有的金額
    ///   - format: 顯示與解析金額的格式
    ///   - prompt: 草稿為空時的提示文字
    ///   - focus: 呼叫端的布林焦點狀態
    init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Decimal>,
        format: Decimal.FormatStyle,
        prompt: Text? = nil,
        focus: FocusState<FocusValue>.Binding
    ) where FocusValue == Bool {
        self.init(
            titleKey,
            value: value,
            format: format,
            prompt: prompt,
            focus: focus,
            equals: true
        )
    }

    /// 建立以列舉表示焦點的數字欄位，首幀即顯示格式化金額
    ///
    /// - Parameters:
    ///   - titleKey: 欄位標題
    ///   - value: 呼叫端持有的金額
    ///   - format: 顯示與解析金額的格式
    ///   - prompt: 草稿為空時的提示文字
    ///   - focus: 呼叫端的焦點列舉狀態
    ///   - equals: 此欄位對應的焦點值
    init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Decimal>,
        format: Decimal.FormatStyle,
        prompt: Text? = nil,
        focus: FocusState<FocusValue>.Binding,
        equals: FocusValue
    ) {
        _draft = State(initialValue: BLNumberFieldDraft(value: value.wrappedValue, format: format))
        _value = value
        self.focus = focus
        focusMatch = equals
        self.format = format
        self.prompt = prompt
        self.titleKey = titleKey
    }

    // MARK: - Body

    /// 輸入欄骨架，只將焦點與外部金額變動交給草稿處理
    var body: some View {
        inputField
            .onChange(of: isFocused) { _, isNowFocused in
                draft.setFocused(isNowFocused, value: value, format: format)
            }
            .onChange(of: value) { _, newValue in
                draft.synchronizeValue(newValue, format: format)
            }
    }
}

// MARK: - Private Views

private extension BLNumberField {

    /// 系統數字輸入欄，保留呼叫端提供的鍵盤與外觀修飾器
    var inputField: some View {
        TextField(titleKey, text: trackedText, prompt: prompt)
            .focused(focus, equals: focusMatch)
    }
}

// MARK: - Private Method

private extension BLNumberField {

    /// 此欄位是否持有焦點
    var isFocused: Bool {
        focus.wrappedValue == focusMatch
    }

    /// 系統讀寫的草稿，只有 setter 會把使用者輸入寫回金額
    var trackedText: Binding<String> {
        Binding {
            draft.text
        } set: { newText in
            guard let requestedValue = draft.updateText(newText, format: format) else {
                return
            }
            value = requestedValue
            draft.recordWrittenValue(value)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var isFocused: Bool

    Form {
        BLNumberField(
            "orders.edit.label.customerPayment",
            value: .constant(2500),
            format: .number.precision(.fractionLength(0)).grouping(.never),
            focus: $isFocused
        )
    }
}
