//
//  OrderFilterSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import SwiftUI

/// iPhone Compact 訂單頁的整合篩選 sheet
///
/// 把「日期區間」「商品類別」與「付款方式」三種篩選整合到單一 sheet，由 ``OrdersCompactView`` 的整合 trigger button 開啟
///
/// 結構：`NavigationStack` 包 `List` 三個 `Section`，左上 toolbar「取消」按鈕收合 sheet
///
/// 第一個 `Section` 為「日期區間」，列出 ``OrderDatePeriod/orderBrowsingCases``
///
/// 第二個 `Section` 為「付款方式」，首列固定「全部」清除選項，其後依 ``OrdersFeature/State/availablePaymentMethods`` 列出 (受搜尋過濾)
///
/// 第三個 `Section` 為「商品類別」，同樣首列固定「全部」清除選項，其後依 ``OrdersFeature/State/availableCategories`` 列出 (受搜尋過濾)
///
/// 點選任一列 dispatch 對應 ``OrdersFeature/Action`` 後 sheet 自動 dismiss
///
/// 此元件**僅供 iPhone Compact 使用**；iPad regular 仍使用各自的 chip 列 + ``OptionPickerSheet`` 類別 trigger，與此 sheet 無關
///
/// 故意不重用 ``OptionPickerSheet``：OptionPickerSheet 是「一個 sheet 對應一個單選 picker」的完整元件 (內含自己的 `NavigationStack` 與 toolbar)，要嵌入此 sheet 必須拆分元件，回歸風險高於從零實作
struct OrderFilterSheet: View {

    // MARK: - View Properties

    /// 訂單功能 store；用於初始化 pending state 與 Apply 時 dispatch 變動
    let store: StoreOf<OrdersFeature>

    /// 由 sheet 環境注入的 dismiss action；點「套用」或「取消」時收合 sheet
    @Environment(\.dismiss) private var dismiss

    /// 類別 section 的搜尋輸入；只過濾類別列，**不**影響日期 section
    @State private var searchText = ""

    /// 使用者在 sheet 內 pending 的日期區間選擇
    ///
    /// 點 row 只更新此 pending state，不 dispatch；要按右上「套用」才把變動 commit 到 store
    @State private var pendingDatePeriod: OrderDatePeriod

    /// 使用者在 sheet 內 pending 的類別選擇 (`nil` 代表「全部」)
    ///
    /// 點 row 只更新此 pending state，不 dispatch；要按右上「套用」才把變動 commit 到 store
    @State private var pendingCategory: String?

    /// 使用者在 sheet 內 pending 的付款方式選擇 (`nil` 代表「全部」)
    ///
    /// 點 row 只更新此 pending state，不 dispatch；要按右上「套用」才把變動 commit 到 store
    @State private var pendingPaymentMethod: String?

    // MARK: - Init

    /// 從目前 store state 取得 pending 初值
    /// - Parameter store: 訂單功能 store
    init(store: StoreOf<OrdersFeature>) {
        self.store = store
        self._pendingDatePeriod = State(initialValue: store.state.selectedDatePeriod)
        self._pendingCategory = State(initialValue: store.state.selectedCategory)
        self._pendingPaymentMethod = State(initialValue: store.state.selectedPaymentMethod)
    }

    // MARK: - View Body

    /// 整合篩選 sheet 的內容
    var body: some View {
        NavigationStack {
            List {
                datePeriodSection
                paymentMethodSection
                categorySection
            }
            .navigationTitle("篩選")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("套用") {
                        applyAndDismiss()
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋類別")
            )
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - ViewBuilder

private extension OrderFilterSheet {

    // MARK: Sections

    /// 「日期區間」section：固定 4 列，順序為 ``OrderDatePeriod/orderBrowsingCases``
    ///
    /// 搜尋輸入完全不影響此 section——4 列永遠顯示
    @ViewBuilder
    var datePeriodSection: some View {
        Section {
            ForEach(OrderDatePeriod.orderBrowsingCases) { period in
                datePeriodRow(period)
            }
        } header: {
            Text("日期區間")
        }
    }

    /// 「商品類別」section：第一列固定「全部」clear row，其後依 ``filteredCategories`` 列出
    ///
    /// 當搜尋無匹配 (`filteredCategories.isEmpty`) 時，類別列以 `ContentUnavailableView` 空狀態取代；clear row 仍維持顯示
    /// 當 `availableCategories` 本身為空時，行為相同 (clear row + 空狀態描述「尚無類別」)
    @ViewBuilder
    var categorySection: some View {
        Section {
            categoryClearRow

            if filteredCategories.isEmpty {
                categoryEmptyStateRow
            } else {
                ForEach(filteredCategories, id: \.self) { category in
                    categoryRow(category)
                }
            }
        } header: {
            Text("商品類別")
        }
    }

    /// 「付款方式」section：第一列固定「全部」clear row，其後依 ``filteredPaymentMethods`` 列出
    ///
    /// 當搜尋無匹配 (`filteredPaymentMethods.isEmpty`) 時，付款方式列以 `ContentUnavailableView` 空狀態取代；clear row 仍維持顯示
    /// 當 `availablePaymentMethods` 本身為空時，行為相同 (clear row + 空狀態描述「尚無付款方式」)
    @ViewBuilder
    var paymentMethodSection: some View {
        Section {
            paymentMethodClearRow

            if filteredPaymentMethods.isEmpty {
                paymentMethodEmptyStateRow
            } else {
                ForEach(filteredPaymentMethods, id: \.self) { paymentMethod in
                    paymentMethodRow(paymentMethod)
                }
            }
        } header: {
            Text("付款方式")
        }
    }

    // MARK: Rows

    /// 單一日期區間 row：calendar icon + 區間 title + 末端 checkmark (當該區間為目前 pending 選擇時)
    ///
    /// 點選只更新 ``pendingDatePeriod``，**不** dispatch、**不** dismiss；使用者改完所有想改的欄位後再按右上「套用」(``applyAndDismiss()``) 才 commit 變動
    /// - Parameter period: 該列代表的日期區間
    /// - Returns: row view
    @ViewBuilder
    func datePeriodRow(_ period: OrderDatePeriod) -> some View {
        Button {
            pendingDatePeriod = period
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "calendar")
                    .foregroundStyle(.tint)

                Text(period.title)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if pendingDatePeriod == period {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 類別「全部」清除 row：點選只把 ``pendingCategory`` 設為 `nil`，不 dispatch、不 dismiss
    ///
    /// 當 ``pendingCategory`` 為 `nil` 時顯示 checkmark；不參與 ``filteredCategories`` 搜尋過濾、永遠顯示
    @ViewBuilder
    var categoryClearRow: some View {
        Button {
            pendingCategory = nil
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "tag")
                    .foregroundStyle(.tint)

                Text("全部")
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if pendingCategory == nil {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 單一類別 row：tag icon + 類別名 + 末端 checkmark (當該類別為目前 pending 選擇時)
    ///
    /// 點選只更新 ``pendingCategory``，不 dispatch、不 dismiss。多行支援同 ``datePeriodRow(_:)`` 規格
    /// - Parameter category: 該列代表的類別名稱
    /// - Returns: row view
    @ViewBuilder
    func categoryRow(_ category: String) -> some View {
        Button {
            pendingCategory = category
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "tag")
                    .foregroundStyle(.tint)

                Text(category)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if pendingCategory == category {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 類別 section 在搜尋無匹配或類別清單本身為空時顯示的空狀態 row
    @ViewBuilder
    var categoryEmptyStateRow: some View {
        ContentUnavailableView(
            "沒有符合的類別",
            systemImage: "tray",
            description: Text("試試其他搜尋關鍵字，或回到設定頁新增類別。")
        )
    }

    /// 付款方式「全部」清除 row：點選只把 ``pendingPaymentMethod`` 設為 `nil`，不 dispatch、不 dismiss
    ///
    /// 當 ``pendingPaymentMethod`` 為 `nil` 時顯示 checkmark；不參與 ``filteredPaymentMethods`` 搜尋過濾、永遠顯示
    @ViewBuilder
    var paymentMethodClearRow: some View {
        Button {
            pendingPaymentMethod = nil
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "creditcard")
                    .foregroundStyle(.tint)

                Text("全部")
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if pendingPaymentMethod == nil {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 單一付款方式 row：creditcard icon + 付款方式名 + 末端 checkmark (當該付款方式為目前 pending 選擇時)
    ///
    /// 點選只更新 ``pendingPaymentMethod``，不 dispatch、不 dismiss。多行支援同 ``datePeriodRow(_:)`` 規格
    /// - Parameter paymentMethod: 該列代表的付款方式名稱
    /// - Returns: row view
    @ViewBuilder
    func paymentMethodRow(_ paymentMethod: String) -> some View {
        Button {
            pendingPaymentMethod = paymentMethod
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "creditcard")
                    .foregroundStyle(.tint)

                Text(paymentMethod)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if pendingPaymentMethod == paymentMethod {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 付款方式 section 在搜尋無匹配或付款方式清單本身為空時顯示的空狀態 row
    @ViewBuilder
    var paymentMethodEmptyStateRow: some View {
        ContentUnavailableView(
            "沒有符合的付款方式",
            systemImage: "tray",
            description: Text("試試其他搜尋關鍵字，或回到設定頁新增付款方式。")
        )
    }
}

// MARK: - Private Method

private extension OrderFilterSheet {

    /// 把 pending 篩選 commit 到 store，然後關 sheet
    ///
    /// 只在 pending 與 store 目前值不同時才 dispatch 對應 action，避免冗餘 reducer 觸發 (例如 `selectedOrderID` 只在篩選真有變動時才重算)
    ///
    /// 即使無任何 pending 變動，仍會呼叫 `dismiss()`——「套用」永遠 dismiss sheet
    func applyAndDismiss() {
        if pendingDatePeriod != store.state.selectedDatePeriod {
            store.send(.datePeriodSelected(pendingDatePeriod))
        }

        if pendingCategory != store.state.selectedCategory {
            store.send(.categoryFilterSelected(pendingCategory))
        }

        if pendingPaymentMethod != store.state.selectedPaymentMethod {
            store.send(.paymentMethodFilterSelected(pendingPaymentMethod))
        }

        dismiss()
    }

    /// 依 ``searchText`` 過濾後的類別清單
    ///
    /// 空字串 (或全空白) 時返回完整 `availableCategories`；否則以 `localizedStandardContains` 比對類別名稱 (自動折疊大小寫／變音／全半形)
    /// clear row「全部」不參與此過濾，由 ``categorySection`` 在外層永遠渲染
    var filteredCategories: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return store.state.availableCategories
        }

        return store.state.availableCategories.filter { category in
            category.localizedStandardContains(trimmed)
        }
    }

    /// 依 ``searchText`` 過濾後的付款方式清單
    ///
    /// 取 ``OrdersFeature/State/availablePaymentMethods`` 的 `name` 欄位 (篩選只需名稱、不需 `isCardless` 旗標)
    /// 空字串 (或全空白) 時返回完整清單；否則以 `localizedStandardContains` 比對付款方式名稱 (自動折疊大小寫／變音／全半形)
    /// clear row「全部」不參與此過濾，由 ``paymentMethodSection`` 在外層永遠渲染
    var filteredPaymentMethods: [String] {
        let names = store.state.availablePaymentMethods.map(\.name)
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return names
        }

        return names.filter { name in
            name.localizedStandardContains(trimmed)
        }
    }
}

// MARK: - Preview

#Preview("整合篩選 sheet (.all + nil)") {
    OrderFilterSheet(
        store: Store(
            initialState: previewState(date: .all, category: nil)
        ) {
            OrdersFeature()
        }
    )
}

#Preview("整合篩選 sheet (.thisMonth + 美妝)") {
    OrderFilterSheet(
        store: Store(
            initialState: previewState(date: .thisMonth, category: "美妝")
        ) {
            OrdersFeature()
        }
    )
}

#Preview("整合篩選 sheet (.all + 含長類別名)") {
    OrderFilterSheet(
        store: Store(
            initialState: previewState(date: .all, category: "aespa Lemonade QQ 音樂限定禮包")
        ) {
            OrdersFeature()
        }
    )
}

/// 共用的 Preview 起手 state：注入指定的篩選組合與 sample 類別、付款方式清單
/// - Parameters:
///   - date: 預設選中的日期區間
///   - category: 預設選中的類別；`nil` 代表「全部」
///   - paymentMethod: 預設選中的付款方式；`nil` 代表「全部」
/// - Returns: 已套用篩選預設的 `OrdersFeature.State`
private func previewState(
    date: OrderDatePeriod,
    category: String?,
    paymentMethod: String? = nil
) -> OrdersFeature.State {
    var state = OrdersFeature.State()
    state.selectedDatePeriod = date
    state.selectedCategory = category
    state.selectedPaymentMethod = paymentMethod
    state.categoryMaster = [
        "3C",
        "美妝",
        "精品",
        "食品",
        "保健",
        "零食",
        "書籍",
        "aespa Lemonade QQ 音樂限定禮包"
    ]
    state.paymentMethodMaster = [
        PaymentMethodInfo(name: "信用卡", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
        PaymentMethodInfo(name: "現金", isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
        PaymentMethodInfo(name: "銀行轉帳", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
        PaymentMethodInfo(name: "貨到付款", isCardless: false, isBankTransfer: false, isCashOnDelivery: true)
    ]
    state.hasLoaded = true
    return state
}
