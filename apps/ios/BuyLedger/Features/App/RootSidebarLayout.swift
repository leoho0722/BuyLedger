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

    /// App 根層級 store
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
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(
                            top: 6,
                            leading: 12,
                            bottom: 14,
                            trailing: 12
                        )
                    )
            }

            Section("工作區") {
                navRow(.dashboard, isSelected: selection == .tab(.dashboard))

                navRow(
                    .orders,
                    isSelected: selection == .tab(.orders),
                    badgeCount: SidebarBadgeCounts.activeOrderCount(orders: store.orders.orders)
                )

                navRow(.campaigns, isSelected: selection == .tab(.campaigns))

                navRow(.insights, isSelected: selection == .tab(.insights))
            }

            Section("工具") {
                navRow(.more, isSelected: selection == .tab(.more))
            }

            Section("智慧分組") {
                ForEach(SidebarSmartGroup.orderBrowsingCases) {
                    // 分頁與智慧分組共用同一個選取型別並統一標記，系統才只會高亮一列
                    smartGroupRow(
                        $0,
                        palette: palette,
                        isSelected: selection == .smartGroup($0.status)
                    )
                    .tag(SidebarSelection.smartGroup($0.status))
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.sidebar)
        .accessibilityIdentifier(BLAccessibilityID.Root.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
    }

    /// BL gradient logo 與 App 名稱列
    ///
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: logo 列 view
    @ViewBuilder
    func logoRow(palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.accent, palette.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Text("BL")
                    .font(BLTypographyStyle.caption.font.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text("BuyLedger")
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
                BLBadge("\(badgeCount)", tone: .destructive, variant: .count)
            }
        }
        .tag(SidebarSelection.tab(tab))
        // 整列合併為單一朗讀單位，筆數改由這一層的 accessibility value 承載
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(BLAccessibilityID.Root.tab(tab.accessibilityKey))
        .accessibilityLabel(Text(LocalizedStringKey(tab.title)))
        .accessibilityValue(badgeAccessibilityValue(badgeCount))
        // 選取態由清單 cell 承載，合併後的這個元素讀不到，故顯式標上
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 智慧分組單列：色點 + 狀態名稱 + 計數
    ///
    /// - Parameters:
    ///   - group: 智慧分組項目
    ///   - palette: 目前外觀使用的色盤
    ///   - isSelected: 該列是否為目前選取項
    /// - Returns: 智慧分組列 view
    @ViewBuilder
    func smartGroupRow(
        _ group: SidebarSmartGroup,
        palette: BLPalette,
        isSelected: Bool
    ) -> some View {
        let count = SidebarBadgeCounts.orderCount(for: group.status, orders: store.orders.orders)

        HStack(spacing: BLSpacing.small) {
            Circle()
                .fill(group.color(in: palette))
                .frame(width: 9, height: 9)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(group.status.title))
                .blTextStyle(.subhead)
                .foregroundStyle(palette.label)

            Spacer(minLength: 0)

            Text("\(count)")
                .font(BLTypographyStyle.footnote.font.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(palette.secondaryLabel)
        }
        // 整列合併為單一朗讀單位，筆數改由這一層的 accessibility value 承載
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(BLAccessibilityID.Root.smartGroup(group.accessibilityKey))
        .accessibilityLabel(Text(LocalizedStringKey(group.status.title)))
        .accessibilityValue(Text(" \(count) 件"))
        // 選取態由清單 cell 承載，合併後的這個元素讀不到，故顯式標上
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 目前選取分頁的內容
    ///
    /// - Parameter selectedTab: 目前選取的主要分頁
    /// - Returns: 分頁對應的 SwiftUI view
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

        /// 智慧分組 (訂單頁的狀態篩選)
        ///
        /// - Parameter status: 對應的訂單狀態
        case smartGroup(OrderStatus)
    }
}

// MARK: - Private Method

private extension RootSidebarLayout {

    /// 目前選取的側邊欄項目
    var currentSelection: SidebarSelection {
        if case .status(let status) = store.orders.selectedStatus,
           store.selectedTab == .orders,
           SidebarSmartGroup.orderBrowsingCases.contains(where: { $0.status == status }) {
            return .smartGroup(status)
        }
        return .tab(store.selectedTab)
    }

    /// `List` 單選 binding：分頁與智慧分組共用同一個選取型別
    var selectionBinding: Binding<SidebarSelection?> {
        Binding {
            currentSelection
        } set: { newSelection in
            switch newSelection {
            case .tab(let tab):
                store.send(.view(.sidebarTabSelected(tab)))

            case .smartGroup(let status):
                store.send(.view(.smartGroupSelected(status)))

            case nil:
                return
            }
        }
    }

    /// 分頁列合併朗讀後承載徽章筆數的 accessibility value
    ///
    /// - Parameter badgeCount: 徽章數字；為 `nil` 或 `0` 時不朗讀筆數
    /// - Returns: 筆數描述
    func badgeAccessibilityValue(_ badgeCount: Int?) -> Text {
        guard let badgeCount, badgeCount > 0 else {
            return Text(verbatim: "")
        }
        return Text("\(badgeCount) 件進行中")
    }
}

// MARK: - Preview

#Preview("Sidebar") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.hasLoaded = true
        return state
    }()

    return RootSidebarLayout(
        store: Store(initialState: previewState) {
            RootFeature()
        },
        language: .traditionalChinese
    )
}
