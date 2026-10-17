//
//  TelemetryService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

// MARK: - DependencyKey

extension TelemetryService: DependencyKey {

    /// 正式環境啟用 Analytics、Crashlytics 與 Performance 收集
    static var liveValue: Self {
        Self(
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
    }

    /// 測試預設不觸碰 Firebase SDK，未覆寫時會回報未實作 issue
    static var testValue: Self {
        Self(
            enablePreInitializationCollection: unimplemented(
                "TelemetryService.enablePreInitializationCollection"
            ),
            enableCollection: unimplemented("TelemetryService.enableCollection")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 App 啟動設定取得遙測收集操作
    var telemetryService: TelemetryService {
        get { self[TelemetryService.self] }
        set { self[TelemetryService.self] = newValue }
    }
}
