//
//  OrderRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData

/// SwiftData 持久化用的訂單記錄
@Model
final class OrderRecord {
    
    // MARK: - Data Properties
    
    /// 以訂單編號查詢，以日期排序
    #Index<OrderRecord>([\.id], [\.date])
    
    /// 訂單編號 (領域層級的 stable id)
    var id: String
    
    /// 客戶資料 (嵌入式 Codable 儲存)
    var customer: LedgerCustomer
    
    /// 訂單目前狀態
    var status: OrderStatus
    
    /// 商品原始幣別 (以 ISO 4217 code 字串存放)
    var currency: String
    
    /// 訂單建立或更新日期
    var date: Date
    
    /// 商品項目 (嵌入式 Codable 陣列儲存)
    var items: [LedgerOrderItem]
    
    /// 商品折合 TWD 後的成本
    var itemCost: Decimal
    
    /// 國內運費成本
    var domesticShipping: Decimal
    
    /// 國際運費成本
    var internationalShipping: Decimal
    
    /// 商品來源國當地國內運費成本 (TWD)
    var foreignDomesticShipping: Decimal = 0
    
    /// 刷卡手續費比例
    var cardFeeRate: Decimal
    
    /// 平台手續費比例
    var platformFeeRate: Decimal
    
    /// 金流手續費比例；帶 default 0 走 SwiftData lightweight migration
    var paymentFeeRate: Decimal = 0
    
    /// 實際向客戶收款的新台幣金額
    var chargedAmount: Decimal
    
    /// 無卡付款使用的折抵金額 (TWD)
    var cardlessDeductionAmount: Decimal = 0
    
    /// 無卡付款的補款金額 (TWD)
    var cardlessSupplementAmount: Decimal = 0
    
    /// 訂單來源
    var orderSource: String = ""
    
    /// 商品類別清單 (V11 起為字串陣列；至少一個，由編輯流程守門)
    var categories: [String] = []
    
    /// 付款方式
    var paymentMethod: String = ""
    
    /// 訂單備註
    var notes: String = ""
    
    /// 對帳狀態
    @Attribute(originalName: "verificationStatus")
    var reconciliationStatus: String = ""
    
    /// 歸屬的開團名稱清單 (V11 起為字串陣列；空陣列代表未歸團)
    var campaignNames: [String] = []
    
    /// 收款狀態的 rawValue (待收款／已收款)
    var paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue
    
    /// 此訂單是否以「貨到付款」類付款方式成立
    var isCashOnDelivery: Bool = false
    
    /// 訂單照片 (已正規化的 JPEG data，嵌入式 Codable 陣列儲存)
    var photos: [Data] = []
    
    /// 合併來源訂單編號 (V11 新增)
    var mergedSourceIDs: [String] = []
    
    // MARK: - Init
    
    /// 依領域型別 ``LedgerOrder`` 建立持久化記錄
    /// - Parameter order: 對應的領域訂單
    init(order: LedgerOrder) {
        self.id = order.id
        self.customer = order.customer
        self.status = order.status
        self.currency = order.currency.rawValue
        self.date = order.date
        self.items = order.items
        self.itemCost = order.itemCost
        self.domesticShipping = order.domesticShipping
        self.internationalShipping = order.internationalShipping
        self.foreignDomesticShipping = order.foreignDomesticShipping
        self.cardFeeRate = order.cardFeeRate
        self.platformFeeRate = order.platformFeeRate
        self.paymentFeeRate = order.paymentFeeRate
        self.chargedAmount = order.chargedAmount
        self.cardlessDeductionAmount = order.cardlessDeductionAmount
        self.cardlessSupplementAmount = order.cardlessSupplementAmount
        self.orderSource = order.orderSource
        self.categories = order.categories
        self.paymentMethod = order.paymentMethod
        self.notes = order.notes
        self.reconciliationStatus = order.reconciliationStatus
        self.campaignNames = order.campaignNames
        self.paymentReceiptStatus = order.paymentReceiptStatus.rawValue
        self.isCashOnDelivery = order.isCashOnDelivery
        self.photos = order.photos
        self.mergedSourceIDs = order.mergedSourceIDs
    }
}

// MARK: - Internal Method

extension OrderRecord {
    
    // MARK: Mapping
    
    /// 將 SwiftData 記錄轉回領域型別
    /// - Parameter includingPhotos: 是否包含照片；清單傳 false，單筆傳 true
    /// - Returns: 對應的 ``LedgerOrder``
    func toDomain(includingPhotos: Bool = true) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
            currency: CurrencyCode(rawValue: currency),
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            paymentFeeRate: paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: PaymentReceiptStatus(rawValue: paymentReceiptStatus) ?? .pending,
            isCashOnDelivery: isCashOnDelivery,
            photos: includingPhotos ? photos : [],
            mergedSourceIDs: mergedSourceIDs
        )
    }
    
    /// 將領域型別的內容套用到本記錄 (用於更新意圖的寫入流程)
    /// - Parameter order: 來源 ``LedgerOrder``
    func apply(_ order: LedgerOrder) {
        self.customer = order.customer
        self.status = order.status
        self.currency = order.currency.rawValue
        self.date = order.date
        self.items = order.items
        self.itemCost = order.itemCost
        self.domesticShipping = order.domesticShipping
        self.internationalShipping = order.internationalShipping
        self.foreignDomesticShipping = order.foreignDomesticShipping
        self.cardFeeRate = order.cardFeeRate
        self.platformFeeRate = order.platformFeeRate
        self.paymentFeeRate = order.paymentFeeRate
        self.chargedAmount = order.chargedAmount
        self.cardlessDeductionAmount = order.cardlessDeductionAmount
        self.cardlessSupplementAmount = order.cardlessSupplementAmount
        self.orderSource = order.orderSource
        self.categories = order.categories
        self.paymentMethod = order.paymentMethod
        self.notes = order.notes
        self.reconciliationStatus = order.reconciliationStatus
        self.campaignNames = order.campaignNames
        self.paymentReceiptStatus = order.paymentReceiptStatus.rawValue
        self.isCashOnDelivery = order.isCashOnDelivery
        self.mergedSourceIDs = order.mergedSourceIDs
    }
}
