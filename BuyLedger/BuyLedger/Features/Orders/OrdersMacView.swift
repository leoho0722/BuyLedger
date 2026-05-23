//
//  OrdersMacView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

#if os(macOS)

import ComposableArchitecture
import SwiftUI

/// macOS 使用的訂單瀏覽畫面。
///
/// 採用扁平 SwiftUI ``Table`` 呈現所有訂單，搭配右側 inspector 顯示選取訂單的詳情，對應設計稿的 Mac Orders tab。
struct OrdersMacView: View {
    
    // MARK: - View Properties
    
    /// 訂單功能 store。
    @Bindable var store: StoreOf<OrdersFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 控制 inspector 是否顯示。
    @State private var showsInspector = true

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:)`` 的「現在」時間；測試可注入固定值。
    @Dependency(\.date) private var date

    // MARK: - View Body
    
    /// 訂單瀏覽畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            titleAndFilters(palette: palette)
            searchAndDateRow(palette: palette)
            errorBanner(palette: palette)
            ordersTable(palette: palette)
        }
        .padding(BLSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.background)
        .inspector(isPresented: $showsInspector) {
            inspectorContent(palette: palette)
                .inspectorColumnWidth(min: 560, ideal: 720, max: 960)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    store.send(.newOrderTapped)
                } label: {
                    Label("新訂單", systemImage: "plus")
                }
                .help("建立新訂單（⌘N）")
                .keyboardShortcut("n", modifiers: [.command])
            }
            
            ToolbarItem {
                Button {
                    showsInspector.toggle()
                } label: {
                    Label("詳情", systemImage: "sidebar.right")
                }
                .help(showsInspector ? "隱藏訂單詳情" : "顯示訂單詳情")
            }
        }
        .focusedSceneValue(\.newOrderAction) {
            store.send(.newOrderTapped)
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension OrdersMacView {
    
    /// 標題列：H1 與狀態 chip 篩選。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 標題與篩選列 view。
    func titleAndFilters(palette: BLPalette) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.large) {
            Text("全部訂單")
                .font(.title2.bold())
                .foregroundStyle(palette.label)
            
            Spacer(minLength: BLSpacing.medium)
            
            OrderStatusFilterBar(
                selection: store.selectedStatus,
                filters: OrderStatusFilter.orderBrowsingCases
            ) { filter in
                store.send(.statusFilterSelected(filter))
            }
        }
    }
    
    /// 搜尋輸入欄與日期區間 chip 列並排。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 搜尋欄與日期 chip 列 view。
    func searchAndDateRow(palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.medium) {
            BLSearchField(
                placeholder: "搜尋客戶、單號或商品",
                text: $store.searchText.sending(\.searchTextChanged)
            )
            .frame(maxWidth: 320, alignment: .leading)
            
            dateChipRow(palette: palette)
            
            Spacer(minLength: 0)
        }
    }
    
    /// 日期區間 chip 列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 日期 chip 列 view。
    func dateChipRow(palette: BLPalette) -> some View {
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
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(isSelected ? palette.accent.opacity(0.18) : palette.fillTertiary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    /// 載入失敗訊息。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 錯誤橫幅 view，沒有錯誤時為空。
    @ViewBuilder
    func errorBanner(palette: BLPalette) -> some View {
        if let errorMessage = store.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(palette.red)
        }
    }
    
    /// 訂單表格。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 訂單 ``Table`` view。
    func ordersTable(palette: BLPalette) -> some View {
        Table(
            store.state.filteredOrders(referenceDate: date.now),
            selection: $store.selectedOrderID.sending(\.orderSelected)
        ) {
            TableColumn("單號") { order in
                Text(order.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(palette.secondaryLabel)
            }
            .width(min: 110, ideal: 120, max: 140)
            
            TableColumn("客戶") { order in
                HStack(spacing: BLSpacing.small) {
                    BLAvatar(
                        name: order.customer.name,
                        initials: order.customer.initials,
                        size: 24
                    )
                    Text(order.customer.name)
                        .font(.subheadline.weight(.medium))
                }
            }
            .width(min: 140, ideal: 180)
            
            TableColumn("幣別") { order in
                Text("\(order.currency.flag) \(order.currency.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryLabel)
            }
            .width(min: 70, ideal: 90, max: 110)
            
            TableColumn("商品") { order in
                Text(order.primaryItemDescription)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryLabel)
                    .lineLimit(1)
            }
            
            TableColumn("狀態") { order in
                BLStatusPill(order.status.title, tone: order.status.tone)
            }
            .width(min: 88, ideal: 110, max: 130)
            
            TableColumn("收款") { order in
                Text(OrderFormatters.twd(order.summary.revenue))
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 90, ideal: 110, max: 140)
            
            TableColumn("獲利") { order in
                let profit = order.summary.profit
                
                Text("\(profit >= 0 ? "+" : "")\(OrderFormatters.twd(profit))")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(profit >= 0 ? palette.green : palette.red)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 90, ideal: 110, max: 140)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        .contextMenu(forSelectionType: LedgerOrder.ID.self) { ids in
            if let id = ids.first {
                Button(role: .destructive) {
                    store.send(.deleteOrderTapped(id))
                } label: {
                    Label("刪除訂單", systemImage: "trash")
                }
            }
        }
        .overlay {
            if store.isLoading {
                ProgressView("載入訂單")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(palette.background)
            } else if store.state.filteredOrders(referenceDate: date.now).isEmpty {
                ContentUnavailableView("沒有符合條件的訂單", systemImage: "tray")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(palette.background)
            }
        }
    }
    
    /// Inspector 內顯示的訂單詳情或空狀態。
    ///
    /// macOS `.inspector(...)` 預設背景比 app background 淺，會讓詳情欄看起來像浮在內容區之外；統一在最外層套 `palette.background` 讓整個 inspector 與訂單表格的背景一致。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: inspector 內容 view。
    @ViewBuilder
    func inspectorContent(palette: BLPalette) -> some View {
        Group {
            if let order = store.state.selectedOrder(referenceDate: date.now) {
                VStack(spacing: 0) {
                    inspectorTitleBar(order: order, palette: palette)
                    OrderDetailView(order: order, layout: .wide)
                }
            } else {
                ContentUnavailableView(
                    "選擇訂單以檢視詳情",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("從左側表格挑選任一訂單，這裡會顯示成本拆解與商品明細。")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }
    
    /// Inspector 上方的訂購人姓名標題列，含「編輯」按鈕。
    ///
    /// macOS inspector 不會自動顯示 ``View/navigationTitle`` 的標題，因此以自繪標題列補齊。訂單編號已由 ``OrderDetailView`` 的內容區顯示，此處不再重複。
    /// - Parameters:
    ///   - order: 要顯示的訂單。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 自繪標題列 view。
    func inspectorTitleBar(order: LedgerOrder, palette: BLPalette) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text(order.customer.name)
                .font(.title3.bold())
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
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
}

// MARK: - Preview

#Preview("macOS 訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        state.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        return state
    }()
    
    OrdersMacView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        }
    )
    .frame(width: 1100, height: 700)
}

#endif
