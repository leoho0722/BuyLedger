//
//  OptionPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

/// 訂單編輯表單與設定／報價／匯率工具裡用於「單選一個字串選項」的通用 sheet。
///
/// 取代原本的 `Menu`：iOS Menu 因為是 `UIMenu` 的二次包裝，UIKit 端會把 Button action 排到 menu collapse 動畫結束後才派發給 SwiftUI，造成「選完選項 → 約 300ms 後 label 才更新」的可見延遲。改用 sheet 後，使用者點選時 binding 立即 commit，sheet 收合與 form label 更新解耦，視覺上不再卡頓。
///
/// 內容區依平台分流：macOS 採 `ScrollView` + `palette.background` + `BLCard` 卡片版面 (對齊 ``LookupManagementView`` / ``CustomersView``)；iOS / iPadOS 維持系統 `List`。
///
/// 透過參數讓「商品類別」「付款方式」「幣別」等選單共用同一份元件：
/// - ``allowsAdd`` 控制是否顯示「新增」按鈕 (商品類別 / 付款方式 = `true`、幣別 = `false`，幣別僅能從 API 主檔挑)
/// - ``searchable`` 控制是否啟用搜尋 (清單超過 ~20 項就建議開)
/// - ``displayName`` 可選的「顯示名稱」轉換 closure，用於幣別 sheet 把 `"USD"` 顯示成 `"USD · 美元"`
/// - ``clearOption`` 可選的「清除目前選擇」row 設定；用於 picker 需要支援「不選任何項目」的場景 (例如訂單頁類別篩選的「全部」)。未傳時 picker 行為與外觀完全不變，與既有 call site 向後相容。
/// - ``multiSelection`` 可選的多選模式設定；非 `nil` 時點列改為 toggle 勾選、sheet 不自動關閉、toolbar 改提供「完成」。用於合併情境的類別與開團多選。未傳時維持單選行為，與既有 call site 向後相容。
struct OptionPickerSheet: View {

    // MARK: - View Properties

    /// Sheet 的標題 (顯示在 navigation bar)。
    let title: String

    /// 是否允許在 sheet 內新增項目 (toolbar 出現「新增」按鈕)。
    let allowsAdd: Bool

    /// 是否啟用搜尋欄。
    let searchable: Bool

    /// 「新增」按鈕顯示的標題；`allowsAdd` 為 `false` 時忽略。
    let addButtonTitle: String

    /// 沒有任何選項時 ``ContentUnavailableView`` 的標題。
    let emptyTitle: String

    /// 沒有任何選項時 ``ContentUnavailableView`` 的描述。
    let emptyDescription: String

    /// 「新增」alert 的標題；`allowsAdd` 為 `false` 時忽略。
    let addAlertTitle: String

    /// 「新增」alert 內 TextField 的 placeholder；`allowsAdd` 為 `false` 時忽略。
    let addFieldPlaceholder: String

    /// 「新增」alert 的說明訊息；`allowsAdd` 為 `false` 時忽略。
    let addAlertMessage: String

    /// 目前可選的選項清單。
    let options: [String]

    /// 目前已選中的選項；用來在列表中顯示勾選。
    ///
    /// 當 ``clearOption`` 非 `nil` 時，空字串 `""` 為「目前處於 clear 狀態」的 sentinel——picker 會在 clear row 上顯示 checkmark 而不在任何選項列上顯示。
    let selected: String

    /// 顯示用名稱轉換；`nil` 時直接顯示 `option`。
    let displayName: (@Sendable (String) -> String)?

    /// 搜尋時納入比對的補充文字；用於幣別 sheet 把在地化名稱也納入搜尋。
    let searchKeywords: (@Sendable (String) -> String)?

    /// 使用者選擇既有選項時的 callback。
    let onSelect: (String) -> Void

    /// 使用者透過「新增」alert 確認新增一個選項時的 callback；`allowsAdd` 為 `false` 時不會被呼叫。
    let onAdd: (String) -> Void

    /// 使用者透過「新增付款方式」sheet 確認新增時的 callback；不為 `nil` 時，「新增」按鈕會改顯示 ``PaymentMethodEditorSheet`` (含 `isCardless` 切換)，取代既有 alert 流程。
    ///
    /// 因為 SwiftUI 的 `.alert` actions builder 不支援 `Toggle`，無法在 alert 中同時讓使用者填名稱與決定 `isCardless` / `isBankTransfer` / `isCashOnDelivery`；改用 sheet 是為了把這些輸入合併在同一張表單。callback 參數依序為 (名稱, isCardless, isBankTransfer, isCashOnDelivery)。
    let onAddPaymentMethod: ((String, Bool, Bool, Bool) -> Void)?

    /// 使用者透過「新增」name-only medium sheet 確認新增時的 callback；不為 `nil` 且 ``onAddPaymentMethod`` 為 `nil` 時，「新增」按鈕會改顯示 ``LookupItemEditorSheet`` (只收名稱)，取代既有 alert 流程。供對帳狀態等只需名稱的主檔比照「新增付款方式」使用 medium sheet。
    let onAddViaNameSheet: ((String) -> Void)?

    /// 可選的「清除目前選擇」row 設定。
    ///
    /// 當非 `nil` 時，picker 會在選項列上方額外渲染一列以 ``ClearOption/title`` 為 label 的 row；點擊該 row 會呼叫 ``ClearOption/onClear`` 並 dismiss，且 picker 會把 `selected == ""` 視為「目前處於 clear 狀態」並在 clear row 上顯示 checkmark。為 `nil` 時，picker 行為與外觀完全不變 (與既有 call site 向後相容)。
    ///
    /// 採用獨立參數而非在 ``options`` 中注入 sentinel 字串，是為了避免與使用者自建選項撞名 (例如使用者真的建立一個叫「全部」的類別)。
    let clearOption: ClearOption?

    /// 可選的多選模式設定。
    ///
    /// 當非 `nil` 時：點選選項列改為 toggle 勾選 (呼叫 ``MultiSelection/onToggle``、sheet 不自動關閉)、已選集合由 caller 經 ``MultiSelection/selections`` 持有並驅動勾選指示、toolbar 以「完成」取代「取消」供使用者結束選取。搜尋與新增選項流程與單選模式完全一致。為 `nil` 時維持既有單選行為 (與既有 call site 向後相容)；``selected`` 與 ``onSelect`` 僅在單選模式有效。
    let multiSelection: MultiSelection?

    /// 由 sheet 環境注入的 dismiss action。
    @Environment(\.dismiss) private var dismiss

    /// 目前系統深淺色外觀；macOS 卡片版面用來取得色盤。
    @Environment(\.colorScheme) private var colorScheme

    /// 是否顯示「新增」alert (商品類別等沒有 `isCardless` 需求的入口)。
    @State private var showsAddAlert = false

    /// 是否顯示「新增付款方式」sheet (含 `isCardless` / `isBankTransfer` 切換)。
    @State private var showsAddPaymentMethodSheet = false

    /// 是否顯示 name-only 的「新增」medium sheet (對帳狀態等只需名稱的主檔)。
    @State private var showsAddNameSheet = false

    /// 新增 alert 的名稱輸入草稿。
    @State private var draft = ""

    /// 搜尋輸入。
    @State private var searchText = ""

    // MARK: - Init

    /// 通用建構式；所有 sheet 參數一次傳齊。
    /// - Parameters:
    ///   - title: navigation 標題。
    ///   - allowsAdd: 是否顯示新增。預設 `true`。
    ///   - searchable: 是否啟用搜尋欄。預設 `false`。
    ///   - addButtonTitle: 新增按鈕標題。
    ///   - emptyTitle: 空狀態標題。
    ///   - emptyDescription: 空狀態描述。
    ///   - addAlertTitle: 新增 alert 標題。
    ///   - addFieldPlaceholder: 新增 TextField placeholder。
    ///   - addAlertMessage: 新增 alert 提示訊息。
    ///   - options: 可選項目。
    ///   - selected: 目前選中項目；當 `clearOption` 非 `nil` 時，傳入空字串代表「目前處於 clear 狀態」。
    ///   - displayName: 自訂顯示名稱；`nil` 直接顯示原值。
    ///   - searchKeywords: 自訂搜尋補充文字；`nil` 僅以原值比對。
    ///   - onSelect: 點選 callback。
    ///   - onAdd: 新增 callback；`allowsAdd` 為 `false` 時不會被呼叫；若同時提供 ``onAddPaymentMethod`` 則此 callback 也會被忽略。
    ///   - onAddPaymentMethod: 付款方式新增 callback；不為 `nil` 時，「新增」按鈕改開啟 ``PaymentMethodEditorSheet`` 收集名稱與 `isCardless` / `isBankTransfer` / `isCashOnDelivery`，取代 alert 流程。
    ///   - onAddViaNameSheet: name-only 主檔新增 callback；不為 `nil` 且 `onAddPaymentMethod` 為 `nil` 時，「新增」按鈕改開啟 ``LookupItemEditorSheet`` (只收名稱) 的 medium sheet，取代 alert 流程。
    ///   - clearOption: 可選的「清除目前選擇」row 設定；預設 `nil` (不顯示 clear row、行為與既有版本一致)。
    ///   - multiSelection: 可選的多選模式設定；預設 `nil` (維持單選行為)。非 `nil` 時 `selected` 與 `onSelect` 不會被使用。
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
        onAddViaNameSheet: ((String) -> Void)? = nil,
        clearOption: ClearOption? = nil,
        multiSelection: MultiSelection? = nil
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
        self.onAddViaNameSheet = onAddViaNameSheet
        self.clearOption = clearOption
        self.multiSelection = multiSelection
    }

    // MARK: - View Body

    /// 選項選擇 sheet 的內容。
    ///
    /// 內容區依平台分流 (見 ``content``)，但 navigation 標題、toolbar 取消、搜尋、新增 alert 與付款方式 sheet 由兩平台分支共用，確保操作與業務邏輯一致。
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    if multiSelection != nil {
                        // 多選模式：toggle 即時生效，「完成」僅負責關閉 sheet。
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") {
                                dismiss()
                            }
                        }
                    } else {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") {
                                dismiss()
                            }
                        }
                    }
                }
                .modifier(SearchableModifier(text: $searchText, enabled: searchable))
                .alert(addAlertTitle, isPresented: $showsAddAlert) {
                    TextField(addFieldPlaceholder, text: $draft)
#if !os(macOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif

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
                    Text(addAlertMessage)
                }
                .sheet(isPresented: $showsAddPaymentMethodSheet) {
                    PaymentMethodEditorSheet(
                        title: addAlertTitle,
                        message: addAlertMessage,
                        namePlaceholder: addFieldPlaceholder,
                        submitTitle: "新增",
                        onSubmit: { name, isCardless, isBankTransfer, isCashOnDelivery in
                            onAddPaymentMethod?(name, isCardless, isBankTransfer, isCashOnDelivery)
                            // 新增完成後一併關閉外層 picker sheet，使用者能立即看到新付款方式套用到此訂單。
                            dismiss()
                        }
                    )
                }
                .sheet(isPresented: $showsAddNameSheet) {
                    LookupItemEditorSheet(
                        title: addAlertTitle,
                        message: addAlertMessage,
                        namePlaceholder: addFieldPlaceholder,
                        submitTitle: "新增",
                        onSubmit: { name in
                            onAddViaNameSheet?(name)
                            // 新增完成後一併關閉外層 picker sheet，使用者能立即看到新項目套用到此訂單。
                            dismiss()
                        }
                    )
                }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 480)
#endif
    }
}

// MARK: - Nested Types

extension OptionPickerSheet {

    /// 「清除目前選擇」row 的設定。
    ///
    /// 用於需要在 picker 中表達「不選任何項目」的場景 (例如訂單頁類別篩選的「全部」)。採用獨立參數而非在 `options` 中注入 sentinel 字串，避免與使用者自建選項撞名以及破壞既有 picker 的「必選一個」契約。
    struct ClearOption {

        // MARK: - Data Properties

        /// Clear row 的 label 文字 (例如「全部」)。
        let title: String

        /// 使用者點擊 clear row 時觸發的 callback；執行後 sheet 會自動 dismiss。
        let onClear: () -> Void
    }

    /// 多選模式的設定。
    ///
    /// 已選集合由 caller 持有 (例如 TCA store 的草稿陣列)，picker 只負責呈現勾選與回報 toggle；點列不會關閉 sheet，使用者以 toolbar 的「完成」結束選取。
    struct MultiSelection {

        // MARK: - Data Properties

        /// 目前已選取的選項集合；驅動每一列的勾選指示。
        let selections: Set<String>

        /// 使用者點擊某列時觸發的 toggle callback；caller 應依目前是否已選取自行加入或移除該選項。
        let onToggle: (String) -> Void
    }
}

// MARK: - ViewBuilder

private extension OptionPickerSheet {

    /// 依平台選擇內容呈現：macOS 走 Design System 卡片版面，iOS / iPadOS 維持系統 List。
    @ViewBuilder
    var content: some View {
#if os(macOS)
        macContent
#else
        listContent
#endif
    }
}

#if !os(macOS)

// MARK: - ViewBuilder (iOS / iPadOS List 版本)

private extension OptionPickerSheet {

    /// iOS / iPadOS 維持的系統 List 版本：新增按鈕 Section + 選項 Section (含 optional clear row、勾選與空狀態)。
    ///
    /// 排列順序：新增按鈕 Section (如有) → 選項 Section { clear row (如有) → 空狀態 / 選項列 }。clear row 不參與 ``filteredOptions`` 過濾，搜尋時也永遠顯示在最上方。
    @ViewBuilder
    var listContent: some View {
        List {
            if allowsAdd {
                Section {
                    Button {
                        triggerAdd()
                    } label: {
                        Label(addButtonTitle, systemImage: "plus.circle.fill")
                    }
                }
            }

            Section {
                if let clearOption {
                    listClearRow(clearOption)
                }

                if filteredOptions.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "tray",
                        description: Text(emptyDescription)
                    )
                } else {
                    ForEach(filteredOptions, id: \.self) { option in
                        listOptionRow(option)
                    }
                }
            }
        }
    }

    /// iOS / iPadOS 的 clear row：點擊呼叫 ``ClearOption/onClear`` 並 dismiss；`selected` 為空字串時顯示 checkmark。
    ///
    /// 文字以 `.fixedSize(horizontal: false, vertical: true)` 強制取得需要的垂直空間，配合 `.multilineTextAlignment(.leading)`，讓過長 label 自然換行而不被 trailing checkmark 截斷。
    /// - Parameter clearOption: 已設定的 clear row 設定。
    /// - Returns: clear row view。
    @ViewBuilder
    func listClearRow(_ clearOption: ClearOption) -> some View {
        Button {
            clearOption.onClear()
            dismiss()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(clearOption.title)
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

    /// iOS / iPadOS 的選項列：單選模式點擊呼叫 ``onSelect`` 並 dismiss；多選模式點擊 toggle 勾選且 sheet 維持開啟。已選項顯示 checkmark。
    ///
    /// 文字以 `.fixedSize(horizontal: false, vertical: true)` 強制取得需要的垂直空間，配合 `.multilineTextAlignment(.leading)`，讓過長類別名稱自然換行 (row 高度隨內容增長)，而不被 trailing checkmark 截斷。
    /// - Parameter option: 該列代表的選項字串。
    /// - Returns: 選項列 view。
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

#endif

#if os(macOS)

// MARK: - ViewBuilder (macOS 卡片版面)

private extension OptionPickerSheet {

    /// macOS 的 Design System 卡片版本：以 `BLCard` 呈現選項，對齊 ``LookupManagementView`` / ``CustomersView`` 的卡片風。
    ///
    /// 排列順序：新增按鈕 (如有) → 卡片 (clear row + Divider + 選項列；只在「clear row 存在或有可顯示選項」時呈現) → 空狀態 (`filteredOptions` 為空時，顯示在卡片下方)。
    ///
    /// 背景採分模式處理：
    /// - 淺色模式套上與表單 List 相同的淺灰群組底色 (`palette.background` 在淺色為 `0xF2F2F7`)，讓白色 `BLCard` 列有對比、不致與 sheet 的白底融合。
    /// - 深色模式維持透明、沿用 sheet 預設材質——`palette.background` 在深色為純黑，會與 sheet 的標題列與底部工具列形成突兀的深色色塊。
    @ViewBuilder
    var macContent: some View {
        let palette = BLTheme.palette(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                if allowsAdd {
                    addButton(palette: palette)
                }

                if clearOption != nil || !filteredOptions.isEmpty {
                    optionsCard(palette: palette)
                }

                if filteredOptions.isEmpty {
                    macEmptyState()
                }
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.isDark ? Color.clear : palette.background)
    }

    /// macOS 卡片上方的新增按鈕，沿用 ``triggerAdd()`` 的入口邏輯。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 新增按鈕 view。
    @ViewBuilder
    func addButton(palette: BLPalette) -> some View {
        Button {
            triggerAdd()
        } label: {
            Label(addButtonTitle, systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.accent)
        }
        .buttonStyle(.plain)
    }

    /// macOS 選項卡片：單一 ``BLCard`` 內含 optional clear row + 選項列 (列間帶 leading inset 的 `Divider`)；列為點選即套用並關閉，選中項顯示勾選。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 選項卡片 view。
    @ViewBuilder
    func optionsCard(palette: BLPalette) -> some View {
        BLCard(padding: 0) {
            VStack(spacing: 0) {
                if let clearOption {
                    macClearRow(clearOption, palette: palette)

                    if !filteredOptions.isEmpty {
                        Divider()
                            .padding(.leading, BLSpacing.large)
                    }
                }

                ForEach(Array(filteredOptions.enumerated()), id: \.element) { index, option in
                    macOptionRow(option, palette: palette)

                    if index < filteredOptions.count - 1 {
                        Divider()
                            .padding(.leading, BLSpacing.large)
                    }
                }
            }
        }
    }

    /// macOS 的 clear row：點擊呼叫 ``ClearOption/onClear`` 並 dismiss；`selected` 為空字串時以 `palette.accent` 顯示 checkmark。
    ///
    /// 文字以 `.fixedSize(horizontal: false, vertical: true)` 強制取得需要的垂直空間，配合 `.multilineTextAlignment(.leading)`，讓過長 label 自然換行 (BLCard 列高度隨內容增長)，而不被 trailing checkmark 截斷。
    /// - Parameters:
    ///   - clearOption: 已設定的 clear row 設定。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: clear row view。
    @ViewBuilder
    func macClearRow(_ clearOption: ClearOption, palette: BLPalette) -> some View {
        Button {
            clearOption.onClear()
            dismiss()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Text(clearOption.title)
                    .font(.subheadline)
                    .foregroundStyle(palette.label)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if selected.isEmpty {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// macOS 的選項列：單選模式點擊呼叫 ``onSelect`` 並 dismiss；多選模式點擊 toggle 勾選且 sheet 維持開啟。已選項以 `palette.accent` 顯示 checkmark。
    ///
    /// 文字以 `.fixedSize(horizontal: false, vertical: true)` 強制取得需要的垂直空間，配合 `.multilineTextAlignment(.leading)`，讓過長類別名稱自然換行 (BLCard 列高度隨內容增長)，而不被 trailing checkmark 截斷。
    /// - Parameters:
    ///   - option: 該列代表的選項字串。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 選項列 view。
    @ViewBuilder
    func macOptionRow(_ option: String, palette: BLPalette) -> some View {
        Button {
            handleOptionTap(option)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Text(displayText(for: option))
                    .font(.subheadline)
                    .foregroundStyle(palette.label)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if isSelected(option) {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// macOS 空狀態：置中 `ContentUnavailableView`，沿用 sheet 預設材質背景。
    /// - Returns: 空狀態 view。
    @ViewBuilder
    func macEmptyState() -> some View {
        ContentUnavailableView(
            emptyTitle,
            systemImage: "tray",
            description: Text(emptyDescription)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, BLSpacing.section)
    }
}

#endif

// MARK: - Private Method

private extension OptionPickerSheet {

    /// 依當前搜尋字串過濾後的選項清單。
    ///
    /// 注意：clear row (`clearOption`) 不參與此過濾，永遠在選項列上方獨立呈現。
    var filteredOptions: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return options }

        return options.filter { option in
            if displayText(for: option).lowercased().contains(trimmed) {
                return true
            }
            if let keywords = searchKeywords?(option), keywords.lowercased().contains(trimmed) {
                return true
            }
            return option.lowercased().contains(trimmed)
        }
    }

    /// 取得單筆選項的顯示字串。
    /// - Parameter option: 原始選項值。
    /// - Returns: 顯示文字。
    func displayText(for option: String) -> String {
        displayName?(option) ?? option
    }

    /// 判斷選項是否處於已選取狀態：多選模式查 caller 持有的集合，單選模式比對 ``selected``。
    /// - Parameter option: 要判斷的選項。
    /// - Returns: 是否已選取。
    func isSelected(_ option: String) -> Bool {
        if let multiSelection {
            return multiSelection.selections.contains(option)
        }
        return option == selected
    }

    /// 選項列點擊的共用行為：多選模式 toggle 且維持 sheet 開啟，單選模式套用後 dismiss。
    /// - Parameter option: 被點擊的選項。
    func handleOptionTap(_ option: String) {
        if let multiSelection {
            multiSelection.onToggle(option)
        } else {
            onSelect(option)
            dismiss()
        }
    }

    /// 點擊新增按鈕的共用行為，依 handler precedence 決定呈現：付款方式入口開 ``PaymentMethodEditorSheet``、name-only 入口開 ``LookupItemEditorSheet``，其餘開一般新增 alert。
    func triggerAdd() {
        if onAddPaymentMethod != nil {
            // 付款方式入口：alert 在實機驗證會 silently 丟掉 Toggle (只剩 TextField + 按鈕)，所以改用 sheet 收集名稱與 isCardless / isBankTransfer。
            showsAddPaymentMethodSheet = true
        } else if onAddViaNameSheet != nil {
            // 對帳狀態等只需名稱的主檔：比照「新增付款方式」改用 medium sheet (而非 alert)，操作體驗一致。
            showsAddNameSheet = true
        } else {
            draft = ""
            showsAddAlert = true
        }
    }
}

// MARK: - ViewModifier

/// 條件式 `.searchable` modifier；用 `ViewModifier` 包裝是為了避免 `View` 上的條件 modifier 改變 view identity。
private struct SearchableModifier: ViewModifier {

    /// 搜尋輸入的雙向繫結。
    @Binding var text: String

    /// 是否啟用搜尋欄。
    let enabled: Bool

    /// 依 ``enabled`` 決定是否套上 `.searchable`。
    /// - Parameter content: 原始 view。
    /// - Returns: 套用後的 view。
    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
#if os(macOS)
            content.searchable(text: $text, prompt: Text("搜尋"))
#else
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋")
            )
#endif
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
