//
//  OrderFilterSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import SwiftUI

/// iPhone Compact 訂單頁的整合篩選 sheet。
///
/// 把「日期區間」與「商品類別」兩種篩選整合到單一 sheet，由 ``OrdersCompactView`` 的整合 trigger button 開啟。
///
/// 結構：`NavigationStack` 包 `List` 兩個 `Section`，左上 toolbar「取消」按鈕收合 sheet。第一個 `Section` 為「日期區間」，列出 ``OrderDatePeriod/orderBrowsingCases``；第二個 `Section` 為「商品類別」，首列固定「全部」清除選項，其後依 ``OrdersFeature/State/availableCategories`` 列出 (受搜尋過濾)。點選任一列 dispatch 對應 ``OrdersFeature/Action`` 後 sheet 自動 dismiss。
///
/// 此元件**僅供 iPhone Compact 使用**；iPad regular 與 macOS 仍使用各自的 chip 列 + ``OptionPickerSheet`` 類別 trigger，與此 sheet 無關。
///
/// 故意不重用 ``OptionPickerSheet``：OptionPickerSheet 是「一個 sheet 對應一個單選 picker」的完整元件 (內含自己的 `NavigationStack` 與 toolbar)，要嵌入此 sheet 必須拆分元件，回歸風險高於從零實作。
struct OrderFilterSheet: View {

    // MARK: - View Properties

    /// 訂單功能 store；用於初始化 pending state 與 Apply 時 dispatch 變動。
    let store: StoreOf<OrdersFeature>

    /// 由 sheet 環境注入的 dismiss action；點「套用」或「取消」時收合 sheet。
    @Environment(\.dismiss) private var dismiss

    /// 類別 section 的搜尋輸入；只過濾類別列，**不**影響日期 section。
    @State private var searchText = ""

    /// 使用者在 sheet 內 pending 的日期區間選擇。
    ///
    /// 點 row 只更新此 pending state，不 dispatch；要按右上「套用」才把變動 commit 到 store。
    @State private var pendingDatePeriod: OrderDatePeriod

    /// 使用者在 sheet 內 pending 的類別選擇 (`nil` 代表「全部」)。
    ///
    /// 點 row 只更新此 pending state，不 dispatch；要按右上「套用」才把變動 commit 到 store。
    @State private var pendingCategory: String?

    // MARK: - Init

    /// 從目前 store state 取得 pending 初值。
    /// - Parameter store: 訂單功能 store。
    init(store: StoreOf<OrdersFeature>) {
        self.store = store
        self._pendingDatePeriod = State(initialValue: store.state.selectedDatePeriod)
        self._pendingCategory = State(initialValue: store.state.selectedCategory)
    }

    // MARK: - View Body

    /// 整合篩選 sheet 的內容。
    var body: some View {
        NavigationStack {
            List {
                datePeriodSection
                categorySection
            }
            .navigationTitle("篩選")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
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
#if !os(macOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋類別")
            )
#else
            .searchable(text: $searchText, prompt: Text("搜尋類別"))
#endif
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - ViewBuilder (Sections)

private extension OrderFilterSheet {

    /// 「日期區間」section：固定 4 列，順序為 ``OrderDatePeriod/orderBrowsingCases``。
    ///
    /// 搜尋輸入完全不影響此 section——4 列永遠顯示。
    var datePeriodSection: some View {
        Section {
            ForEach(OrderDatePeriod.orderBrowsingCases) { period in
                datePeriodRow(period)
            }
        } header: {
            Text("日期區間")
        }
    }

    /// 「商品類別」section：第一列固定「全部」clear row，其後依 ``filteredCategories`` 列出。
    ///
    /// 當搜尋無匹配 (`filteredCategories.isEmpty`) 時，類別列以 `ContentUnavailableView` 空狀態取代；clear row 仍維持顯示。
    /// 當 `availableCategories` 本身為空時，行為相同 (clear row + 空狀態描述「尚無類別」)。
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
}

// MARK: - ViewBuilder (Rows)

private extension OrderFilterSheet {

    /// 單一日期區間 row：calendar icon + 區間 title + 末端 checkmark (當該區間為目前 pending 選擇時)。
    ///
    /// 點選只更新 ``pendingDatePeriod``，**不** dispatch、**不** dismiss；使用者改完所有想改的欄位後再按右上「套用」(``applyAndDismiss()``) 才 commit 變動。
    /// - Parameter period: 該列代表的日期區間。
    /// - Returns: row view。
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

    /// 類別「全部」清除 row：點選只把 ``pendingCategory`` 設為 `nil`，不 dispatch、不 dismiss。
    ///
    /// 當 ``pendingCategory`` 為 `nil` 時顯示 checkmark；不參與 ``filteredCategories`` 搜尋過濾、永遠顯示。
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

    /// 單一類別 row：tag icon + 類別名 + 末端 checkmark (當該類別為目前 pending 選擇時)。
    ///
    /// 點選只更新 ``pendingCategory``，不 dispatch、不 dismiss。多行支援同 ``datePeriodRow(_:)`` 規格。
    /// - Parameter category: 該列代表的類別名稱。
    /// - Returns: row view。
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

    /// 類別 section 在搜尋無匹配或類別清單本身為空時顯示的空狀態 row。
    var categoryEmptyStateRow: some View {
        ContentUnavailableView(
            "沒有符合的類別",
            systemImage: "tray",
            description: Text("試試其他搜尋關鍵字，或回到設定頁新增類別。")
        )
    }
}

// MARK: - Private Method

private extension OrderFilterSheet {

    /// 把 pending 篩選 commit 到 store，然後關 sheet。
    ///
    /// 只在 pending 與 store 目前值不同時才 dispatch 對應 action，避免冗餘 reducer 觸發 (例如 `selectedOrderID` 只在篩選真有變動時才重算)。即使無任何 pending 變動，仍會呼叫 `dismiss()`——「套用」永遠 dismiss sheet。
    func applyAndDismiss() {
        if pendingDatePeriod != store.state.selectedDatePeriod {
            store.send(.datePeriodSelected(pendingDatePeriod))
        }

        if pendingCategory != store.state.selectedCategory {
            store.send(.categoryFilterSelected(pendingCategory))
        }

        dismiss()
    }

    /// 依 ``searchText`` 過濾後的類別清單。
    ///
    /// 空字串 (或全空白) 時返回完整 `availableCategories`；否則以 case-insensitive `contains` 比對類別名稱。
    /// clear row「全部」不參與此過濾，由 ``categorySection`` 在外層永遠渲染。
    var filteredCategories: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            return store.state.availableCategories
        }

        return store.state.availableCategories.filter { category in
            category.lowercased().contains(trimmed)
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

/// 共用的 Preview 起手 state：注入指定的篩選組合與 sample 類別清單。
/// - Parameters:
///   - date: 預設選中的日期區間。
///   - category: 預設選中的類別；`nil` 代表「全部」。
/// - Returns: 已套用篩選預設的 `OrdersFeature.State`。
private func previewState(date: OrderDatePeriod, category: String?) -> OrdersFeature.State {
    var state = OrdersFeature.State()
    state.selectedDatePeriod = date
    state.selectedCategory = category
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
    state.hasLoaded = true
    return state
}
