//
//  MockUserDefaultsStore.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

@testable import BuyLedger

/// 以可設定的讀取結果與呼叫記錄模擬偏好儲存
///
/// - Note: 寫入值暫存在記憶體，供 `SettingsService` 儲存後讀回測試使用
final class MockUserDefaultsStore: Sendable {

    // MARK: - Properties

    /// `string(forKey:)` 的呼叫次數
    private let stringCallCountState = LockIsolated(0)

    /// `string(forKey:)` 依呼叫順序收到的 key
    private let stringReceivedArgumentsState = LockIsolated<[String]>([])

    /// `string(forKey:)` 的回傳結果
    private let stringResultState = LockIsolated<String?>(nil)

    /// `double(forKey:)` 的呼叫次數
    private let doubleCallCountState = LockIsolated(0)

    /// `double(forKey:)` 依呼叫順序收到的 key
    private let doubleReceivedArgumentsState = LockIsolated<[String]>([])

    /// `double(forKey:)` 的回傳結果
    private let doubleResultState = LockIsolated(0.0)

    /// `bool(forKey:)` 的呼叫次數
    private let boolCallCountState = LockIsolated(0)

    /// `bool(forKey:)` 依呼叫順序收到的 key
    private let boolReceivedArgumentsState = LockIsolated<[String]>([])

    /// `bool(forKey:)` 的回傳結果
    private let boolResultState = LockIsolated(false)

    /// `hasValue(forKey:)` 的呼叫次數
    private let hasValueCallCountState = LockIsolated(0)

    /// `hasValue(forKey:)` 依呼叫順序收到的 key
    private let hasValueReceivedArgumentsState = LockIsolated<[String]>([])

    /// `hasValue(forKey:)` 的回傳結果
    private let hasValueResultState = LockIsolated(false)

    /// `set(_:forKey:)` 字串方法的呼叫次數
    private let stringSetCallCountState = LockIsolated(0)

    /// `set(_:forKey:)` 字串方法收到的參數
    private let stringSetReceivedArgumentsState = LockIsolated<[SetArgument<String>]>([])

    /// `set(_:forKey:)` 浮點數方法的呼叫次數
    private let doubleSetCallCountState = LockIsolated(0)

    /// `set(_:forKey:)` 浮點數方法收到的參數
    private let doubleSetReceivedArgumentsState = LockIsolated<[SetArgument<Double>]>([])

    /// `set(_:forKey:)` 布林值方法的呼叫次數
    private let boolSetCallCountState = LockIsolated(0)

    /// `set(_:forKey:)` 布林值方法收到的參數
    private let boolSetReceivedArgumentsState = LockIsolated<[SetArgument<Bool>]>([])

    /// 以 `key` 保存的偏好值，供讀寫往返測試使用
    private let storedValuesState = LockIsolated<[String: StoredValue]>([:])
}

// MARK: - Nested Types

extension MockUserDefaultsStore {

    /// 儲存方法收到的值與偏好 key
    struct SetArgument<Value: Sendable>: Sendable {

        /// 呼叫端傳入的值
        let value: Value

        /// 呼叫端傳入的偏好 key
        let key: String
    }

    /// 測試替身記憶體中保存的偏好值
    private enum StoredValue: Sendable {

        /// 字串偏好值
        ///
        /// - Parameter value: 儲存的字串
        case string(value: String)

        /// 浮點數偏好值
        ///
        /// - Parameter value: 儲存的浮點數
        case double(value: Double)

        /// 布林偏好值
        ///
        /// - Parameter value: 儲存的布林值
        case bool(value: Bool)
    }
}

// MARK: - Computed Properties

extension MockUserDefaultsStore {

    /// `string(forKey:)` 的呼叫次數
    var stringCallCount: Int {
        stringCallCountState.withValue { $0 }
    }

    /// `string(forKey:)` 收到的 key
    var stringReceivedArguments: [String] {
        stringReceivedArgumentsState.withValue { $0 }
    }

    /// 設定 `string(forKey:)` 的回傳結果
    var stringResult: String? {
        get {
            stringResultState.withValue { $0 }
        }
        set {
            stringResultState.withValue { $0 = newValue }
        }
    }

    /// `double(forKey:)` 的呼叫次數
    var doubleCallCount: Int {
        doubleCallCountState.withValue { $0 }
    }

    /// `double(forKey:)` 收到的 key
    var doubleReceivedArguments: [String] {
        doubleReceivedArgumentsState.withValue { $0 }
    }

    /// 設定 `double(forKey:)` 的回傳結果
    var doubleResult: Double {
        get {
            doubleResultState.withValue { $0 }
        }
        set {
            doubleResultState.withValue { $0 = newValue }
        }
    }

    /// `bool(forKey:)` 的呼叫次數
    var boolCallCount: Int {
        boolCallCountState.withValue { $0 }
    }

    /// `bool(forKey:)` 收到的 key
    var boolReceivedArguments: [String] {
        boolReceivedArgumentsState.withValue { $0 }
    }

    /// 設定 `bool(forKey:)` 的回傳結果
    var boolResult: Bool {
        get {
            boolResultState.withValue { $0 }
        }
        set {
            boolResultState.withValue { $0 = newValue }
        }
    }

    /// `hasValue(forKey:)` 的呼叫次數
    var hasValueCallCount: Int {
        hasValueCallCountState.withValue { $0 }
    }

    /// `hasValue(forKey:)` 收到的 key
    var hasValueReceivedArguments: [String] {
        hasValueReceivedArgumentsState.withValue { $0 }
    }

    /// 設定 `hasValue(forKey:)` 的回傳結果
    var hasValueResult: Bool {
        get {
            hasValueResultState.withValue { $0 }
        }
        set {
            hasValueResultState.withValue { $0 = newValue }
        }
    }

    /// 字串 `set(_:forKey:)` 的呼叫次數
    var stringSetCallCount: Int {
        stringSetCallCountState.withValue { $0 }
    }

    /// 字串 `set(_:forKey:)` 收到的參數
    var stringSetReceivedArguments: [SetArgument<String>] {
        stringSetReceivedArgumentsState.withValue { $0 }
    }

    /// 浮點數 `set(_:forKey:)` 的呼叫次數
    var doubleSetCallCount: Int {
        doubleSetCallCountState.withValue { $0 }
    }

    /// 浮點數 `set(_:forKey:)` 收到的參數
    var doubleSetReceivedArguments: [SetArgument<Double>] {
        doubleSetReceivedArgumentsState.withValue { $0 }
    }

    /// 布林值 `set(_:forKey:)` 的呼叫次數
    var boolSetCallCount: Int {
        boolSetCallCountState.withValue { $0 }
    }

    /// 布林值 `set(_:forKey:)` 收到的參數
    var boolSetReceivedArguments: [SetArgument<Bool>] {
        boolSetReceivedArgumentsState.withValue { $0 }
    }
}

// MARK: - UserDefaultsStoreProtocol

extension MockUserDefaultsStore: UserDefaultsStoreProtocol {

    /// 記錄字串查詢的 `key`
    ///
    /// - Parameter key: 呼叫端查詢的偏好 key
    /// - Returns: 該 key 寫入過字串時回傳該值，否則回傳 `stringResult`
    func string(forKey key: String) -> String? {
        stringCallCountState.withValue { $0 += 1 }
        stringReceivedArgumentsState.withValue { $0.append(key) }
        if let storedValue = storedValuesState.withValue({ $0[key] }),
           case .string(value: let value) = storedValue {
            return value
        }
        return stringResultState.withValue { $0 }
    }

    /// 記錄浮點數查詢的 `key`
    ///
    /// - Parameter key: 呼叫端查詢的偏好 key
    /// - Returns: 該 key 寫入過浮點數時回傳該值，否則回傳 `doubleResult`
    func double(forKey key: String) -> Double {
        doubleCallCountState.withValue { $0 += 1 }
        doubleReceivedArgumentsState.withValue { $0.append(key) }
        if let storedValue = storedValuesState.withValue({ $0[key] }),
           case .double(value: let value) = storedValue {
            return value
        }
        return doubleResultState.withValue { $0 }
    }

    /// 記錄布林值查詢的 `key`
    ///
    /// - Parameter key: 呼叫端查詢的偏好 key
    /// - Returns: 該 key 寫入過布林值時回傳該值，否則回傳 `boolResult`
    func bool(forKey key: String) -> Bool {
        boolCallCountState.withValue { $0 += 1 }
        boolReceivedArgumentsState.withValue { $0.append(key) }
        if let storedValue = storedValuesState.withValue({ $0[key] }),
           case .bool(value: let value) = storedValue {
            return value
        }
        return boolResultState.withValue { $0 }
    }

    /// 記錄是否有值時查詢的 `key`
    ///
    /// - Parameter key: 呼叫端查詢的偏好 key
    /// - Returns: `key` 有已儲存值時為 `true`，否則回傳 `hasValueResult`
    func hasValue(forKey key: String) -> Bool {
        hasValueCallCountState.withValue { $0 += 1 }
        hasValueReceivedArgumentsState.withValue { $0.append(key) }
        if storedValuesState.withValue({ $0[key] != nil }) {
            return true
        }
        return hasValueResultState.withValue { $0 }
    }

    /// 記錄字串與 key，並保存在測試替身記憶體
    ///
    /// - Parameters:
    ///   - value: 呼叫端傳入的字串
    ///   - key: 呼叫端傳入的偏好 key
    func set(_ value: String, forKey key: String) {
        stringSetCallCountState.withValue { $0 += 1 }
        stringSetReceivedArgumentsState.withValue { $0.append(SetArgument(value: value, key: key)) }
        storedValuesState.withValue { $0[key] = .string(value: value) }
    }

    /// 記錄浮點數與 key，並保存在測試替身記憶體
    ///
    /// - Parameters:
    ///   - value: 呼叫端傳入的浮點數
    ///   - key: 呼叫端傳入的偏好 key
    func set(_ value: Double, forKey key: String) {
        doubleSetCallCountState.withValue { $0 += 1 }
        doubleSetReceivedArgumentsState.withValue { $0.append(SetArgument(value: value, key: key)) }
        storedValuesState.withValue { $0[key] = .double(value: value) }
    }

    /// 記錄布林值與 key，並保存在測試替身記憶體
    ///
    /// - Parameters:
    ///   - value: 呼叫端傳入的布林值
    ///   - key: 呼叫端傳入的偏好 key
    func set(_ value: Bool, forKey key: String) {
        boolSetCallCountState.withValue { $0 += 1 }
        boolSetReceivedArgumentsState.withValue { $0.append(SetArgument(value: value, key: key)) }
        storedValuesState.withValue { $0[key] = .bool(value: value) }
    }
}
