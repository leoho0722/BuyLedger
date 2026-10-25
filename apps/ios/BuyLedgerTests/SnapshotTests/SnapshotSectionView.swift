//
//  SnapshotSectionView.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import SwiftUI

/// 讓編輯表單的單一區段在分組表單內單獨渲染，供逐區段 snapshot 使用
///
/// - Note: 需要焦點綁定的區段無法在 View 之外建立 `FocusState`，由本型別持有並傳入
struct SnapshotSectionView<Field: Hashable, Content: View>: View {

    // MARK: - Properties

    /// 區段需要的焦點狀態，快照只提供綁定、不聚焦任何欄位
    @FocusState private var focusedField: Field?

    /// 以焦點綁定建立區段內容
    let content: (FocusState<Field?>.Binding) -> Content

    // MARK: - Body

    /// 包住區段內容的分組樣式表單
    var body: some View {
        Form {
            content($focusedField)
        }
        .formStyle(.grouped)
    }
}
