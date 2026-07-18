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
    var body: some View {
        layout
            .dismissKeyboardOnTap()
            .preferredColorScheme(preferredScheme)
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

// MARK: - Private Method

private extension RootView {

    /// 將 ``SettingsFeature`` 的外觀偏好對映到 SwiftUI 的 `ColorScheme`
    var preferredScheme: ColorScheme? {
        switch store.settings.appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
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
