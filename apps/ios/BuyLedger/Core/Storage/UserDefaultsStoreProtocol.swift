//
//  UserDefaultsStoreProtocol.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// `UserDefaults` 偏好資料的技術讀寫介面
protocol UserDefaultsStoreProtocol: Sendable {

    /// 讀取字串值
    ///
    /// - Parameter key: 要讀取的偏好 `key`
    /// - Returns: 儲存的字串，或在值不存在時回傳 nil
    func string(forKey key: String) -> String?

    /// 讀取浮點數值
    ///
    /// - Parameter key: 要讀取的偏好 `key`
    /// - Returns: 儲存的浮點數，或在值不存在時回傳 0
    func double(forKey key: String) -> Double

    /// 讀取布林值
    ///
    /// - Parameter key: 要讀取的偏好 `key`
    /// - Returns: 儲存的布林值，或在值不存在時回傳 false
    func bool(forKey key: String) -> Bool

    /// 確認指定 `key` 是否已有儲存值
    ///
    /// - Parameter key: 要確認的偏好 `key`
    /// - Returns: `key` 已有值時為 true
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
