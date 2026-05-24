//
//  OrdersCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

#if !os(macOS)

import ComposableArchitecture
import SwiftUI

/// iPhone (compact) 使用的訂單瀏覽畫面。
///
/// 採用 NavigationStack 配合自訂大標題、橫向滾動的狀態 chip 與卡片化的訂單列表，對應設計稿的 iPhone 訂單列表樣式。
struct OrdersCompactView: View {
    
    // MARK: - View Properties
    
    /// 訂單功能 store。
    @Bindable var store: StoreOf<OrdersFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:)`` 的「現在」時間；測試可注入固定值。
    @Dependency(\.date) private var date

    /// iPhone NavigationStack 的瀏覽路徑。改用 path-driven binding，使訂單被刪除時可手動把對應 id 從 path 移除，觸發系統自動 pop 回列表。
    @State private var navigationPath: [LedgerOrder.ID] = []

    // MARK: - View Body
    
    /// 訂單瀏覽畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.medium) {
                    BLSearchField(
                        placeholder: "搜尋客戶、單號或商品",
                        text: $store.searchText.sending(\.searchTextChanged)
                    )
                    .padding(.horizontal, BLSpacing.large)
                    
                    chipStrip(palette: palette)
                    dateChipStrip(palette: palette)
                    
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(palette.red)
                            .padding(.horizontal, BLSpacing.large)
                    }
                    
                    listSection(palette: palette)
                }
                .padding(.top, BLSpacing.small)
                .padding(.bottom, BLSpacing.section)
            }
            .background(palette.background)
            .scrollDismissesKeyboard(.immediately)
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
            .navigationDestination(for: LedgerOrder.ID.self) { id in
                if let order = store.orders.first(where: { $0.id == id }) {
                    OrderDetailView(order: order)
                        .navigationTitle(order.customer.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
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
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                .accessibilityLabel("更新狀態")
                            }
                            
                            ToolbarItem(placement: .primaryAction) {
                                Button("編輯") {
                                    store.send(.editOrderTapped(order.id))
                                }
                            }

                            ToolbarItem(placement: .primaryAction) {
                                Button(role: .destructive) {
                                    store.send(.deleteOrderTapped(order.id))
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("刪除訂單")
                            }
                        }
                }
            }
            .task {
                await store.send(.task).finish()
            }
            .onChange(of: store.orders) { _, newOrders in
                let availableIDs = Set(newOrders.map(\.id))
                navigationPath.removeAll { !availableIDs.contains($0) }
            }
        }
    }
}

// MARK: - ViewBuilder

private extension OrdersCompactView {
    
    /// 狀態篩選 chip 橫向滾動列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: chip 列 view。
    func chipStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    chipButton(filter, palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }
    
    /// 單一狀態篩選 chip。
    /// - Parameters:
    ///   - filter: 要顯示的狀態篩選。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: chip 按鈕 view。
    func chipButton(_ filter: OrderStatusFilter, palette: BLPalette) -> some View {
        let isSelected = store.selectedStatus == filter
        
        return Button {
            store.send(.statusFilterSelected(filter))
        } label: {
            Text(filter.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(isSelected ? palette.background : palette.secondaryLabel)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(isSelected ? palette.label : palette.fillTertiary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    /// 日期區間篩選 chip 橫向滾動列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 日期 chip 列 view。
    func dateChipStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderDatePeriod.orderBrowsingCases) { period in
                    dateChipButton(period, palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }
    
    /// 單一日期區間 chip。
    /// - Parameters:
    ///   - period: 要顯示的日期區間。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 日期 chip 按鈕 view。
    func dateChipButton(_ period: OrderDatePeriod, palette: BLPalette) -> some View {
        let isSelected = store.selectedDatePeriod == period
        
        return Button {
            store.send(.datePeriodSelected(period))
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption.weight(.semibold))
                
                Text(period.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? palette.accent : palette.secondaryLabel)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(isSelected ? palette.accent.opacity(0.18) : palette.fillTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    /// 訂單列表卡片區塊，包含載入、空狀態與資料列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 列表區塊 view。
    @ViewBuilder
    func listSection(palette: BLPalette) -> some View {
        if store.isLoading {
            ProgressView("載入訂單")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else if store.state.filteredOrders(referenceDate: date.now).isEmpty {
            emptyState(palette: palette)
        } else {
            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(store.state.filteredOrders(referenceDate: date.now).enumerated()), id: \.element.id) { index, order in
                        NavigationLink(value: order.id) {
                            OrderRowView(order: order)
                                .padding(.horizontal, BLSpacing.large)
                                .padding(.vertical, BLSpacing.small)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.send(.deleteOrderTapped(order.id))
                            } label: {
                                Label("刪除訂單", systemImage: "trash")
                            }
                        }

                        if index < store.state.filteredOrders(referenceDate: date.now).count - 1 {
                            Divider()
                                .padding(.leading, BLSpacing.large + 40 + BLSpacing.medium)
                        }
                    }
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }
    
    /// 沒有符合條件的訂單時顯示的空狀態。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 空狀態 view。
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            "沒有符合條件的訂單",
            systemImage: "tray",
            description: Text("試著調整搜尋字詞或狀態篩選。")
        )
        .padding(.top, BLSpacing.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
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
        }
    )
}

#endif
