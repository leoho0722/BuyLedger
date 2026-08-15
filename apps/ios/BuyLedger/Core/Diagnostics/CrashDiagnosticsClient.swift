//
//  CrashDiagnosticsClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/26.
//

import FirebaseCrashlytics
import Foundation

/// 將啟動診斷送往當機診斷服務的可替換介面
struct CrashDiagnosticsClient: Sendable {

    // MARK: - Dependency Properties

    /// 記錄不含使用者資料的啟動診斷訊息
    /// - Parameter message: 要送出的診斷訊息
    var record: @Sendable (_ message: String) -> Void
}

// MARK: - Dependency Values

extension CrashDiagnosticsClient {

    /// 正式環境的 Crashlytics 實作
    static let live = CrashDiagnosticsClient { message in
        Crashlytics.crashlytics().log(message)
    }

    /// 測試與不需遙測的環境使用的空實作
    static let noop = CrashDiagnosticsClient { _ in }
}
