//
//  RootSidebarLayout.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// iPadOS 使用的側邊欄導覽
///
/// 對應設計稿的左側欄：BL gradient logo、依語意分段的分頁清單 (工作區 / 工具 / 智慧分組)，以及進行中訂單數量的紅色徽章
struct RootSidebarLayout: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Body

    /// 側邊欄導覽的畫面內容
    var body: some View {
        splitView
    }
}

// MARK: - Nested Types

private extension RootSidebarLayout {

    /// 側邊欄「智慧分組」中以狀態 + 顏色呈現的項目
    ///
    /// 涵蓋訂單從報價到交付的整條 pipeline；`cancelled` 不列入，避免使用者誤以為這是常用入口
    enum SmartGroup: String, Identifiable, CaseIterable {

        // MARK: - Cases

        /// 報價中的訂單分組
        case quoting

        /// 已確認但尚未下單的訂單分組
        case confirmed

        /// 已下單但尚未集運的訂單分組
        case purchased

        /// 集運中的訂單分組
        case shipping

        /// 部分商品已到貨的訂單分組
        case partiallyArrived

        /// 已到貨但尚未交付的訂單分組
        case arrived

        /// 已交付完成的訂單分組
        case delivered

        /// 買家已取貨完成的訂單分組
        case pickedUp

        // MARK: - Identifiable Properties

        /// 分組的穩定識別值
        var id: String { rawValue }

        // MARK: - Data Properties

        /// 對應的訂單狀態
        var status: OrderStatus {
            switch self {
            case .quoting:
                .quoting
            case .confirmed:
                .confirmed
            case .purchased:
                .purchased
            case .shipping:
                .shipping
            case .partiallyArrived:
                .partiallyArrived
            case .arrived:
                .arrived
            case .delivered:
                .delivered
            case .pickedUp:
                .pickedUp
            }
        }

        /// 在側邊欄顯示的色點顏色
        /// - Parameter palette: 目前外觀使用的色盤
        /// - Returns: 色點顏色
        func color(in palette: BLPalette) -> Color {
            switch self {
            case .quoting:
                palette.teal
            case .confirmed:
                palette.accent
            case .purchased:
                palette.indigo
            case .shipping:
                palette.orange
            case .partiallyArrived:
                palette.purple
            case .arrived:
                palette.yellow
            case .delivered:
                palette.green
            case .pickedUp:
                palette.pink
            }
        }

        // MARK: - Static Properties

        /// 訂單瀏覽 sidebar 中提供的固定順序 (依訂單生命週期由前到後排)
        static let orderBrowsingCases: [SmartGroup] = [
            .quoting, .confirmed, .purchased, .shipping, .partiallyArrived, .arrived, .delivered,
            .pickedUp,
        ]
    }
}

// MARK: - ViewBuilder

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
        let palette = BLTheme.palette(for: colorScheme)

        List(selection: tabSelectionBinding) {
            Section {
                logoRow(palette: palette)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 14, trailing: 12))
            }

            Section("工作區") {
                navRow(.dashboard, palette: palette)
                navRow(.orders, palette: palette, badgeCount: SidebarBadgeCounts.activeOrderCount(orders: store.orders.orders))
                navRow(.campaigns, palette: palette)
                navRow(.insights, palette: palette)
            }

            Section("工具") {
                navRow(.more, palette: palette)
            }

            Section("智慧分組") {
                ForEach(SmartGroup.orderBrowsingCases) { group in
                    Button {
                        store.send(.smartGroupSelected(group.status))
                    } label: {
                        smartGroupRow(group, palette: palette)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        isSmartGroupHighlighted(group)
                            ? palette.accent.opacity(0.18)
                            : Color.clear
                    )
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
    }

    /// BL gradient logo 與 App 名稱列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: logo 列 view
    @ViewBuilder
    func logoRow(palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LinearGradient(
                        colors: [palette.accent, palette.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)

                Text("BL")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("BuyLedger")
                .font(.headline.weight(.bold))
                .foregroundStyle(palette.label)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// 主要分頁列
    ///
    /// `palette _:` 採用「外部 label `palette` + 內部名稱 `_`」的寫法：``BLBadge`` 自帶 tone-based 色彩、
    /// body 已不讀 palette；保留外部 label 是為了與其他 row helper (``smartGroupRow``、``logoRow`` 等)
    /// 呼叫風格一致，未來 nav 列要套色也不必動呼叫端
    /// - Parameters:
    ///   - tab: 對應的分頁
    ///   - palette: 目前外觀使用的色盤；目前未使用，預留給未來不同 tab 套不同色等需求
    ///   - badgeCount: 顯示在右側的紅色徽章數字；為 `nil` 或 `0` 時不顯示
    /// - Returns: 分頁列 view
    @ViewBuilder
    func navRow(_ tab: RootTab, palette _: BLPalette, badgeCount: Int? = nil) -> some View {
        HStack(spacing: BLSpacing.small) {
            Label(LocalizedStringKey(tab.title), systemImage: tab.systemImage)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 0)

            if let badgeCount, badgeCount > 0 {
                BLBadge("\(badgeCount)", tone: .destructive, variant: .count)
                    .accessibilityLabel(Text("\(badgeCount) 件進行中"))
            }
        }
        .tag(tab)
    }

    /// 智慧分組單列：色點 + 狀態名稱 + 計數
    /// - Parameters:
    ///   - group: 智慧分組項目
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 智慧分組列 view
    @ViewBuilder
    func smartGroupRow(_ group: SmartGroup, palette: BLPalette) -> some View {
        let count = SidebarBadgeCounts.orderCount(for: group.status, orders: store.orders.orders)

        HStack(spacing: BLSpacing.small) {
            Circle()
                .fill(group.color(in: palette))
                .frame(width: 9, height: 9)

            Text(LocalizedStringKey(group.status.title))
                .font(.subheadline)
                .foregroundStyle(palette.label)

            Spacer(minLength: 0)

            Text("\(count)")
                .font(.footnote.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(palette.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(group.status.title)))
        .accessibilityValue(Text(" \(count) 件"))
    }

    /// 目前選取分頁的內容
    /// - Parameter selectedTab: 目前選取的主要分頁
    /// - Returns: 分頁對應的 SwiftUI view
    @ViewBuilder
    func destination(selectedTab: RootTab) -> some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(store: store)
        case .orders:
            OrdersView(store: store.scope(state: \.orders, action: \.orders), language: language)
        case .campaigns:
            CampaignListView(store: store)
        case .insights:
            InsightsView(store: store)
        case .more:
            MoreView(store: store)
        }
    }
}

// MARK: - Private Method

private extension RootSidebarLayout {

    /// `List` 單選 binding：將 SwiftUI 的 `RootTab?` 選取轉成 TCA action
    var tabSelectionBinding: Binding<RootTab?> {
        Binding(
            get: { store.selectedTab },
            set: { newTab in
                guard let newTab, newTab != store.selectedTab else {
                    return
                }

                store.send(.tabSelected(newTab))
            }
        )
    }

    /// 智慧分組列是否應顯示「目前生效」的 highlight
    ///
    /// 條件為：使用者當下停留在訂單頁，且訂單頁的狀態篩選正套用到此 group 對應的狀態
    /// - Parameter group: 要判斷的智慧分組
    /// - Returns: 是否要套用 accent 背景
    func isSmartGroupHighlighted(_ group: SmartGroup) -> Bool {
        store.selectedTab == .orders
            && store.orders.selectedStatus == .status(group.status)
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
