//
//  CampaignEditNotesSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

import SwiftUI

/// 開團資訊下方的多行備註區段
struct CampaignEditNotesSection: View {

    // MARK: - Properties

    /// 備註的雙向綁定
    @Binding var notes: String

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<CampaignEditFeature.State.Field?>.Binding

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Section("orders.detail.label.notes") {
            notesField
        }
    }
}

// MARK: - Private Views

private extension CampaignEditNotesSection {

    /// 可輸入二至五行的選填備註
    var notesField: some View {
        TextField("orders.edit.label.optional", text: $notes, axis: .vertical)
            .lineLimit(2...5)
            .textContentType(nil)
            .focused(focusedField, equals: .notes)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: CampaignEditFeature.State.Field?

    Form {
        CampaignEditNotesSection(notes: .constant(""), focusedField: $focusedField)
    }
}
