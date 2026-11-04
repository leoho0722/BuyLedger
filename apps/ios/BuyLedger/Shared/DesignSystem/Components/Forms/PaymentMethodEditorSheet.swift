//
//  PaymentMethodEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 新增或編輯付款方式時的 sheet 表單，草稿、旗標、焦點與捨棄確認由呼叫端持有
///
/// - Note: 以付款方式分類旗標參數化表單，領域語意由呼叫端決定
struct PaymentMethodEditorSheet: View {

    // MARK: - Properties

    /// 由 sheet 環境注入的 `dismiss` action
    @Environment(\.dismiss) private var dismiss

    /// 名稱欄位的鍵盤焦點，與 `isNameFieldFocused` 同步
    @FocusState private var nameFieldFocused: Bool

    /// 名稱輸入草稿
    @Binding private var draftName: String

    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @Binding private var isDiscardConfirmationPresented: Bool

    /// 是否標記為銀行匯款類付款方式
    @Binding private var isDraftBankTransfer: Bool

    /// 是否標記為無卡類付款方式
    @Binding private var isDraftCardless: Bool

    /// 是否標記為貨到付款類付款方式
    @Binding private var isDraftCashOnDelivery: Bool

    /// 名稱欄位是否持有焦點，重新呈現時依此還原焦點
    @Binding private var isNameFieldFocused: Bool

    /// 草稿去除空白後可以送出時為 `true`
    private let canSubmit: Bool

    /// 草稿有未儲存的變更時為 `true`，阻擋下滑並讓取消鍵改以彈窗確認
    private let isDirty: Bool

    /// 是否嵌入既有導覽堆疊；預設 `false` 為獨立 sheet
    private let isEmbedded: Bool

    /// 表單上方的說明訊息；空字串時不顯示
    private let message: String

    /// 名稱 `TextField` 的 placeholder
    private let namePlaceholder: String

    /// 取消鍵的處理，由呼叫端決定；`nil` 時由 `View` 依未儲存變更決定顯示捨棄確認或直接關閉
    private let onCancel: (() -> Void)?

    /// 捨棄確認選擇捨棄後的處理，由呼叫端決定；`nil` 時由 `View` 直接關閉
    private let onDiscardChanges: (() -> Void)?

    /// 提交付款方式時執行，名稱與旗標由呼叫端的 `State` 讀取
    private let onSubmit: () -> Void

    /// 提交按鈕的文字
    private let submitTitle: String

    /// Sheet 的標題 (顯示在 navigation bar)
    private let title: String

    // MARK: - Init

    /// 建立付款方式 sheet，草稿與焦點由呼叫端提供
    ///
    /// - Parameters:
    ///   - title: 導覽標題
    ///   - message: 表單上方說明；空字串時不顯示
    ///   - namePlaceholder: 名稱 `TextField` placeholder
    ///   - submitTitle: 提交按鈕文字 (新增用「新增」、編輯用「儲存」)
    ///   - draftName: 名稱輸入草稿
    ///   - isDraftCardless: 是否標記為無卡類付款方式
    ///   - isDraftBankTransfer: 是否標記為銀行匯款類付款方式
    ///   - isDraftCashOnDelivery: 是否標記為貨到付款類付款方式
    ///   - isNameFieldFocused: 名稱欄位是否持有焦點
    ///   - isDiscardConfirmationPresented: 是否顯示捨棄確認彈窗
    ///   - isDirty: 草稿是否有未儲存的變更
    ///   - canSubmit: 草稿去除空白後是否可以送出
    ///   - onCancel: 取消鍵的處理；`nil` 時由 `View` 依未儲存變更決定顯示捨棄確認或直接關閉
    ///   - onDiscardChanges: 捨棄確認選擇捨棄後的處理；`nil` 時由 `View` 直接關閉
    ///   - isEmbedded: 是否嵌入既有導覽堆疊，預設為 `false` 時以獨立 sheet 呈現
    ///   - onSubmit: 提交付款方式時執行
    init(
        title: String,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        draftName: Binding<String>,
        isDraftCardless: Binding<Bool>,
        isDraftBankTransfer: Binding<Bool>,
        isDraftCashOnDelivery: Binding<Bool>,
        isNameFieldFocused: Binding<Bool>,
        isDiscardConfirmationPresented: Binding<Bool>,
        isDirty: Bool,
        canSubmit: Bool,
        onCancel: (() -> Void)? = nil,
        onDiscardChanges: (() -> Void)? = nil,
        isEmbedded: Bool = false,
        onSubmit: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self._draftName = draftName
        self._isDraftCardless = isDraftCardless
        self._isDraftBankTransfer = isDraftBankTransfer
        self._isDraftCashOnDelivery = isDraftCashOnDelivery
        self._isNameFieldFocused = isNameFieldFocused
        self._isDiscardConfirmationPresented = isDiscardConfirmationPresented
        self.isDirty = isDirty
        self.canSubmit = canSubmit
        self.onCancel = onCancel
        self.onDiscardChanges = onDiscardChanges
        self.isEmbedded = isEmbedded
        self.onSubmit = onSubmit
    }

    /// 以固定草稿建立付款方式 sheet，供預覽與快照使用；輸入與提交不會保存或送出
    ///
    /// - Parameters:
    ///   - title: 導覽標題
    ///   - message: 表單上方說明；空字串時不顯示
    ///   - namePlaceholder: 名稱 `TextField` placeholder
    ///   - submitTitle: 提交按鈕文字
    ///   - initialName: 固定的名稱草稿，空字串時提交按鈕停用
    ///   - isInitialCardless: 固定的無卡旗標
    ///   - isInitialBankTransfer: 固定的銀行匯款旗標
    ///   - isInitialCashOnDelivery: 固定的貨到付款旗標
    ///   - isEmbedded: 是否嵌入既有導覽堆疊，預設為 `false`
    ///   - onSubmit: 提交時收到固定草稿與旗標的回呼
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
        self.init(
            title: title,
            message: message,
            namePlaceholder: namePlaceholder,
            submitTitle: submitTitle,
            draftName: .constant(initialName),
            isDraftCardless: .constant(isInitialCardless),
            isDraftBankTransfer: .constant(isInitialBankTransfer),
            isDraftCashOnDelivery: .constant(isInitialCashOnDelivery),
            isNameFieldFocused: .constant(false),
            isDiscardConfirmationPresented: .constant(false),
            isDirty: false,
            canSubmit: !initialName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isEmbedded: isEmbedded,
            onSubmit: {
                onSubmit(
                    initialName,
                    isInitialCardless,
                    isInitialBankTransfer,
                    isInitialCashOnDelivery
                )
            }
        )
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
                    discardChanges()
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
                    .focused($nameFieldFocused)
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
        .blReadableScrollContent(.form)
        .formStyle(.grouped)
        .accessibilityIdentifier(BLAccessibilityID.LookupManagement.paymentMethodEditorRoot)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            // 重新呈現時依草稿還原焦點，與 `SwiftNavigation` 的 `bind` 語意相同
            nameFieldFocused = isNameFieldFocused
        }
        .onChange(of: nameFieldFocused) { _, newValue in
            guard newValue != isNameFieldFocused else {
                return
            }
            isNameFieldFocused = newValue
        }
        .onChange(of: isNameFieldFocused) { _, newValue in
            guard newValue != nameFieldFocused else {
                return
            }
            nameFieldFocused = newValue
        }
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
                .disabled(!canSubmit)
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
}

// MARK: - Private Method

private extension PaymentMethodEditorSheet {

    /// 捨棄變更：有外部處理時交給呼叫端，否則直接關閉表單
    func discardChanges() {
        if let onDiscardChanges {
            onDiscardChanges()
        } else {
            dismiss()
        }
    }

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

    /// 通過可送出檢查後提交付款方式並關閉表單
    func submitDraft() {
        guard canSubmit else {
            return
        }
        onSubmit()
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
        initialName: "銀行匯款",
        isInitialBankTransfer: true,
        onSubmit: { _, _, _, _ in
        }
    )
}
