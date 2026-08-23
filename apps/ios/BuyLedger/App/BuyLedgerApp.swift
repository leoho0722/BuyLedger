//
//  BuyLedgerApp.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/29.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

/// BuyLedger 的 App 入口
@main
struct BuyLedgerApp: App {
    
    // MARK: - App Properties
    
    /// AppDelegate，負責 App 啟動設定
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    
    /// App 根層級 store
    private let store: StoreOf<RootFeature>
    
    /// App 共用的 SwiftData 資料庫容器
    private let modelContainer: ModelContainer
    
    /// 目前 App 場景狀態，交給 AppLockFeature 處理
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Init
    
    init() {
        // 順序不可調換：UI 測試的依賴注入必須早於 store 建立，否則依賴已定型
        AppLaunchConfigurator.prepareUITestHarnessIfNeeded()
        let bootstrap = AppLaunchConfigurator.activePersistenceBootstrap
        
        @Dependency(SettingsStorage.self) var settingsStorage
        let isBiometricUnlockEnabled = settingsStorage.load().isBiometricUnlockEnabled
        
        store = Store(
            initialState: RootFeature.State(
                persistenceStatus: bootstrap.status,
                isBiometricUnlockEnabled: isBiometricUnlockEnabled
            )
        ) {
            RootFeature()
        }
        modelContainer = bootstrap.container
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            AppScenePhaseCoordinator.handle(newPhase: newPhase) { action in
                store.send(.settings(.appLock(action)))
            }
        }
    }
}
