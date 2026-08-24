//
//  OrderFilterSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import SwiftUI

/// iPhone Compact 訂單頁的整合篩選 sheet
struct OrderFilterSheet: View {
    
    // MARK: - View Properties
    
    /// 訂單篩選 sheet 的呈現 store
    @Bindable var store: StoreOf<OrdersFeature>
    
    // MARK: - View Body
    
    /// 整合篩選 sheet 的內容
    var body: some View {
        NavigationStack {
            List {
                datePeriodSection
                paymentMethodSection
                categorySection
            }
            .navigationTitle(Text("篩選"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.filterCancelTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("取消"))
                    .accessibilityIdentifier(BLAccessibilityID.Orders.filterCancelButton)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("套用") {
                        store.send(.filterApplyTapped)
                    }
                    .accessibilityIdentifier(BLAccessibilityID.Orders.filterApplyButton)
                }
            }
            .searchable(
                text: $store.filterSheetSearchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋類別或付款方式")
            )
            .accessibilityIdentifier(BLAccessibilityID.Orders.filterSheet)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // 有未套用變更時先確認捨棄。
        .interactiveDismissDisabled(store.hasUnappliedFilterChanges)
        .alert(
            $store.scope(state: \.filterDiscardConfirmation, action: \.filterDiscardConfirmation)
        )
    }
}

// MARK: - ViewBuilder

private extension OrderFilterSheet {
    
    // MARK: Sections
    
    /// 「日期區間」section：固定 4 列，順序為 ``OrderDatePeriod/orderBrowsingCases``
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
    
    /// 商品類別 section，包含「全部」與類別選項
    @ViewBuilder
    var categorySection: some View {
        Section {
            categoryClearRow
            
            let filteredCategories = store.filterSheetFilteredCategories
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
    
    /// 付款方式 section：第一列清除篩選，其後顯示可選項目
    @ViewBuilder
    var paymentMethodSection: some View {
        Section {
            paymentMethodClearRow
            
            let filteredPaymentMethods = store.filterSheetFilteredPaymentMethods
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
    
    /// 日期區間選項列
    /// - Parameter period: 該列代表的日期區間
    /// - Returns: row view
    @ViewBuilder
    func datePeriodRow(_ period: OrderDatePeriod) -> some View {
        Button {
            store.send(.filterPendingDatePeriodSelected(period))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "calendar")
                    .foregroundStyle(.tint)
                
                Text(LocalizedStringKey(period.title))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if store.pendingFilterSelection.datePeriod == period {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.datePeriod == period ? .isSelected : []
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterDatePeriod(period.id))
    }
    
    /// 清除類別篩選的 row；點選後不關閉 sheet
    @ViewBuilder
    var categoryClearRow: some View {
        Button {
            store.send(.filterPendingCategorySelected(nil))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "tag")
                    .foregroundStyle(.tint)
                
                Text("全部")
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if store.pendingFilterSelection.category == nil {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.pendingFilterSelection.category == nil ? .isSelected : [])
    }
    
    /// 商品類別選項列
    /// - Parameter category: 該列代表的類別名稱
    /// - Returns: row view
    @ViewBuilder
    func categoryRow(_ category: String) -> some View {
        Button {
            store.send(.filterPendingCategorySelected(category))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "tag")
                    .foregroundStyle(.tint)
                
                Text(category)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if store.pendingFilterSelection.category == category {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.category == category ? .isSelected : [])
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
    
    /// 付款方式的「全部」列；點選後清除付款方式篩選
    @ViewBuilder
    var paymentMethodClearRow: some View {
        Button {
            store.send(.filterPendingPaymentMethodSelected(nil))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "creditcard")
                    .foregroundStyle(.tint)
                
                Text("全部")
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if store.pendingFilterSelection.paymentMethod == nil {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.paymentMethod == nil ? .isSelected : []
        )
    }
    
    /// 付款方式 row，顯示名稱與勾選狀態
    /// - Parameter paymentMethod: 該列代表的付款方式名稱
    /// - Returns: row view
    @ViewBuilder
    func paymentMethodRow(_ paymentMethod: String) -> some View {
        Button {
            store.send(.filterPendingPaymentMethodSelected(paymentMethod))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "creditcard")
                    .foregroundStyle(.tint)
                
                Text(paymentMethod)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if store.pendingFilterSelection.paymentMethod == paymentMethod {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.paymentMethod == paymentMethod ? .isSelected : []
        )
    }
    
    /// 沒有符合付款方式時的空狀態列
    @ViewBuilder
    var paymentMethodEmptyStateRow: some View {
        ContentUnavailableView(
            "沒有符合的付款方式",
            systemImage: "tray",
            description: Text("試試其他搜尋關鍵字，或回到設定頁新增付款方式。")
        )
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

/// Preview 的初始篩選 state
/// - Parameters:
///   - date: 預設選中的日期區間
///   - category: 預設選中的類別；`nil` 代表「全部」
///   - paymentMethod: 預設選中的付款方式；`nil` 代表「全部」
/// - Returns: 已套用篩選預設、且未套用選擇與其一致的 `OrdersFeature.State`
private func previewState(
    date: OrderDatePeriod,
    category: String?,
    paymentMethod: String? = nil
) -> OrdersFeature.State {
    var state = OrdersFeature.State()
    state.selectedDatePeriod = date
    state.selectedCategory = category
    state.selectedPaymentMethod = paymentMethod
    state.$lookupCatalog.withLock {
        $0.categories = [
            "3C",
            "美妝",
            "精品",
            "食品",
            "保健",
            "零食",
            "書籍",
            "aespa Lemonade QQ 音樂限定禮包",
        ]
        $0.paymentMethods = [
            PaymentMethodInfo(
                name: "信用卡",
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
            PaymentMethodInfo(
                name: "現金",
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
            PaymentMethodInfo(
                name: "銀行轉帳",
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            ),
            PaymentMethodInfo(
                name: "貨到付款",
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            ),
        ]
    }
    state.hasLoaded = true
    // 預覽直接使用已套用的篩選。
    state.pendingFilterSelection = state.committedFilterSelection
    return state
}
