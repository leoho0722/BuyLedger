//
//  PaymentMethodRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「付款方式主檔」記錄。
///
/// 用於使用者在「更多」頁獨立管理付款方式（不依賴任何一張訂單存在），亦作為訂單編輯選單的選項來源。
@Model
final class PaymentMethodRecord {

    // MARK: - Data Properties

    /// 付款方式名稱；同時作為 upsert 識別值。
    var name: String

    // MARK: - Init

    /// 建立指定名稱的付款方式記錄。
    /// - Parameter name: 付款方式名稱。
    init(name: String) {
        self.name = name
    }
}
