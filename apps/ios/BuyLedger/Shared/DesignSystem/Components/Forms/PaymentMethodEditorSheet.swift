//
//  PaymentMethodEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 新增或編輯付款方式時的 sheet 表單
///
/// - Note: 以付款方式分類旗標參數化表單，領域語意由呼叫端決定
struct PaymentMethodEditorSheet: View {

    // MARK: - Properties

    /// 由 sheet 環境注入的 `dismiss` action
    @Environment(\.dismiss) private var dismiss

    /// 名稱輸入草稿
    @State private var draftName: String

    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @State private var isDiscardConfirmationPresented = false

    /// 是否標記為銀行匯款類付款方式
    @State private var isDraftBankTransfer: Bool

    /// 是否標記為無卡類付款方式
    @State private var isDraftCardless: Bool

    /// 是否標記為貨到付款類付款方式
    @State private var isDraftCashOnDelivery: Bool

    /// 名稱欄位的鍵盤焦點
    @FocusState private var isNameFieldFocused: Bool

    /// 表單初始值，用於判斷 `isDirty`
    private let initialName: String

    /// 是否嵌入既有導覽堆疊；預設 `false` 為獨立 sheet
    private let isEmbedded: Bool

    /// 銀行匯款付款方式初始值，用於判斷 `isDirty`
    private let isInitialBankTransfer: Bool

    /// 無卡付款方式初始值，用於判斷 `isDirty`
    private let isInitialCardless: Bool

    /// 貨到付款付款方式初始值，用於判斷 `isDirty`
    private let isInitialCashOnDelivery: Bool

    /// 表單上方的說明訊息；空字串時不顯示
    private let message: String

    /// 名稱 `TextField` 的 placeholder
    private let namePlaceholder: String

    /// 提交付款方式時使用的 closure，接收名稱與三個分類旗標
    private let onSubmit: SubmitAction

    /// 提交按鈕的文字
    private let submitTitle: String

    /// Sheet 的標題 (顯示在 navigation bar)
    private let title: String

    // MARK: - Init

    /// 建立付款方式 sheet
    ///
    /// - Parameters:
    ///   - title: 導覽標題
    ///   - message: 表單上方說明；空字串時不顯示
    ///   - namePlaceholder: 名稱 `TextField` placeholder
    ///   - submitTitle: 提交按鈕文字 (新增用「新增」、編輯用「儲存」)
    ///   - initialName: 名稱初始值；編輯時帶入原名稱，新增時留空
    ///   - isInitialCardless: 無卡付款方式初始值；編輯時帶入原狀態
    ///   - isInitialBankTransfer: 銀行匯款付款方式初始值；編輯時帶入原狀態
    ///   - isInitialCashOnDelivery: 貨到付款付款方式初始值；編輯時帶入原狀態
    ///   - isEmbedded: 是否嵌入既有導覽堆疊；預設為 `false` 時以獨立 sheet 呈現
    ///   - onSubmit: 提交付款方式時使用的 closure，接收名稱與三個分類旗標
    init(
        title: String,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        initialName: String = "",
        isInitialCardless: Bool = false,
        isInitialBankTransfer: Bool = false,
        isInitialCashOnDelivery: Bool = false,
        isEmbedded: Bool = false,
        onSubmit: @escaping SubmitAction
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self.isEmbedded = isEmbedded
        self.onSubmit = onSubmit
        self._draftName = State(initialValue: initialName)
        self._isDraftCardless = State(initialValue: isInitialCardless)
        self._isDraftBankTransfer = State(initialValue: isInitialBankTransfer)
        self._isDraftCashOnDelivery = State(initialValue: isInitialCashOnDelivery)
        self.initialName = initialName
        self.isInitialCardless = isInitialCardless
        self.isInitialBankTransfer = isInitialBankTransfer
        self.isInitialCashOnDelivery = isInitialCashOnDelivery
    }

    // MARK: - Body

    /// 新增／編輯付款方式的內容
    var body: some View {
        if isEmbedded {
            formContent
        } else {
            NavigationStack {
                formContent
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
            .interactiveDismissDisabled(isDirty)
            .alert(
                "orders.list.label.discardChanges",
                isPresented: $isDiscardConfirmationPresented
            ) {
                Button("orders.list.label.discardChanges", role: .destructive) {
                    dismiss()
                }
                Button("orders.list.label.keepEditing", role: .cancel) {
                }
            } message: {
                Text("common.ui.message.paymentMethodHas")
            }
        }
    }
}

// MARK: - Private Views

private extension PaymentMethodEditorSheet {

    /// 付款方式表單內容，依 `isEmbedded` 決定是否包裝導覽
    @ViewBuilder
    var formContent: some View {
        Form {
            Section {
                TextField(LocalizedStringKey(namePlaceholder), text: $draftName)
                    .focused($isNameFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(
                        BLAccessibilityID.LookupManagement.paymentMethodNameField
                    )
            } header: {
                Text("orders.detail.label.paymentMethodName")
            } footer: {
                if !message.isEmpty {
                    Text(LocalizedStringKey(message))
                        .blTextStyle(.footnote)
                        .foregroundStyle(.blSecondaryLabel)
                }
            }

            Section {
                Toggle(isOn: $isDraftCardless) {
                    Text("common.ui.label.markAsCardless")
                }
            } footer: {
                Text("common.ui.message.whenEnabledOrders")
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blSecondaryLabel)
            }

            Section {
                Toggle(isOn: $isDraftBankTransfer) {
                    Text("common.ui.label.markAsBank")
                }
            } footer: {
                Text("common.ui.message.whenEnabledOrdersUsing")
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blSecondaryLabel)
            }

            Section {
                Toggle("common.ui.label.markAsCash", isOn: $isDraftCashOnDelivery)
                    .accessibilityIdentifier(
                        BLAccessibilityID.LookupManagement.paymentMethodCashOnDeliveryToggle
                    )
            } footer: {
                Text("common.ui.message.whenEnabled")
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blSecondaryLabel)
            }
        }
        .formStyle(.grouped)
        .accessibilityIdentifier(BLAccessibilityID.LookupManagement.paymentMethodEditorRoot)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(LocalizedStringKey(title)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEmbedded {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: cancelEditing) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("common.action.cancel"))
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(action: submitDraft) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(Text(LocalizedStringKey(submitTitle)))
                .accessibilityIdentifier(BLAccessibilityID.LookupManagement.paymentMethodSaveButton)
                .keyboardShortcut(.defaultAction)
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

// MARK: - Nested Types

extension PaymentMethodEditorSheet {

    /// 提交付款方式時使用的 closure，接收名稱與三個分類旗標
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - isCardless: 是否為無卡付款方式
    ///   - isBankTransfer: 是否為銀行匯款付款方式
    ///   - isCashOnDelivery: 是否為貨到付款付款方式
    typealias SubmitAction = (
        _ name: String,
        _ isCardless: Bool,
        _ isBankTransfer: Bool,
        _ isCashOnDelivery: Bool
    ) -> Void

    /// 付款方式表單用於判斷未儲存變更的值快照
    struct Snapshot: Equatable {

        /// 付款方式名稱
        let name: String

        /// 是否為無卡付款方式
        let isCardless: Bool

        /// 是否為銀行匯款付款方式
        let isBankTransfer: Bool

        /// 是否為貨到付款付款方式
        let isCashOnDelivery: Bool
    }
}

// MARK: - Private Method

private extension PaymentMethodEditorSheet {

    /// 表單目前輸入值的快照
    ///
    /// - Returns: 草稿欄位組成的表單快照
    var draftSnapshot: Snapshot {
        Snapshot(
            name: draftName,
            isCardless: isDraftCardless,
            isBankTransfer: isDraftBankTransfer,
            isCashOnDelivery: isDraftCashOnDelivery
        )
    }

    /// 表單開啟時初始值的快照
    ///
    /// - Returns: 初始欄位組成的表單快照
    var initialSnapshot: Snapshot {
        Snapshot(
            name: initialName,
            isCardless: isInitialCardless,
            isBankTransfer: isInitialBankTransfer,
            isCashOnDelivery: isInitialCashOnDelivery
        )
    }

    /// 草稿是否已變更
    ///
    /// - Returns: 草稿與初始快照不相等時為 `true`
    var isDirty: Bool {
        draftSnapshot != initialSnapshot
    }

    /// 依表單是否變更決定直接關閉或顯示捨棄確認
    func cancelEditing() {
        if isDirty {
            isDiscardConfirmationPresented = true
        } else {
            dismiss()
        }
    }

    /// 驗證草稿後提交付款方式
    func submitDraft() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        onSubmit(
            trimmed,
            isDraftCardless,
            isDraftBankTransfer,
            isDraftCashOnDelivery
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview("orders.edit.label.addPaymentMethod") {
    PaymentMethodEditorSheet(
        title: "orders.edit.label.addPaymentMethod",
        message: "orders.edit.message.enterNewPayment",
        namePlaceholder: "orders.detail.label.paymentMethodName",
        submitTitle: "orders.list.button.add",
        onSubmit: { _, _, _, _ in
        }
    )
}

#Preview("orders.lookup.label.editPaymentMethod") {
    PaymentMethodEditorSheet(
        title: "orders.lookup.label.editPaymentMethod",
        message: "orders.lookup.message.editNameTags",
        namePlaceholder: "orders.detail.label.paymentMethodName",
        submitTitle: "orders.edit.button.save",
        initialName: "orders.edit.label.bankTransfer",
        isInitialBankTransfer: true,
        onSubmit: { _, _, _, _ in
        }
    )
}
