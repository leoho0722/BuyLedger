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

    // MARK: - Properties

    /// 目前水平尺寸分類
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    // MARK: - Body

    /// App 根畫面的內容
    var body: some View {
        Group {
            if let failureStore = store.scope(
                state: \.persistenceFailure,
                action: \.persistenceFailure.presented
            ) {
                PersistenceFailureView(store: failureStore)
            } else {
                mainContent
            }
        }
        .environment(\.locale, store.preferences.language.locale)
    }
}

// MARK: - Private Views

private extension RootView {

    /// 持久層正常時的主內容，依鎖定狀態切換鎖定畫面與一般佈局；啟動工作只在這一層執行
    var mainContent: some View {
        Group {
            if store.appLock.isLocked {
                AppLockView(store: store.scope(state: \.appLock, action: \.appLock))
            } else {
                layout
            }
        }
        .task {
            await store.send(.view(.task)).finish()
        }
    }

    /// 依尺寸分類選擇對應的根層級導覽佈局
    @ViewBuilder
    var layout: some View {
        if horizontalSizeClass == .compact {
            RootTabLayout(store: store, language: store.preferences.language)
        } else {
            RootSidebarLayout(store: store, language: store.preferences.language)
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
