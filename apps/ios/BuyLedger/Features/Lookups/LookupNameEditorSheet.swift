//
//  LookupNameEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 主檔項目的單欄名稱表單 sheet
struct LookupNameEditorSheet: View {

    // MARK: - Properties

    /// 關閉目前的表單
    @Environment(\.dismiss) private var dismiss

    /// 名稱輸入草稿
    @State private var draftName: String

    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @State private var isDiscardConfirmationPresented = false

    /// 表單開啟時的名稱，用來判斷輸入內容是否已變更
    private let initialName: String

    /// 表單下方顯示的說明；空字串時不顯示
    let message: String

    /// 名稱欄位尚未輸入時顯示的提示
    let namePlaceholder: String

    /// 使用者提交有效名稱後執行的處理
    let onSubmit: (_ name: String) -> Void

    /// 提交按鈕顯示的文字
    let submitTitle: String

    /// 導覽列顯示的表單標題
    let title: LocalizedStringKey

    // MARK: - Init

    /// 建立名稱輸入表單
    ///
    /// - Parameters:
    ///   - title: 導覽列顯示的表單標題
    ///   - message: 表單下方顯示的說明；空字串時不顯示
    ///   - namePlaceholder: 名稱欄位尚未輸入時顯示的提示
    ///   - submitTitle: 提交按鈕顯示的文字
    ///   - initialName: 名稱初始值；重新命名時帶入目前名稱，新增時留空
    ///   - onSubmit: 使用者提交時收到去除首尾空白的名稱
    init(
        title: LocalizedStringKey,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        initialName: String = "",
        onSubmit: @escaping (_ name: String) -> Void
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self.onSubmit = onSubmit
        self._draftName = State(initialValue: initialName)
        self.initialName = initialName
    }

    // MARK: - Body

    /// 名稱表單的畫面內容
    var body: some View {
        NavigationStack {
            formContent
        }
        // 單一欄位加一段說明，medium 已足夠；保留 large 供最大字級時展開
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
        .interactiveDismissDisabled(isDirty)
        .alert("捨棄變更", isPresented: $isDiscardConfirmationPresented) {
            discardChangesButton
            continueEditingButton
        } message: {
            discardConfirmationMessage
        }
    }
}

// MARK: - Private Views

private extension LookupNameEditorSheet {

    /// 確認捨棄目前尚未儲存的內容
    var discardChangesButton: some View {
        Button("捨棄變更", role: .destructive) {
            dismiss()
        }
    }

    /// 保留內容並繼續編輯
    var continueEditingButton: some View {
        Button("繼續編輯", role: .cancel) {}
    }

    /// 說明離開表單後尚未儲存的內容會被清除
    var discardConfirmationMessage: some View {
        Text("這個項目有尚未儲存的變更，離開後將不會保留。")
    }

    /// 表單內容：名稱欄位、說明與取消／儲存工具列
    @ViewBuilder
    var formContent: some View {
        Form {
            Section {
                TextField(LocalizedStringKey(namePlaceholder), text: $draftName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(nil)
                    .accessibilityIdentifier(BLAccessibilityID.LookupManagement.nameField)
            } footer: {
                if !message.isEmpty {
                    Text(LocalizedStringKey(message))
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if isDirty {
                        isDiscardConfirmationPresented = true
                    } else {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onSubmit(trimmedName)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(Text(LocalizedStringKey(submitTitle)))
                .accessibilityIdentifier(BLAccessibilityID.LookupManagement.nameSubmitButton)
                .disabled(!canSubmit)
            }
        }
    }
}

// MARK: - Private Method

private extension LookupNameEditorSheet {

    /// 去除首尾空白後的名稱
    var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 是否可提交：名稱非空且與初始值不同
    var canSubmit: Bool {
        !trimmedName.isEmpty && trimmedName != initialName
    }

    /// 是否有未儲存的變更
    var isDirty: Bool {
        trimmedName != initialName
    }
}

// MARK: - Preview

#Preview("主檔名稱表單") {
    LookupNameEditorSheet(
        title: "新增訂單來源",
        message: "輸入新的訂單來源名稱，加入後會立即套用。",
        namePlaceholder: "來源名稱",
        submitTitle: "新增"
    ) { _ in }
}
