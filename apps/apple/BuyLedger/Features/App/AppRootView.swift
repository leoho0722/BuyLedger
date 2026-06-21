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

    /// 跨裝置同步引擎 (登入後建立並啟動投影監聽、登出時釋放)。
    @State private var engine: CloudSyncEngine?

    // MARK: - View Body

    /// 依登入狀態切換登入畫面或主畫面，並依登入狀態管理同步引擎生命週期。
    var body: some View {
        Group {
            if auth.user == nil {
                CloudSignInView(auth: auth)
            } else {
                RootView(store: store)
            }
        }
        .task(id: auth.uid) {
            engine?.stop()
            engine = nil
            guard let uid = auth.uid else { return }

            let newEngine = CloudSyncEngine(
                uid: uid,
                api: BackendAPIClient.liveValue,
                idTokenProvider: { try await auth.idToken() },
                now: { Date() }
            )
            newEngine.onOrdersMerged = { store.send(.orders(.reloadFromStore)) }
            await newEngine.start()
            engine = newEngine
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--auto-push-demo") {
                await newEngine.pushDemoOrder(idSuffix: Int(Date().timeIntervalSince1970))
            }
            if ProcessInfo.processInfo.arguments.contains("--auto-conflict-demo") {
                await newEngine.pushFieldDemo(id: "BL-F4A3D7", field: "customerName", value: "iOS改名")
            }
            if ProcessInfo.processInfo.arguments.contains("--auto-fail-demo") {
                await newEngine.pushDemoOrder(idSuffix: 999_999)
            }
            if ProcessInfo.processInfo.arguments.contains("--auto-drain") {
                await newEngine.drainQueue()
            }
#endif
        }
        .task {
            // Dev/演示用：帶 --auto-dev-signin 啟動參數時自動以 custom token 登入 (繞過互動式 OAuth)。
#if DEBUG
            if auth.user == nil,
               ProcessInfo.processInfo.arguments.contains("--auto-dev-signin") {
                try? await auth.signInWithDevToken()
            }
#endif
        }
    }
}
