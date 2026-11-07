//
//  BLSearchableModifier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/5.
//

import SwiftUI

/// 套用常駐搜尋欄，焦點由無到有時把游標放在既有文字尾端，不全選也不清空
///
/// - Note: `.searchable`、`.searchFocused`、`.searchSelection` 與文字、選取追蹤集中在這裡套用，維持已驗證的組合
@MainActor
struct BLSearchableModifier {

    // MARK: - Properties

    /// 搜尋欄的焦點，由 `.searchFocused` 與系統搜尋欄同步
    @FocusState private var isFocused: Bool

    /// 最後一次由使用者輸入寫回的文字，與目前文字不同時代表外部改值
    @State private var lastInputText: String

    /// 選取範圍，只在焦點由無到有時設定，之後由系統更新
    @State private var selection: TextSelection?

    /// 搜尋文字，由呼叫端持有
    @Binding private var text: String

    /// 搜尋欄的提示文字
    private let prompt: Text

    // MARK: - Init

    /// 建立常駐搜尋欄
    ///
    /// - Parameters:
    ///   - text: 搜尋文字
    ///   - prompt: 搜尋欄的提示文字
    init(text: Binding<String>, prompt: Text) {
        _lastInputText = State(initialValue: text.wrappedValue)
        _text = text
        self.prompt = prompt
    }
}

// MARK: - ViewModifier

extension BLSearchableModifier: ViewModifier {

    /// 套用搜尋欄，焦點轉換時放游標，外部改值時丟棄舊選取
    ///
    /// - Parameter content: 要加上搜尋欄的內容
    /// - Returns: 套用搜尋欄與游標處理後的畫面
    func body(content: Content) -> some View {
        content
            .searchable(
                text: trackedText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: prompt
            )
            .searchFocused($isFocused)
            .searchSelection(trackedSelection)
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

// MARK: - blSearchable

extension View {

    /// 套用 App 的標準搜尋欄
    ///
    /// - Parameters:
    ///   - text: 搜尋文字
    ///   - prompt: 搜尋欄的提示文字
    /// - Returns: 加上搜尋欄的畫面
    func blSearchable(text: Binding<String>, prompt: Text) -> some View {
        modifier(BLSearchableModifier(text: text, prompt: prompt))
    }
}

// MARK: - Private Method

private extension BLSearchableModifier {

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
