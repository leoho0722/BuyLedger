//
//  OrdersCompactListView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 窄版訂單清單的篩選列、載入訊息與日期卡片
struct OrdersCompactListView: View {

    // MARK: - Properties

    /// 篩選摘要使用的顯示語系
    @Environment(\.locale) private var locale

    /// 清單背景與文字使用的色盤
    let palette: BLPalette

    /// 已由父層整理好的日期區段
    let sections: [OrderDateSection]

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderListFeature>

    // MARK: - Body

    /// 可捲動的清單骨架，由上而下顯示篩選、載入訊息與訂單區段
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                chipStrip

                unifiedFilterTrigger

                loadFailureMessage

                listSection
            }
            .padding(.top, BLSpacing.small)
            .padding(.bottom, BLSpacing.section)
        }
        .background(palette.background)
        .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Private Views

private extension OrdersCompactListView {

    /// 可橫向捲動的訂單狀態篩選列
    @ViewBuilder
    var chipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) {
                    chipButton($0)
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
        .scrollIndicators(.hidden)
    }

    /// 顯示並切換單一訂單狀態篩選
    ///
    /// - Parameter filter: 要顯示的狀態篩選
    /// - Returns: 可切換訂單狀態的篩選按鈕
    @ViewBuilder
    func chipButton(_ filter: OrderStatusFilter) -> some View {
        BLFilterChip(
            title: LocalizedStringKey(filter.title),
            isSelected: store.selectedStatus == filter,
            size: .large
        ) {
            store.send(.view(.statusFilterSelected(filter)))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
    }

    /// 顯示日期、類別與付款方式的整合篩選按鈕
    @ViewBuilder
    var unifiedFilterTrigger: some View {
        let language = AppLanguage(locale: locale)
        let summary = Text(verbatim: store.state.filterSummary(language: language))

        BLFilterChip(
            title: "篩選: \(summary)",
            isSelected: store.committedFilterSelection.isActive,
            style: .purple,
            size: .large,
            icon: "line.3.horizontal.decrease",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.view(.filterSheetTapped))
        }
        .padding(.horizontal, BLSpacing.large)
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterButton)
    }

    /// 載入失敗時持續顯示的訊息，一次性操作失敗由容器的對話框呈現
    @ViewBuilder
    var loadFailureMessage: some View {
        if case .failed(let message) = store.loadState {
            Text(LocalizedStringKey(message))
                .padding(.horizontal, BLSpacing.large)
                .blTextStyle(.footnote)
                .foregroundStyle(palette.red)
        }
    }

    /// 沒有符合條件的訂單時顯示的空狀態
    @ViewBuilder
    var emptyState: some View {
        ContentUnavailableView(
            "沒有符合條件的訂單",
            systemImage: "tray",
            description: Text("試著調整搜尋字詞或狀態篩選。")
        )
        // 容器相對高度撐開後置中；垂直 `ScrollView` 內單設 `maxHeight` 不生效
        // 空狀態會黏在頂端而非可視區域中央
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
        .background(palette.background)
        .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
    }

    /// 訂單列表區塊，包含載入、空狀態與「以日期分組」的資料區段
    @ViewBuilder
    var listSection: some View {
        if store.isLoading {
            ProgressView("載入訂單")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else {
            if sections.isEmpty {
                emptyState
            } else {
                // 惰性只施加於外層日期區段，卡片內的訂單列容器維持非惰性
                // 否則卡片背景會因高度漸進確定而包不住當日所有列
                LazyVStack(alignment: .leading, spacing: BLSpacing.medium) {
                    ForEach(sections) {
                        orderDateSection($0)
                    }
                }
            }
        }
    }

    /// 單一日期區段，包含日期標題與訂單卡片
    ///
    /// - Parameter section: 要呈現的日期區段
    /// - Returns: 含日期標題與訂單卡片的區段
    @ViewBuilder
    func orderDateSection(_ section: OrderDateSection) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(LocalizedStringKey(section.title))
                .padding(.horizontal, BLSpacing.large)
                .font(BLTypographyStyle.footnote.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)

            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(section.orders.enumerated()), id: \.element.id) { index, order in
                        if store.isSelecting {
                            OrderSelectableRow(
                                order: order,
                                palette: palette,
                                isShowingDate: false,
                                store: store
                            )
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
    ///
    /// - Parameter order: 要呈現的訂單
    /// - Returns: 可開啟詳情的訂單列
    @ViewBuilder
    func navigableRow(order: LedgerOrder) -> some View {
        Button {
            store.send(.view(.orderTapped(order.id)))
        } label: {
            OrderRowView(order: order, isShowingDate: false)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                .contentShape(Rectangle())
                .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
        }
        .buttonStyle(.plain)
        .contextMenu {
            OrderDetailRowMenu(
                detail: OrderDetailFeature.State(orderID: order.id, orders: store.$orders)
            ) {
                store.send(.view(.mergeOrderTapped(order.id)))
            } onDelete: {
                store.send(.view(.deleteOrderTapped(order.id)))
            }
        }
    }
}

// MARK: - Preview

#Preview("窄版訂單清單") {
    OrdersCompactListView(
        palette: BLPalette(),
        sections: [],
        store: Store(initialState: OrderListFeature.State(orders: SharedReader(value: []))) {
            OrderListFeature()
        }
    )
}
