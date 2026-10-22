//
//  AppLaunchConfigurator.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/25.
//

import ComposableArchitecture
import FirebaseCore

/// 集中管理 App 啟動時的各項服務初始化
enum AppLaunchConfigurator {}

// MARK: - Computed Properties

extension AppLaunchConfigurator {

    /// 啟動時使用的持久層狀態；UI 測試已備妥測試資料庫時一律視為正常
    @MainActor
    static var activePersistenceStatus: PersistenceContainer.Status {
#if DEBUG
        if BLUITestHarness.modelContainer != nil {
            return .healthy
        }
#endif

        return PersistenceContainer.bootstrap.status
    }
}

// MARK: - Internal Method

extension AppLaunchConfigurator {

    /// 帶 UI 測試啟動參數時完成資料與依賴的前置注入
    @MainActor
    static func prepareUITestHarnessIfNeeded() {
#if DEBUG
        BLUITestHarness.prepareIfNeeded()
#endif
    }

    /// 初始化 Firebase 並強制開啟遙測，不讀取任何使用者偏好；資料庫開不起來時另外回報給崩潰診斷
    ///
    /// - Parameter crashDiagnosticsClient: 崩潰診斷服務；預設使用正式服務
    /// - Note: 單元測試與 UI 測試模式下直接略過
    static func configure(crashDiagnosticsClient: CrashDiagnosticsClient = .live) {
        guard !RuntimeEnvironment.isUnitTesting else {
            return
        }

#if DEBUG
        guard !BLUITestConfiguration.current.isEnabled else {
            return
        }
#endif

        @Dependency(\.telemetryService) var telemetryService
        telemetryService.enablePreInitializationCollection()

        FirebaseApp.configure()
        telemetryService.enableCollection()

        if case .degraded(let reason) = PersistenceContainer.bootstrap.status {
            crashDiagnosticsClient.record("SwiftData store could not open: \(reason)")
        }
    }
}
