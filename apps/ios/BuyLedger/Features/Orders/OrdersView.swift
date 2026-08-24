//
//  OrdersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 訂單列表與詳情畫面
struct OrdersView: View {
    
    // MARK: - View Properties
    
    /// 訂單功能 store
    @Bindable var store: StoreOf<OrdersFeature>
    
    /// App 目前選用的顯示語系
    let language: AppLanguage
    
    /// 目前水平尺寸分類，用來區分 iPhone 與 iPad 佈局
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// 篩選使用的目前時間；測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 訂單篩選與日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar
    
    // MARK: - View Body
    
    /// 訂單功能的畫面內容
    var body: some View {
        platformContent
            .sheet(item: $store.scope(state: \.editOrder, action: \.editOrder)) { editStore in
                OrderEditView(store: editStore)
            }
            .sheet(item: $store.scope(state: \.aiSummary, action: \.aiSummary)) { summaryStore in
                AISummaryView(store: summaryStore)
            }
            .sheet(item: $store.scope(state: \.orderMerge, action: \.orderMerge)) { mergeStore in
                OrderMergeCandidateSheet(store: mergeStore)
            }
            .alert($store.scope(state: \.deletionConfirmation, action: \.deletionConfirmation))
            .alert($store.scope(state: \.writeFailureAlert, action: \.writeFailureAlert))
            .alert($store.scope(state: \.aiDisabledAlert, action: \.aiDisabledAlert))
    }
}

// MARK: - ViewBuilder

private extension OrdersView {
    
    /// 依尺寸分類選擇對應的訂單瀏覽 view
    @ViewBuilder
    var platformContent: some View {
        if horizontalSizeClass == .compact {
            OrdersCompactView(store: store, language: language)
        } else {
            regularSplitContent
        }
    }
    
    /// iPad regular 使用的「清單 + 詳情」兩欄佈局
    @ViewBuilder
    var regularSplitContent: some View {
        let palette = BLPalette()
        // 先計算一次 filteredOrders，再傳給各區塊
        let filtered = store.state.filteredOrders(referenceDate: date.now, calendar: calendar)
        let filteredIDs = filtered.map(\.id)
        let allFilteredSelected =
        !filteredIDs.isEmpty && filteredIDs.allSatisfy { store.selectedOrderIDs.contains($0) }
        NavigationStack {
            HStack(spacing: 0) {
                listPane(orders: filtered)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
                    .background(palette.background)
                
                Divider()
                
                detailPane(filteredOrders: filtered)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(palette.background)
            }
            .rootNavigationTitle(store.navigationTitleKey, language: language)
            // searchable 無穩定 identifier，UI 測試改查 searchFields
            .searchable(
                text: $store.searchText.sending(\.searchTextChanged),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋客戶、單號或商品")
            )
            .toolbar {
                OrdersToolbarContent(
                    store: store,
                    palette: palette,
                    filteredIDs: filteredIDs,
                    allFilteredSelected: allFilteredSelected
                )
            }
        }
        .task {
            await store.send(.task).finish()
        }
        .sheet(isPresented: $store.showsCategoryPicker) {
            OptionPickerSheet(
                title: "選擇商品類別",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "沒有符合的類別",
                emptyDescription: "試試其他搜尋關鍵字。",
                options: store.availableCategories,
                selected: store.selectedCategory ?? "",
                onSelect: { category in
                    store.send(.categoryFilterSelected(category))
                },
                clearOption: OptionPickerSheet.ClearOption(
                    title: "全部",
                    onClear: {
                        store.send(.categoryFilterSelected(nil))
                    }
                )
            )
        }
        .sheet(isPresented: $store.showsPaymentMethodPicker) {
            OptionPickerSheet(
                title: "選擇付款方式",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "沒有符合的付款方式",
                emptyDescription: "試試其他搜尋關鍵字。",
                options: store.availablePaymentMethods.map(\.name),
                selected: store.selectedPaymentMethod ?? "",
                onSelect: { paymentMethod in
                    store.send(.paymentMethodFilterSelected(paymentMethod))
                },
                clearOption: OptionPickerSheet.ClearOption(
                    title: "全部",
                    onClear: {
                        store.send(.paymentMethodFilterSelected(nil))
                    }
                )
            )
        }
    }
    
    /// 訂單列表欄
    /// - Parameter orders: 已由 ``regularSplitContent`` 單次求值好的篩選結果
    /// - Returns: 訂單列表欄 view
    @ViewBuilder
    func listPane(orders: [LedgerOrder]) -> some View {
        let palette = BLPalette()
        
        VStack(spacing: 0) {
            listHeader(palette: palette)
            
            ScrollView {
                if store.isLoading {
                    ProgressView("載入訂單")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, BLSpacing.large)
                } else if orders.isEmpty {
                    ContentUnavailableView("沒有符合條件的訂單", systemImage: "tray")
                        .padding(.top, BLSpacing.extraLarge)
                        .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
                } else {
                    orderListCard(orders: orders)
                        .padding(.horizontal, BLSpacing.medium)
                        .padding(.bottom, BLSpacing.medium)
                }
            }
            .background(palette.background)
            .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
        }
    }
    
    /// 卡片化的訂單列表，內含逐列訂單與分隔線
    /// - Parameter orders: 已套用篩選的訂單清單
    /// - Returns: 卡片化的訂單列表 view
    @ViewBuilder
    func orderListCard(orders: [LedgerOrder]) -> some View {
        let palette = BLPalette()
        
        BLCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                    if store.isSelecting {
                        OrderSelectableRow(order: order, palette: palette, store: store)
                    } else {
                        selectDetailRow(order: order)
                    }
                    
                    if index < orders.count - 1 {
                        Divider()
                            .padding(.leading, BLListMetrics.dividerInset)
                    }
                }
            }
        }
    }
    
    /// 一般模式的訂單列；點擊開啟詳情，長按顯示操作選單
    /// - Parameter order: 要呈現的訂單
    /// - Returns: 可選取詳情的訂單列 view
    @ViewBuilder
    func selectDetailRow(order: LedgerOrder) -> some View {
        Button {
            store.send(.orderSelected(order.id))
        } label: {
            OrderRowView(order: order)
                .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if order.status != .merged, order.status != .cancelled {
                Button {
                    store.send(.mergeOrderTapped(order.id))
                } label: {
                    Label("合併訂單", systemImage: "arrow.triangle.merge")
                }
            }
            
            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除訂單", systemImage: "trash")
            }
        }
    }
    
    /// 訂單列表上方的標題、搜尋與狀態篩選
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 列表 header view
    @ViewBuilder
    func listHeader(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            chipScrollStrip(palette: palette)
            dateChipScrollStrip(palette: palette)
            if !store.availablePaymentMethods.isEmpty {
                paymentMethodFilterTrigger(palette: palette)
            }
            if !store.availableCategories.isEmpty {
                categoryFilterTrigger(palette: palette)
            }
            
            // 持續性載入失敗才走這裡
            // 一次性操作失敗改以 writeFailureAlert 對話框呈現，兩者不共用欄位
            if case let .failed(message) = store.loadState {
                Text(LocalizedStringKey(message))
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.red)
            }
        }
        .padding(.top, BLSpacing.small)
        .padding(.horizontal, BLSpacing.medium)
        .padding(.bottom, BLSpacing.medium)
    }
    
    /// iPad 中間欄使用的橫向滾動狀態 chip 列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: chip 列 view
    @ViewBuilder
    func chipScrollStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    BLFilterChip(
                        title: LocalizedStringKey(filter.title),
                        isSelected: store.selectedStatus == filter
                    ) {
                        store.send(.statusFilterSelected(filter))
                    }
                    .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    /// iPad 中間欄使用的橫向滾動日期區間 chip 列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 日期 chip 列 view
    @ViewBuilder
    func dateChipScrollStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderDatePeriod.orderBrowsingCases) { period in
                    BLFilterChip(
                        title: LocalizedStringKey(period.title),
                        isSelected: store.selectedDatePeriod == period,
                        style: .accent,
                        icon: "calendar"
                    ) {
                        store.send(.datePeriodSelected(period))
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    /// iPad regular 中間欄使用的商品類別篩選 trigger button
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: trigger button view (左對齊，剩餘水平空間由 ``SwiftUI/Spacer`` 推開)
    @ViewBuilder
    func categoryFilterTrigger(palette: BLPalette) -> some View {
        let isSelected = store.selectedCategory != nil
        let currentLabel = store.selectedCategory ?? "全部"
        
        BLFilterChip(
            title: "類別：\(currentLabel)",
            isSelected: isSelected,
            style: .purple,
            icon: "tag",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.categoryPickerTapped)
        }
    }
    
    /// iPad regular 中間欄使用的付款方式篩選 trigger button
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: trigger button view (左對齊，剩餘水平空間由 ``SwiftUI/Spacer`` 推開)
    @ViewBuilder
    func paymentMethodFilterTrigger(palette: BLPalette) -> some View {
        let isSelected = store.selectedPaymentMethod != nil
        let currentLabel = store.selectedPaymentMethod ?? "全部"
        
        BLFilterChip(
            title: "付款方式：\(currentLabel)",
            isSelected: isSelected,
            style: .purple,
            icon: "creditcard",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.paymentMethodPickerTapped)
        }
    }
    
    /// 訂單詳情欄
    /// - Parameter filteredOrders: 已由 ``regularSplitContent`` 單次求值好的篩選結果
    /// - Returns: 詳情欄 view
    @ViewBuilder
    func detailPane(filteredOrders: [LedgerOrder]) -> some View {
        let palette = BLPalette()
        
        if let order = selectedOrder(in: filteredOrders) {
            // 標題列疊在捲動內容上，底色使用系統 bar 材質。
            OrderDetailView(order: order, layout: .wide)
                .safeAreaInset(edge: .top, spacing: 0) {
                    detailTitleBar(order: order)
                }
        } else {
            ContentUnavailableView("選擇訂單", systemImage: "list.bullet.rectangle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
        }
    }
    
    /// 詳情欄頂部的姓名列，含狀態與更多操作選單
    /// - Parameter order: 要顯示的訂單
    /// - Returns: 自繪標題列 view
    @ViewBuilder
    func detailTitleBar(order: LedgerOrder) -> some View {
        let palette = BLPalette()
        
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text(order.customer.name)
                .blTextStyle(.title3Bold)
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            statusUpdateMenu(order: order)
            
            moreActionsMenu(order: order)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 使用系統 bar 材質保留捲動邊緣效果。
        .background(.bar)
    }
    
    /// 詳情頁的狀態更新選單；已合併只能由合併流程寫入
    /// - Parameter order: 對應訂單
    /// - Returns: menu view
    @ViewBuilder
    func statusUpdateMenu(order: LedgerOrder) -> some View {
        Menu {
            ForEach(OrderStatus.allCases.filter { $0 != .merged || order.status == .merged }) {
                status in
                Button {
                    store.send(.statusChanged(order.id, status))
                } label: {
                    if status == order.status {
                        Label(LocalizedStringKey(status.title), systemImage: "checkmark")
                    } else {
                        Text(LocalizedStringKey(status.title))
                    }
                }
            }
        } label: {
            Label("更新狀態", systemImage: "arrow.triangle.2.circlepath")
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailStatusMenuButton)
    }
    
    /// 詳情頁右上角的合併、編輯與刪除選單
    /// - Parameter order: 對應訂單
    /// - Returns: menu view
    @ViewBuilder
    func moreActionsMenu(order: LedgerOrder) -> some View {
        Menu {
            if order.status != .merged, order.status != .cancelled {
                Button {
                    store.send(.mergeOrderTapped(order.id))
                } label: {
                    Label("合併訂單", systemImage: "arrow.triangle.merge")
                }
                .accessibilityIdentifier(BLAccessibilityID.Orders.detailMergeButton)
            }
            
            Button {
                store.send(.editOrderTapped(order.id))
            } label: {
                Label("編輯", systemImage: "pencil")
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailEditButton)
            
            Divider()
            
            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除", systemImage: "trash")
            }
            .accessibilityIdentifier(BLAccessibilityID.Orders.detailDeleteButton)
        } label: {
            Label("更多", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .accessibilityLabel("更多操作")
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailMoreButton)
    }
}

// MARK: - Private Method

private extension OrdersView {
    
    /// 目前選取的訂單；不在篩選結果時為 nil
    /// - Parameter filteredOrders: 已單次求值好的篩選結果
    /// - Returns: 對應的訂單；`selectedOrderID` 為 `nil` 時回傳第一筆
    func selectedOrder(in filteredOrders: [LedgerOrder]) -> LedgerOrder? {
        guard let selectedOrderID = store.selectedOrderID else {
            return filteredOrders.first
        }
        return filteredOrders.first { $0.id == selectedOrderID }
    }
}

// MARK: - Preview

#Preview("訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        state.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        return state
    }()
    
    OrdersView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        },
        language: .traditionalChinese
    )
}
