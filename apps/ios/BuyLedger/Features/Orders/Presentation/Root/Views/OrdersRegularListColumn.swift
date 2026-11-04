//
//  OrdersRegularListColumn.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// 寬版 (iPad 全螢幕) 訂單瀏覽的清單欄，上方是篩選區，下方是卡片化的訂單列
struct OrdersRegularListColumn: View {

    // MARK: - Properties

    /// 目前使用的動態字級大小
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 分隔線的高度，列內距保留此高度給卡片內分隔線
    @Environment(\.pixelLength) private var pixelLength

    /// 清單欄可用的垂直尺寸分類
    ///
    /// - Note: 高度不足 (compact) 時收合日期、付款方式、類別與清除篩選，改由統一篩選鈕呈現
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderListFeature>

    /// 已套用篩選的訂單，由父層單次求值後傳入
    let orders: [LedgerOrder]

    /// 由 Orders 詳情 `path` 投影出的目前選取訂單
    let selectedOrderID: LedgerOrder.ID?

    /// 原生清單選取的讀寫轉接，由 Orders 容器依 `path` 建立
    let selection: Binding<LedgerOrder.ID?>?

    // MARK: - Body

    /// 清單欄骨架：一般字級固定篩選區於頂部，輔助字級時篩選區隨清單捲動，避免被壓縮重疊
    var body: some View {
        VStack(spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                listHeader
            }

            List(selection: selection) {
                if dynamicTypeSize.isAccessibilitySize {
                    listHeader
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                listContent
            }
            .environment(\.defaultMinListRowHeight, 0)
            .contentMargins(
                .bottom,
                BLSpacing.medium - BLCardRowMetrics.edgeRoom,
                for: .scrollContent
            )
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.blBackground)
            .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(.blBackground)
    }
}

// MARK: - Private Views

private extension OrdersRegularListColumn {

    /// 清單上方的多選筆數、篩選、清除入口與持續性載入失敗訊息
    var listHeader: some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            if store.isSelecting {
                selectionSummary
            }

            OrdersFilterControlsView(
                store: store,
                isUnifiedFilterTriggerShown: verticalSizeClass == .compact,
                statusChipHorizontalInset: 0,
                statusChipSize: .standard,
                unifiedFilterHorizontalInset: 0
            )

            if verticalSizeClass != .compact {
                let paymentMethodNames = store.availablePaymentMethodNames
                dateChipStrip

                if !paymentMethodNames.isEmpty {
                    paymentMethodFilterTrigger(names: paymentMethodNames)
                }

                if store.hasAvailableCategories {
                    categoryFilterTrigger
                }

                clearFiltersButton
            }

            loadFailureMessage
        }
        .padding(.top, BLSpacing.small)
        .padding(.horizontal, verticalSizeClass == .compact ? BLSpacing.large : BLSpacing.medium)
        .padding(.bottom, BLSpacing.medium - BLCardRowMetrics.edgeRoom)
    }

    /// 多選模式的已選筆數，與 iPhone 多選標題同一份文字
    ///
    /// - Note: 直向清單欄放不下 inline 標題與多選工具列，筆數改顯示在這裡
    var selectionSummary: some View {
        Text(verbatim: AppLanguage(locale: locale).localized(store.navigationTitleKey))
            .blTextStyle(.headline)
            .foregroundStyle(.blLabel)
            .accessibilityIdentifier(BLAccessibilityID.Orders.selectionSummary)
    }

    /// 可橫向捲動的日期區間篩選列
    var dateChipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderDatePeriod.orderBrowsingCases) {
                    dateChip($0)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 顯示並切換單一日期區間篩選
    ///
    /// - Parameter period: 要呈現的日期區間
    /// - Returns: 日期區間篩選按鈕
    func dateChip(_ period: OrderDatePeriod) -> some View {
        BLFilterChip(
            icon: "calendar",
            isSelected: store.selectedDatePeriod == period,
            style: .accent,
            title: LocalizedStringKey(period.title)
        ) {
            store.send(.view(.datePeriodSelected(period)))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.dateChip(period.id))
    }

    /// 顯示付款方式單選選單，選取後立即套用，前置勾號由系統選擇器提供
    ///
    /// - Parameter names: 可供選取的付款方式名稱清單
    /// - Returns: 付款方式選單視圖
    func paymentMethodFilterTrigger(names: [String]) -> some View {
        Menu {
            Picker(
                selection: $store.selectedPaymentMethod.sending(\.view.paymentMethodFilterSelected)
            ) {
                Text("common.action.label.all")
                    .tag(nil as String?)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.paymentMethodMenuAllOption)
                    .accessibilityAddTraits(store.selectedPaymentMethod == nil ? .isSelected : [])

                ForEach(names, id: \.self) {
                    Text($0)
                        .tag(Optional($0))
                        .accessibilityIdentifier(
                            BLAccessibilityID.Orders.paymentMethodMenuOption($0)
                        )
                        .accessibilityAddTraits(
                            store.selectedPaymentMethod == $0 ? .isSelected : []
                        )
                }
            } label: {
                Text("orders.list.label.selectPaymentMethod")
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            BLFilterChipLabel(
                icon: "creditcard",
                isExpanded: true,
                isSelected: store.hasPaymentMethodFilter,
                style: .purple,
                title: OrderFormatters.paymentMethodFilterTitle(
                    store.selectedPaymentMethod,
                    locale: locale
                ),
                trailingIcon: "chevron.down"
            )
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .menuOrder(.fixed)
        .accessibilityAddTraits(store.hasPaymentMethodFilter ? .isSelected : [])
        .accessibilityIdentifier(BLAccessibilityID.Orders.paymentMethodMenuButton)
    }

    /// 商品類別篩選的觸發鈕，顯示目前選取的類別，沒有選取時顯示「全部」
    var categoryFilterTrigger: some View {
        Button {
            store.send(.view(.categoryPickerTapped))
        } label: {
            BLFilterChipLabel(
                icon: "tag",
                isExpanded: true,
                isSelected: store.hasCategoryFilter,
                style: .purple,
                title: OrderFormatters.categoryFilterTitle(
                    store.selectedCategories,
                    locale: locale
                ),
                trailingIcon: "chevron.down"
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.hasCategoryFilter ? .isSelected : [])
        .accessibilityIdentifier(BLAccessibilityID.Orders.categoryFilterButton)
    }

    /// 立即清除三項篩選的按鈕，原本皆為預設時由系統停用
    var clearFiltersButton: some View {
        Button {
            store.send(.view(.clearFiltersTapped))
        } label: {
            Label("orders.filter.button.clearFilters", systemImage: "arrow.counterclockwise")
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: BLHitTarget.minimum)
                .labelStyle(.titleAndIcon)
                .blTextStyle(.subhead)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .disabled(!store.committedFilterSelection.isActive)
        .accessibilityIdentifier(BLAccessibilityID.Orders.clearFiltersButton)
    }

    /// 載入失敗時持續顯示的訊息，一次性操作失敗由容器的對話框呈現
    @ViewBuilder
    var loadFailureMessage: some View {
        if case .failed(let message) = store.loadState {
            Text(LocalizedStringKey(message))
                .blTextStyle(.footnote)
                .foregroundStyle(.blRed)
        }
    }

    /// 清單欄的捲動內容，依載入中、沒有符合的訂單與有訂單三種情況切換
    @ViewBuilder
    var listContent: some View {
        if store.isLoading {
            ProgressView("orders.list.label.loadOrders")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else if orders.isEmpty {
            ContentUnavailableView("orders.list.label.matchingOrders", systemImage: "tray")
                .padding(.top, BLSpacing.extraLarge)
                .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else {
            ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                let position = BLCardRowPosition(index: index, count: orders.count)

                if store.isSelecting {
                    selectableRow(order: order, position: position)
                } else {
                    navigableRow(order: order, position: position)
                }
            }
        }
    }

    /// 顯示多選模式的可勾選訂單列
    ///
    /// - Parameters:
    ///   - order: 要呈現的訂單
    ///   - position: 訂單在卡片中的位置
    /// - Returns: 帶卡片樣式的多選清單列
    func selectableRow(order: LedgerOrder, position: BLCardRowPosition) -> some View {
        OrderSelectableRow(store: store, order: order)
            .listRowInsets(cardRowInsets(position: position))
            .listRowSeparator(.hidden)
            .listRowBackground(cardRowBackground(position: position))
    }

    /// 為清單中的訂單列提供共用卡片表面與分隔線
    ///
    /// - Parameter position: 訂單在卡片中的位置
    /// - Returns: 與設計系統卡片一致的列背景，水平內距與列內距相同
    func cardRowBackground(position: BLCardRowPosition) -> some View {
        BLCardRowBackground(
            dividerLeadingInset: BLListMetrics.dividerInset,
            dividerTrailingInset: 0,
            horizontalInset: BLSpacing.medium,
            position: position
        )
    }

    /// 顯示一般訂單列，點擊更新原生選取，長按顯示合併與刪除選單
    ///
    /// - Parameters:
    ///   - order: 要呈現的訂單
    ///   - position: 訂單在卡片中的位置
    /// - Returns: 連結至 split 詳情選取的訂單列
    func navigableRow(order: LedgerOrder, position: BLCardRowPosition) -> some View {
        let isSelected = selectedOrderID == order.id

        return NavigationLink(value: order.id) {
            OrderRowView(order: order)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                // 選取時系統會把預設前景改為單色，固定色盤色避免白字疊在淺色底上
                .foregroundStyle(.blLabel)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous)
                            .fill(.blAccent.opacity(0.12))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .navigationLinkIndicatorVisibility(.hidden)
        .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .contextMenu {
            OrderDetailRowMenu(
                detail: OrderDetailFeature.State(orderID: order.id, orders: store.$orders)
            ) {
                store.send(.view(.mergeOrderTapped(order.id)))
            } onDelete: {
                store.send(.view(.deleteOrderTapped(order.id)))
            }
        }
        .listRowInsets(cardRowInsets(position: position))
        .listRowSeparator(.hidden)
        .listRowBackground(cardRowBackground(position: position))
    }
}

// MARK: - Private Method

private extension OrdersRegularListColumn {

    /// 計算寬版清單的列內距，卡片水平內距為 `BLSpacing.medium`，與窄版的設計系統預設不同
    ///
    /// - Parameter position: 訂單在卡片中的位置
    /// - Returns: 列內距
    func cardRowInsets(position: BLCardRowPosition) -> EdgeInsets {
        position.cardRowInsets(dividerHeight: pixelLength, horizontalInset: BLSpacing.medium)
    }
}

// MARK: - Preview

#Preview("訂單清單欄") {
    let previewState: OrderListFeature.State = {
        let state = OrderListFeature.State(orders: SharedReader(value: LedgerOrder.sampleOrders))
        state.$hasLoaded = SharedReader(value: true)
        return state
    }()

    OrdersRegularListColumn(
        store: Store(initialState: previewState) {
            OrderListFeature()
        },
        orders: LedgerOrder.sampleOrders,
        selectedOrderID: nil,
        selection: nil
    )
}
