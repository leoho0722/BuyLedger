//
//  OrdersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 訂單列表與詳情畫面
///
/// 依尺寸選擇對應導覽樣式：
/// - iPhone (compact) 使用 NavigationStack 對應的 ``OrdersCompactView``
/// - iPadOS (regular) 以 ``HStack`` 在父層 NavigationSplitView 的 detail 欄中自排列「清單 + 詳情」兩欄，避免巢狀 NavigationSplitView 互相搶寬度
struct OrdersView: View {

    // MARK: - View Properties

    /// 訂單功能 store
    @Bindable var store: StoreOf<OrdersFeature>

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 目前水平尺寸分類，用來區分 iPhone 與 iPad 佈局
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:calendar:)`` 的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 訂單篩選與日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar

    /// 商品類別篩選 sheet 是否呈現。僅 iPad regular 分支使用 (透過 ``regularSplitContent`` 與 ``listHeader`` 中的 trigger 觸發)；compact 分支委派給 ``OrdersCompactView`` 各自的本地 state
    @State private var showsCategoryPicker = false

    /// 付款方式篩選 sheet 是否呈現。點 trigger button 後設為 `true`，由 ``OptionPickerSheet`` 內部 dismiss 結束回 `false`
    @State private var showsPaymentMethodPicker = false

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
            .alert($store.scope(state: \.aiDisabledAlert, action: \.aiDisabledAlert))
    }

    /// 依尺寸分類選擇對應的訂單瀏覽 view
    @ViewBuilder
    private var platformContent: some View {
        if horizontalSizeClass == .compact {
            OrdersCompactView(store: store)
        } else {
            regularSplitContent
        }
    }
}

// MARK: - ViewBuilder

private extension OrdersView {

    /// iPad regular 使用的「清單 + 詳情」兩欄佈局
    ///
    /// 以 ``NavigationStack`` 包住兩欄並用 `.navigationTitle("訂單")` 提供系統大標題，讓頂端標題與「更多」等其他分頁一致對齊側邊欄 (先前用 HStack + 手動 `.padding(.top)` 會讓內容偏下、與側邊欄錯位)。內層僅用 ``HStack`` 自排「清單 + 詳情」，不再使用巢狀 ``NavigationSplitView``，避免兩層 split 互相搶寬度造成中間欄被擠壓
    @ViewBuilder
    var regularSplitContent: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let filteredIDs = store.state.filteredOrders(referenceDate: date.now, calendar: calendar).map(\.id)
        let allFilteredSelected = !filteredIDs.isEmpty && filteredIDs.allSatisfy { store.selectedOrderIDs.contains($0) }

        NavigationStack {
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
                if store.isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(allFilteredSelected ? "清除" : "全選") {
                            store.send(allFilteredSelected ? .clearSelectionTapped : .selectAllTapped)
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button("完成") {
                            store.send(.selectionModeToggled)
                        }
                    }

                    ToolbarItemGroup(placement: .bottomBar) {
                        Text("已選 \(store.selectedOrderIDs.count) 筆")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(palette.secondaryLabel)

                        Spacer()

                        Menu {
                            // 「已合併」僅能由合併流程寫入，批次目標清單一律排除
                            ForEach(OrderStatus.allCases.filter { $0 != .merged }) { status in
                                Button(status.title) {
                                    store.send(.batchStatusChanged(status))
                                }
                            }
                        } label: {
                            Text("更改狀態")
                        }
                        .disabled(store.selectedOrderIDs.isEmpty)
                    }
                } else {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Text("\(store.orders.count)")
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(palette.secondaryLabel)

                        Button {
                            store.send(.aiSummaryTapped)
                        } label: {
                            Image(systemName: "sparkles")
                        }
                        .accessibilityLabel("AI 商品明細總結")
                        .disabled(store.state.filteredOrders(referenceDate: date.now, calendar: calendar).isEmpty)

                        Button {
                            store.send(.selectionModeToggled)
                        } label: {
                            Image(systemName: "checklist")
                        }
                        .accessibilityLabel("選取訂單")
                        .disabled(store.orders.isEmpty)

                        Button {
                            store.send(.newOrderTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("新增訂單")
                    }
                }
            }
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

    /// 訂單列表欄
    ///
    /// 與 iPhone (compact) 的 ``OrdersCompactView`` 共用同一套 ``BLCard`` + 分隔線排版，讓三平台的訂單列表呈現一致的單一圓角卡片外觀。選取狀態僅反映在右側詳情欄，列表本身不畫選取高亮 (比照 iOS)；刪除走 row 的 context menu
    @ViewBuilder
    var listPane: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let orders = store.state.filteredOrders(referenceDate: date.now, calendar: calendar)

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
                } else {
                    orderListCard(orders: orders)
                        .padding(.horizontal, BLSpacing.medium)
                        .padding(.bottom, BLSpacing.medium)
                }
            }
            .background(palette.background)
        }
    }

    /// 卡片化的訂單列表，內含逐列訂單與分隔線
    ///
    /// 與 ``OrdersCompactView`` 的 `listSection` 採同一套 ``BLCard`` + ``Divider`` 排版以維持三平台一致；每列以 ``Button`` 送出 ``OrdersFeature/Action/orderSelected(_:)`` 更新右側詳情
    /// - Parameter orders: 已套用篩選的訂單清單
    /// - Returns: 卡片化的訂單列表 view
    @ViewBuilder
    func orderListCard(orders: [LedgerOrder]) -> some View {
        let palette = BLTheme.palette(for: colorScheme)

        BLCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                    if store.isSelecting {
                        selectableRow(order: order, palette: palette)
                    } else {
                        selectDetailRow(order: order)
                    }

                    if index < orders.count - 1 {
                        Divider()
                            .padding(.leading, BLSpacing.large + 40 + BLSpacing.medium)
                    }
                }
            }
        }
    }

    /// 一般 (非多選) 模式的訂單列：點擊更新右側詳情，長按提供合併／刪除 context menu
    /// - Parameter order: 要呈現的訂單
    /// - Returns: 可選取詳情的訂單列 view
    @ViewBuilder
    func selectDetailRow(order: LedgerOrder) -> some View {
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

    /// 多選模式的訂單列：左側勾選圈，點擊切換選取而非更新詳情
    /// - Parameters:
    ///   - order: 要呈現的訂單
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 可勾選的訂單列 view
    @ViewBuilder
    func selectableRow(order: LedgerOrder, palette: BLPalette) -> some View {
        let isSelected = store.selectedOrderIDs.contains(order.id)

        Button {
            store.send(.orderSelectionToggled(order.id))
        } label: {
            HStack(spacing: BLSpacing.medium) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? palette.accent : palette.tertiaryLabel)

                OrderRowView(order: order)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.extraSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 訂單列表上方的標題、搜尋與狀態篩選
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 列表 header view
    @ViewBuilder
    func listHeader(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            BLSearchField(
                placeholder: "搜尋客戶、單號或商品",
                text: $store.searchText.sending(\.searchTextChanged)
            )

            chipScrollStrip(palette: palette)
            dateChipScrollStrip(palette: palette)
            if !store.availablePaymentMethods.isEmpty {
                paymentMethodFilterTrigger(palette: palette)
            }
            if !store.availableCategories.isEmpty {
                categoryFilterTrigger(palette: palette)
            }

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

    /// iPad 中間欄使用的橫向滾動狀態 chip 列
    ///
    /// 在 320 px 寬的中間欄內，6 個 chip 無法單行排列，因此改用橫向滾動避免換行造成的視覺斷裂
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: chip 列 view
    @ViewBuilder
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

    /// iPad 中間欄使用的橫向滾動日期區間 chip 列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 日期 chip 列 view
    @ViewBuilder
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

    /// iPad regular 中間欄使用的商品類別篩選 trigger button
    ///
    /// 與 ``OrdersCompactView`` 共用同一個視覺契約：以單顆 Capsule 呈現當前選擇 (「類別：<current>」)，點擊後 present ``OptionPickerSheet`` (含搜尋與「全部」清除選項)。padding / font 沿用 iPad 中間欄既有 chip 的尺寸 (`.footnote` / `.caption2` / `12pt horizontal`)
    ///
    /// - 未選任何類別時，label 顯示「類別：全部」、capsule fill 為 `fillTertiary`、前景色為 `secondaryLabel`
    /// - 已選某類別時，label 顯示「類別：<類別名>」、capsule fill 為 `purple.opacity(0.18)`、前景色為 `purple`
    /// - 類別名過長時，label 套 ``SwiftUI/Text/lineLimit(_:)`` 與 ``SwiftUI/Text/truncationMode(_:)`` 以 ellipsis 結尾，capsule 不換行
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: trigger button view (左對齊，剩餘水平空間由 ``SwiftUI/Spacer`` 推開)
    @ViewBuilder
    func categoryFilterTrigger(palette: BLPalette) -> some View {
        let isSelected = store.selectedCategory != nil
        let currentLabel = store.selectedCategory ?? "全部"

        Button {
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
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(isSelected ? palette.purple.opacity(0.18) : palette.fillTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// iPad regular 中間欄使用的付款方式篩選 trigger button
    ///
    /// 與 ``categoryFilterTrigger(palette:)`` 共用同一個視覺契約：以單顆 Capsule 呈現當前選擇 (「付款方式：<current>」)，點擊後 present ``OptionPickerSheet`` (含搜尋與「全部」清除選項)
    ///
    /// - 未選任何付款方式時，label 顯示「付款方式：全部」、capsule fill 為 `fillTertiary`、前景色為 `secondaryLabel`
    /// - 已選某付款方式時，label 顯示「付款方式：<付款方式名>」、capsule fill 為 `purple.opacity(0.18)`、前景色為 `purple`
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: trigger button view (左對齊，剩餘水平空間由 ``SwiftUI/Spacer`` 推開)
    @ViewBuilder
    func paymentMethodFilterTrigger(palette: BLPalette) -> some View {
        let isSelected = store.selectedPaymentMethod != nil
        let currentLabel = store.selectedPaymentMethod ?? "全部"

        Button {
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
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(isSelected ? palette.purple.opacity(0.18) : palette.fillTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// 訂單詳情欄
    @ViewBuilder
    var detailPane: some View {
        let palette = BLTheme.palette(for: colorScheme)

        if let order = store.state.selectedOrder(referenceDate: date.now, calendar: calendar) {
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

    /// 詳情欄頂部的訂購人姓名標題列，含「更新狀態」選單與「更多」操作選單 (合併/編輯/刪除)
    ///
    /// 因 iPad regular 的訂單詳情位於父層 NavigationSplitView 的 detail 中，但本 view 內部已不再使用 NavigationStack，所以以自繪標題列代替系統 navigation title。訂單編號已由 ``OrderDetailView`` 的內容區顯示，此處不再重複
    /// - Parameter order: 要顯示的訂單
    /// - Returns: 自繪標題列 view
    @ViewBuilder
    func detailTitleBar(order: LedgerOrder) -> some View {
        let palette = BLTheme.palette(for: colorScheme)

        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Text(order.customer.name)
                .font(.title3.bold())
                .foregroundStyle(palette.label)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            statusUpdateMenu(order: order)

            moreActionsMenu(order: order)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    /// 詳情頁右上角的「更新狀態」menu，目前狀態加 checkmark；「已合併」只能由合併流程寫入，僅當目前狀態已是已合併時保留該選項
    /// - Parameter order: 對應訂單
    /// - Returns: menu view
    @ViewBuilder
    func statusUpdateMenu(order: LedgerOrder) -> some View {
        Menu {
            ForEach(OrderStatus.allCases.filter { $0 != .merged || order.status == .merged }) { status in
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

    /// 詳情頁右上角的「更多」操作選單，收納功能性質相近的合併/編輯/刪除，避免操作列擁擠
    ///
    /// 「合併訂單」沿用既有條件——狀態為「已合併」或「已取消」時不顯示；「刪除」為 destructive 並以分隔線與前兩項隔開。三個動作 dispatch 的 action 與原並排按鈕完全一致
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
            }

            Button {
                store.send(.editOrderTapped(order.id))
            } label: {
                Label("編輯", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除", systemImage: "trash")
            }
        } label: {
            Label("更多", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .accessibilityLabel("更多操作")
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
