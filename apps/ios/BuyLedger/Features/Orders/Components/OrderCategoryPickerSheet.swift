//
//  OrderCategoryPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import SwiftUI

/// 寬版訂單頁的類別暫存多選、搜尋與完成表單
struct OrderCategoryPickerSheet: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層或 App 進入點建立後傳入
    @Bindable var store: StoreOf<OrderCategoryPickerFeature>

    // MARK: - Body

    /// 搜尋採固定識別的普通列，避免 header 隨結果更新重建而使輸入框失焦，分組每次重繪只算一次
    var body: some View {
        let groups = store.categoryGroups
        NavigationStack {
            List {
                Section {
                    OrderCategoryFilterRows.SearchRow(
                        isSearchFieldFocused: $store.isSearchFieldFocused,
                        searchText: $store.searchText,
                        clearIdentifier: BLAccessibilityID.Orders.categoryPickerSearchClearButton,
                        fieldIdentifier: BLAccessibilityID.Orders.categoryPickerSearchField,
                        onClear: {
                            store.send(.view(.searchClearTapped))
                        },
                        onSubmit: {
                            store.send(.view(.searchSubmitted))
                        }
                    )
                }
                .listSectionMargins(.bottom, BLSpacing.medium)

                Section {
                    OrderCategoryFilterRows.AllAndEmptyRows(
                        allIdentifier: BLAccessibilityID.Orders.categoryPickerAllOption,
                        isAllSelected: store.pendingCategories.isEmpty,
                        isEmpty: groups.isEmpty,
                        onAllTapped: {
                            store.send(.view(.allTapped))
                        }
                    )
                }
                .listSectionMargins(.top, 0)

                OrderCategoryGrid(
                    groups: groups,
                    initialColumnCount: 4,
                    onCategoryTapped: {
                        store.send(.view(.categoryToggled($0)))
                    },
                    onGroupTapped: {
                        store.send(.view(.groupToggled($0)))
                    },
                    selected: store.pendingCategories
                )
                .blTextStyle(.subhead)
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, BLHitTarget.minimum)
            .accessibilityIdentifier(BLAccessibilityID.Orders.categoryPickerSheet)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text("orders.list.label.category1"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                pickerToolbar
            }
        }
        .interactiveDismissDisabled(store.hasUnappliedChanges)
        .presentationSizing(.form)
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.discardConfirmation, action: \.discardConfirmation))
    }
}

// MARK: - Private Views

private extension OrderCategoryPickerSheet {

    /// 選擇器頂部的取消與完成入口
    @ToolbarContentBuilder
    var pickerToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            cancelButton
        }

        ToolbarItem(placement: .confirmationAction) {
            doneButton
        }
    }

    /// 取消，有未套用變更時由 Feature 顯示確認
    var cancelButton: some View {
        Button {
            store.send(.view(.cancelTapped))
        } label: {
            Image(systemName: "xmark")
                .frame(minWidth: BLHitTarget.minimum, minHeight: BLHitTarget.minimum)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("common.action.cancel"))
        .accessibilityIdentifier(BLAccessibilityID.Orders.categoryPickerCancelButton)
    }

    /// 將完整暫存集合交給清單提交
    var doneButton: some View {
        Button {
            store.send(.view(.doneTapped))
        } label: {
            Text("common.action.button.done")
                .frame(minHeight: BLHitTarget.minimum)
                .blTextStyle(.body)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(BLAccessibilityID.Orders.categoryPickerDoneButton)
    }
}

// MARK: - Preview

#Preview("類別選擇器 (兩組展開與長名稱)") {
    let source = OrderFilterPreviewFixtures.makeState(
        selection: OrderFilterSelection(categories: ["美妝", "書籍"])
    )
    OrderCategoryPickerSheet(
        store: Store(
            initialState: OrderCategoryPickerFeature.State(
                orders: source.$orders,
                campaigns: SharedReader(value: source.campaigns),
                lookupCatalog: source.$lookupCatalog,
                committedCategories: ["美妝", "書籍"],
                dateContext: source.dateContext
            )
        ) {
            OrderCategoryPickerFeature()
        }
    )
}
