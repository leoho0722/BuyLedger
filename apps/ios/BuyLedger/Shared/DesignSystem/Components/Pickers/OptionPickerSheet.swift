//
//  OptionPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 依選取與新增模式呈現字串選項的選擇器
struct OptionPickerSheet: View {

    // MARK: - Properties

    /// 用於關閉選擇器的 `dismiss` action
    ///
    /// - Note: 嵌入時返回上一頁，獨立 sheet 時關閉選擇器
    @Environment(\.dismiss) private var dismiss

    /// 是否推入付款方式編輯器
    @State private var isAddPaymentMethodPresented = false

    /// 搜尋欄目前的輸入
    @State private var searchText = ""

    /// 可用的新增入口
    ///
    /// - Note: `nil` 時隱藏新增按鈕
    private let addition: Addition?

    /// 沒有符合選項時顯示的文案
    private let emptyState: EmptyState

    /// 是否沿用宿主的導覽堆疊
    private let isEmbedded: Bool

    /// 是否顯示搜尋欄
    private let isSearchEnabled: Bool

    /// 自訂顯示名稱與搜尋補充文字
    ///
    /// - Note: `nil` 時使用原值
    private let labeling: Labeling?

    /// 尚未套用搜尋的完整選項清單
    private let options: [String]

    /// 單選或多選的目前值與操作回呼
    private let selection: Selection

    /// 導覽列顯示的標題
    private let title: LocalizedStringResource

    // MARK: - Init

    /// 建立依選取與新增模式配置的選擇器
    ///
    /// - Parameters:
    ///   - title: 導覽列顯示的標題
    ///   - options: 可供選取的原始值清單
    ///   - selection: 單選或多選的目前值與操作回呼
    ///   - addition: 新增入口；`nil` 時不允許新增
    ///   - emptyState: 沒有符合選項時顯示的文案
    ///   - labeling: 自訂顯示名稱與搜尋補充文字
    ///   - isSearchEnabled: 是否顯示搜尋欄，預設 `false`
    ///   - isEmbedded: 是否嵌入既有導覽堆疊，預設 `false`
    init(
        title: LocalizedStringResource,
        options: [String],
        selection: Selection,
        addition: Addition? = nil,
        emptyState: EmptyState,
        labeling: Labeling? = nil,
        isSearchEnabled: Bool = false,
        isEmbedded: Bool = false
    ) {
        self.title = title
        self.options = options
        self.selection = selection
        self.addition = addition
        self.emptyState = emptyState
        self.labeling = labeling
        self.isSearchEnabled = isSearchEnabled
        self.isEmbedded = isEmbedded
    }

    // MARK: - Body

    /// 依是否嵌入決定導覽堆疊的選項內容畫面
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

    /// 搜尋欄與導覽目的地組成的畫面內容
    var configuredContent: some View {
        searchableContent
            .navigationDestination(isPresented: $isAddPaymentMethodPresented) {
                if case .paymentMethod(let prompt, let onSubmit) = addition {
                    // 編輯器送出後自己會退回選擇器，這裡不能再包一層呼叫 `dismiss()`，否則會關掉宿主 sheet
                    EmbeddedPaymentMethodEditor(prompt: prompt, onSubmit: onSubmit)
                }
            }
    }

    /// 依搜尋開關決定是否套上共用搜尋欄的畫面內容
    ///
    /// - Note: 停用時不建立搜尋狀態
    @ViewBuilder
    var searchableContent: some View {
        if isSearchEnabled {
            listContent
                .blSearchable(text: $searchText, prompt: Text("common.action.action.search"))
        } else {
            listContent
        }
    }

    /// 清單內容：新增入口、選項與工具列
    var listContent: some View {
        List {
            if let addition {
                OptionPickerAddSection(addition: addition) {
                    isAddPaymentMethodPresented = true
                }
            }

            OptionPickerList(
                displayName: labeling?.displayName,
                emptyState: emptyState,
                options: filteredOptions,
                selection: selection
            )
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.root)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .multiple = selection {
                // 多選時立即套用，完成鍵結束選取
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.action.button.done") {
                        dismiss()
                    }
                    .accessibilityIdentifier(BLAccessibilityID.OptionPicker.doneButton)
                }
            }

            // 嵌入時由宿主的返回鍵承接，獨立 sheet 才提供取消
            if !isEmbedded {
                cancelToolbarItem()
            }
        }
    }

    /// 建立獨立 sheet 使用的取消按鈕
    ///
    /// - Returns: 關閉目前選擇器的工具列項目
    @ToolbarContentBuilder
    func cancelToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text("common.action.cancel"))
        }
    }
}

// MARK: - Nested Types

private extension OptionPickerSheet {

    /// 嵌入選擇器推入的付款方式編輯器，草稿隨每次推入重新建立
    struct EmbeddedPaymentMethodEditor: View {

        /// 名稱輸入草稿
        @State private var draftName = ""

        /// 是否顯示捨棄確認彈窗
        ///
        /// - Note: 嵌入時不呈現捨棄確認，此狀態只為滿足編輯器的介面
        @State private var isDiscardConfirmationPresented = false

        /// 是否標記為銀行匯款類付款方式
        @State private var isDraftBankTransfer = false

        /// 是否標記為無卡類付款方式
        @State private var isDraftCardless = false

        /// 是否標記為貨到付款類付款方式
        @State private var isDraftCashOnDelivery = false

        /// 名稱欄位是否持有焦點
        @State private var isNameFieldFocused = false

        /// 編輯器送出名稱與付款方式旗標的回呼
        let onSubmit: PaymentMethodEditorSheet.SubmitAction

        /// 新增按鈕與編輯器的文案
        let prompt: AddPrompt

        /// 建立嵌入編輯器，草稿由本元件保存
        ///
        /// - Parameters:
        ///   - prompt: 新增按鈕與編輯器的文案
        ///   - onSubmit: 編輯器送出名稱與付款方式旗標的回呼
        init(prompt: AddPrompt, onSubmit: @escaping PaymentMethodEditorSheet.SubmitAction) {
            self.prompt = prompt
            self.onSubmit = onSubmit
        }

        /// 本地草稿與嵌入式編輯器組成的畫面內容
        ///
        /// - Note: 送出時回傳修剪後的名稱與旗標
        var body: some View {
            PaymentMethodEditorSheet(
                title: prompt.title,
                message: prompt.message,
                namePlaceholder: prompt.placeholder,
                submitTitle: "orders.list.button.add",
                draftName: $draftName,
                isDraftCardless: $isDraftCardless,
                isDraftBankTransfer: $isDraftBankTransfer,
                isDraftCashOnDelivery: $isDraftCashOnDelivery,
                isNameFieldFocused: $isNameFieldFocused,
                isDiscardConfirmationPresented: $isDiscardConfirmationPresented,
                // 嵌入時不顯示取消鍵也不阻擋下滑，未儲存變更不影響畫面
                isDirty: false,
                canSubmit: !trimmedName.isEmpty,
                isEmbedded: true,
                onSubmit: {
                    onSubmit(
                        trimmedName,
                        isDraftCardless,
                        isDraftBankTransfer,
                        isDraftCashOnDelivery
                    )
                }
            )
        }

        /// 去除前後空白後的名稱
        private var trimmedName: String {
            draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - Private Method

private extension OptionPickerSheet {

    /// 搜尋輸入篩出的選項清單
    ///
    /// - Note: 比對顯示名稱、補充文字與原值
    var filteredOptions: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return options
        }

        return options.filter { option in
            let displayText = labeling?.displayName(option) ?? option
            if displayText.localizedStandardContains(trimmed) {
                return true
            }
            if let keywords = labeling?.searchKeywords(option),
               keywords.localizedStandardContains(trimmed) {
                return true
            }
            return option.localizedStandardContains(trimmed)
        }
    }
}

// MARK: - Preview

#Preview("商品類別 (可新增)") {
    OptionPickerSheet(
        title: "orders.list.label.category1",
        options: ["3C", "美妝", "精品", "食品"],
        selection: .single(selected: "美妝") { _ in
        },
        addition: .prompt(
            .init(
                buttonTitle: "orders.edit.label.addCategory",
                title: "orders.edit.label.addItemCategory",
                message: "orders.edit.message.enterNewProduct",
                placeholder: "orders.edit.label.categoryName"
            )
        ) { _ in
        },
        emptyState: .init(
            title: "orders.edit.label.categories",
            description: "orders.edit.message.addFirstCategory"
        )
    )
}

#Preview("幣別 (不可新增、可搜尋)") {
    OptionPickerSheet(
        title: "orders.edit.label.selectCurrency",
        options: ["TWD", "USD", "JPY", "KRW", "EUR", "CNY"],
        selection: .single(selected: "TWD") { _ in
        },
        emptyState: .init(
            title: "orders.edit.label.currenciesAvailable",
            description: "orders.edit.message.internetConnectionRequired"
        ),
        labeling: CurrencyDisplayName.optionLabeling(locale: AppLanguage.traditionalChinese.locale),
        isSearchEnabled: true
    )
}

#Preview("類別篩選 (含清除選項、未選任何類別)") {
    let emptyDescription = "試試其他搜尋關鍵字。"
    OptionPickerSheet(
        title: "orders.list.label.category1",
        options: ["3C", "美妝", "精品", "食品", "保健", "零食", "書籍"],
        selection: .single(
            selected: "",
            onSelect: { _ in
            },
            clear: .init(title: "common.action.label.all") {
            }
        ),
        emptyState: .init(
            title: "orders.list.label.matchingCategories",
            description: LocalizedStringResource(String.LocalizationValue(emptyDescription))
        ),
        isSearchEnabled: true
    )
}

#Preview("類別篩選 (含清除選項、已選美妝)") {
    let emptyDescription = "試試其他搜尋關鍵字。"
    OptionPickerSheet(
        title: "orders.list.label.category1",
        options: ["3C", "美妝", "精品", "食品", "保健", "零食", "書籍"],
        selection: .single(
            selected: "美妝",
            onSelect: { _ in
            },
            clear: .init(title: "common.action.label.all") {
            }
        ),
        emptyState: .init(
            title: "orders.list.label.matchingCategories",
            description: LocalizedStringResource(String.LocalizationValue(emptyDescription))
        ),
        isSearchEnabled: true
    )
}

#Preview("商品類別 (多選模式)") {
    @Previewable @State var selections: Set<String> = ["美妝", "服飾"]

    OptionPickerSheet(
        title: "orders.list.label.category1",
        options: ["3C", "美妝", "服飾", "精品", "食品"],
        selection: .multiple(selections: selections) { option in
            if selections.contains(option) {
                selections.remove(option)
            } else {
                selections.insert(option)
            }
        },
        addition: .prompt(
            .init(
                buttonTitle: "orders.edit.label.addCategory",
                title: "orders.edit.label.addItemCategory",
                message: "orders.edit.message.enterNewProduct",
                placeholder: "orders.edit.label.categoryName"
            )
        ) { _ in
        },
        emptyState: .init(
            title: "orders.edit.label.categories",
            description: "orders.edit.message.addFirstCategory"
        )
    )
}

#Preview("空狀態") {
    OptionPickerSheet(
        title: "orders.list.label.category1",
        options: [],
        selection: .single(selected: "") { _ in
        },
        emptyState: .init(
            title: "orders.edit.label.categories",
            description: "orders.edit.message.addFirstCategory"
        )
    )
}

#Preview("付款方式新增") {
    OptionPickerSheet(
        title: "orders.list.label.selectPaymentMethod",
        options: ["現金", "信用卡"],
        selection: .single(selected: "現金") { _ in
        },
        addition: .paymentMethod(
            .init(
                buttonTitle: "orders.edit.label.addPaymentMethod",
                title: "orders.edit.label.addPaymentMethod",
                message: "orders.edit.message.enterNewPayment",
                placeholder: "orders.detail.label.paymentMethodName"
            )
        ) { _, _, _, _ in
        },
        emptyState: .init(
            title: "orders.edit.label.paymentMethods",
            description: "orders.edit.message.addFirstPayment"
        )
    )
}
