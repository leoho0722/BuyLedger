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
/// 用於使用者在「更多」頁獨立管理付款方式 (不依賴任何一張訂單存在)，亦作為訂單編輯選單的選項來源。
@Model
final class PaymentMethodRecord {

    // MARK: - Data Properties

    /// 付款方式名稱；同時作為 upsert 識別值。
    var name: String

    /// 是否屬於「無卡」類付款方式 (例如「無卡」「無卡存款」)。
    ///
    /// 帶 default `false` 走 SwiftData lightweight migration；既有資料庫升級後預設都不是無卡，使用者可在付款方式管理頁逐筆勾選。
    var isCardless: Bool = false

    // MARK: - Init

    /// 建立指定名稱與是否無卡的付款方式記錄。
    /// - Parameters:
    ///   - name: 付款方式名稱。
    ///   - isCardless: 是否屬於無卡類付款方式，預設 `false`。
    init(name: String, isCardless: Bool = false) {
        self.name = name
        self.isCardless = isCardless
    }
}
