//
//  PaymentMethodEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 新增或編輯付款方式時的 sheet 表單
///
/// SwiftUI 的 `.alert` actions builder 只支援 `Button`／`TextField`，無法塞入 `Toggle`；而「是否為無卡類／銀行匯款類／貨到付款類」必須在當下決定，所以付款方式的新增與編輯流程改採獨立 sheet，將名稱輸入與三個旗標切換放在同一張表單，確認後一次帶出 `(name, isCardless, isBankTransfer, isCashOnDelivery)` 給 caller
///
/// 編輯既有付款方式時，caller 透過 `initialName` / `initialIsCardless` / `initialIsBankTransfer` / `initialIsCashOnDelivery` 帶入原有資料，並把 `title` 設為「編輯付款方式」、`submitTitle` 設為「儲存」
///
/// 商品類別等沒有旗標概念的主檔不走這張 sheet (改用 alert 或 ``LookupItemEditorSheet``)
struct PaymentMethodEditorSheet: View {

    // MARK: - View Properties

    /// Sheet 的標題 (顯示在 navigation bar)
    let title: String

    /// 表單上方的說明訊息；空字串時不顯示
    let message: String

    /// 名稱 TextField 的 placeholder
    let namePlaceholder: String

    /// 提交按鈕的文字
    let submitTitle: String

    /// 使用者按下儲存時的 callback；caller 拿到 `(name, isCardless, isBankTransfer, isCashOnDelivery)` 後負責寫入主檔
    let onSubmit: (_ name: String, _ isCardless: Bool, _ isBankTransfer: Bool, _ isCashOnDelivery: Bool) -> Void

    /// 由 sheet 環境注入的 dismiss action
    @Environment(\.dismiss) private var dismiss

    /// 名稱輸入草稿
    @State private var draftName: String

    /// 是否標記為無卡類付款方式
    @State private var draftIsCardless: Bool

    /// 是否標記為銀行匯款類付款方式
    @State private var draftIsBankTransfer: Bool

    /// 是否標記為貨到付款類付款方式
    @State private var draftIsCashOnDelivery: Bool

    // MARK: - Init

    /// 建立付款方式 sheet
    /// - Parameters:
    ///   - title: navigation 標題 (新增用「新增付款方式」、編輯用「編輯付款方式」)
    ///   - message: 表單上方說明；空字串時不顯示
    ///   - namePlaceholder: 名稱 TextField placeholder
    ///   - submitTitle: 提交按鈕文字 (新增用「新增」、編輯用「儲存」)
    ///   - initialName: 名稱初始值；編輯時帶入原名稱，新增時留空
    ///   - initialIsCardless: 無卡旗標初始值；編輯時帶入原狀態
    ///   - initialIsBankTransfer: 銀行匯款旗標初始值；編輯時帶入原狀態
    ///   - initialIsCashOnDelivery: 貨到付款旗標初始值；編輯時帶入原狀態
    ///   - onSubmit: 確認時的 callback，帶出 `(name, isCardless, isBankTransfer, isCashOnDelivery)`
    init(
        title: String,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        initialName: String = "",
        initialIsCardless: Bool = false,
        initialIsBankTransfer: Bool = false,
        initialIsCashOnDelivery: Bool = false,
        onSubmit: @escaping (_ name: String, _ isCardless: Bool, _ isBankTransfer: Bool, _ isCashOnDelivery: Bool) -> Void
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self.onSubmit = onSubmit
        self._draftName = State(initialValue: initialName)
        self._draftIsCardless = State(initialValue: initialIsCardless)
        self._draftIsBankTransfer = State(initialValue: initialIsBankTransfer)
        self._draftIsCashOnDelivery = State(initialValue: initialIsCashOnDelivery)
    }

    // MARK: - View Body

    /// 新增付款方式 sheet 的內容
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

                Section {
                    Toggle(isOn: $draftIsBankTransfer) {
                        Text("標記為「銀行匯款」付款方式")
                    }
                } footer: {
                    Text("啟用後，使用此付款方式的訂單在編輯時會出現「對帳狀態」欄位，供你在款項入帳後標記對帳結果。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle(isOn: $draftIsCashOnDelivery) {
                        Text("標記為「貨到付款」付款方式")
                    }
                } footer: {
                    Text("啟用後，使用此付款方式的訂單因收款金額已含預估運費，獲利會自動扣除國內、國際與外國國內三種運費。")
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
                        onSubmit(trimmed, draftIsCardless, draftIsBankTransfer, draftIsCashOnDelivery)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
#else
        // 表單為 name + 無卡／銀行匯款／貨到付款三個旗標段；medium (約半屏) 仍維持「貼上來的小卡」的
        // 輕量感、讓使用者看見背後的主檔列表，但同時提供 large 供需要看完整三段說明時展開
        .presentationDetents([.medium, .large])
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
        onSubmit: { _, _, _, _ in }
    )
}

#Preview("編輯付款方式") {
    PaymentMethodEditorSheet(
        title: "編輯付款方式",
        message: "修改名稱與分類；變更名稱會一併更新引用此付款方式的訂單。",
        namePlaceholder: "付款方式名稱",
        submitTitle: "儲存",
        initialName: "銀行匯款",
        initialIsCardless: false,
        initialIsBankTransfer: true,
        onSubmit: { _, _, _, _ in }
    )
}
