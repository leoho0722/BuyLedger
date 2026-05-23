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
    /// 因為 SwiftUI 的 `.alert` actions builder 不支援 `Toggle`，無法在 alert 中同時讓使用者填名稱與決定 `isCardless`；改用 sheet 是為了把這兩個輸入合併在同一張表單，避免「先 alert 輸入名稱、再到主檔管理頁切 toggle」的兩段式 UX。
    let onAddPaymentMethod: ((String, Bool) -> Void)?

    /// 由 sheet 環境注入的 dismiss action。
    @Environment(\.dismiss) private var dismiss

    /// 目前系統深淺色外觀；macOS 卡片版面用來取得色盤。
    @Environment(\.colorScheme) private var colorScheme

    /// 是否顯示「新增」alert (商品類別等沒有 `isCardless` 需求的入口)。
    @State private var showsAddAlert = false

    /// 是否顯示「新增付款方式」sheet (含 `isCardless` 切換)。
    @State private var showsAddPaymentMethodSheet = false

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
    ///   - selected: 目前選中項目。
    ///   - displayName: 自訂顯示名稱；`nil` 直接顯示原值。
    ///   - searchKeywords: 自訂搜尋補充文字；`nil` 僅以原值比對。
    ///   - onSelect: 點選 callback。
    ///   - onAdd: 新增 callback；`allowsAdd` 為 `false` 時不會被呼叫；若同時提供 ``onAddPaymentMethod`` 則此 callback 也會被忽略。
    ///   - onAddPaymentMethod: 付款方式新增 callback；不為 `nil` 時，「新增」按鈕改開啟 ``PaymentMethodEditorSheet`` 收集名稱與 `isCardless`，取代 alert 流程。
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
        selected: String,
        displayName: (@Sendable (String) -> String)? = nil,
        searchKeywords: (@Sendable (String) -> String)? = nil,
        onSelect: @escaping (String) -> Void,
        onAdd: @escaping (String) -> Void = { _ in },
        onAddPaymentMethod: ((String, Bool) -> Void)? = nil
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
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
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
                        onSubmit: { name, isCardless in
                            onAddPaymentMethod?(name, isCardless)
                            // 新增完成後一併關閉外層 picker sheet，使用者能立即看到新付款方式套用到此訂單。
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

    /// 點擊新增按鈕的共用行為：付款方式入口開 ``PaymentMethodEditorSheet``，其餘開一般新增 alert。
    func triggerAdd() {
        if onAddPaymentMethod != nil {
            // 付款方式入口：alert 在實機驗證會 silently 丟掉 Toggle (只剩 TextField + 按鈕)，所以改用 sheet 收集名稱與 isCardless。
            showsAddPaymentMethodSheet = true
        } else {
            draft = ""
            showsAddAlert = true
        }
    }
}

#if !os(macOS)

// MARK: - ViewBuilder (iOS / iPadOS List 版本)

private extension OptionPickerSheet {

    /// iOS / iPadOS 維持的系統 List 版本：新增按鈕 Section + 選項 Section (含勾選與空狀態)。
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
                if filteredOptions.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "tray",
                        description: Text(emptyDescription)
                    )
                } else {
                    ForEach(filteredOptions, id: \.self) { option in
                        Button {
                            onSelect(option)
                            dismiss()
                        } label: {
                            HStack {
                                Text(displayText(for: option))
                                    .foregroundStyle(.primary)

                                Spacer()

                                if option == selected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#endif

#if os(macOS)

// MARK: - ViewBuilder (macOS 卡片版面)

private extension OptionPickerSheet {

    /// macOS 的 Design System 卡片版本：以 `BLCard` 呈現選項，對齊 ``LookupManagementView`` / ``CustomersView`` 的卡片風。
    ///
    /// 背景採分模式處理：
    /// - 淺色模式套上與表單 List 相同的淺灰群組底色 (`palette.background` 在淺色為 `0xF2F2F7`)，讓白色 `BLCard` 列有對比、不致與 sheet 的白底融合。
    /// - 深色模式維持透明、沿用 sheet 預設材質——`palette.background` 在深色為純黑，會與 sheet 的標題列與底部工具列形成突兀的深色色塊。
    var macContent: some View {
        let palette = BLTheme.palette(for: colorScheme)

        return ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                if allowsAdd {
                    addButton(palette: palette)
                }

                if filteredOptions.isEmpty {
                    macEmptyState()
                } else {
                    optionsCard(palette: palette)
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

    /// macOS 選項卡片：單一 ``BLCard`` 內含選項列 (列間帶 leading inset 的 `Divider`)，列為點選即套用並關閉，選中項顯示勾選。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 選項卡片 view。
    func optionsCard(palette: BLPalette) -> some View {
        BLCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(filteredOptions.enumerated()), id: \.element) { index, option in
                    Button {
                        onSelect(option)
                        dismiss()
                    } label: {
                        HStack(spacing: BLSpacing.small) {
                            Text(displayText(for: option))
                                .font(.subheadline)
                                .foregroundStyle(palette.label)

                            Spacer()

                            if option == selected {
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

                    if index < filteredOptions.count - 1 {
                        Divider()
                            .padding(.leading, BLSpacing.large)
                    }
                }
            }
        }
    }

    /// macOS 空狀態：置中 `ContentUnavailableView`，沿用 sheet 預設材質背景。
    /// - Returns: 空狀態 view。
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
}

// MARK: - ViewBuilder

/// 條件式 `.searchable` modifier；用 `ViewModifier` 包裝是為了避免 `View` 上的條件 modifier 改變 view identity。
private struct SearchableModifier: ViewModifier {

    /// 搜尋輸入的雙向繫結。
    @Binding var text: String

    /// 是否啟用搜尋欄。
    let enabled: Bool

    /// 依 ``enabled`` 決定是否套上 `.searchable`。
    /// - Parameter content: 原始 view。
    /// - Returns: 套用後的 view。
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
