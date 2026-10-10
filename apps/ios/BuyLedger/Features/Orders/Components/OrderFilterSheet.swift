//
//  OrderFilterSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import SwiftUI

/// 窄版訂單頁的日期、付款方式與類別篩選表單
struct OrderFilterSheet: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderFilterFeature>

    // MARK: - Body

    /// 篩選表單骨架，依序顯示日期、付款方式與類別區段
    var body: some View {
        NavigationStack {
            List {
                OrderFilterDateSection(store: store)

                OrderFilterPaymentMethodSection(store: store)

                OrderFilterCategorySection(store: store)
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.filterSheet)
            .searchable(
                text: $store.filterSheetSearchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋類別或付款方式")
            )
            .navigationTitle(Text("篩選"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                filterToolbar
            }
        }
        // 有未套用變更時先確認捨棄
        .interactiveDismissDisabled(store.hasUnappliedFilterChanges)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(
            $store.scope(state: \.filterDiscardConfirmation, action: \.filterDiscardConfirmation)
        )
    }
}

// MARK: - Private Views

private extension OrderFilterSheet {

    /// 取消並在必要時確認捨棄尚未套用的篩選
    var cancelButton: some View {
        Button {
            store.send(.view(.filterCancelTapped))
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(Text("取消"))
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterCancelButton)
    }

    /// 套用目前選取的日期、付款方式與類別
    var applyButton: some View {
        Button("套用") {
            store.send(.view(.filterApplyTapped))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterApplyButton)
    }

    /// 篩選表單頂部的取消與套用入口
    @ToolbarContentBuilder
    var filterToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            cancelButton
        }

        ToolbarItem(placement: .confirmationAction) {
            applyButton
        }
    }
}

// MARK: - Preview

#Preview("整合篩選 sheet (.all + nil)") {
    OrderFilterSheet(
        store: Store(
            initialState: OrderFilterPreviewFixtures.makeState(date: .all, category: nil)
        ) {
            OrderFilterFeature()
        }
    )
}

#Preview("整合篩選 sheet (.thisMonth + 美妝)") {
    OrderFilterSheet(
        store: Store(
            initialState: OrderFilterPreviewFixtures.makeState(date: .thisMonth, category: "美妝")
        ) {
            OrderFilterFeature()
        }
    )
}

#Preview("整合篩選 sheet (.all + 含長類別名)") {
    OrderFilterSheet(
        store: Store(
            initialState: OrderFilterPreviewFixtures.makeState(
                date: .all,
                category: "aespa Lemonade QQ 音樂限定禮包"
            )
        ) {
            OrderFilterFeature()
        }
    )
}
