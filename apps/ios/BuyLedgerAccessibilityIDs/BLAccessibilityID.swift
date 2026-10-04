//
//  BLAccessibilityID.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

/// UI 測試定位元素用的 accessibility identifier 常數
enum BLAccessibilityID {}

// MARK: - Internal Method

extension BLAccessibilityID {

    /// 組出列舉型集合的 identifier
    ///
    /// - Parameters:
    ///   - prefix: identifier 前綴
    ///   - key: 集合項目的識別值
    /// - Returns: 組合後的 accessibility identifier
    static func option(_ prefix: String, key: String) -> String {
        "\(prefix).\(key)"
    }

    /// 組出使用者資料列的 identifier
    ///
    /// - Parameters:
    ///   - prefix: identifier 前綴
    ///   - key: 資料列的識別值
    /// - Returns: 組合後的 accessibility identifier
    static func row(_ prefix: String, key: String) -> String {
        "\(prefix):\(key)"
    }

    /// 組出純序位集合的 identifier
    ///
    /// - Parameters:
    ///   - prefix: identifier 前綴
    ///   - index: 集合項目的序位
    /// - Returns: 組合後的 accessibility identifier
    static func indexed(_ prefix: String, index: Int) -> String {
        "\(prefix).index.\(index)"
    }
}
