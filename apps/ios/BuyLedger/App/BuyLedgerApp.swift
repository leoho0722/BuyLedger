//
//  BuyLedgerApp.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/29.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct BuyLedgerApp: App {

    // MARK: - App Properties

    /// 以 `@UIApplicationDelegateAdaptor` 接上 ``AppDelegate``，於啟動時初始化 Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    /// App 根層級 store
    private let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    /// SwiftData 共用 ``ModelContainer``：直接取用 ``PersistenceContainer/shared``，
    /// 讓 environment 注入的 container 與各 repository 的 `liveValue` 是同一實例
    ///
    /// 不另呼叫 ``PersistenceContainer/makeForApp()``——同一 process 並存多個 container 會造成 SwiftData 內部狀態錯亂
    private let modelContainer: ModelContainer = PersistenceContainer.shared

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
        .modelContainer(modelContainer)
    }
}
