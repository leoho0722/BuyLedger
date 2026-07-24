//
//  RootTabLayout.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// iPhone 使用的分頁導覽
struct RootTabLayout: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - View Body

    /// 分頁導覽的畫面內容
    ///
    /// 底部分頁列的按鈕掛不上 identifier：identifier 不論加在 `Tab` 或其 label 上都不會傳到分頁按鈕 (實測)。
    /// UI 測試改由導覽分流器依 `RootTab.allCases` 的順序取按鈕，再等該分頁的畫面根 identifier 確認切換成功
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            ForEach(RootTab.allCases) { tab in
                Tab(LocalizedStringKey(tab.title), systemImage: tab.systemImage, value: tab) {
                    destination(for: tab)
                }
            }
        }
    }
}

// MARK: - ViewBuilder

private extension RootTabLayout {

    /// 回傳指定分頁的主要內容
    /// - Parameter tab: 要顯示的分頁
    /// - Returns: 分頁對應的 SwiftUI view
    @ViewBuilder
    func destination(for tab: RootTab) -> some View {
        switch tab {
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

// MARK: - Preview

#Preview("iPhone 分頁") {
    RootTabLayout(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        },
        language: .traditionalChinese
    )
}
