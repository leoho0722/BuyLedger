//
//  VerificationStatusRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「對帳狀態主檔」記錄
///
/// 用於使用者管理可選的對帳狀態 (例如「待對帳」「對帳成功」「對帳失敗」)，作為訂單編輯選單的選項來源
///
/// 沿用 ``OrderSourceRecord`` 的設計準則：不使用 `@Attribute(.unique)` (CloudKit 不支援)，由 actor 在 upsert 時自行檢查避免重複
@Model
final class VerificationStatusRecord {

    // MARK: - Data Properties

    /// 對帳狀態名稱；同時作為 upsert 識別值
    var name: String

    // MARK: - Init

    /// 建立指定名稱的對帳狀態記錄
    /// - Parameter name: 對帳狀態名稱
    init(name: String) {
        self.name = name
    }
}
