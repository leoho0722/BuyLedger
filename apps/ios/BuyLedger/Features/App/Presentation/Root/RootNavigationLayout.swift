//
//  RootNavigationLayout.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/27.
//

import ComposableArchitecture
import SwiftUI

/// App 的原生自適應根分頁與目的地宿主
struct RootNavigationLayout: View {

    // MARK: - Properties

    /// 側邊欄品牌標誌的圓角，隨動態字級等比放大
    @ScaledMetric private var logoTileCornerRadius: CGFloat = 7

    /// 側邊欄品牌標誌的邊長，隨動態字級等比放大
    @ScaledMetric private var logoTileSize: CGFloat = 28

    /// 根導覽狀態與各功能 Store 的來源
    @Bindable var store: StoreOf<RootFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 以同一組五個目的地呈現原生可調整分頁列與側邊欄
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.view.tabSelected)) {
            Tab(
                RootTab.dashboard.title,
                systemImage: RootTab.dashboard.systemImage,
                value: RootTab.dashboard
            ) {
                destination(for: .dashboard)
            }
            .accessibilityIdentifier(BLAccessibilityID.Root.tab(.dashboard))

            Tab(
                RootTab.orders.title,
                systemImage: RootTab.orders.systemImage,
                value: RootTab.orders
            ) {
                destination(for: .orders)
            }
            .badge(SidebarBadgeCounts.activeOrderCount(orders: store.orders.orders))
            .accessibilityIdentifier(BLAccessibilityID.Root.tab(.orders))

            Tab(
                RootTab.campaigns.title,
                systemImage: RootTab.campaigns.systemImage,
                value: RootTab.campaigns
            ) {
                destination(for: .campaigns)
            }
            .accessibilityIdentifier(BLAccessibilityID.Root.tab(.campaigns))

            Tab(
                RootTab.insights.title,
                systemImage: RootTab.insights.systemImage,
                value: RootTab.insights
            ) {
                destination(for: .insights)
            }
            .accessibilityIdentifier(BLAccessibilityID.Root.tab(.insights))

            Tab(RootTab.more.title, systemImage: RootTab.more.systemImage, value: RootTab.more) {
                destination(for: .more)
            }
            .accessibilityIdentifier(BLAccessibilityID.Root.tab(.more))
        }
        .tabViewStyle(.sidebarAdaptable)
        .defaultAdaptableTabBarPlacement(.tabBar)
        .tabViewSidebarHeader {
            sidebarHeader
        }
    }
}

// MARK: - Private Views

private extension RootNavigationLayout {

    /// 依根分頁回傳其專屬功能畫面與 scoped Store
    ///
    /// - Parameter tab: 要呈現的根分頁
    /// - Returns: 以所屬功能 Store 建立的畫面
    @ViewBuilder
    func destination(for tab: RootTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(
                store: store.scope(state: \.dashboard, action: \.dashboard),
                language: language
            )

        case .orders:
            OrdersView(store: store.scope(state: \.orders, action: \.orders), language: language)

        case .campaigns:
            CampaignView(
                store: store.scope(state: \.campaigns, action: \.campaigns),
                language: language
            )

        case .insights:
            InsightsView(
                store: store.scope(state: \.insights, action: \.insights),
                language: language
            )

        case .more:
            MoreView(store: store.scope(state: \.more, action: \.more), language: language)
        }
    }

    /// BL 漸層標誌與 App 名稱，僅顯示於原生根側邊欄
    var sidebarHeader: some View {
        HStack(spacing: BLSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: logoTileCornerRadius, style: .continuous)
                    .frame(width: logoTileSize, height: logoTileSize)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blAccent, .blPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(verbatim: "BL")
                    .font(BLTypographyStyle.caption.font.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(verbatim: "BuyLedger")
                .font(BLTypographyStyle.headline.font.weight(.bold))
                .foregroundStyle(.blLabel)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(BLAccessibilityID.Root.sidebar)
    }
}

// MARK: - Preview

#Preview("自適應根導覽") {
    let previewState: RootFeature.State = {
        let state = RootFeature.State(orders: OrdersFeature.State(orders: LedgerOrder.sampleOrders))
        state.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        return state
    }()

    RootNavigationLayout(
        store: Store(initialState: previewState) {
            RootFeature()
        },
        language: .traditionalChinese
    )
}
