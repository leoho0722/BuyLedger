//
//  OrderSourceRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「訂單來源主檔」記錄
///
/// 用於使用者在訂單編輯選單獨立管理訂單來源 (不依賴任何一張訂單存在)，作為訂單編輯選單的選項來源。沿用 ``CategoryRecord`` 的設計準則：不使用 `@Attribute(.unique)` (CloudKit 不支援)，由 actor 在 upsert 時自行檢查避免重複
@Model
final class OrderSourceRecord {

    // MARK: - Data Properties

    /// 訂單來源名稱；同時作為 upsert 識別值
    var name: String

    // MARK: - Init

    /// 建立指定名稱的訂單來源記錄
    /// - Parameter name: 訂單來源名稱
    init(name: String) {
        self.name = name
    }
}
