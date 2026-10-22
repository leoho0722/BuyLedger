//
//  OrderEditNotesSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import SwiftUI

/// 商品明細下方的多行備註區段
struct OrderEditNotesSection: View {

    // MARK: - Properties

    /// 備註的雙向綁定
    @Binding var notes: String

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<OrderEditFeature.State.Field?>.Binding

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Section {
            notesField
        } header: {
            sectionHeader
        }
    }
}

// MARK: - Private Views

private extension OrderEditNotesSection {

    /// 可輸入三至八行的選填備註
    var notesField: some View {
        TextField("orders.edit.placeholder.enterNotesOptional", text: $notes, axis: .vertical)
            .lineLimit(3...8)
            .textContentType(.none)
            .focused(focusedField, equals: .notes)
    }

    /// 備註區段的標題
    var sectionHeader: some View {
        Text("orders.detail.label.notes")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    Form {
        OrderEditNotesSection(notes: .constant(""), focusedField: $focusedField)
    }
}
