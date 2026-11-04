//
//  RootView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// App 根畫面，阻斷持久層失敗並呈現自適應根導覽
struct RootView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由 App 進入點建立後傳入
    @Bindable var store: StoreOf<RootFeature>

    // MARK: - Body

    /// 根畫面骨架：持久層無法開啟時顯示復原畫面，否則顯示主內容，並套用 App 選用的語系
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
                rootNavigation
            }
        }
        .task {
            await store.send(.view(.task)).finish()
        }
    }

    /// 正式 App 使用的唯一自適應根導覽
    var rootNavigation: some View {
        RootNavigationLayout(store: store, language: store.preferences.language)
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
