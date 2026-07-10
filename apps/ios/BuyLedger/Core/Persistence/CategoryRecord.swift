//
//  CategoryRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「商品類別主檔」記錄
///
/// 用於使用者在「更多」頁獨立管理類別 (不依賴任何一張訂單存在)，亦作為訂單編輯選單的選項來源。沿用 ``OrderRecord`` 的設計準則：不使用 `@Attribute(.unique)` (CloudKit 不支援)，由 actor 在 upsert 時自行檢查避免重複
@Model
final class CategoryRecord {

    // MARK: - Data Properties

    /// 類別名稱；同時作為 upsert 識別值
    var name: String

    // MARK: - Init

    /// 建立指定名稱的類別記錄
    /// - Parameter name: 類別名稱
    init(name: String) {
        self.name = name
    }
}
