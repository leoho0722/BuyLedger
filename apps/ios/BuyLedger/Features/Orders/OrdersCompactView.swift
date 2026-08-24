//
//  OrdersCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// iPhone (compact) 使用的訂單瀏覽畫面
struct OrdersCompactView: View {
    
    // MARK: - View Properties
    
    /// 訂單功能 store
    @Bindable var store: StoreOf<OrdersFeature>
    
    /// App 目前選用的顯示語系
    let language: AppLanguage
    
    /// App 目前選用的顯示語系
    @Environment(\.locale) private var locale
    
    /// 篩選使用的目前時間；測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 訂單篩選與日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar
    
    // MARK: - View Body
    
    /// 訂單瀏覽畫面內容
    var body: some View {
        let palette = BLPalette()
        // 先計算一次 filteredOrders，再傳給各區塊
        let sections = store.state.dateSections(
            referenceDate: date.now,
            calendar: calendar,
            locale: locale
        )
        let filteredIDs = sections.flatMap(\.orders).map(\.id)
        let allFilteredSelected = !filteredIDs.isEmpty && filteredIDs.allSatisfy { store.selectedOrderIDs.contains($0) }
        NavigationStack(path: $store.scope(state: \.detailPath, action: \.detailPath)) {
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.medium) {
                    chipStrip(palette: palette)
                    unifiedFilterTrigger(palette: palette)
                    
                    // 持續性載入失敗才走這裡
                    // 一次性操作失敗改以 writeFailureAlert 對話框呈現，兩者不共用欄位
                    if case let .failed(message) = store.loadState {
                        Text(LocalizedStringKey(message))
                            .blTextStyle(.footnote)
                            .foregroundStyle(palette.red)
                            .padding(.horizontal, BLSpacing.large)
                    }
                    
                    listSection(palette: palette, sections: sections)
                }
                .padding(.top, BLSpacing.small)
                .padding(.bottom, BLSpacing.section)
            }
            .background(palette.background)
            .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
            .scrollDismissesKeyboard(.interactively)
            .rootNavigationTitle(store.navigationTitleKey, language: language)
            .toolbar {
                OrdersToolbarContent(
                    store: store,
                    palette: palette,
                    filteredIDs: filteredIDs,
                    allFilteredSelected: allFilteredSelected
                )
            }
            // searchable 無穩定 identifier，UI 測試改查 searchFields
            .searchable(
                text: $store.searchText.sending(\.searchTextChanged),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋客戶、單號或商品")
            )
            .task {
                await store.send(.task).finish()
            }
            .sheet(isPresented: $store.showsFilterSheet) {
                OrderFilterSheet(store: store)
            }
        } destination: { detailStore in
            if let order = store.orders.first(where: { $0.id == detailStore.orderID }) {
                OrderDetailView(order: order)
                    .navigationTitle(Text(verbatim: order.customer.name))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                // 「已合併」只能由合併流程寫入，僅當目前狀態已是已合併時保留選項
                                ForEach(
                                    OrderStatus.allCases.filter {
                                        $0 != .merged || order.status == .merged
                                    }
                                ) { status in
                                    Button {
                                        store.send(.statusChanged(order.id, status))
                                    } label: {
                                        if status == order.status {
                                            Label(
                                                LocalizedStringKey(status.title),
                                                systemImage: "checkmark")
                                        } else {
                                            Text(LocalizedStringKey(status.title))
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .accessibilityLabel("更新狀態")
                            .accessibilityIdentifier(
                                BLAccessibilityID.Orders.detailStatusMenuButton)
                        }
                        
                        // 將合併、編輯與刪除收進更多選單。
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                if order.status != .merged, order.status != .cancelled {
                                    Button {
                                        store.send(.mergeOrderTapped(order.id))
                                    } label: {
                                        Label("合併訂單", systemImage: "arrow.triangle.merge")
                                    }
                                    .accessibilityIdentifier(
                                        BLAccessibilityID.Orders.detailMergeButton)
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
                                .accessibilityIdentifier(
                                    BLAccessibilityID.Orders.detailDeleteButton)
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .accessibilityLabel("更多操作")
                            .accessibilityIdentifier(BLAccessibilityID.Orders.detailMoreButton)
                        }
                    }
            }
        }
    }
}

// MARK: - ViewBuilder

private extension OrdersCompactView {
    
    /// 狀態篩選 chip 橫向滾動列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: chip 列 view
    @ViewBuilder
    func chipStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    chipButton(filter, palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
        .scrollIndicators(.hidden)
    }
    
    /// 單一狀態篩選 chip
    /// - Parameters:
    ///   - filter: 要顯示的狀態篩選
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: chip 按鈕 view
    @ViewBuilder
    func chipButton(_ filter: OrderStatusFilter, palette: BLPalette) -> some View {
        BLFilterChip(
            title: LocalizedStringKey(filter.title),
            isSelected: store.selectedStatus == filter,
            size: .large
        ) {
            store.send(.statusFilterSelected(filter))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
    }
    
    /// 顯示日期、類別與付款方式的整合篩選按鈕
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: trigger button view (含左側內距，與其他篩選膠囊水平對齊)
    @ViewBuilder
    func unifiedFilterTrigger(palette: BLPalette) -> some View {
        let hasActiveFilter = store.committedFilterSelection.isActive
        let summary = filterSummaryText(
            date: store.selectedDatePeriod,
            category: store.selectedCategory,
            paymentMethod: store.selectedPaymentMethod
        )
        
        BLFilterChip(
            title: "篩選: \(summary)",
            isSelected: hasActiveFilter,
            style: .purple,
            size: .large,
            icon: "line.3.horizontal.decrease",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.filterSheetTapped)
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterButton)
        .padding(.horizontal, BLSpacing.large)
    }
    
    /// 訂單列表區塊，包含載入、空狀態與「以日期分組」的資料區段
    /// - Parameters:
    ///   - palette: 目前外觀使用的色盤
    ///   - sections: 已由 ``body`` 單次求值好的日期區段
    /// - Returns: 列表區塊 view
    @ViewBuilder
    func listSection(palette: BLPalette, sections: [OrderDateSection]) -> some View {
        if store.isLoading {
            ProgressView("載入訂單")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else {
            if sections.isEmpty {
                emptyState(palette: palette)
            } else {
                // 惰性只施加於外層日期區段，卡片內的訂單列容器維持非惰性。
                // 否則卡片背景會因高度漸進確定而包不住當日所有列
                LazyVStack(alignment: .leading, spacing: BLSpacing.medium) {
                    ForEach(sections) { section in
                        orderDateSection(section, palette: palette)
                    }
                }
            }
        }
    }
    
    /// 單一日期區段，包含日期標題與訂單卡片
    /// - Parameters:
    ///   - section: 要呈現的日期區段
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 日期區段 view
    @ViewBuilder
    func orderDateSection(_ section: OrderDateSection, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(LocalizedStringKey(section.title))
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .padding(.horizontal, BLSpacing.large)
            
            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(section.orders.enumerated()), id: \.element.id) { index, order in
                        if store.isSelecting {
                            OrderSelectableRow(
                                order: order, showsDate: false, palette: palette, store: store)
                        } else {
                            navigableRow(order: order)
                        }
                        
                        if index < section.orders.count - 1 {
                            Divider()
                                .padding(.leading, BLListMetrics.dividerInset)
                        }
                    }
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }
    
    /// 一般模式的訂單列；點擊開啟詳情，長按顯示操作選單
    /// - Parameter order: 要呈現的訂單
    /// - Returns: 可導覽的訂單列 view
    @ViewBuilder
    func navigableRow(order: LedgerOrder) -> some View {
        NavigationLink(state: OrderDetailPath.State(orderID: order.id)) {
            OrderRowView(order: order, showsDate: false)
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
    
    /// 沒有符合條件的訂單時顯示的空狀態
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 空狀態 view
    @ViewBuilder
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            "沒有符合條件的訂單",
            systemImage: "tray",
            description: Text("試著調整搜尋字詞或狀態篩選。")
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
        // 容器相對高度撐開後置中；垂直 ScrollView 內單設 maxHeight 不生效。
        // 空狀態會黏在頂端而非可視區域中央
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
        .background(palette.background)
    }
}

// MARK: - Private Method

private extension OrdersCompactView {
    
    /// 計算整合篩選按鈕的摘要文字
    /// - Parameters:
    ///   - date: 目前選中的日期區間
    ///   - category: 目前選中的類別；`nil` 代表「全部類別」
    ///   - paymentMethod: 目前選中的付款方式；`nil` 代表「全部付款方式」
    /// - Returns: trigger label 中「篩選：」後接的 summary 字串
    func filterSummaryText(
        date: OrderDatePeriod,
        category: String?,
        paymentMethod: String?
    ) -> Text {
        var summary: Text?
        if date != .all {
            summary = Text(LocalizedStringKey(date.title))
        }
        if let category {
            summary = appendVerbatim(category, to: summary)
        }
        if let paymentMethod {
            summary = appendVerbatim(paymentMethod, to: summary)
        }
        return summary ?? Text("全部")
    }
    
    /// 以原文串接外部資料，避免誤翻譯
    /// - Parameters:
    ///   - value: 要串接的字串
    ///   - summary: 目前已串接的 summary；`nil` 代表尚未有任何片段
    /// - Returns: 串接後的 summary；若 `summary` 為 `nil`，回傳僅含 `value` 的 `Text`
    func appendVerbatim(_ value: String, to summary: Text?) -> Text {
        guard let summary else {
            return Text(verbatim: value)
        }
        return summary + Text(verbatim: " · \(value)")
    }
}

// MARK: - Preview

#Preview("iPhone 訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        return state
    }()
    
    OrdersCompactView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        },
        language: .traditionalChinese
    )
}
