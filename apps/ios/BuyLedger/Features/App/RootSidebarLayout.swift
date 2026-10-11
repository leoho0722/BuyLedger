//
//  RootSidebarLayout.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// iPadOS 使用的側邊欄導覽
struct RootSidebarLayout: View {

    // MARK: - Properties

    /// 徽章朗讀使用的顯示語系
    @Environment(\.locale) private var locale

    /// logo 磚的圓角，隨動態字級等比放大
    @ScaledMetric private var logoTileCornerRadius: CGFloat = 7

    /// logo 磚的邊長，隨動態字級等比放大
    @ScaledMetric private var logoTileSize: CGFloat = 28

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<RootFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 側邊欄導覽的畫面內容
    var body: some View {
        splitView
    }
}

// MARK: - Private Views

private extension RootSidebarLayout {

    /// 根層級分欄導覽
    @ViewBuilder
    var splitView: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            destination(selectedTab: store.selectedTab)
        }
    }

    /// 側邊欄內容
    @ViewBuilder
    var sidebar: some View {
        let palette = BLPalette()
        let selection = currentSelection

        List(selection: selectionBinding) {
            Section {
                logoRow(palette: palette)
                    .listRowInsets(
                        EdgeInsets(
                            top: 6,
                            leading: 12,
                            bottom: 14,
                            trailing: 12
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section("common.general.label.workspace") {
                navRow(.dashboard, isSelected: selection == .tab(.dashboard))

                navRow(
                    .orders,
                    isSelected: selection == .tab(.orders),
                    badgeCount: SidebarBadgeCounts.activeOrderCount(orders: store.orders.orders)
                )

                navRow(.campaigns, isSelected: selection == .tab(.campaigns))

                navRow(.insights, isSelected: selection == .tab(.insights))
            }

            Section("orders.list.label.tools") {
                navRow(.more, isSelected: selection == .tab(.more))
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        .listStyle(.sidebar)
        .accessibilityIdentifier(BLAccessibilityID.Root.sidebar)
    }

    /// BL gradient logo 與 App 名稱列
    ///
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: logo 列 view
    @ViewBuilder
    func logoRow(palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: logoTileCornerRadius, style: .continuous)
                    .frame(width: logoTileSize, height: logoTileSize)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [palette.accent, palette.purple],
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
                .foregroundStyle(palette.label)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// 主要分頁列
    ///
    /// - Parameters:
    ///   - tab: 對應的分頁
    ///   - isSelected: 該列是否為目前選取項
    ///   - badgeCount: 顯示在右側的紅色徽章數字；為 `nil` 或 `0` 時不顯示
    /// - Returns: 分頁列 view
    @ViewBuilder
    func navRow(_ tab: RootTab, isSelected: Bool, badgeCount: Int? = nil) -> some View {
        HStack(spacing: BLSpacing.small) {
            Label(LocalizedStringKey(tab.title), systemImage: tab.systemImage)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 0)

            if let badgeCount, badgeCount > 0 {
                BLBadge(String(badgeCount), tone: .destructive, variant: .count)
            }
        }
        .tag(SidebarSelection.tab(tab))
        // 整列合併為單一朗讀單位，筆數改由這一層的 accessibility value 承載
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(BLAccessibilityID.Root.tab(tab.accessibilityKey))
        .accessibilityLabel(Text(LocalizedStringKey(tab.title)))
        .accessibilityValue(
            Text(
                verbatim: SidebarBadgeCounts.accessibilityValue(
                    badgeCount,
                    language: AppLanguage(locale: locale)
                )
            )
        )
        // 選取態由清單 cell 承載，合併後的這個元素讀不到，故顯式標上
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 目前選取分頁的內容
    ///
    /// - Parameter selectedTab: 目前選取的主要分頁
    /// - Returns: 分頁對應的 `SwiftUI` view
    @ViewBuilder
    func destination(selectedTab: RootTab) -> some View {
        switch selectedTab {
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
}

// MARK: - Nested Types

private extension RootSidebarLayout {

    /// 側邊欄的單一選取型別
    enum SidebarSelection: Hashable {

        /// 主要分頁
        ///
        /// - Parameter tab: 對應的主要分頁
        case tab(RootTab)
    }
}

// MARK: - Private Method

private extension RootSidebarLayout {

    /// 目前選取的側邊欄項目
    var currentSelection: SidebarSelection {
        .tab(store.selectedTab)
    }

    /// `List` 單選 binding：選取分頁列時切換分頁
    var selectionBinding: Binding<SidebarSelection?> {
        Binding {
            currentSelection
        } set: { newSelection in
            switch newSelection {
            case .tab(let tab):
                store.send(.view(.sidebarTabSelected(tab)))

            case nil:
                return
            }
        }
    }
}

// MARK: - Preview

#Preview("Sidebar") {
    let previewState: RootFeature.State = {
        let state = RootFeature.State(orders: OrdersFeature.State(orders: LedgerOrder.sampleOrders))
        state.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        return state
    }()

    return RootSidebarLayout(
        store: Store(initialState: previewState) {
            RootFeature()
        },
        language: .traditionalChinese
    )
}
