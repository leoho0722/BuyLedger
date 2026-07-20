//
//  RootView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// App 根畫面，依平台與水平尺寸切換主要導覽樣式
struct RootView: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// 目前水平尺寸分類
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    // MARK: - View Body

    /// App 根畫面的內容
    ///
    /// 外觀一律跟隨系統：外觀是系統層級設定，App 內重複切換會讓使用者困惑系統設定是否生效
    var body: some View {
        layout
            // 於根層統一設定色調，讓系統元件與自訂元件取用同一個強調色資源
            .tint(Color("AccentColor", bundle: .assets))
            .environment(\.locale, store.settings.language.locale)
            .task {
                await store.send(.task).finish()
            }
    }
}

// MARK: - ViewBuilder

private extension RootView {

    /// 依尺寸分類選擇對應的根層級導覽佈局
    @ViewBuilder
    var layout: some View {
        if horizontalSizeClass == .compact {
            RootTabLayout(store: store, language: store.settings.language)
        } else {
            RootSidebarLayout(store: store, language: store.settings.language)
        }
    }
}

// MARK: - Preview

#Preview("Root") {
    RootView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
