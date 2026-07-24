//
//  AppLaunchConfigurator.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/25.
//

import FirebaseCore
import SwiftData

/// 集中管理 App 啟動時的各項服務初始化
///
/// App 的 ``AppDelegate`` 在 `didFinishLaunching` 時呼叫 ``configure()``，
/// ``BuyLedgerApp`` 則在建立根 store 之前呼叫 ``prepareUITestHarnessIfNeeded()``，
/// 讓「啟動要做哪些設定」只存在一處；日後新增 Crashlytics、Analytics、Performance
/// 等啟動設定也都集中在此
enum AppLaunchConfigurator {}

// MARK: - Internal Method

extension AppLaunchConfigurator {

    /// 初始化 Firebase
    ///
    /// UI 測試模式略過遙測：避免測試流量混進分析，也讓冷啟動量測不含 Firebase 初始化成本
    static func configure() {
        #if DEBUG
        guard !BLUITestConfiguration.current.isEnabled else {
            return
        }
        #endif

        FirebaseApp.configure()
    }

    /// 帶 UI 測試啟動參數時完成資料與依賴的前置注入
    ///
    /// 必須早於根 store 建立，否則依賴已定型、注入不生效
    @MainActor
    static func prepareUITestHarnessIfNeeded() {
        #if DEBUG
        BLUITestHarness.prepareIfNeeded()
        #endif
    }
}

// MARK: - Computed Properties

extension AppLaunchConfigurator {

    /// 本次啟動實際使用的 ``ModelContainer``
    ///
    /// UI 測試模式取 harness 的 in-memory container，其餘一律取 ``PersistenceContainer/shared``
    @MainActor
    static var activeModelContainer: ModelContainer {
        #if DEBUG
        if let container = BLUITestHarness.modelContainer {
            return container
        }
        #endif

        return PersistenceContainer.shared
    }
}
