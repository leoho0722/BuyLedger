//
//  LookupNameEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import SwiftUI

/// 主檔項目的單欄名稱表單 sheet，草稿、焦點與捨棄確認由呼叫端的 `State` 持有
struct LookupNameEditorSheet: View {

    // MARK: - Properties

    /// 關閉目前的表單
    @Environment(\.dismiss) private var dismiss

    /// 名稱欄位的鍵盤焦點，與 `isNameFieldFocused` 同步
    @FocusState private var nameFieldFocused: Bool

    /// 名稱輸入草稿
    @Binding private var draftName: String

    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @Binding private var isDiscardConfirmationPresented: Bool

    /// 名稱欄位是否持有焦點，重新呈現時依此還原焦點
    @Binding private var isNameFieldFocused: Bool

    /// 草稿去除空白後可以送出時為 `true`
    private let canSubmit: Bool

    /// 草稿有未儲存的變更時為 `true`，阻擋下滑並讓取消鍵改以彈窗確認
    private let isDirty: Bool

    /// 表單下方顯示的說明；空字串時不顯示
    private let message: String

    /// 名稱欄位尚未輸入時顯示的提示
    private let namePlaceholder: String

    /// 取消鍵的處理，由呼叫端決定；`nil` 時由 `View` 依未儲存變更決定顯示捨棄確認或直接關閉
    private let onCancel: (() -> Void)?

    /// 捨棄確認選擇捨棄後的處理，由呼叫端決定；`nil` 時由 `View` 直接關閉
    private let onDiscardChanges: (() -> Void)?

    /// 使用者提交有效名稱後執行的處理，名稱由呼叫端的 `State` 讀取
    private let onSubmit: () -> Void

    /// 提交按鈕顯示的文字
    private let submitTitle: String

    /// 導覽列顯示的表單標題
    private let title: LocalizedStringKey

    // MARK: - Init

    /// 建立名稱輸入表單，草稿與焦點由呼叫端的 `State` 提供
    ///
    /// - Parameters:
    ///   - title: 導覽列顯示的表單標題
    ///   - message: 表單下方顯示的說明；空字串時不顯示
    ///   - namePlaceholder: 名稱欄位尚未輸入時顯示的提示
    ///   - submitTitle: 提交按鈕顯示的文字
    ///   - draftName: 名稱輸入草稿
    ///   - isNameFieldFocused: 名稱欄位是否持有焦點
    ///   - isDiscardConfirmationPresented: 是否顯示捨棄確認彈窗
    ///   - isDirty: 草稿是否有未儲存的變更
    ///   - canSubmit: 草稿去除空白後是否可以送出
    ///   - onCancel: 取消鍵的處理；`nil` 時由 `View` 依未儲存變更決定顯示捨棄確認或直接關閉
    ///   - onDiscardChanges: 捨棄確認選擇捨棄後的處理；`nil` 時由 `View` 直接關閉
    ///   - onSubmit: 使用者提交時執行
    init(
        title: LocalizedStringKey,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        draftName: Binding<String>,
        isNameFieldFocused: Binding<Bool>,
        isDiscardConfirmationPresented: Binding<Bool>,
        isDirty: Bool,
        canSubmit: Bool,
        onCancel: (() -> Void)? = nil,
        onDiscardChanges: (() -> Void)? = nil,
        onSubmit: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self._draftName = draftName
        self._isNameFieldFocused = isNameFieldFocused
        self._isDiscardConfirmationPresented = isDiscardConfirmationPresented
        self.isDirty = isDirty
        self.canSubmit = canSubmit
        self.onCancel = onCancel
        self.onDiscardChanges = onDiscardChanges
        self.onSubmit = onSubmit
    }

    /// 以固定草稿建立名稱表單，供預覽與快照使用；草稿與原名稱相同，輸入與提交不會保存或送出
    ///
    /// - Parameters:
    ///   - title: 導覽列顯示的表單標題
    ///   - message: 表單下方顯示的說明；空字串時不顯示
    ///   - namePlaceholder: 名稱欄位尚未輸入時顯示的提示
    ///   - submitTitle: 提交按鈕顯示的文字
    ///   - initialName: 固定的名稱草稿，同時作為原名稱
    ///   - onSubmit: 提交時收到固定草稿名稱的回呼
    init(
        title: LocalizedStringKey,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        initialName: String = "",
        onSubmit: @escaping (_ name: String) -> Void
    ) {
        self.init(
            title: title,
            message: message,
            namePlaceholder: namePlaceholder,
            submitTitle: submitTitle,
            draftName: .constant(initialName),
            isNameFieldFocused: .constant(false),
            isDiscardConfirmationPresented: .constant(false),
            isDirty: false,
            canSubmit: false,
            onSubmit: {
                onSubmit(initialName)
            }
        )
    }

    // MARK: - Body

    /// 名稱表單的畫面內容
    var body: some View {
        NavigationStack {
            formContent
        }
        // 單一欄位加一段說明，`.medium` 已足夠；保留 `.large` 供最大字級時展開
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
        .interactiveDismissDisabled(isDirty)
        .alert("orders.list.label.discardChanges", isPresented: $isDiscardConfirmationPresented) {
            discardChangesButton
            continueEditingButton
        } message: {
            discardConfirmationMessage
        }
    }
}

// MARK: - Private Views

private extension LookupNameEditorSheet {

    /// 表單內容：名稱欄位、說明與取消／儲存工具列
    @ViewBuilder
    var formContent: some View {
        Form {
            Section {
                TextField(LocalizedStringKey(namePlaceholder), text: $draftName)
                    .focused($nameFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(nil)
                    .accessibilityIdentifier(BLAccessibilityID.LookupManagement.nameField)
            } footer: {
                if !message.isEmpty {
                    Text(LocalizedStringKey(message))
                        .blTextStyle(.footnote)
                        .foregroundStyle(.blSecondaryLabel)
                }
            }
        }
        .blReadableScrollContent(.form)
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .bind($isNameFieldFocused, to: $nameFieldFocused)
        .accessibilityIdentifier(BLAccessibilityID.LookupManagement.nameEditorRoot)
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.action.cancel", action: cancelEditing)
                    .accessibilityIdentifier(BLAccessibilityID.LookupManagement.nameCancelButton)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onSubmit()
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

    /// 確認捨棄目前尚未儲存的內容
    var discardChangesButton: some View {
        Button("orders.list.label.discardChanges", role: .destructive) {
            discardChanges()
        }
    }

    /// 保留內容並繼續編輯
    var continueEditingButton: some View {
        Button("orders.list.label.keepEditing", role: .cancel) {
        }
    }

    /// 說明離開表單後尚未儲存的內容會被清除
    var discardConfirmationMessage: some View {
        Text("orders.lookup.message.itemHasUnsaved")
    }
}

// MARK: - Private Method

private extension LookupNameEditorSheet {

    /// 取消鍵的處理：有外部處理時交給呼叫端，否則依未儲存變更決定顯示捨棄確認或直接關閉
    func cancelEditing() {
        if let onCancel {
            onCancel()
        } else if isDirty {
            isDiscardConfirmationPresented = true
        } else {
            dismiss()
        }
    }

    /// 捨棄變更：有外部處理時交給呼叫端，否則直接關閉表單
    func discardChanges() {
        if let onDiscardChanges {
            onDiscardChanges()
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("主檔名稱表單") {
    LookupNameEditorSheet(
        title: "orders.edit.label.addOrderSource",
        message: "輸入新的訂單來源名稱，加入後會立即套用。",
        namePlaceholder: "orders.edit.label.sourceName",
        submitTitle: "orders.list.button.add"
    ) { _ in
    }
}
