//
//  OptionPickerAddSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

import SwiftUI

/// 顯示新增入口並處理名稱輸入，付款方式編輯交由宿主推入
struct OptionPickerAddSection: View {

    // MARK: - Properties

    /// 名稱確認後關閉目前選擇器
    @Environment(\.dismiss) private var dismiss

    /// 新增名稱的輸入草稿
    @State private var draft = ""

    /// 是否顯示新增名稱的 alert
    @State private var isAddAlertPresented = false

    /// 新增項目的輸入方式與送出回呼
    let addition: OptionPickerSheet.Addition

    /// 請宿主推入付款方式編輯器
    let onPaymentMethodRequested: () -> Void

    // MARK: - Body

    /// 顯示新增選項列與名稱輸入對話框
    var body: some View {
        Section {
            addButton
        }
        .alert(LocalizedStringKey(prompt.title), isPresented: $isAddAlertPresented) {
            alertActions
        } message: {
            Text(LocalizedStringKey(prompt.message))
        }
    }
}

// MARK: - Private Views

private extension OptionPickerAddSection {

    /// 開啟目前模式對應的新增入口
    var addButton: some View {
        Button {
            triggerAdd()
        } label: {
            Label(LocalizedStringKey(prompt.buttonTitle), systemImage: "plus.circle.fill")
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addButton)
    }

    /// 新增名稱的輸入欄、確認與取消操作
    @ViewBuilder
    var alertActions: some View {
        TextField(LocalizedStringKey(prompt.placeholder), text: $draft)
            .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertNameField)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

        Button("orders.list.button.add") {
            addDraft()
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertConfirmButton)
        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        Button("common.action.cancel", role: .cancel) {
            draft = ""
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertCancelButton)
    }
}

// MARK: - Private Method

private extension OptionPickerAddSection {

    /// 目前新增入口的按鈕與輸入文案
    var prompt: OptionPickerSheet.AddPrompt {
        switch addition {
        case .prompt(let prompt, _), .paymentMethod(let prompt, _):
            return prompt
        }
    }

    /// 依新增模式開啟名稱輸入或請宿主推入編輯器
    func triggerAdd() {
        switch addition {
        case .prompt:
            draft = ""
            isAddAlertPresented = true

        case .paymentMethod:
            onPaymentMethodRequested()
        }
    }

    /// 送出修剪後的名稱、清空草稿並關閉選擇器
    func addDraft() {
        guard case .prompt(_, let onAdd) = addition else {
            return
        }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        onAdd(trimmed)
        draft = ""
        dismiss()
    }
}

// MARK: - Preview

#Preview("新增商品類別") {
    List {
        OptionPickerAddSection(
            addition: .prompt(
                .init(
                    buttonTitle: "orders.edit.label.addCategory",
                    title: "orders.edit.label.addItemCategory",
                    message: "orders.edit.message.enterNewProduct",
                    placeholder: "orders.edit.label.categoryName"
                )
            ) { _ in
            }
        ) {
        }
    }
}
