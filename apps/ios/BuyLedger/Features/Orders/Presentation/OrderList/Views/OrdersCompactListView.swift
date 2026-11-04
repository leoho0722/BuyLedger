//
//  OrdersCompactListView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 窄版訂單清單的篩選列、載入訊息與日期分組
struct OrdersCompactListView: View {

    // MARK: - Properties

    /// 分隔線的高度，列內距保留此高度給卡片內分隔線
    @Environment(\.pixelLength) private var pixelLength

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderListFeature>

    /// 已由父層整理好的日期區段
    let sections: [OrderDateSection]

    /// 導覽 `path` 投影出的目前訂單選取；多選模式由父層傳入 `nil`
    let selection: Binding<LedgerOrder.ID?>?

    // MARK: - Body

    /// 原生清單列承載選取；每筆訂單保留卡片外觀
    var body: some View {
        List(selection: selection) {
            controls

            orderSections
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, BLSpacing.section - BLCardRowMetrics.edgeRoom, for: .scrollContent)
        .background(.blBackground)
        .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Private Views

private extension OrdersCompactListView {

    /// 篩選列與失敗訊息沿用原本的垂直間距
    var controls: some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            OrdersFilterControlsView(
                store: store,
                isUnifiedFilterTriggerShown: true,
                statusChipHorizontalInset: BLSpacing.large,
                statusChipSize: .large,
                unifiedFilterHorizontalInset: BLSpacing.large
            )

            loadFailureMessage
        }
        .padding(.top, BLSpacing.small)
        .padding(.bottom, BLSpacing.medium)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    /// 載入失敗時持續顯示的訊息，一次性操作失敗由容器的對話框呈現
    @ViewBuilder
    var loadFailureMessage: some View {
        if case .failed(let message) = store.loadState {
            Text(LocalizedStringKey(message))
                .padding(.horizontal, BLSpacing.large)
                .blTextStyle(.footnote)
                .foregroundStyle(.blRed)
        }
    }

    /// 顯示載入狀態、空狀態或依日期分組的訂單列
    @ViewBuilder
    var orderSections: some View {
        if store.isLoading {
            ProgressView("orders.list.label.loadOrders")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else if sections.isEmpty {
            emptyState
        } else {
            ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in
                dateHeader(section, isFirst: sectionIndex == 0)

                ForEach(Array(section.orders.enumerated()), id: \.element.id) { index, order in
                    let position = BLCardRowPosition(index: index, count: section.orders.count)

                    if store.isSelecting {
                        selectableRow(order: order, position: position)
                    } else {
                        navigableRow(order: order, position: position)
                    }
                }
            }
        }
    }

    /// 沒有符合條件的訂單時顯示的空狀態
    var emptyState: some View {
        ContentUnavailableView(
            "orders.list.label.matchingOrders",
            systemImage: "tray",
            description: Text("orders.list.message.tryChangingSearch")
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    /// 顯示日期區段標題，背景與分隔線隱藏並由列內距維持卡片間距
    ///
    /// - Parameters:
    ///   - section: 要呈現的日期區段
    ///   - isFirst: 是否為清單的第一個日期區段
    /// - Returns: 日期標題列
    func dateHeader(_ section: OrderDateSection, isFirst: Bool) -> some View {
        Text(LocalizedStringKey(section.title))
            .padding(.horizontal, BLSpacing.large)
            .font(BLTypographyStyle.footnote.font.weight(.semibold))
            .foregroundStyle(.blSecondaryLabel)
            .accessibilityAddTraits(.isHeader)
            .listRowInsets(
                EdgeInsets(
                    top: isFirst ? 0 : BLSpacing.medium - BLCardRowMetrics.edgeRoom,
                    leading: 0,
                    bottom: BLSpacing.small - BLCardRowMetrics.edgeRoom,
                    trailing: 0
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// 在多選模式中以日期共用卡片呈現可勾選列
    ///
    /// - Parameters:
    ///   - order: 要呈現的訂單
    ///   - position: 訂單在日期卡片中的位置
    /// - Returns: 帶卡片樣式的多選清單列
    func selectableRow(order: LedgerOrder, position: BLCardRowPosition) -> some View {
        OrderSelectableRow(store: store, isShowingDate: false, order: order)
            .listRowInsets(position.cardRowInsets(dividerHeight: pixelLength))
            .listRowSeparator(.hidden)
            .listRowBackground(cardRowBackground(position: position))
    }

    /// 為日期卡片內的列提供共用表面，列間分隔線對齊訂單列文字起點
    ///
    /// - Parameter position: 訂單在日期卡片中的位置
    /// - Returns: 與 `BLCard` 相同填色、圓角、描邊與陰影的列背景
    func cardRowBackground(position: BLCardRowPosition) -> some View {
        BLCardRowBackground(
            dividerLeadingInset: BLListMetrics.dividerInset,
            dividerTrailingInset: 0,
            horizontalInset: BLCardRowMetrics.horizontalInset,
            position: position
        )
    }

    /// 顯示一般訂單列，點擊更新原生選取，長按顯示列選單
    ///
    /// - Parameters:
    ///   - order: 要呈現的訂單
    ///   - position: 訂單在日期卡片中的位置
    /// - Returns: 連結至 split 詳情選取的訂單列
    @ViewBuilder
    func navigableRow(order: LedgerOrder, position: BLCardRowPosition) -> some View {
        NavigationLink(value: order.id) {
            OrderRowView(isShowingDate: false, order: order)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .navigationLinkIndicatorVisibility(.hidden)
        .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
        .contextMenu {
            OrderDetailRowMenu(
                detail: OrderDetailFeature.State(orderID: order.id, orders: store.$orders)
            ) {
                store.send(.view(.mergeOrderTapped(order.id)))
            } onDelete: {
                store.send(.view(.deleteOrderTapped(order.id)))
            }
        }
        .listRowInsets(position.cardRowInsets(dividerHeight: pixelLength))
        .listRowSeparator(.hidden)
        .listRowBackground(cardRowBackground(position: position))
    }
}

// MARK: - Preview

#Preview("窄版訂單清單") {
    OrdersCompactListView(
        store: Store(initialState: OrderListFeature.State(orders: SharedReader(value: []))) {
            OrderListFeature()
        },
        sections: [],
        selection: nil
    )
}
