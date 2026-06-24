//
//  LookupItemEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import SwiftUI

/// 新增「只需要名稱、沒有額外旗標」主檔項目時的 medium sheet 表單
///
/// 對帳狀態等主檔比照「新增付款方式」改用 medium sheet 收集名稱 (而非系統 alert)，操作體驗一致。與 ``PaymentMethodEditorSheet`` 的差別在於本表單沒有任何 Toggle，僅有單一名稱欄位，供 ``OptionPickerSheet`` 與 ``LookupManagementView`` 共用
struct LookupItemEditorSheet: View {

    // MARK: - View Properties

    /// Sheet 的標題 (顯示在 navigation bar)
    let title: String

    /// 表單上方的說明訊息；空字串時不顯示
    let message: String

    /// 名稱 TextField 的 placeholder
    let namePlaceholder: String

    /// 提交按鈕的文字
    let submitTitle: String

    /// 使用者按下儲存時的 callback；caller 拿到 trim 後的名稱後負責寫入主檔
    let onSubmit: (_ name: String) -> Void

    /// 由 sheet 環境注入的 dismiss action
    @Environment(\.dismiss) private var dismiss

    /// 名稱輸入草稿
    @State private var draftName: String = ""

    // MARK: - View Body

    /// 新增主檔項目 sheet 的內容
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(namePlaceholder, text: $draftName)
#if !os(macOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                } header: {
                    Text(namePlaceholder)
                } footer: {
                    if !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(title)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(submitTitle) {
                        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSubmit(trimmed)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 240)
#else
        // 只有單一名稱欄位，medium 高度 (約半屏) 已足夠呈現，並比照「新增付款方式」維持一致的「貼上來的小卡」體驗
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
#endif
    }
}

// MARK: - Preview

#Preview("新增對帳狀態") {
    LookupItemEditorSheet(
        title: "新增對帳狀態",
        message: "輸入新的對帳狀態名稱；不會自動套用到任何既有訂單。",
        namePlaceholder: "對帳狀態名稱",
        submitTitle: "新增",
        onSubmit: { _ in }
    )
}
