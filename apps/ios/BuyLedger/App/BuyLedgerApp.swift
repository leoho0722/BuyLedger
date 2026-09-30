//
//  BuyLedgerApp.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/29.
//

import ComposableArchitecture
import SwiftUI

/// BuyLedger 的 App 入口
@main
struct BuyLedgerApp: App {

    // MARK: - Properties

    /// `AppDelegate`，負責 App 啟動設定
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// App 根層級的 `Store`；單元測試執行時不建立，為 `nil`
    private let store: StoreOf<RootFeature>?

    /// 目前 App 場景狀態，交給 `AppLockFeature` 處理
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init

    /// 建立 App 根狀態；單元測試執行時略過整個啟動流程
    init() {
        if RuntimeEnvironment.isUnitTesting {
            store = nil
            return
        }

        // 順序不可調換：UI 測試的依賴注入必須早於 store 建立，否則依賴已定型
        AppLaunchConfigurator.prepareUITestHarnessIfNeeded()
        let persistenceStatus = AppLaunchConfigurator.activePersistenceStatus

        @Dependency(\.settingsService) var settingsService
        let settings = SettingsFeature.State(
            snapshot: settingsService.load(),
            appVersion: Bundle.appVersion
        )

        store = Store(
            initialState: RootFeature.State(
                persistenceStatus: persistenceStatus,
                settings: settings
            )
        ) {
            RootFeature()
        }
    }

    // MARK: - Body

    /// App 的視窗：顯示根畫面，並把前景與背景切換轉給 `AppLockFeature`
    var body: some Scene {
        WindowGroup {
            if let store {
                RootView(store: store)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard let store else {
                return
            }

            AppScenePhaseCoordinator.handle(newPhase: newPhase) {
                store.send(.settings(.appLock($0)))
            }
        }
    }
}
