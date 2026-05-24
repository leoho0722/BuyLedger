//
//  OrdersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 訂單列表與詳情畫面。
///
/// 依平台選擇對應導覽樣式：iPhone (compact) 使用 NavigationStack 對應的 ``OrdersCompactView``，macOS 使用扁平 ``Table`` 對應的 ``OrdersMacView``，iPadOS (regular) 以 ``HStack`` 在父層 NavigationSplitView 的 detail 欄中自排列「清單 + 詳情」兩欄，避免巢狀 NavigationSplitView 互相搶寬度。
struct OrdersView: View {
    
    // MARK: - View Properties
    
    /// 訂單功能 store。
    @Bindable var store: StoreOf<OrdersFeature>
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

#if !os(macOS)
    /// 目前水平尺寸分類，用來在 iOS 上區分 iPhone 與 iPad 佈局。
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:)`` 的「現在」時間；測試可注入固定值。
    @Dependency(\.date) private var date

    // MARK: - View Body
    
    /// 訂單功能的畫面內容。
    var body: some View {
        platformContent
            .sheet(item: $store.scope(state: \.editOrder, action: \.editOrder)) { editStore in
                OrderEditView(store: editStore)
            }
            .alert($store.scope(state: \.deletionConfirmation, action: \.deletionConfirmation))
    }
    
    /// 依平台與尺寸分類選擇對應的訂單瀏覽 view。
    @ViewBuilder
    private var platformContent: some View {
#if os(macOS)
        OrdersMacView(store: store)
#else
        if horizontalSizeClass == .compact {
            OrdersCompactView(store: store)
        } else {
            regularSplitContent
        }
#endif
    }
}

// MARK: - ViewBuilder

private extension OrdersView {
    
    /// iPad regular 使用的「清單 + 詳情」兩欄佈局。
    ///
    /// 以 ``NavigationStack`` 包住兩欄並用 `.navigationTitle("訂單")` 提供系統大標題，讓頂端標題與「更多」等其他分頁一致對齊側邊欄 (先前用 HStack + 手動 `.padding(.top)` 會讓內容偏下、與側邊欄錯位)。內層僅用 ``HStack`` 自排「清單 + 詳情」，不再使用巢狀 ``NavigationSplitView``，避免兩層 split 互相搶寬度造成中間欄被擠壓。
    var regularSplitContent: some View {
        let palette = BLTheme.palette(for: colorScheme)

        return NavigationStack {
            HStack(spacing: 0) {
                listPane
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
                    .background(palette.background)

                Divider()

                detailPane
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(palette.background)
            }
            .navigationTitle("訂單")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Text("\(store.orders.count)")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(palette.secondaryLabel)

                    Button {
                        store.send(.newOrderTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增訂單")
                }
            }
        }
        .task {
            await store.send(.task).finish()
        }
    }
    
    /// 訂單列表欄。
    var listPane: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        return VStack(spacing: 0) {
            listHeader(palette: palette)
            
            List(selection: $store.selectedOrderID.sending(\.orderSelected)) {
                if store.isLoading {
                    ProgressView("載入訂單")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(palette.background)
                        .listRowSeparator(.hidden)
                } else if store.state.filteredOrders(referenceDate: date.now).isEmpty {
                    ContentUnavailableView("沒有符合條件的訂單", systemImage: "tray")
                        .listRowBackground(palette.background)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(store.state.filteredOrders(referenceDate: date.now)) { order in
                        Button {
                            store.send(.orderSelected(order.id))
                        } label: {
                            OrderRowView(order: order)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            store.selectedOrderID == order.id
                            ? palette.accent.opacity(0.12)
                            : palette.background
                        )
                        .tag(order.id)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.send(.deleteOrderTapped(order.id))
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                store.send(.deleteOrderTapped(order.id))
                            } label: {
                                Label("刪除訂單", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(palette.background)
        }
    }
    
    /// 訂單列表上方的標題、搜尋與狀態篩選。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 列表 header view。
    func listHeader(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            BLSearchField(
                placeholder: "搜尋客戶、單號或商品",
                text: $store.searchText.sending(\.searchTextChanged)
            )

            chipScrollStrip(palette: palette)
            dateChipScrollStrip(palette: palette)

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(palette.red)
            }
        }
        .padding(.top, BLSpacing.small)
        .padding(.horizontal, BLSpacing.medium)
        .padding(.bottom, BLSpacing.medium)
    }
    
    /// iPad 中間欄使用的橫向滾動狀態 chip 列。
    ///
    /// 在 320 px 寬的中間欄內，6 個 chip 無法單行排列，因此改用橫向滾動避免換行造成的視覺斷裂。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: chip 列 view。
    func chipScrollStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    let isSelected = store.selectedStatus == filter
                    
                    Button {
                        store.send(.statusFilterSelected(filter))
                    } label: {
                        Text(filter.title)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                            .foregroundStyle(isSelected ? palette.background : palette.secondaryLabel)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 12)
                            .background(isSelected ? palette.label : palette.fillTertiary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    /// iPad 中間欄使用的橫向滾動日期區間 chip 列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 日期 chip 列 view。
    func dateChipScrollStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderDatePeriod.orderBrowsingCases) { period in
                    let isSelected = store.selectedDatePeriod == period
                    
                    Button {
                        store.send(.datePeriodSelected(period))
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2.weight(.semibold))
                            
                            Text(period.title)
                                .font(.footnote.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? palette.accent : palette.secondaryLabel)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(isSelected ? palette.accent.opacity(0.18) : palette.fillTertiary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    /// 訂單詳情欄。
    @ViewBuilder
    var detailPane: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        if let order = store.state.selectedOrder(referenceDate: date.now) {
            VStack(spacing: 0) {
                detailTitleBar(order: order)
                OrderDetailView(order: order, layout: .wide)
            }
        } else {
            ContentUnavailableView("選擇訂單", systemImage: "list.bullet.rectangle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
        }
    }
    
    /// 詳情欄頂部的訂購人姓名標題列，含「編輯」按鈕。
    ///
    /// 因 iPad regular 的訂單詳情位於父層 NavigationSplitView 的 detail 中，但本 view 內部已不再使用 NavigationStack，所以以自繪標題列代替系統 navigation title。訂單編號已由 ``OrderDetailView`` 的內容區顯示，此處不再重複。
    /// - Parameter order: 要顯示的訂單。
    /// - Returns: 自繪標題列 view。
    func detailTitleBar(order: LedgerOrder) -> some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        return HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text(order.customer.name)
                .font(.title3.bold())
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            statusUpdateMenu(order: order)

            Button("編輯") {
                store.send(.editOrderTapped(order.id))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(palette.red)
            .accessibilityLabel("刪除訂單")
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    /// 詳情頁右上角的「更新狀態」menu，列出所有 ``OrderStatus``，目前狀態加 checkmark。
    /// - Parameter order: 對應訂單。
    /// - Returns: menu view。
    func statusUpdateMenu(order: LedgerOrder) -> some View {
        Menu {
            ForEach(OrderStatus.allCases) { status in
                Button {
                    store.send(.statusChanged(order.id, status))
                } label: {
                    if status == order.status {
                        Label(status.title, systemImage: "checkmark")
                    } else {
                        Text(status.title)
                    }
                }
            }
        } label: {
            Label("更新狀態", systemImage: "arrow.triangle.2.circlepath")
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
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
        }
    )
}
