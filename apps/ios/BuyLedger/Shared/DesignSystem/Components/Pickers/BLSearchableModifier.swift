//
//  BLSearchableModifier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/20.
//

import SwiftUI

/// 依條件套用搜尋修飾器並維持畫面識別
struct BLSearchableModifier {

    // MARK: - Properties

    /// 搜尋輸入的雙向繫結
    @Binding var text: String

    /// 是否啟用搜尋欄
    let isEnabled: Bool
}

// MARK: - ViewModifier

extension BLSearchableModifier: ViewModifier {

    /// 依 ``isEnabled`` 決定是否套上 `.searchable`
    /// - Parameter content: 原始內容
    /// - Returns: 套用修飾器後的畫面
    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋")
            )
        } else {
            content
        }
    }
}
