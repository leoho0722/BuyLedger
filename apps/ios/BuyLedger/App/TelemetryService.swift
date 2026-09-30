//
//  TelemetryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

/// 控制 Firebase 遙測資料的收集時機與範圍；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
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
