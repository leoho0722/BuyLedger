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
/// 以 SwiftUI ``List`` 搭配 ``OrderRowView`` 呈現所有訂單，搭配右側 inspector 顯示選取訂單的詳情，對應設計稿的 Mac Orders tab。先前採用 ``Table``，但其固定單行 row 高度會截斷商品明細，改用 ``List`` 後商品明細能多行完整顯示。
struct OrdersMacView: View {
    
    // MARK: - View Properties
    
    /// 訂單功能 store。
    @Bindable var store: StoreOf<OrdersFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 控制 inspector 是否顯示。
    @State private var showsInspector = true

    /// 商品類別篩選 sheet 是否呈現。點 trigger button 後設為 `true`，由 ``OptionPickerSheet`` 內部 dismiss 結束回 `false`。
    @State private var showsCategoryPicker = false

    /// 付款方式篩選 sheet 是否呈現。點 trigger button 後設為 `true`，由 ``OptionPickerSheet`` 內部 dismiss 結束回 `false`。
    @State private var showsPaymentMethodPicker = false

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:)`` 的「現在」時間；測試可注入固定值。
    @Dependency(\.date) private var date

    // MARK: - View Body
    
    /// 訂單瀏覽畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            titleAndFilters(palette: palette)
            searchAndDateRow(palette: palette)
            if !store.availablePaymentMethods.isEmpty {
                paymentMethodFilterTrigger(palette: palette)
            }
            if !store.availableCategories.isEmpty {
                categoryFilterTrigger(palette: palette)
            }
            errorBanner(palette: palette)
            ordersList(palette: palette)
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
                .help("建立新訂單 (⌘N)")
                .keyboardShortcut("n", modifiers: [.command])
            }

            ToolbarItem {
                Button {
                    store.send(.aiSummaryTapped)
                } label: {
                    Label("AI 總結", systemImage: "sparkles")
                }
                .help("AI 商品明細總結")
                .disabled(store.state.filteredOrders(referenceDate: date.now).isEmpty)
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
        .sheet(isPresented: $showsCategoryPicker) {
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
        .sheet(isPresented: $showsPaymentMethodPicker) {
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
    
    /// macOS 訂單頁的商品類別篩選 trigger button。
    ///
    /// 與 ``OrdersCompactView`` / iPad 的 trigger 共用同一個視覺契約：以單顆 Capsule 呈現當前選擇 (「類別：<current>」)，點擊後 present ``OptionPickerSheet`` (含搜尋與「全部」清除選項)。padding / font 沿用 macOS 既有 chip 的尺寸 (`.footnote` / `.caption2` / `6pt vertical / 12pt horizontal`)；sheet 尺寸沿用 ``OptionPickerSheet`` 既有 `400×480`，與訂單編輯流程選類別時一致。
    ///
    /// - 未選任何類別時，label 顯示「類別：全部」、capsule fill 為 `fillTertiary`、前景色為 `secondaryLabel`。
    /// - 已選某類別時，label 顯示「類別：<類別名>」、capsule fill 為 `purple.opacity(0.18)`、前景色為 `purple`。
    /// - 類別名過長時，label 套 ``SwiftUI/Text/lineLimit(_:)`` 與 ``SwiftUI/Text/truncationMode(_:)`` 以 ellipsis 結尾，capsule 不換行。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: trigger button view (左對齊，剩餘水平空間由 ``SwiftUI/Spacer`` 推開)。
    func categoryFilterTrigger(palette: BLPalette) -> some View {
        let isSelected = store.selectedCategory != nil
        let currentLabel = store.selectedCategory ?? "全部"

        return Button {
            showsCategoryPicker = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "tag")
                    .font(.caption2.weight(.semibold))

                Text("類別：\(currentLabel)")
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? palette.purple : palette.secondaryLabel)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? palette.purple.opacity(0.18) : palette.fillTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// macOS 訂單頁的付款方式篩選 trigger button。
    ///
    /// 與 ``categoryFilterTrigger(palette:)`` 共用同一個視覺契約：以單顆 Capsule 呈現當前選擇 (「付款方式：<current>」)，點擊後 present ``OptionPickerSheet`` (含搜尋與「全部」清除選項)。
    ///
    /// - 未選任何付款方式時，label 顯示「付款方式：全部」、capsule fill 為 `fillTertiary`、前景色為 `secondaryLabel`。
    /// - 已選某付款方式時，label 顯示「付款方式：<付款方式名>」、capsule fill 為 `purple.opacity(0.18)`、前景色為 `purple`。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: trigger button view (左對齊，剩餘水平空間由 ``SwiftUI/Spacer`` 推開)。
    func paymentMethodFilterTrigger(palette: BLPalette) -> some View {
        let isSelected = store.selectedPaymentMethod != nil
        let currentLabel = store.selectedPaymentMethod ?? "全部"

        return Button {
            showsPaymentMethodPicker = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "creditcard")
                    .font(.caption2.weight(.semibold))

                Text("付款方式：\(currentLabel)")
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? palette.purple : palette.secondaryLabel)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? palette.purple.opacity(0.18) : palette.fillTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
    
    /// 訂單清單。
    ///
    /// 與 iPhone (compact) 的 ``OrdersCompactView`` 及 iPad 的 ``OrdersView`` `listPane` 共用同一套 ``BLCard`` + ``Divider`` 排版，讓三平台的訂單列表呈現一致的單一圓角卡片外觀。先前採用 ``Table`` (固定單行 row 高度會截斷商品明細)，後改 ``List``；但 macOS `.inset` list 的 `List(selection:)` 會在選取列疊上不透明的系統 accent 高亮，蓋掉自訂卡片色而呈現整塊亮藍，因此改以 ``ScrollView`` + ``BLCard`` 自繪列表。選取狀態僅反映在右側 inspector，列表本身不畫選取高亮 (比照 iOS)；刪除走 row 的 context menu。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 訂單列表 view。
    func ordersList(palette: BLPalette) -> some View {
        let orders = store.state.filteredOrders(referenceDate: date.now)

        return ScrollView {
            if store.isLoading {
                ProgressView("載入訂單")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, BLSpacing.large)
            } else if orders.isEmpty {
                ContentUnavailableView("沒有符合條件的訂單", systemImage: "tray")
                    .padding(.top, BLSpacing.extraLarge)
            } else {
                orderListCard(orders: orders)
                    .padding(.top, BLSpacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 卡片化的訂單列表，內含逐列訂單與分隔線。
    ///
    /// 與 ``OrdersCompactView`` 的 `listSection`、iPad `listPane` 的 `orderListCard` 採同一套 ``BLCard`` + ``Divider`` 排版以維持三平台一致；每列以 ``Button`` 送出 ``OrdersFeature/Action/orderSelected(_:)`` 更新右側 inspector。
    /// - Parameter orders: 已套用篩選的訂單清單。
    /// - Returns: 卡片化的訂單列表 view。
    func orderListCard(orders: [LedgerOrder]) -> some View {
        BLCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                    Button {
                        store.send(.orderSelected(order.id))
                    } label: {
                        OrderRowView(order: order)
                            .padding(.horizontal, BLSpacing.large)
                            .padding(.vertical, BLSpacing.extraSmall)
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

                    if index < orders.count - 1 {
                        Divider()
                            .padding(.leading, BLSpacing.large + 40 + BLSpacing.medium)
                    }
                }
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
