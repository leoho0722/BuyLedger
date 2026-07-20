//
//  DismissKeyboardOnBackgroundTap.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 點擊背景收鍵盤
///
/// 取代原本掛在 window 上的全域手勢：那個作法對所有觸控都先攔一次，再靠黑名單把互動元件排除，
/// 而黑名單永遠追不上系統新增的 view 型別。改由背景層自己承接點擊——只有真正點在背景才會觸發，
/// 互動元件天生不在背景層上，不需要任何排除清單
struct DismissKeyboardOnBackgroundTap<Value: Hashable>: ViewModifier {

    // MARK: - View Properties

    /// 焦點綁定；收鍵盤即把它設為 `nil`
    ///
    /// 以泛型承載各畫面不同的焦點型別；修飾子本身不持有狀態，也不假設焦點型別的內容
    @FocusState.Binding var focus: Value?

    // MARK: - View Body

    /// 在內容底下鋪一層可命中的透明區域承接背景點擊
    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    // 透明色預設不可命中，須明確宣告形狀才會接到觸控
                    .contentShape(.rect)
                    .onTapGesture {
                        // 以焦點狀態收鍵盤，不呼叫 UIKit 的結束編輯：
                        // 讓收鍵盤與焦點成為同一個狀態的兩面，不會出現「鍵盤已收但焦點仍指向某欄位」
                        focus = nil
                    }
                    .accessibilityHidden(true)
            }
    }
}

/// 點擊背景收鍵盤 (單一欄位版)
///
/// 只有一個輸入欄的畫面以 `Bool` 表達焦點即可，不需要為單一欄位造一個列舉
struct DismissKeyboardOnBackgroundTapForSingleField: ViewModifier {

    // MARK: - View Properties

    /// 焦點綁定；收鍵盤即把它設為 `false`
    @FocusState.Binding var isFocused: Bool

    // MARK: - View Body

    /// 在內容底下鋪一層可命中的透明區域承接背景點擊
    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture {
                        isFocused = false
                    }
                    .accessibilityHidden(true)
            }
    }
}

// MARK: - View Method

extension View {

    /// 點擊背景時清除焦點以收起鍵盤
    ///
    /// 只加在有文字輸入的畫面上；使用系統搜尋呈現的畫面毋須加掛，其 Cancel 與捲動收合由系統提供
    /// - Parameter focus: 該畫面的焦點綁定
    /// - Returns: 套用背景點擊收鍵盤的 view
    func dismissKeyboardOnBackgroundTap<Value: Hashable>(
        focus: FocusState<Value?>.Binding
    ) -> some View {
        modifier(DismissKeyboardOnBackgroundTap(focus: focus))
    }

    /// 點擊背景時清除焦點以收起鍵盤 (單一輸入欄的畫面)
    /// - Parameter isFocused: 該畫面唯一輸入欄的焦點綁定
    /// - Returns: 套用背景點擊收鍵盤的 view
    func dismissKeyboardOnBackgroundTap(isFocused: FocusState<Bool>.Binding) -> some View {
        modifier(DismissKeyboardOnBackgroundTapForSingleField(isFocused: isFocused))
    }
}
