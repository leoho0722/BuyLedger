//
//  PaymentMethodEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 新增或編輯付款方式時的 sheet 表單
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
    
    /// 是否嵌入既有導覽堆疊；預設 false 為獨立 sheet
    let isEmbedded: Bool
    
    /// 儲存時回傳付款方式名稱與三個旗標
    let onSubmit:
    (
        _ name: String,
        _ isCardless: Bool,
        _ isBankTransfer: Bool,
        _ isCashOnDelivery: Bool
    ) ->
    Void
    
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
    
    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @State private var showsDiscardConfirmation = false
    
    /// 名稱欄位的鍵盤焦點
    @FocusState private var isNameFieldFocused: Bool
    
    /// 表單初始值，用於判斷 isDirty
    private let initialName: String
    private let initialIsCardless: Bool
    private let initialIsBankTransfer: Bool
    private let initialIsCashOnDelivery: Bool
    
    // MARK: - Init
    
    /// 建立付款方式 sheet
    /// - Parameters:
    ///   - title: 導覽標題
    ///   - message: 表單上方說明；空字串時不顯示
    ///   - namePlaceholder: 名稱 TextField placeholder
    ///   - submitTitle: 提交按鈕文字 (新增用「新增」、編輯用「儲存」)
    ///   - initialName: 名稱初始值；編輯時帶入原名稱，新增時留空
    ///   - initialIsCardless: 無卡旗標初始值；編輯時帶入原狀態
    ///   - initialIsBankTransfer: 銀行匯款旗標初始值；編輯時帶入原狀態
    ///   - initialIsCashOnDelivery: 貨到付款旗標初始值；編輯時帶入原狀態
    ///   - onSubmit: 確認時回傳名稱與付款方式旗標
    init(
        title: String,
        message: String,
        namePlaceholder: String,
        submitTitle: String,
        initialName: String = "",
        initialIsCardless: Bool = false,
        initialIsBankTransfer: Bool = false,
        initialIsCashOnDelivery: Bool = false,
        isEmbedded: Bool = false,
        onSubmit:
        @escaping (
            _ name: String,
            _ isCardless: Bool,
            _ isBankTransfer: Bool,
            _ isCashOnDelivery: Bool
        ) -> Void
    ) {
        self.title = title
        self.message = message
        self.namePlaceholder = namePlaceholder
        self.submitTitle = submitTitle
        self.isEmbedded = isEmbedded
        self.onSubmit = onSubmit
        self._draftName = State(initialValue: initialName)
        self._draftIsCardless = State(initialValue: initialIsCardless)
        self._draftIsBankTransfer = State(initialValue: initialIsBankTransfer)
        self._draftIsCashOnDelivery = State(initialValue: initialIsCashOnDelivery)
        self.initialName = initialName
        self.initialIsCardless = initialIsCardless
        self.initialIsBankTransfer = initialIsBankTransfer
        self.initialIsCashOnDelivery = initialIsCashOnDelivery
    }
    
    // MARK: - View Body
    
    /// 新增／編輯付款方式的內容
    var body: some View {
        if isEmbedded {
            formContent
        } else {
            NavigationStack {
                formContent
            }
            // 提供半屏與全屏兩種高度。
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
            .interactiveDismissDisabled(isDirty)
            .alert("捨棄變更", isPresented: $showsDiscardConfirmation) {
                Button("捨棄變更", role: .destructive) {
                    dismiss()
                }
                Button("繼續編輯", role: .cancel) {}
            } message: {
                Text("這個付款方式有尚未儲存的變更，離開後將不會保留。")
            }
        }
    }
}

// MARK: - ViewBuilder

private extension PaymentMethodEditorSheet {
    
    /// 付款方式表單內容，依 isEmbedded 決定是否包裝導覽
    @ViewBuilder
    var formContent: some View {
        Form {
            Section {
                TextField(LocalizedStringKey(namePlaceholder), text: $draftName)
                    .focused($isNameFieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("付款方式名稱")
            } footer: {
                if !message.isEmpty {
                    Text(LocalizedStringKey(message))
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
            }
            
            Section {
                Toggle(isOn: $draftIsCardless) {
                    Text("標記為「無卡」付款方式")
                }
            } footer: {
                Text("啟用後，使用此付款方式的訂單在「收款金額」區段會出現「無卡折抵金額」與「無卡補款金額」兩個欄位，並計入總收款公式。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
            
            Section {
                Toggle(isOn: $draftIsBankTransfer) {
                    Text("標記為「銀行匯款」付款方式")
                }
            } footer: {
                Text("啟用後，使用此付款方式的訂單在編輯時會出現「對帳狀態」欄位，供你在款項入帳後標記對帳結果。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
            
            Section {
                Toggle(isOn: $draftIsCashOnDelivery) {
                    Text("標記為「貨到付款」付款方式")
                }
            } footer: {
                Text("啟用後，使用此付款方式的訂單因收款金額已含預估運費，獲利會自動扣除國內、國際與外國國內三種運費。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(LocalizedStringKey(title)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEmbedded {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        // 有未儲存變更時先彈窗確認，避免取消靜默遺失草稿
                        if isDirty {
                            showsDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("取消"))
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        return
                    }
                    onSubmit(trimmed, draftIsCardless, draftIsBankTransfer, draftIsCashOnDelivery)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(Text(LocalizedStringKey(submitTitle)))
                .keyboardShortcut(.defaultAction)
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

// MARK: - Private Types

/// 付款方式表單用於判斷未儲存變更的值快照
private struct PaymentMethodEditorSnapshot: Equatable {

    // MARK: - Data Properties

    /// 付款方式名稱
    let name: String

    /// 是否屬於無卡類付款方式
    let isCardless: Bool

    /// 是否屬於銀行匯款類付款方式
    let isBankTransfer: Bool

    /// 是否屬於貨到付款類付款方式
    let isCashOnDelivery: Bool
}

// MARK: - Private Method

private extension PaymentMethodEditorSheet {
    
    /// 表單目前輸入值的快照
    /// - Returns: 草稿欄位組成的表單快照
    var draftSnapshot: PaymentMethodEditorSnapshot {
        PaymentMethodEditorSnapshot(
            name: draftName,
            isCardless: draftIsCardless,
            isBankTransfer: draftIsBankTransfer,
            isCashOnDelivery: draftIsCashOnDelivery
        )
    }

    /// 表單開啟時初始值的快照
    /// - Returns: 初始欄位組成的表單快照
    var initialSnapshot: PaymentMethodEditorSnapshot {
        PaymentMethodEditorSnapshot(
            name: initialName,
            isCardless: initialIsCardless,
            isBankTransfer: initialIsBankTransfer,
            isCashOnDelivery: initialIsCashOnDelivery
        )
    }

    /// 草稿是否已變更
    /// - Returns: 草稿與初始快照不相等時為 `true`
    var isDirty: Bool {
        draftSnapshot != initialSnapshot
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
