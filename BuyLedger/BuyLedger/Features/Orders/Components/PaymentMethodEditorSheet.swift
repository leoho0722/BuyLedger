//
//  PaymentMethodEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 新增付款方式時的 sheet 表單。
///
/// SwiftUI 的 `.alert` actions builder 只支援 `Button`／`TextField`，無法塞入 `Toggle`；而「是否為無卡類」必須在新增當下決定，所以付款方式新增流程改採獨立 sheet，將名稱輸入與 `isCardless` 切換放在同一張表單，確認後一次帶出 `(name, isCardless)` 給 caller。
///
/// 商品類別新增流程沒有 `isCardless` 概念，繼續沿用 ``OptionPickerSheet`` 內建的 alert，不走這張 sheet。
struct PaymentMethodEditorSheet: View {

    // MARK: - View Properties

    /// Sheet 的標題 (顯示在 navigation bar)。
    let title: String

    /// 表單上方的說明訊息；空字串時不顯示。
    let message: String

    /// 名稱 TextField 的 placeholder。
    let namePlaceholder: String

    /// 提交按鈕的文字。
    let submitTitle: String

    /// 使用者按下儲存時的 callback；caller 拿到 `(name, isCardless)` 後負責寫入主檔。
    let onSubmit: (_ name: String, _ isCardless: Bool) -> Void

    /// 由 sheet 環境注入的 dismiss action。
    @Environment(\.dismiss) private var dismiss

    /// 名稱輸入草稿。
    @State private var draftName: String = ""

    /// 是否標記為無卡類付款方式。
    @State private var draftIsCardless: Bool = false

    // MARK: - View Body

    /// 新增付款方式 sheet 的內容。
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
                    Text("付款方式名稱")
                } footer: {
                    if !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle(isOn: $draftIsCardless) {
                        Text("標記為「無卡」付款方式")
                    }
                } footer: {
                    Text("啟用後，使用此付款方式的訂單在「收款金額」區段會出現「無卡折抵金額」與「無卡補款金額」兩個欄位，並計入總收款公式。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                        onSubmit(trimmed, draftIsCardless)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 320)
#else
        // 表單只有 name + isCardless 兩段，medium 高度 (約半屏) 已足夠呈現，
        // 同時讓使用者能看見背後的主檔列表，UX 上更像「貼上來的小卡」而非整頁 modal。
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
#endif
    }
}

// MARK: - Preview

#Preview("新增付款方式") {
    PaymentMethodEditorSheet(
        title: "新增付款方式",
        message: "輸入新的付款方式名稱，加入後會立即套用至此訂單。",
        namePlaceholder: "付款方式名稱",
        submitTitle: "新增",
        onSubmit: { _, _ in }
    )
}
