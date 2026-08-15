//
//  TelemetryClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/29.
//

import ComposableArchitecture
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

/// 套用遙測資料收集的可替換介面
struct TelemetryClient: Sendable {

    // MARK: - Dependency Properties

    /// 在 Firebase 框架初始化前啟用 Performance 的自動埋點；此時機之後無法變更
    var enablePreInitializationCollection: @Sendable () -> Void

    /// 啟用 Analytics、Crashlytics 與 Performance 的資料收集
    var enableCollection: @Sendable () -> Void
}

// MARK: - Dependency Values

extension TelemetryClient: DependencyKey {

    /// 正式環境套用三個遙測 SDK 的收集開關
    nonisolated static let liveValue: TelemetryClient = TelemetryClient(
        enablePreInitializationCollection: {
            let performance = Performance.sharedInstance()
            performance.isInstrumentationEnabled = true
            performance.isDataCollectionEnabled = true
        },
        enableCollection: {
            Analytics.setAnalyticsCollectionEnabled(true)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

            let performance = Performance.sharedInstance()
            performance.isInstrumentationEnabled = true
            performance.isDataCollectionEnabled = true
        }
    )

    /// 測試環境不觸碰 Firebase SDK
    nonisolated static let testValue: TelemetryClient = TelemetryClient(
        enablePreInitializationCollection: {},
        enableCollection: {}
    )

    /// Preview 不觸碰 Firebase SDK
    nonisolated static let previewValue: TelemetryClient = testValue
}
