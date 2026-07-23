//
//  PaymentMethodEditorSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 新增或編輯付款方式時的 sheet 表單
///
/// SwiftUI 的 `.alert` actions builder 只支援 `Button`／`TextField`，無法塞入 `Toggle`；而「是否為無卡類／銀行匯款類／貨到付款類」必須在當下決定
///
/// 所以付款方式的新增與編輯流程改採獨立 sheet，將名稱輸入與三個旗標切換放在同一張表單，確認後一次帶出 `(name, isCardless, isBankTransfer, isCashOnDelivery)` 給 caller
///
/// 編輯既有付款方式時，caller 透過 `initialName` / `initialIsCardless` / `initialIsBankTransfer` / `initialIsCashOnDelivery` 帶入原有資料，並把 `title` 設為「編輯付款方式」、`submitTitle` 設為「儲存」
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

    /// 是否為嵌入 (push) 呈現：`true` 時不自帶 `NavigationStack`、不放取消鍵與 sheet 專屬修飾 (detents／grabber／未儲存確認)，由宿主導覽堆疊的 Back 返回；`false` (預設) 維持既有單層 sheet 呈現。用於訂單編輯的付款方式選擇器內以 push 新增付款方式，消除三層疊 sheet
    let isEmbedded: Bool

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

    /// 是否顯示「捨棄變更／繼續編輯」確認彈窗
    @State private var showsDiscardConfirmation = false

    /// 名稱欄位的鍵盤焦點
    ///
    /// 不綁 store、以閉包與 caller 溝通的可重用元件，焦點屬元件內部狀態 (專案既有例外)
    @FocusState private var isNameFieldFocused: Bool

    /// 表單開啟時的初始值快照；供 ``isDirty`` 判斷未儲存變更
    private let initialName: String
    private let initialIsCardless: Bool
    private let initialIsBankTransfer: Bool
    private let initialIsCashOnDelivery: Bool

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
        isEmbedded: Bool = false,
        onSubmit: @escaping (_ name: String, _ isCardless: Bool, _ isBankTransfer: Bool, _ isCashOnDelivery: Bool) -> Void
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
    ///
    /// 單層 sheet 呈現 (``isEmbedded`` == `false`) 時自帶 `NavigationStack` 與 sheet 專屬修飾 (detents／grabber／未儲存確認)；嵌入 (push) 時直接回傳表單，由宿主導覽堆疊提供標題列與 Back
    var body: some View {
        if isEmbedded {
            formContent
        } else {
            NavigationStack {
                formContent
            }
            // 表單為 name + 無卡／銀行匯款／貨到付款三個旗標段；medium (約半屏) 仍維持「貼上來的小卡」的
            // 輕量感、讓使用者看見背後的主檔列表，但同時提供 large 供需要看完整三段說明時展開
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
            .interactiveDismissDisabled(isDirty)
            .alert("捨棄變更", isPresented: $showsDiscardConfirmation) {
                Button("捨棄變更", role: .destructive) {
                    dismiss()
                }
                Button("繼續編輯", role: .cancel) { }
            } message: {
                Text("這個付款方式有尚未儲存的變更，離開後將不會保留。")
            }
        }
    }
}

// MARK: - ViewBuilder

private extension PaymentMethodEditorSheet {

    /// 付款方式表單內容 (含標題列、旗標段與 toolbar)；由 ``body`` 依 ``isEmbedded`` 決定是否再包 `NavigationStack` 與 sheet 專屬修飾
    ///
    /// 嵌入 (push) 時不放取消鍵，由宿主導覽堆疊的 Back 返回；提交鍵始終保留
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

// MARK: - Private Method

private extension PaymentMethodEditorSheet {

    /// 草稿是否已被修改：任一欄位與開啟時的初始值不同即為 `true`；供未儲存變更下滑關閉確認判斷
    var isDirty: Bool {
        draftName != initialName
            || draftIsCardless != initialIsCardless
            || draftIsBankTransfer != initialIsBankTransfer
            || draftIsCashOnDelivery != initialIsCashOnDelivery
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
