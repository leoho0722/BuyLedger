//
//  UserDefaultsStore+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

/// 把 `UserDefaultsStoreProtocol` 註冊進 TCA 依賴系統：正式 App 用正式實作，Preview 用 stub；
/// 不宣告測試值，測 Service 時漏了以 `withDependencies` 注入 mock 就會直接失敗
enum UserDefaultsStoreKey: DependencyKey {

    /// App 執行時使用標準 `UserDefaults`
    static var liveValue: any UserDefaultsStoreProtocol {
        UserDefaultsStore(suiteName: nil)
    }

    #if DEBUG

    /// Preview 使用固定的空偏好值，不保存寫入內容
    static var previewValue: any UserDefaultsStoreProtocol {
        PreviewUserDefaultsStore()
    }

    #endif
}

// MARK: - DependencyValues

extension DependencyValues {

    /// App 偏好設定的技術儲存介面
    var userDefaultsStore: any UserDefaultsStoreProtocol {
        get { self[UserDefaultsStoreKey.self] }
        set { self[UserDefaultsStoreKey.self] = newValue }
    }
}
