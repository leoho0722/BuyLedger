//
//  OptionPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 通用的單選字串選項 sheet
struct OptionPickerSheet: View {
    
    // MARK: - View Properties
    
    /// Sheet 的標題 (顯示在 navigation bar)
    let title: String
    
    /// 是否允許在 sheet 內新增項目 (toolbar 出現「新增」按鈕)
    let allowsAdd: Bool
    
    /// 是否啟用搜尋欄
    let searchable: Bool
    
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
    
    /// 使用者選擇既有選項時的 callback
    let onSelect: (String) -> Void
    
    /// 使用者確認新增選項時的 callback
    let onAdd: (String) -> Void
    
    /// 付款方式新增 callback；提供時改用付款方式表單
    let onAddPaymentMethod: ((String, PaymentMethodFlags) -> Void)?
    
    /// 可選的「清除目前選擇」row 設定
    let clearOption: ClearOption?
    
    /// 可選的多選模式設定
    let multiSelection: MultiSelection?
    
    /// 是否嵌入既有導覽堆疊；預設 false 為獨立 sheet
    let isEmbedded: Bool
    
    /// sheet 提供的 dismiss action；嵌入時返回，sheet 時關閉
    @Environment(\.dismiss) private var dismiss
    
    /// 是否顯示「新增」alert (商品類別等沒有 `isCardless` 需求的入口)
    @State private var showsAddAlert = false
    
    /// 是否顯示「新增付款方式」sheet (含 `isCardless` / `isBankTransfer` 切換)
    @State private var showsAddPaymentMethodSheet = false
    
    /// 新增 alert 的名稱輸入草稿
    @State private var draft = ""
    
    /// 搜尋輸入
    @State private var searchText = ""
    
    // MARK: - Init
    
    /// 通用建構式；所有 sheet 參數一次傳齊
    /// - Parameters:
    ///   - title: navigation 標題
    ///   - allowsAdd: 是否顯示新增。預設 `true`
    ///   - searchable: 是否啟用搜尋欄。預設 `false`
    ///   - addButtonTitle: 新增按鈕標題
    ///   - emptyTitle: 空狀態標題
    ///   - emptyDescription: 空狀態描述
    ///   - addAlertTitle: 新增 alert 標題
    ///   - addFieldPlaceholder: 新增 TextField placeholder
    ///   - addAlertMessage: 新增 alert 提示訊息
    ///   - options: 可選項目
    ///   - selected: 目前選項；clear 時以空字串表示未選
    ///   - displayName: 自訂顯示名稱；`nil` 直接顯示原值
    ///   - searchKeywords: 自訂搜尋補充文字；`nil` 僅以原值比對
    ///   - onSelect: 點選 callback
    ///   - onAdd: 新增 callback；停用新增或使用付款方式表單時不會呼叫
    ///   - onAddPaymentMethod: 提供時，新增按鈕改用付款方式表單
    ///   - clearOption: 清除選擇的 row；nil 時不顯示
    ///   - multiSelection: 多選設定；nil 表示單選
    init(
        title: String,
        allowsAdd: Bool = true,
        searchable: Bool = false,
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
        onAddPaymentMethod: ((String, PaymentMethodFlags) -> Void)? = nil,
        clearOption: ClearOption? = nil,
        multiSelection: MultiSelection? = nil,
        isEmbedded: Bool = false
    ) {
        self.title = title
        self.allowsAdd = allowsAdd
        self.searchable = searchable
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
    
    // MARK: - View Body
    
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

// MARK: - Nested Types

extension OptionPickerSheet {
    
    /// 「清除目前選擇」row 的設定
    struct ClearOption {
        
        // MARK: - Data Properties
        
        /// Clear row 的 label 文字 (例如「全部」)
        let title: String
        
        /// 使用者點擊 clear row 時觸發的 callback；執行後 sheet 會自動 dismiss
        let onClear: () -> Void
    }
    
    /// 多選模式的設定
    struct MultiSelection {
        
        // MARK: - Data Properties
        
        /// 目前已選取的選項集合；驅動每一列的勾選指示
        let selections: Set<String>
        
        /// 點擊選項時的 callback
        let onToggle: (String) -> Void
    }
}

// MARK: - ViewBuilder

private extension OptionPickerSheet {
    
    /// 建立標題、toolbar、搜尋與新增內容
    @ViewBuilder
    var configuredContent: some View {
        content
            .navigationTitle(Text(LocalizedStringKey(title)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if multiSelection != nil {
                    // 多選時立即套用，完成鍵結束選取。
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            dismiss()
                        }
                        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.doneButton)
                    }
                    
                    // 獨立 sheet 也要提供取消出口
                    // 嵌入 (push) 時由宿主 Back 承接，不再加重複的取消
                    if !isEmbedded {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel(Text("取消"))
                        }
                    }
                } else if !isEmbedded {
                    // 只有獨立 sheet 顯示取消鍵，push 頁面使用 Back
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
            .modifier(SearchableModifier(text: $searchText, enabled: searchable))
            .scrollDismissesKeyboard(.interactively)
            .alert(LocalizedStringKey(addAlertTitle), isPresented: $showsAddAlert) {
                TextField(LocalizedStringKey(addFieldPlaceholder), text: $draft)
                    .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addAlertNameField)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button("新增") {
                    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onAdd(trimmed)
                        draft = ""
                        dismiss()
                    }
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
            .navigationDestination(isPresented: $showsAddPaymentMethodSheet) {
                // 付款方式以 push 呈現；其他情境維持原本導覽
                PaymentMethodEditorSheet(
                    title: addAlertTitle,
                    message: addAlertMessage,
                    namePlaceholder: addFieldPlaceholder,
                    submitTitle: "新增",
                    isEmbedded: true,
                    onSubmit: { name, flags in
                        onAddPaymentMethod?(name, flags)
                        // 新增後返回訂單表單。
                        dismiss()
                    }
                )
            }
    }
    
    /// 選項選擇 sheet 的內容
    @ViewBuilder
    var content: some View {
        listContent
    }
    
    /// 選項清單版面，包含新增、清除、勾選與空狀態
    @ViewBuilder
    var listContent: some View {
        List {
            if allowsAdd {
                Section {
                    Button {
                        triggerAdd()
                    } label: {
                        Label(LocalizedStringKey(addButtonTitle), systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier(BLAccessibilityID.OptionPicker.addButton)
                }
            }
            
            Section {
                if let clearOption {
                    listClearRow(clearOption)
                }
                
                if filteredOptions.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey(emptyTitle),
                        systemImage: "tray",
                        description: Text(LocalizedStringKey(emptyDescription))
                    )
                } else {
                    ForEach(filteredOptions, id: \.self) { option in
                        listOptionRow(option)
                    }
                }
            }
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.root)
    }
    
    /// 清除選項的 row；空字串時顯示勾選
    /// - Parameter clearOption: 已設定的 clear row 設定
    /// - Returns: clear row view
    @ViewBuilder
    func listClearRow(_ clearOption: ClearOption) -> some View {
        Button {
            clearOption.onClear()
            dismiss()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey(clearOption.title))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if selected.isEmpty {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected.isEmpty ? .isSelected : [])
    }
    
    /// 選項 row；單選後關閉，多選後保留 sheet
    /// - Parameter option: 該列代表的選項字串
    /// - Returns: 選項列 view
    @ViewBuilder
    func listOptionRow(_ option: String) -> some View {
        Button {
            handleOptionTap(option)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(displayText(for: option))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if isSelected(option) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.optionRow(option))
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected(option) ? .isSelected : [])
    }
}

// MARK: - Private Method

private extension OptionPickerSheet {
    
    /// 依當前搜尋字串過濾後的選項清單
    var filteredOptions: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return options
        }
        
        return options.filter { option in
            if displayText(for: option).localizedStandardContains(trimmed) {
                return true
            }
            if let keywords = searchKeywords?(option), keywords.localizedStandardContains(trimmed) {
                return true
            }
            return option.localizedStandardContains(trimmed)
        }
    }
    
    /// 取得單筆選項的顯示字串
    /// - Parameter option: 原始選項值
    /// - Returns: 顯示文字
    func displayText(for option: String) -> String {
        displayName?(option) ?? option
    }
    
    /// 判斷選項是否已選取
    /// - Parameter option: 要判斷的選項
    /// - Returns: 是否已選取
    func isSelected(_ option: String) -> Bool {
        if let multiSelection {
            return multiSelection.selections.contains(option)
        }
        return option == selected
    }
    
    /// 處理選項列點擊
    /// - Parameter option: 被點擊的選項
    func handleOptionTap(_ option: String) {
        if let multiSelection {
            multiSelection.onToggle(option)
        } else {
            onSelect(option)
            dismiss()
        }
    }
    
    /// 新增按鈕行為；付款方式開表單，其餘開 alert
    func triggerAdd() {
        if onAddPaymentMethod != nil {
            // 付款方式使用 sheet，避免 alert 遺失旗標開關
            showsAddPaymentMethodSheet = true
        } else {
            draft = ""
            showsAddAlert = true
        }
    }
}

// MARK: - ViewModifier

/// 條件式 searchable modifier，維持 view identity
private struct SearchableModifier: ViewModifier {
    
    /// 搜尋輸入的雙向繫結
    @Binding var text: String
    
    /// 是否啟用搜尋欄
    let enabled: Bool
    
    /// 依 ``enabled`` 決定是否套上 `.searchable`
    /// - Parameter content: 原始 view
    /// - Returns: 套用後的 view
    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋")
            )
        } else {
            content
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
            let name = Locale.current.localizedString(forCurrencyCode: code) ?? ""
            return name.isEmpty ? code : "\(code) · \(name)"
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
