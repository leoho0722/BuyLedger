//
//  UserDefaultsStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

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
    /// - Parameter key: 要查詢的偏好 `key`
    /// - Returns: 儲存的字串，或在值不存在時回傳 nil
    func string(forKey key: String) -> String? {
        makeUserDefaults().string(forKey: key)
    }

    /// 從目前的 `UserDefaults` 讀取浮點數
    ///
    /// - Parameter key: 要查詢的偏好 `key`
    /// - Returns: 儲存的浮點數，或在值不存在時回傳 0
    func double(forKey key: String) -> Double {
        makeUserDefaults().double(forKey: key)
    }

    /// 從目前的 `UserDefaults` 讀取布林值
    ///
    /// - Parameter key: 要查詢的偏好 `key`
    /// - Returns: 儲存的布林值，或在值不存在時回傳 false
    func bool(forKey key: String) -> Bool {
        makeUserDefaults().bool(forKey: key)
    }

    /// 以 `object(forKey:)` 判斷目前的 `UserDefaults` 是否含有該值
    ///
    /// - Parameter key: 要查詢的偏好 `key`
    /// - Returns: `key` 已有值時為 true
    func hasValue(forKey key: String) -> Bool {
        makeUserDefaults().object(forKey: key) != nil
    }

    /// 將字串寫入目前的 `UserDefaults`
    ///
    /// - Parameters:
    ///   - value: 要儲存的字串
    ///   - key: 對應的偏好 `key`
    func set(_ value: String, forKey key: String) {
        makeUserDefaults().set(value, forKey: key)
    }

    /// 將浮點數寫入目前的 `UserDefaults`
    ///
    /// - Parameters:
    ///   - value: 要儲存的浮點數
    ///   - key: 對應的偏好 `key`
    func set(_ value: Double, forKey key: String) {
        makeUserDefaults().set(value, forKey: key)
    }

    /// 將布林值寫入目前的 `UserDefaults`
    ///
    /// - Parameters:
    ///   - value: 要儲存的布林值
    ///   - key: 對應的偏好 `key`
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

        preconditionFailure("無法建立 UserDefaults suite：\(suiteName)")
    }
}
