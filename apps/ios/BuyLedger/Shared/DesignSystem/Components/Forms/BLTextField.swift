//
//  BLTextField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/4.
//

import SwiftUI

/// 文字輸入欄位，焦點由無到有時把游標放在既有文字尾端，不全選也不清空
///
/// - Note: 焦點由呼叫端的 `FocusState` 持有，元件不另建焦點狀態
struct BLTextField<FocusValue: Hashable>: View {

    // MARK: - Properties

    /// 最後一次由使用者輸入寫回的文字，與目前文字不同時代表外部改值
    @State private var lastInputText: String

    /// 選取範圍，只在焦點轉換時設定，之後由系統更新
    @State private var selection: TextSelection?

    /// 文字內容，由呼叫端持有
    @Binding private var text: String

    /// 輸入軸向，`nil` 為單行，`.vertical` 為多行
    private let axis: Axis?

    /// 呼叫端的焦點狀態
    private let focus: FocusState<FocusValue>.Binding

    /// 此欄位對應的焦點值
    private let focusMatch: FocusValue

    /// 無輸入時顯示的提示文字
    private let prompt: Text?

    /// 欄位標題，同時作為無障礙名稱
    private let title: LocalizedStringResource

    // MARK: - Init

    /// 建立以 `Bool` 表示焦點的文字欄位
    ///
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - text: 文字內容
    ///   - prompt: 無輸入時顯示的提示文字
    ///   - axis: 輸入軸向，`nil` 為單行
    ///   - focus: 呼叫端的 `Bool` 焦點狀態
    init(
        _ title: LocalizedStringResource,
        text: Binding<String>,
        prompt: Text? = nil,
        axis: Axis? = nil,
        focus: FocusState<FocusValue>.Binding
    ) where FocusValue == Bool {
        self.init(
            title,
            text: text,
            prompt: prompt,
            axis: axis,
            focus: focus,
            equals: true
        )
    }

    /// 建立以列舉表示焦點的文字欄位
    ///
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - text: 文字內容
    ///   - prompt: 無輸入時顯示的提示文字
    ///   - axis: 輸入軸向，`nil` 為單行
    ///   - focus: 呼叫端的焦點列舉狀態
    ///   - equals: 此欄位對應的焦點值
    init(
        _ title: LocalizedStringResource,
        text: Binding<String>,
        prompt: Text? = nil,
        axis: Axis? = nil,
        focus: FocusState<FocusValue>.Binding,
        equals: FocusValue
    ) {
        _lastInputText = State(initialValue: text.wrappedValue)
        _text = text
        self.axis = axis
        self.focus = focus
        focusMatch = equals
        self.prompt = prompt
        self.title = title
    }

    // MARK: - Body

    /// 輸入欄，焦點轉換時放游標，外部改值時丟棄舊選取
    var body: some View {
        inputField
            .onChange(of: isFocused) { _, isNowFocused in
                guard isNowFocused, !text.isEmpty else {
                    return
                }
                selection = TextSelection(insertionPoint: text.endIndex)
            }
            .onChange(of: text) { _, newText in
                guard newText != lastInputText else {
                    return
                }
                lastInputText = newText
                selection = nil
            }
    }
}

// MARK: - Private Views

private extension BLTextField {

    /// 系統文字欄位，文字與選取都經追蹤用的綁定
    var inputField: some View {
        TextField(
            title,
            text: trackedText,
            selection: trackedSelection,
            prompt: prompt,
            axis: axis
        )
        .focused(focus, equals: focusMatch)
    }
}

// MARK: - Private Method

private extension BLTextField {

    /// 此欄位是否持有焦點
    var isFocused: Bool {
        focus.wrappedValue == focusMatch
    }

    /// 系統讀寫的文字，只有使用者輸入會經過 setter
    var trackedText: Binding<String> {
        Binding {
            text
        } set: { newText in
            lastInputText = newText
            text = newText
        }
    }

    /// 系統讀寫的選取，外部改值後不把舊字串的索引交給系統
    var trackedSelection: Binding<TextSelection?> {
        Binding {
            text == lastInputText ? selection : nil
        } set: {
            selection = $0
        }
    }
}

// MARK: - Preview

#Preview("單行") {
    @Previewable @FocusState var isFocused: Bool

    Form {
        BLTextField("orders.list.label.customerName", text: .constant("林書宇"), focus: $isFocused)
    }
}

#Preview("多行") {
    @Previewable @FocusState var isFocused: Bool

    Form {
        BLTextField(
            "orders.detail.label.notes",
            text: .constant("第一行\n第二行"),
            axis: .vertical,
            focus: $isFocused
        )
    }
}
