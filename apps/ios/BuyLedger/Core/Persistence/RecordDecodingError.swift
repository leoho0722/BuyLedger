//
//  RecordDecodingError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/19.
//

/// 持久化記錄的 raw value 無法轉回領域型別時的錯誤
struct RecordDecodingError: Error, Sendable {

    // MARK: - Properties

    /// 發生錯誤的持久化記錄型別名稱
    let entity: String

    /// 發生錯誤的記錄識別值
    let identifier: String

    /// 無法解析的欄位名稱
    let field: String

    /// 無法解析的原始字串
    let rawValue: String
}
