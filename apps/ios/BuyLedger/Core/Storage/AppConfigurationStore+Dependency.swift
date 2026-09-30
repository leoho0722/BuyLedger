//
//  AppConfigurationStore+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

// MARK: - DependencyKey

/// 把 `AppConfigurationStoreProtocol` 註冊進 TCA 依賴系統：正式 App 用正式實作，Preview 用 stub；
/// 不宣告測試值，測 Service 時漏了以 `withDependencies` 注入 mock 就會直接失敗
enum AppConfigurationStoreKey: DependencyKey {

    /// App 執行時從主要 `Bundle` 讀取設定
    static var liveValue: any AppConfigurationStoreProtocol {
        AppConfigurationStore(bundle: .main)
    }

    #if DEBUG

    /// Preview 使用固定設定值
    static var previewValue: any AppConfigurationStoreProtocol {
        PreviewAppConfigurationStore()
    }

    #endif
}

// MARK: - DependencyValues

extension DependencyValues {

    /// App 環境設定的技術讀取介面
    var appConfigurationStore: any AppConfigurationStoreProtocol {
        get { self[AppConfigurationStoreKey.self] }
        set { self[AppConfigurationStoreKey.self] = newValue }
    }
}
