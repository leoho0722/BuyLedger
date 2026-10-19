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

    /// 依序呈現篩選條件、兩列選單與類別區段，分組只讀取一次
    var body: some View {
        let groups = store.filterSheetCategoryGroups
        NavigationStack {
            List {
                Section {
                    OrderFilterDateSection(store: store)

                    OrderFilterPaymentMethodSection(store: store)
                } header: {
                    conditionsHeader
                }
                .textCase(nil)

                OrderFilterCategorySection(store: store, groups: groups)
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, BLHitTarget.minimum)
            .accessibilityIdentifier(BLAccessibilityID.Orders.filterSheet)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text("orders.list.label.filter"))
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

    /// 篩選條件標題與清除暫存入口，預設值時由系統停用
    var conditionsHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text("orders.filter.label.conditions")
                .fixedSize(horizontal: false, vertical: true)
                .blTextStyle(.subhead)
                .foregroundStyle(.blSecondaryLabel)

            Spacer(minLength: BLSpacing.small)

            clearFiltersButton
        }
    }

    /// 重設暫存日期、付款方式與類別，套用前不提交
    var clearFiltersButton: some View {
        Button {
            store.send(.view(.filterClearTapped))
        } label: {
            Label("orders.filter.button.clearFilters", systemImage: "arrow.counterclockwise")
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: BLHitTarget.minimum)
                .labelStyle(.titleAndIcon)
                .blTextStyle(.subhead)
                .contentShape(Rectangle())
        }
        .disabled(!store.pendingFilterSelection.isActive)
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterClearButton)
    }

    /// 取消並在必要時確認捨棄尚未套用的篩選
    var cancelButton: some View {
        Button {
            store.send(.view(.filterCancelTapped))
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(Text("common.action.cancel"))
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterCancelButton)
    }

    /// 套用目前選取的日期、付款方式與類別
    var applyButton: some View {
        Button("orders.list.button.apply") {
            store.send(.view(.filterApplyTapped))
        }
        .buttonStyle(.borderedProminent)
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

#Preview("整合篩選 sheet (兩組展開含長名稱)") {
    OrderFilterSheet(
        store: Store(
            initialState: OrderFilterPreviewFixtures.makeState(
                selection: OrderFilterSelection(
                    datePeriod: .thisMonth,
                    categories: ["美妝", "書籍"],
                    paymentMethod: "信用卡"
                )
            )
        ) {
            OrderFilterFeature()
        }
    )
}

#Preview("整合篩選 sheet (搜尋食)") {
    OrderFilterSheet(
        store: Store(
            initialState: OrderFilterPreviewFixtures.makeState(
                selection: OrderFilterSelection(),
                searchText: "食"
            )
        ) {
            OrderFilterFeature()
        }
    )
}
