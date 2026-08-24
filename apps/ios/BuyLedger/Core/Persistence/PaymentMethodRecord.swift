//
//  PaymentMethodRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「付款方式主檔」記錄
@Model
final class PaymentMethodRecord {
    
    // MARK: - Data Properties
    
    /// 以付款方式名稱建立索引，供查詢與更新
    #Index<PaymentMethodRecord>([\.name])
    
    /// 付款方式名稱；同時作為 upsert 識別值
    var name: String
    
    /// 是否屬於「無卡」類付款方式 (例如「無卡」「無卡存款」)
    var isCardless: Bool = false
    
    /// 是否屬於「銀行匯款」類付款方式
    var isBankTransfer: Bool = false
    
    /// 是否屬於「貨到付款」類付款方式
    var isCashOnDelivery: Bool = false
    
    // MARK: - Init
    
    /// 建立指定名稱、是否無卡、是否銀行匯款與是否貨到付款的付款方式記錄
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - isCardless: 是否屬於無卡類付款方式，預設 `false`
    ///   - isBankTransfer: 是否屬於銀行匯款類付款方式，預設 `false`
    ///   - isCashOnDelivery: 是否屬於貨到付款類付款方式，預設 `false`
    init(
        name: String,
        isCardless: Bool = false,
        isBankTransfer: Bool = false,
        isCashOnDelivery: Bool = false
    ) {
        self.name = name
        self.isCardless = isCardless
        self.isBankTransfer = isBankTransfer
        self.isCashOnDelivery = isCashOnDelivery
    }
}
