//
//  UserDefaultsStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

// MARK: - Protocol

/// `UserDefaults` 偏好資料的技術讀寫介面
protocol UserDefaultsStoreProtocol: Sendable {

    /// 讀取字串值
    ///
    /// - Parameter key: 要讀取的偏好 `key`
    /// - Returns: 儲存的字串，或在值不存在時回傳 `nil`
    func string(forKey key: String) -> String?

    /// 讀取浮點數值
    ///
    /// - Parameter key: 要讀取的偏好 `key`
    /// - Returns: 儲存的浮點數，或在值不存在時回傳 `0`
    func double(forKey key: String) -> Double

    /// 讀取布林值
    ///
    /// - Parameter key: 要讀取的偏好 `key`
    /// - Returns: 儲存的布林值，或在值不存在時回傳 `false`
    func bool(forKey key: String) -> Bool

    /// 確認指定 `key` 是否已有儲存值
    ///
    /// - Parameter key: 要確認的偏好 `key`
    /// - Returns: `key` 已有值時為 `true`
    func hasValue(forKey key: String) -> Bool

    /// 儲存字串值
    ///
    /// - Parameters:
    ///   - value: 要儲存的字串
    ///   - key: 對應的偏好 `key`
    func set(_ value: String, forKey key: String)

    /// 儲存浮點數值
    ///
    /// - Parameters:
    ///   - value: 要儲存的浮點數
    ///   - key: 對應的偏好 `key`
    func set(_ value: Double, forKey key: String)

    /// 儲存布林值
    ///
    /// - Parameters:
    ///   - value: 要儲存的布林值
    ///   - key: 對應的偏好 `key`
    func set(_ value: Bool, forKey key: String)
}

// MARK: - Implementation

/// 以 suite 名稱在每次操作時取得 `UserDefaults` 並讀寫偏好
struct UserDefaultsStore {

    // MARK: - Properties

    /// 每次操作用來取得 `UserDefaults` 的 suite 名稱
    private let suiteName: String?

    // MARK: - Init

    /// 建立使用指定 suite 的偏好儲存
    ///
    /// - Parameter suiteName: `UserDefaults` suite 名稱；`nil` 時使用標準 `UserDefaults`
    init(suiteName: String?) {
        self.suiteName = suiteName
    }
}

// MARK: - UserDefaultsStoreProtocol

extension UserDefaultsStore: UserDefaultsStoreProtocol {

    /// 從目前的 `UserDefaults` 讀取字串
    ///
    /// - Parameter key: 直接交給 `UserDefaults` 查詢的 `key`
    /// - Returns: `UserDefaults.string(forKey:)` 的結果
    func string(forKey key: String) -> String? {
        makeUserDefaults().string(forKey: key)
    }

    /// 從目前的 `UserDefaults` 讀取浮點數
    ///
    /// - Parameter key: 直接交給 `UserDefaults` 查詢的 `key`
    /// - Returns: `UserDefaults.double(forKey:)` 的結果
    func double(forKey key: String) -> Double {
        makeUserDefaults().double(forKey: key)
    }

    /// 從目前的 `UserDefaults` 讀取布林值
    ///
    /// - Parameter key: 直接交給 `UserDefaults` 查詢的 `key`
    /// - Returns: `UserDefaults.bool(forKey:)` 的結果
    func bool(forKey key: String) -> Bool {
        makeUserDefaults().bool(forKey: key)
    }

    /// 以 `object(forKey:)` 判斷目前的 `UserDefaults` 是否含有該值
    ///
    /// - Parameter key: 直接交給 `UserDefaults` 查詢的 `key`
    /// - Returns: `object(forKey:)` 有回傳值時為 `true`
    func hasValue(forKey key: String) -> Bool {
        makeUserDefaults().object(forKey: key) != nil
    }

    /// 將字串寫入目前的 `UserDefaults`
    ///
    /// - Parameters:
    ///   - value: 原樣交給 `UserDefaults` 寫入的字串
    ///   - key: 直接作為 `UserDefaults` 的 `key`
    func set(_ value: String, forKey key: String) {
        makeUserDefaults().set(value, forKey: key)
    }

    /// 將浮點數寫入目前的 `UserDefaults`
    ///
    /// - Parameters:
    ///   - value: 原樣交給 `UserDefaults` 寫入的浮點數
    ///   - key: 直接作為 `UserDefaults` 的 `key`
    func set(_ value: Double, forKey key: String) {
        makeUserDefaults().set(value, forKey: key)
    }

    /// 將布林值寫入目前的 `UserDefaults`
    ///
    /// - Parameters:
    ///   - value: 原樣交給 `UserDefaults` 寫入的布林值
    ///   - key: 直接作為 `UserDefaults` 的 `key`
    func set(_ value: Bool, forKey key: String) {
        makeUserDefaults().set(value, forKey: key)
    }
}

// MARK: - Private Method

private extension UserDefaultsStore {

    /// 依 suite 名稱取得本次操作使用的 `UserDefaults`
    ///
    /// - Returns: suite 名稱為 `nil` 時是標準 `UserDefaults`，
    ///   否則是以該名稱建立的 `UserDefaults`
    ///
    /// - Note: 指定 suite 無法建立代表呼叫端提供了無效名稱，視為程式錯誤
    func makeUserDefaults() -> UserDefaults {
        guard let suiteName else {
            return .standard
        }

        if let defaults = UserDefaults(suiteName: suiteName) {
            return defaults
        }

        // 無效的 suite 名稱是呼叫端的錯誤，沒有其他儲存區可以改用
        preconditionFailure("無法建立 UserDefaults suite：\(suiteName)")
    }
}

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

    /// 供 Service 的 `liveValue` 以 `@Dependency(\.userDefaultsStore)` 取得的偏好設定儲存介面
    var userDefaultsStore: any UserDefaultsStoreProtocol {
        get { self[UserDefaultsStoreKey.self] }
        set { self[UserDefaultsStoreKey.self] = newValue }
    }
}

#if DEBUG

// MARK: - Preview

/// Preview 使用固定的空偏好值，不保存寫入內容
struct PreviewUserDefaultsStore {

    // MARK: - Init

    /// 建立只供 Preview 與測試環境使用的偏好 stub
    init() {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PreviewUserDefaultsStore 只能在 Preview、UI Test 或單元測試中使用"
        )
    }
}

// MARK: - UserDefaultsStoreProtocol

extension PreviewUserDefaultsStore: UserDefaultsStoreProtocol {

    /// 固定回傳 `nil`，不讀取或保存偏好值
    ///
    /// - Parameter key: 未使用的偏好 `key`
    /// - Returns: `nil`
    func string(forKey key: String) -> String? {
        nil
    }

    /// 固定回傳 `0`，不讀取或保存偏好值
    ///
    /// - Parameter key: 未使用的偏好 `key`
    /// - Returns: `0`
    func double(forKey key: String) -> Double {
        0
    }

    /// 固定回傳 `false`，不讀取或保存偏好值
    ///
    /// - Parameter key: 未使用的偏好 `key`
    /// - Returns: `false`
    func bool(forKey key: String) -> Bool {
        false
    }

    /// 固定表示偏好值不存在
    ///
    /// - Parameter key: 未使用的偏好 `key`
    /// - Returns: `false`
    func hasValue(forKey key: String) -> Bool {
        false
    }

    /// 忽略字串寫入
    ///
    /// - Parameters:
    ///   - value: 未使用的字串值
    ///   - key: 未使用的偏好 `key`
    func set(_ value: String, forKey key: String) {
    }

    /// 忽略浮點數寫入
    ///
    /// - Parameters:
    ///   - value: 未使用的浮點數值
    ///   - key: 未使用的偏好 `key`
    func set(_ value: Double, forKey key: String) {
    }

    /// 忽略布林值寫入
    ///
    /// - Parameters:
    ///   - value: 未使用的布林值
    ///   - key: 未使用的偏好 `key`
    func set(_ value: Bool, forKey key: String) {
    }
}

#endif
