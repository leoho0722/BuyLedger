//
//  OrderFilterCategorySection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 訂單篩選表單的商品類別區段
struct OrderFilterCategorySection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderFilterFeature>

    // MARK: - Body

    /// 顯示商品類別篩選的區段與選項列
    var body: some View {
        Section {
            categoryClearRow

            optionRows
        } header: {
            header
        }
    }
}

// MARK: - Private Views

private extension OrderFilterCategorySection {

    /// 清除類別篩選，點選後保留篩選表單
    @ViewBuilder
    var categoryClearRow: some View {
        Button {
            store.send(.view(.filterPendingCategorySelected(nil)))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "tag")
                    .foregroundStyle(.blAccent)

                Text("common.action.label.all")
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()

                if store.pendingFilterSelection.category == nil {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blAccent)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.pendingFilterSelection.category == nil ? .isSelected : [])
    }

    /// 商品類別選項列
    ///
    /// - Parameter category: 該列代表的類別名稱
    /// - Returns: 可選取的篩選列
    @ViewBuilder
    func categoryRow(_ category: String) -> some View {
        Button {
            store.send(.view(.filterPendingCategorySelected(category)))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "tag")
                    .foregroundStyle(.blAccent)

                Text(category)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()

                if store.pendingFilterSelection.category == category {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blAccent)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.category == category ? .isSelected : []
        )
    }

    /// 搜尋無匹配或類別清單為空時顯示的空狀態
    @ViewBuilder
    var categoryEmptyStateRow: some View {
        ContentUnavailableView(
            "orders.list.label.matchingCategories",
            systemImage: "tray",
            description: Text("orders.filter.message.tryAnotherSearch")
        )
    }

    /// 符合搜尋的選項，沒有符合項目時顯示空狀態
    @ViewBuilder
    var optionRows: some View {
        if store.filterSheetFilteredCategories.isEmpty {
            categoryEmptyStateRow
        } else {
            ForEach(store.filterSheetFilteredCategories, id: \.self) {
                categoryRow($0)
            }
        }
    }

    /// 顯示此區段的篩選項目名稱
    var header: some View {
        Text("orders.list.label.itemCategory")
    }
}

// MARK: - Preview

#Preview("商品類別篩選") {
    List {
        OrderFilterCategorySection(
            store: Store(
                initialState: OrderFilterPreviewFixtures.makeState(date: .all, category: nil)
            ) {
                OrderFilterFeature()
            }
        )
    }
}
