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

    /// 接上 iOS / iPadOS 的 ``AppDelegate``，於啟動時初始化 Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    /// App 根層級 store
    private let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    /// SwiftData 共用 ``ModelContainer``；以純本機方式建立
    ///
    /// 直接取用 ``PersistenceContainer/shared`` (而非另呼叫 `makeForApp()`)，確保 SwiftUI environment 注入的 container 與各 repository 的 `liveValue` 是「同一個」實例，避免同一 process 內並存多個 container 造成 SwiftData 內部狀態錯亂。切換成 CloudKit 同步的步驟詳見 ``PersistenceContainer``
    private let modelContainer: ModelContainer = PersistenceContainer.shared

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
        .modelContainer(modelContainer)
    }
}
