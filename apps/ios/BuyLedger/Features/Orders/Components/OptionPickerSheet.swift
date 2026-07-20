//
//  OptionPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 訂單編輯表單與設定／報價／匯率工具裡用於「單選一個字串選項」的通用 sheet
///
/// 取代原本的 `Menu`
///
/// iOS Menu 因為是 `UIMenu` 的二次包裝，UIKit 端會把 Button action 排到 menu collapse 動畫結束後才派發給 SwiftUI，造成「選完選項 → 約 300ms 後 label 才更新」的可見延遲
///
/// 改用 sheet 後，使用者點選時 binding 立即 commit，sheet 收合與 form label 更新解耦，視覺上不再卡頓
///
/// 內容區以系統 `List` 呈現選項清單
///
/// 透過參數讓「商品類別」「付款方式」「幣別」等選單共用同一份元件：
/// - ``allowsAdd`` 控制是否顯示「新增」按鈕 (商品類別 / 付款方式 = `true`、幣別 = `false`，幣別僅能從 API 主檔挑)
/// - ``searchable`` 控制是否啟用搜尋 (清單超過 ~20 項就建議開)
/// - ``displayName`` 可選的「顯示名稱」轉換 closure，用於幣別 sheet 把 `"USD"` 顯示成 `"USD · 美元"`
/// - ``clearOption`` 可選的「清除目前選擇」row 設定；用於 picker 需要支援「不選任何項目」的場景 (例如訂單頁類別篩選的「全部」)。未傳時 picker 行為與外觀完全不變，與既有 call site 向後相容
/// - ``multiSelection`` 可選的多選模式設定；非 `nil` 時點列改為 toggle 勾選、sheet 不自動關閉、toolbar 改提供「完成」。用於合併情境的類別與開團多選。未傳時維持單選行為，與既有 call site 向後相容
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
    ///
    /// 當 ``clearOption`` 非 `nil` 時，空字串 `""` 為「目前處於 clear 狀態」的 sentinel——picker 會在 clear row 上顯示 checkmark 而不在任何選項列上顯示
    let selected: String

    /// 顯示用名稱轉換；`nil` 時直接顯示 `option`
    let displayName: (@Sendable (String) -> String)?

    /// 搜尋時納入比對的補充文字；用於幣別 sheet 把在地化名稱也納入搜尋
    let searchKeywords: (@Sendable (String) -> String)?

    /// 使用者選擇既有選項時的 callback
    let onSelect: (String) -> Void

    /// 使用者透過「新增」alert 確認新增一個選項時的 callback；`allowsAdd` 為 `false` 時不會被呼叫
    let onAdd: (String) -> Void

    /// 使用者透過「新增付款方式」sheet 確認新增時的 callback；不為 `nil` 時，「新增」按鈕會改顯示 ``PaymentMethodEditorSheet`` (含 `isCardless` 切換)，取代既有 alert 流程
    ///
    /// 因為 SwiftUI 的 `.alert` actions builder 不支援 `Toggle`，無法在 alert 中同時讓使用者填名稱與決定 `isCardless` / `isBankTransfer` / `isCashOnDelivery`；改用 sheet 是為了把這些輸入合併在同一張表單
    ///
    /// callback 參數依序為 (名稱, isCardless, isBankTransfer, isCashOnDelivery)
    let onAddPaymentMethod: ((String, Bool, Bool, Bool) -> Void)?

    /// 可選的「清除目前選擇」row 設定
    ///
    /// 當非 `nil` 時，picker 會在選項列上方額外渲染一列以 ``ClearOption/title`` 為 label 的 row；點擊該 row 會呼叫 ``ClearOption/onClear`` 並 dismiss，且 picker 會把 `selected == ""` 視為「目前處於 clear 狀態」並在 clear row 上顯示 checkmark
    ///
    /// 為 `nil` 時，picker 行為與外觀完全不變 (與既有 call site 向後相容)
    ///
    /// 採用獨立參數而非在 ``options`` 中注入 sentinel 字串，是為了避免與使用者自建選項撞名 (例如使用者真的建立一個叫「全部」的類別)
    let clearOption: ClearOption?

    /// 可選的多選模式設定
    ///
    /// 當非 `nil` 時：點選選項列改為 toggle 勾選 (呼叫 ``MultiSelection/onToggle``、sheet 不自動關閉)、已選集合由 caller 經 ``MultiSelection/selections`` 持有並驅動勾選指示、toolbar 以「完成」取代「取消」供使用者結束選取
    ///
    /// 搜尋與新增選項流程與單選模式完全一致
    ///
    /// 為 `nil` 時維持既有單選行為 (與既有 call site 向後相容)；``selected`` 與 ``onSelect`` 僅在單選模式有效
    let multiSelection: MultiSelection?

    /// 是否為嵌入 (push) 呈現：`true` 時不自帶 `NavigationStack`、不放取消鍵 (由宿主導覽堆疊的 Back 取代)，供訂單編輯表單內以 push 呈現；`false` (預設) 維持既有自帶 `NavigationStack` + 取消鍵的單層 sheet 呈現
    let isEmbedded: Bool

    /// 由 sheet 環境注入的 dismiss action；嵌入 (push) 時 `dismiss()` 為 pop、單層 sheet 時為關閉
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
    ///   - selected: 目前選中項目；當 `clearOption` 非 `nil` 時，傳入空字串代表「目前處於 clear 狀態」
    ///   - displayName: 自訂顯示名稱；`nil` 直接顯示原值
    ///   - searchKeywords: 自訂搜尋補充文字；`nil` 僅以原值比對
    ///   - onSelect: 點選 callback
    ///   - onAdd: 新增 callback；`allowsAdd` 為 `false` 時不會被呼叫；若同時提供 ``onAddPaymentMethod`` 則此 callback 也會被忽略
    ///   - onAddPaymentMethod: 付款方式新增 callback；不為 `nil` 時，「新增」按鈕改開啟 ``PaymentMethodEditorSheet`` 收集名稱與 `isCardless` / `isBankTransfer` / `isCashOnDelivery`，取代 alert 流程
    ///   - clearOption: 可選的「清除目前選擇」row 設定；預設 `nil` (不顯示 clear row、行為與既有版本一致)
    ///   - multiSelection: 可選的多選模式設定；預設 `nil` (維持單選行為)。非 `nil` 時 `selected` 與 `onSelect` 不會被使用
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
        onAddPaymentMethod: ((String, Bool, Bool, Bool) -> Void)? = nil,
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
    ///
    /// 單層 sheet 呈現 (``isEmbedded`` == `false`) 時自帶 `NavigationStack`；嵌入 (push) 呈現時直接回傳內容，由宿主導覽堆疊提供標題列與 Back。組合細節見 ``configuredContent``
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
    ///
    /// 用於需要在 picker 中表達「不選任何項目」的場景 (例如訂單頁類別篩選的「全部」)
    ///
    /// 採用獨立參數而非在 `options` 中注入 sentinel 字串，避免與使用者自建選項撞名以及破壞既有 picker 的「必選一個」契約
    struct ClearOption {

        // MARK: - Data Properties

        /// Clear row 的 label 文字 (例如「全部」)
        let title: String

        /// 使用者點擊 clear row 時觸發的 callback；執行後 sheet 會自動 dismiss
        let onClear: () -> Void
    }

    /// 多選模式的設定
    ///
    /// 已選集合由 caller 持有 (例如 TCA store 的草稿陣列)，picker 只負責呈現勾選與回報 toggle；點列不會關閉 sheet，使用者以 toolbar 的「完成」結束選取
    struct MultiSelection {

        // MARK: - Data Properties

        /// 目前已選取的選項集合；驅動每一列的勾選指示
        let selections: Set<String>

        /// 使用者點擊某列時觸發的 toggle callback；caller 應依目前是否已選取自行加入或移除該選項
        let onToggle: (String) -> Void
    }
}

// MARK: - ViewBuilder

private extension OptionPickerSheet {

    /// 組好標題列、toolbar、搜尋、新增 alert 與新增付款方式 push 的完整內容；由 ``body`` 依 ``isEmbedded`` 決定是否再包一層 `NavigationStack`
    @ViewBuilder
    var configuredContent: some View {
        content
            .navigationTitle(Text(LocalizedStringKey(title)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if multiSelection != nil {
                    // 多選模式：toggle 即時生效，「完成」負責結束選取 (嵌入時亦保留，Back 亦可返回)
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            dismiss()
                        }
                    }

                    // 獨立呈現時「完成」是唯一出口，等於逼使用者以完成來取消；補上取消動作。
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
                    // 單層 sheet 才放取消鍵；嵌入 (push) 時由宿主導覽堆疊的 Back 取代
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
            .alert(LocalizedStringKey(addAlertTitle), isPresented: $showsAddAlert) {
                TextField(LocalizedStringKey(addFieldPlaceholder), text: $draft)
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
                .disabled(
                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                Button("取消", role: .cancel) {
                    draft = ""
                }
            } message: {
                Text(LocalizedStringKey(addAlertMessage))
            }
            .navigationDestination(isPresented: $showsAddPaymentMethodSheet) {
                // 新增付款方式改以 push 呈現 (消除訂單編輯的三層疊 sheet)；嵌入模式沿宿主堆疊、單層模式沿自帶 NavigationStack
                PaymentMethodEditorSheet(
                    title: addAlertTitle,
                    message: addAlertMessage,
                    namePlaceholder: addFieldPlaceholder,
                    submitTitle: "新增",
                    isEmbedded: true,
                    onSubmit: { name, isCardless, isBankTransfer, isCashOnDelivery in
                        onAddPaymentMethod?(name, isCardless, isBankTransfer, isCashOnDelivery)
                        // 新增完成後一併返回訂單表單，使用者能立即看到新付款方式套用到此訂單
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

    /// 系統 `List` 版面：新增按鈕 Section + 選項 Section (含 optional clear row、勾選與空狀態)
    ///
    /// 排列順序：新增按鈕 Section (如有) → 選項 Section { clear row (如有) → 空狀態 / 選項列 }。clear row 不參與 ``filteredOptions`` 過濾，搜尋時也永遠顯示在最上方
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
    }

    /// iOS / iPadOS 的 clear row：點擊呼叫 ``ClearOption/onClear`` 並 dismiss；`selected` 為空字串時顯示 checkmark
    ///
    /// 文字以 `.fixedSize(horizontal: false, vertical: true)` 強制取得需要的垂直空間，配合 `.multilineTextAlignment(.leading)`，讓過長 label 自然換行而不被 trailing checkmark 截斷
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
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// iOS / iPadOS 的選項列：單選模式點擊呼叫 ``onSelect`` 並 dismiss；多選模式點擊 toggle 勾選且 sheet 維持開啟。已選項顯示 checkmark
    ///
    /// 文字以 `.fixedSize(horizontal: false, vertical: true)` 強制取得需要的垂直空間，配合 `.multilineTextAlignment(.leading)`，讓過長類別名稱自然換行 (row 高度隨內容增長)，而不被 trailing checkmark 截斷
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
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Private Method

private extension OptionPickerSheet {

    /// 依當前搜尋字串過濾後的選項清單
    ///
    /// 注意：clear row (`clearOption`) 不參與此過濾，永遠在選項列上方獨立呈現
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

    /// 判斷選項是否處於已選取狀態：多選模式查 caller 持有的集合，單選模式比對 ``selected``
    /// - Parameter option: 要判斷的選項
    /// - Returns: 是否已選取
    func isSelected(_ option: String) -> Bool {
        if let multiSelection {
            return multiSelection.selections.contains(option)
        }
        return option == selected
    }

    /// 選項列點擊的共用行為：多選模式 toggle 且維持 sheet 開啟，單選模式套用後 dismiss
    /// - Parameter option: 被點擊的選項
    func handleOptionTap(_ option: String) {
        if let multiSelection {
            multiSelection.onToggle(option)
        } else {
            onSelect(option)
            dismiss()
        }
    }

    /// 點擊新增按鈕的共用行為：付款方式入口開 ``PaymentMethodEditorSheet`` (需收集旗標)，其餘開一般新增 alert
    func triggerAdd() {
        if onAddPaymentMethod != nil {
            // 付款方式入口：alert 在實機驗證會 silently 丟掉 Toggle (只剩 TextField + 按鈕)，所以改用 sheet 收集名稱與 isCardless / isBankTransfer
            showsAddPaymentMethodSheet = true
        } else {
            draft = ""
            showsAddAlert = true
        }
    }
}

// MARK: - ViewModifier

/// 條件式 `.searchable` modifier；用 `ViewModifier` 包裝是為了避免 `View` 上的條件 modifier 改變 view identity
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
        clearOption: .init(title: "全部", onClear: { })
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
        clearOption: .init(title: "全部", onClear: { })
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
