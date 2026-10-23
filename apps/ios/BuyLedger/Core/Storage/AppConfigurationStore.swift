//
//  AppConfigurationStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

// MARK: - Protocol

/// App `Info.plist` 字串設定的讀取介面
protocol AppConfigurationStoreProtocol: Sendable {

    /// 讀取並正規化指定 `key` 的字串值
    ///
    /// - Parameter key: `Info.plist` 中的設定 `key`
    /// - Returns: 正規化後的字串，或在值未設定時回傳 `nil`
    func string(forKey key: String) -> String?
}

// MARK: - Implementation

/// 從指定的 `Bundle` 讀取並正規化 `Info.plist` 字串
struct AppConfigurationStore {

    // MARK: - Properties

    /// 提供 `Info.plist` 設定的 `Bundle`
    private let bundle: Bundle

    // MARK: - Init

    /// 建立正式實作
    ///
    /// - Parameter bundle: 提供 `Info.plist` 的 `Bundle`
    init(bundle: Bundle) {
        self.bundle = bundle
    }
}

// MARK: - AppConfigurationStoreProtocol

extension AppConfigurationStore: AppConfigurationStoreProtocol {

    /// 從注入的 `Bundle` 讀取字串並去掉前後空白
    ///
    /// - Parameter key: 原樣拿去查注入 `Bundle` 的 `Info.plist`，不做轉換
    /// - Returns: 仍有內容的字串；未設定、空白，或仍是沒被 Xcode 替換的 `$(key)` 原文時為 `nil`
    func string(forKey key: String) -> String? {
        let rawValue = bundle.object(forInfoDictionaryKey: key) as? String
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholder = "$(\(key))"

        guard let trimmed, !trimmed.isEmpty, trimmed != placeholder else {
            return nil
        }

        return trimmed
    }
}

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

    /// 供 Service 的 `liveValue` 以 `@Dependency(\.appConfigurationStore)` 取得的 `Info.plist` 設定讀取介面
    var appConfigurationStore: any AppConfigurationStoreProtocol {
        get { self[AppConfigurationStoreKey.self] }
        set { self[AppConfigurationStoreKey.self] = newValue }
    }
}

#if DEBUG

// MARK: - Preview

/// Preview 使用固定假值回應設定查詢
struct PreviewAppConfigurationStore {

    // MARK: - Init

    /// 建立只供 Preview 與測試環境使用的設定 stub
    init() {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PreviewAppConfigurationStore 只能在 Preview、UI Test 或單元測試中使用"
        )
    }
}

// MARK: - AppConfigurationStoreProtocol

extension PreviewAppConfigurationStore: AppConfigurationStoreProtocol {

    /// 不讀取 `Bundle`，固定回傳 Preview 設定值
    ///
    /// - Parameter key: 未使用的 `Info.plist` 設定 `key`
    /// - Returns: 固定的 Preview 假值
    func string(forKey key: String) -> String? {
        "preview-stub-key"
    }
}

#endif
