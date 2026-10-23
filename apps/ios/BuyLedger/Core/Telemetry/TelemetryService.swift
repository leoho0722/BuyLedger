//
//  TelemetryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

/// 控制 Firebase 遙測資料的收集時機與範圍；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct TelemetryService: Sendable {

    // MARK: - Properties

    /// 啟用 Performance 的自動效能量測
    ///
    /// - Note: 必須在 `FirebaseApp.configure()` 之前呼叫，之後設定不會生效
    var enablePreInitializationCollection: EnablePreInitializationCollection

    /// 啟用 Analytics、Crashlytics 與 Performance 的資料收集
    var enableCollection: EnableCollection
}

// MARK: - Nested Types

extension TelemetryService {

    /// `enablePreInitializationCollection` 的函式型別
    typealias EnablePreInitializationCollection = @Sendable () -> Void

    /// `enableCollection` 的函式型別
    typealias EnableCollection = @Sendable () -> Void
}

// MARK: - DependencyKey

extension TelemetryService: DependencyKey {

    /// 直接設定各 Firebase SDK 的收集開關，Performance 在兩個操作都會開啟
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

    #if DEBUG

    /// Preview 不送出遙測資料；在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "TelemetryService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            enablePreInitializationCollection: { },
            enableCollection: { }
        )
    }

    #endif

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
