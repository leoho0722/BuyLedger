//
//  OptionPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 通用的單選字串選項 sheet
struct OptionPickerSheet: View {

    // MARK: - Properties

    /// sheet 提供的 dismiss action；嵌入時返回，sheet 時關閉
    @Environment(\.dismiss) private var dismiss

    /// 新增 alert 的名稱輸入草稿
    @State private var draft = ""

    /// 是否顯示「新增」alert (商品類別等沒有 `isCardless` 需求的入口)
    @State private var isAddAlertPresented = false

    /// 是否顯示「新增付款方式」導覽目的地
    @State private var isAddPaymentMethodPresented = false

    /// 搜尋輸入
    @State private var searchText = ""

    /// Sheet 的標題 (顯示在 navigation bar)
    let title: String

    /// 是否允許在 sheet 內新增項目 (toolbar 出現「新增」按鈕)
    let canAdd: Bool

    /// 是否啟用搜尋欄
    let isSearchEnabled: Bool

    /// 「新增」按鈕顯示的標題；`allowsAdd` 為 `false` 時忽略
    let addButtonTitle: String

    /// 沒有任何選項時 ``ContentUnavailableView`` 的標題
    let emptyTitle: String

    /// 沒有任何選項時 ``ContentUnavailableView`` 的描述
    let emptyDescription: String

    /// 「新增」alert 的標題；`allowsAdd` 為 `false` 時忽略
    let addAlertTitle: String

    /// 「新增」alert 內 TextField 的 placeholder；`allowsAdd` 為 `false` 時忽略
    let addFieldPlaceholder: String

    /// 「新增」alert 的說明訊息；`allowsAdd` 為 `false` 時忽略
    let addAlertMessage: String

    /// 目前可選的選項清單
    let options: [String]

    /// 目前已選中的選項；用來在列表中顯示勾選
    let selected: String

    /// 顯示用名稱轉換；`nil` 時直接顯示 `option`
    /// - Returns: 選項的顯示文字
    let displayName: (@Sendable (String) -> String)?

    /// 搜尋時納入比對的補充文字；用於幣別 sheet 把在地化名稱也納入搜尋
    /// - Returns: 選項的搜尋補充文字
    let searchKeywords: (@Sendable (String) -> String)?

    /// 使用者選擇既有選項時的回呼
    let onSelect: (String) -> Void

    /// 使用者確認新增選項時的回呼
    let onAdd: (String) -> Void

    /// 付款方式新增回呼；提供時改用付款方式表單
    let onAddPaymentMethod: PaymentMethodEditorSheet.SubmitAction?

    /// 可選的「清除目前選擇」row 設定
    let clearOption: ClearOption?

    /// 可選的多選模式設定
    let multiSelection: MultiSelection?

    /// 是否嵌入既有導覽堆疊；預設 false 為獨立 sheet
    let isEmbedded: Bool

    // MARK: - Init

    /// 建立選項選擇 sheet
    /// - Parameters:
    ///   - title: navigation bar 顯示的標題
    ///   - allowsAdd: 是否顯示新增。預設 `true`
    ///   - searchable: 是否啟用搜尋欄。預設 `false`
    ///   - addButtonTitle: 新增按鈕標題
    ///   - emptyTitle: 沒有符合選項時顯示的標題
    ///   - emptyDescription: 沒有符合選項時顯示的說明
    ///   - addAlertTitle: 新增項目 alert 的標題
    ///   - addFieldPlaceholder: 新增項目輸入欄的 placeholder
    ///   - addAlertMessage: 新增 alert 提示訊息
    ///   - options: 可供選擇的原始值清單
    ///   - selected: 目前選項；clear 時以空字串表示未選
    ///   - displayName: 自訂顯示名稱；`nil` 直接顯示原值
    ///   - searchKeywords: 自訂搜尋補充文字；`nil` 僅以原值比對
    ///   - onSelect: 點選既有選項時的回呼
    ///   - onAdd: 新增項目時的回呼；停用新增或使用付款方式表單時不會呼叫
    ///   - onAddPaymentMethod: 提供時，新增按鈕改用付款方式表單
    ///   - clearOption: 清除選擇的 row；nil 時不顯示
    ///   - multiSelection: 多選設定；nil 表示單選
    init(
        title: String,
        allowsAdd canAdd: Bool = true,
        searchable isSearchEnabled: Bool = false,
        addButtonTitle: String = "",
        emptyTitle: String,
        emptyDescription: String,
        addAlertTitle: String = "",
        addFieldPlaceholder: String = "",
        addAlertMessage: String = "",
        options: [String],
        selected: String = "",
        displayName: (@Sendable (String) -> String)? = nil,
        searchKeywords: (@Sendable (String) -> String)? = nil,
        onSelect: @escaping (String) -> Void = { _ in },
        onAdd: @escaping (String) -> Void = { _ in },
        onAddPaymentMethod: PaymentMethodEditorSheet.SubmitAction? = nil,
        clearOption: ClearOption? = nil,
        multiSelection: MultiSelection? = nil,
        isEmbedded: Bool = false
    ) {
        self.title = title
        self.canAdd = canAdd
        self.isSearchEnabled = isSearchEnabled
        self.addButtonTitle = addButtonTitle
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.addAlertTitle = addAlertTitle
        self.addFieldPlaceholder = addFieldPlaceholder
        self.addAlertMessage = addAlertMessage
        self.options = options
        self.selected = selected
        self.displayName = displayName
        self.searchKeywords = searchKeywords
        self.onSelect = onSelect
        self.onAdd = onAdd
        self.onAddPaymentMethod = onAddPaymentMethod
        self.clearOption = clearOption
        self.multiSelection = multiSelection
        self.isEmbedded = isEmbedded
    }

    // MARK: - Body

    /// 選項選擇的內容
    var body: some View {
        if isEmbedded {
            configuredContent
        } else {
            NavigationStack {
                configuredContent
            }
        }
    }
}

// MARK: - Private Views

private extension OptionPickerSheet {

    /// 建立標題、toolbar、搜尋與新增內容
    @ViewBuilder
    var configuredContent: some View {
        List {
            if canAdd {
                Section {
                    Button {
                        triggerAdd()
                    } label: {
                        Label(LocalizedStringKey(addButtonTitle), systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addButton)
                }
            }

            OptionPickerList(
                options: filteredOptions,
                selected: selected,
                displayName: displayName,
                clearOption: clearOption.map { option in
                    ClearOption(
                        title: option.title,
                        onClear: {
                            option.onClear()
                            dismiss()
                        }
                    )
                },
                multiSelection: multiSelection,
                onSelect: selectOption,
                emptyTitle: emptyTitle,
                emptyDescription: emptyDescription
            )
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.root)
        .navigationTitle(Text(LocalizedStringKey(title)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if multiSelection != nil {
                // 多選時立即套用，完成鍵結束選取
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .accessibilityIdentifier(BLAccessibilityID.OptionPicker.doneButton)
                }

                // 獨立 sheet 也要提供取消出口
                // 嵌入 (push) 時由宿主 Back 承接，不再加重複的取消
                if !isEmbedded {
                    cancelToolbarItem()
                }
            } else if !isEmbedded {
                // 只有獨立 sheet 顯示取消鍵，push 頁面使用 Back
                cancelToolbarItem()
            }
        }
        .modifier(BLSearchableModifier(text: $searchText, isEnabled: isSearchEnabled))
        .scrollDismissesKeyboard(.interactively)
        .alert(LocalizedStringKey(addAlertTitle), isPresented: $isAddAlertPresented) {
            TextField(LocalizedStringKey(addFieldPlaceholder), text: $draft)
                .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertNameField)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("新增") {
                addDraft()
            }
            .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertConfirmButton)
            .disabled(
                draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )

            Button("取消", role: .cancel) {
                draft = ""
            }
            .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertCancelButton)
        } message: {
            Text(LocalizedStringKey(addAlertMessage))
        }
        .navigationDestination(isPresented: $isAddPaymentMethodPresented) {
            // 付款方式以 push 呈現；其他情境維持原本導覽
            PaymentMethodEditorSheet(
                title: addAlertTitle,
                message: addAlertMessage,
                namePlaceholder: addFieldPlaceholder,
                submitTitle: "新增",
                isEmbedded: true,
                onSubmit: { name, isCardless, isBankTransfer, isCashOnDelivery in
                    onAddPaymentMethod?(
                        name,
                        isCardless,
                        isBankTransfer,
                        isCashOnDelivery
                    )
                    // 提交後回到選項頁
                    dismiss()
                }
            )
        }
    }

    /// 獨立 sheet 使用的取消 toolbar item
    @ToolbarContentBuilder
    func cancelToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text("取消"))
        }
    }
}

// MARK: - Nested Types

extension OptionPickerSheet {

    /// 「清除目前選擇」row 的設定
    struct ClearOption {

        // MARK: - Properties

        /// Clear row 的 label 文字 (例如「全部」)
        let title: String

        /// 使用者點擊清除選項列時觸發的回呼；執行後 sheet 會自動 dismiss
        let onClear: () -> Void
    }

    /// 多選模式的設定
    struct MultiSelection {

        // MARK: - Properties

        /// 目前已選取的選項集合；驅動每一列的勾選指示
        let selections: Set<String>

        /// 點擊選項時的回呼
        let onToggle: (String) -> Void
    }
}

// MARK: - Computed Properties

private extension OptionPickerSheet {

    /// 依當前搜尋字串過濾後的選項清單
    var filteredOptions: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return options
        }

        return options.filter { option in
            let displayText = displayName?(option) ?? option
            if displayText.localizedStandardContains(trimmed) {
                return true
            }
            if let keywords = searchKeywords?(option), keywords.localizedStandardContains(trimmed) {
                return true
            }
            return option.localizedStandardContains(trimmed)
        }
    }
}

// MARK: - Private Method

private extension OptionPickerSheet {

    /// 以目前草稿新增選項；空白內容不送出
    func addDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        onAdd(trimmed)
        draft = ""
        dismiss()
    }

    /// 選取一筆選項並依模式更新或關閉
    /// - Parameter option: 被點擊的選項
    func selectOption(_ option: String) {
        if let multiSelection {
            multiSelection.onToggle(option)
        } else {
            onSelect(option)
            dismiss()
        }
    }

    /// 新增按鈕行為；付款方式開導覽表單，其餘開 alert
    func triggerAdd() {
        if onAddPaymentMethod != nil {
            // 付款方式使用導覽目的地，避免 alert 遺失旗標開關
            isAddPaymentMethodPresented = true
        } else {
            draft = ""
            isAddAlertPresented = true
        }
    }
}

// MARK: - Preview

#Preview("商品類別 (可新增)") {
    OptionPickerSheet(
        title: "選擇商品類別",
        allowsAdd: true,
        addButtonTitle: "新增類別",
        emptyTitle: "尚無類別",
        emptyDescription: "透過上方「新增類別」加入第一個類別。",
        addAlertTitle: "新增商品類別",
        addFieldPlaceholder: "類別名稱",
        addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
        options: ["3C", "美妝", "精品", "食品"],
        selected: "美妝",
        onSelect: { _ in }
    )
}

#Preview("幣別 (不可新增、可搜尋)") {
    OptionPickerSheet(
        title: "選擇幣別",
        allowsAdd: false,
        searchable: true,
        emptyTitle: "尚無幣別",
        emptyDescription: "需要網路連線載入幣別清單，請稍後再試。",
        options: ["TWD", "USD", "JPY", "KRW", "EUR", "CNY"],
        selected: "TWD",
        displayName: { code in
            CurrencyDisplayName.text(code: code, language: .traditionalChinese)
        },
        onSelect: { _ in }
    )
}

#Preview("類別篩選 (含清除選項、未選任何類別)") {
    OptionPickerSheet(
        title: "選擇商品類別",
        allowsAdd: false,
        searchable: true,
        emptyTitle: "沒有符合的類別",
        emptyDescription: "試試其他搜尋關鍵字。",
        options: ["3C", "美妝", "精品", "食品", "保健", "零食", "書籍"],
        selected: "",
        onSelect: { _ in },
        clearOption: .init(title: "全部", onClear: {})
    )
}

#Preview("類別篩選 (含清除選項、已選美妝)") {
    OptionPickerSheet(
        title: "選擇商品類別",
        allowsAdd: false,
        searchable: true,
        emptyTitle: "沒有符合的類別",
        emptyDescription: "試試其他搜尋關鍵字。",
        options: ["3C", "美妝", "精品", "食品", "保健", "零食", "書籍"],
        selected: "美妝",
        onSelect: { _ in },
        clearOption: .init(title: "全部", onClear: {})
    )
}

#Preview("商品類別 (多選模式)") {
    @Previewable @State var selections: Set<String> = ["美妝", "服飾"]

    OptionPickerSheet(
        title: "選擇商品類別",
        allowsAdd: true,
        addButtonTitle: "新增類別",
        emptyTitle: "尚無類別",
        emptyDescription: "透過上方「新增類別」加入第一個類別。",
        addAlertTitle: "新增商品類別",
        addFieldPlaceholder: "類別名稱",
        addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
        options: ["3C", "美妝", "服飾", "精品", "食品"],
        multiSelection: .init(
            selections: selections,
            onToggle: { option in
                if selections.contains(option) {
                    selections.remove(option)
                } else {
                    selections.insert(option)
                }
            }
        )
    )
}

#Preview("空狀態") {
    OptionPickerSheet(
        title: "選擇商品類別",
        allowsAdd: false,
        emptyTitle: "尚無商品類別",
        emptyDescription: "尚未建立任何商品類別。",
        options: [],
        onSelect: { _ in }
    )
}

#Preview("付款方式新增") {
    OptionPickerSheet(
        title: "選擇付款方式",
        addButtonTitle: "新增付款方式",
        emptyTitle: "尚無付款方式",
        emptyDescription: "透過上方「新增付款方式」建立第一個付款方式。",
        addAlertTitle: "新增付款方式",
        addFieldPlaceholder: "付款方式名稱",
        addAlertMessage: "輸入新的付款方式名稱。",
        options: ["現金", "信用卡"],
        selected: "現金",
        onSelect: { _ in },
        onAddPaymentMethod: { _, _, _, _ in }
    )
}
