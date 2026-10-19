//
//  OrderFilterCategorySection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 商品類別搜尋、全部列與共用的分組格子
struct OrderFilterCategorySection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源
    @Bindable var store: StoreOf<OrderFilterFeature>

    /// 宿主本次重繪只計算一次的類別分組
    let groups: [OrderCategoryGroups.Display]

    // MARK: - Body

    /// 搜尋採固定識別的普通列，避免 header 隨結果更新重建而使輸入框失焦
    var body: some View {
        Section {
            OrderCategoryFilterRows.SearchRow(
                isSearchFieldFocused: $store.isSearchFieldFocused,
                searchText: $store.filterSheetSearchText,
                clearIdentifier: BLAccessibilityID.Orders.filterSearchClearButton,
                fieldIdentifier: BLAccessibilityID.Orders.filterSearchField,
                onClear: {
                    store.send(.view(.filterSearchClearTapped))
                },
                onSubmit: {
                    store.send(.view(.filterSearchSubmitted))
                }
            )
        } header: {
            categoryHeader
        }
        .listSectionMargins(.bottom, BLSpacing.medium)
        .textCase(nil)

        Section {
            OrderCategoryFilterRows.AllAndEmptyRows(
                allIdentifier: BLAccessibilityID.Orders.filterCategoryAllOption,
                isAllSelected: store.pendingFilterSelection.categories.isEmpty,
                isEmpty: groups.isEmpty,
                onAllTapped: {
                    store.send(.view(.filterPendingCategoriesCleared))
                }
            )
        }
        .listSectionMargins(.top, 0)

        categoryGrid
    }
}

// MARK: - Private Views

private extension OrderFilterCategorySection {

    /// 商品類別標題沿用系統水平內距，下緣保留搜尋欄間距
    var categoryHeader: some View {
        Text("orders.list.label.itemCategory")
            .frame(maxWidth: .infinity, alignment: .leading)
            .blTextStyle(.subhead)
            .foregroundStyle(.blSecondaryLabel)
            .listRowInsets(.bottom, BLSpacing.small)
    }

    /// 格子互動只傳送本 Feature 的類別與標題操作
    var categoryGrid: some View {
        OrderCategoryGrid(
            groups: groups,
            initialColumnCount: 3,
            onCategoryTapped: {
                store.send(.view(.filterPendingCategoryToggled($0)))
            },
            onGroupTapped: {
                store.send(.view(.filterCategoryGroupToggled($0)))
            },
            selected: store.pendingFilterSelection.categories
        )
        .blTextStyle(.subhead)
    }
}

// MARK: - Preview

#Preview("商品類別分組與搜尋") {
    let state = OrderFilterPreviewFixtures.makeState(date: .all, category: nil)
    List {
        OrderFilterCategorySection(
            store: Store(initialState: state) {
                OrderFilterFeature()
            },
            groups: state.filterSheetCategoryGroups
        )
    }
    .environment(\.defaultMinListRowHeight, BLHitTarget.minimum)
}
