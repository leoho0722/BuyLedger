//
//  PreviewUserDefaultsStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

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

    /// 固定回傳 nil，不讀取或保存偏好值
    ///
    /// - Parameter key: 未使用的偏好 `key`
    /// - Returns: `nil`
    func string(forKey key: String) -> String? {
        nil
    }

    /// 固定回傳 0，不讀取或保存偏好值
    ///
    /// - Parameter key: 未使用的偏好 `key`
    /// - Returns: `0`
    func double(forKey key: String) -> Double {
        0
    }

    /// 固定回傳 false，不讀取或保存偏好值
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
