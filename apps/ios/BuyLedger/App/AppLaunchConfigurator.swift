//
//  AppLaunchConfigurator.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/25.
//

import FirebaseCore
import SwiftData

/// 集中管理 App 啟動時的各項服務初始化
enum AppLaunchConfigurator {}

// MARK: - Internal Method

extension AppLaunchConfigurator {
    
    /// 初始化 Firebase；遙測強制開啟，不讀取任何使用者偏好
    /// - Parameter crashDiagnosticsClient: 崩潰診斷服務；預設使用正式服務
    static func configure(crashDiagnosticsClient: CrashDiagnosticsClient = .live) {
#if DEBUG
        guard !BLUITestConfiguration.current.isEnabled else {
            return
        }
#endif
        
        // 此處刻意直接走 TelemetryClient.liveValue，不經尚未建立的相依注入容器
        TelemetryClient.liveValue.enablePreInitializationCollection()
        
        FirebaseApp.configure()
        TelemetryClient.liveValue.enableCollection()
        
        if case let .degraded(reason) = PersistenceContainer.bootstrap.outcome {
            crashDiagnosticsClient.record("SwiftData store could not open: \(reason)")
        }
    }
    
    /// 帶 UI 測試啟動參數時完成資料與依賴的前置注入
    @MainActor
    static func prepareUITestHarnessIfNeeded() {
#if DEBUG
        BLUITestHarness.prepareIfNeeded()
#endif
    }
}

// MARK: - Computed Properties

extension AppLaunchConfigurator {
    
    /// 啟動時使用的持久層設定
    @MainActor
    static var activePersistenceBootstrap: PersistenceContainer.Bootstrap {
#if DEBUG
        if let container = BLUITestHarness.modelContainer {
            return PersistenceContainer.Bootstrap(container: container, outcome: .healthy)
        }
#endif
        
        return PersistenceContainer.bootstrap
    }
}
