//
//  DashboardRecentOrdersSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// 總覽的「近期訂單」區段：標題列與「查看全部」，下方是訂單卡，沒有訂單時顯示空狀態
struct DashboardRecentOrdersSection: View {

    // MARK: - Properties

    /// 近期訂單，依日期由新到舊，已由 ``DashboardStats`` 取好顯示筆數
    let recentOrders: [LedgerOrder]

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<DashboardFeature>

    // MARK: - Body

    /// 區段骨架，標題列下方依有無訂單顯示訂單卡或空狀態
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            header

            if recentOrders.isEmpty {
                emptyState
            } else {
                orderList
            }
        }
    }
}

// MARK: - Private Views

private extension DashboardRecentOrdersSection {

    /// 區段標題與「查看全部」按鈕
    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("dashboard.overview.label.recentOrders")
                .blTextStyle(.title3Bold)
                .foregroundStyle(palette.label)

            Spacer()

            Button("dashboard.overview.label.viewAll") {
                store.send(.view(.viewAllOrdersTapped))
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.accent)
            .font(BLTypographyStyle.subhead.font.weight(.medium))
            .accessibilityIdentifier(BLAccessibilityID.Dashboard.recentOrdersSeeAllButton)
        }
    }

    /// 沒有任何訂單時的空狀態
    var emptyState: some View {
        ContentUnavailableView(
            "dashboard.overview.label.orders",
            systemImage: "tray",
            description: Text("dashboard.overview.message.createFirstOrder")
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, BLSpacing.large)
        .background(palette.background)
    }

    /// 裝著近期訂單列的卡片，列與列之間以分隔線隔開
    var orderList: some View {
        BLCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(recentOrders.enumerated()), id: \.element.id) { index, order in
                    OrderRowView(order: order)
                        .padding(.horizontal, BLSpacing.large)
                        .padding(.vertical, BLSpacing.extraSmall)
                        .accessibilityIdentifier(
                            BLAccessibilityID.Dashboard.recentOrderRow(orderID: order.id)
                        )

                    if index < recentOrders.count - 1 {
                        Divider()
                            .padding(.leading, BLListMetrics.dividerInset)
                    }
                }
            }
        }
    }
}

// MARK: - Private Method

private extension DashboardRecentOrdersSection {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("dashboard.overview.label.recentOrders") {
    DashboardRecentOrdersSection(
        recentOrders: Array(LedgerOrder.sampleOrders.prefix(4)),
        store: Store(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
    )
    .padding()
}

#Preview("沒有訂單") {
    DashboardRecentOrdersSection(
        recentOrders: [],
        store: Store(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
    )
    .padding()
}
