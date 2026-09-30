//
//  MockAppConfigurationStore.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

@testable import BuyLedger

/// 以可設定結果並記錄呼叫的方式模擬 App 設定讀取
final class MockAppConfigurationStore: Sendable {

    // MARK: - Properties

    /// `string(forKey:)` 的呼叫次數
    private let stringCallCountState = LockIsolated(0)

    /// `string(forKey:)` 依呼叫順序收到的 `key`
    private let stringReceivedArgumentsState = LockIsolated<[String]>([])

    /// `string(forKey:)` 依 `key` 對應的回傳值
    private let stringResultState = LockIsolated<[String: String]>([:])
}

// MARK: - Computed Properties

extension MockAppConfigurationStore {

    /// `string(forKey:)` 的呼叫次數
    var stringCallCount: Int {
        stringCallCountState.withValue { $0 }
    }

    /// `string(forKey:)` 收到的 `key`
    var stringReceivedArguments: [String] {
        stringReceivedArgumentsState.withValue { $0 }
    }

    /// 設定 `string(forKey:)` 依 `key` 回傳的值
    var stringResult: [String: String] {
        get {
            stringResultState.withValue { $0 }
        }
        set {
            stringResultState.withValue { $0 = newValue }
        }
    }
}

// MARK: - AppConfigurationStoreProtocol

extension MockAppConfigurationStore: AppConfigurationStoreProtocol {

    /// 記錄 `key` 並回傳測試端設定的字串
    ///
    /// - Parameter key: 要查詢的設定 `key`
    /// - Returns: `stringResult` 中對應的字串，或未設定時的 `nil`
    func string(forKey key: String) -> String? {
        stringCallCountState.withValue { $0 += 1 }
        stringReceivedArgumentsState.withValue { $0.append(key) }
        return stringResultState.withValue { $0[key] }
    }
}
