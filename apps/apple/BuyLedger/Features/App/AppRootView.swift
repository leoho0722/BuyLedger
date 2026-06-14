//
//  AppRootView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/14.
//

import ComposableArchitecture
import SwiftUI

/// App 根層級進入點：依 ``CloudSyncFeatureFlag`` 決定是否在 ``RootView`` 之前插入雲端登入閘門。
///
/// 旗標關閉 (預設) 時直接顯示 ``RootView``，行為與導入雲端同步前完全一致 (本機 SwiftData、不顯示登入、不存取 Firestore)。
struct AppRootView: View {

    // MARK: - View Properties

    /// App 根層級 store。
    @Bindable var store: StoreOf<RootFeature>

    // MARK: - View Body

    /// 依旗標選擇直接顯示 ``RootView`` 或先過雲端登入閘門。
    var body: some View {
        if CloudSyncFeatureFlag.isEnabled {
            CloudGatedRootView(store: store)
        } else {
            RootView(store: store)
        }
    }
}

// MARK: - CloudGatedRootView

/// 雲端登入閘門：未登入時顯示 ``CloudSignInView``、登入後顯示 ``RootView``。僅在旗標開啟時使用。
private struct CloudGatedRootView: View {

    // MARK: - View Properties

    /// App 根層級 store。
    @Bindable var store: StoreOf<RootFeature>

    /// 雲端身分驗證 (僅在旗標開啟、本 view 建立時實例化)。
    @State private var auth = CloudAuth()

    // MARK: - View Body

    /// 依登入狀態切換登入畫面或主畫面。
    var body: some View {
        if auth.user == nil {
            CloudSignInView(auth: auth)
        } else {
            RootView(store: store)
        }
    }
}
