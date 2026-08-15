//
//  LedgerOrder+OrderMutation.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation

// MARK: - Computed Properties

extension LedgerOrder {
    
    /// 供訂單列表搜尋使用的正規化文字
    var searchableText: String {
        ([
            id,
            customer.name,
            customer.initials,
            orderSource,
            currency.rawValue,
        ] + categories + items.map(\.name))
        .joined(separator: " ")
        .lowercased()
    }
}

// MARK: - Internal Method

extension LedgerOrder {
    
    /// 回傳只改變訂單狀態的複本
    /// - Parameter newStatus: 新的訂單狀態
    /// - Returns: 重建後的訂單
    func withStatus(_ newStatus: OrderStatus) -> LedgerOrder {
        mutated(status: newStatus)
    }
    
    /// 回傳只改變收款狀態的複本
    /// - Parameter newReceiptStatus: 新的收款狀態
    /// - Returns: 重建後的訂單
    func withPaymentReceiptStatus(_ newReceiptStatus: PaymentReceiptStatus) -> LedgerOrder {
        mutated(paymentReceiptStatus: newReceiptStatus)
    }
}

// MARK: - Private Method

private extension LedgerOrder {
    
    /// 建立複本時覆寫指定欄位，其餘維持原值
    /// - Parameters:
    ///   - status: 覆寫的訂單狀態；`nil` 維持現值
    ///   - paymentReceiptStatus: 覆寫的收款狀態；`nil` 維持現值
    /// - Returns: 重建後的訂單
    func mutated(
        status: OrderStatus? = nil,
        paymentReceiptStatus: PaymentReceiptStatus? = nil
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status ?? self.status,
            currency: currency,
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
            paymentReceiptStatus: paymentReceiptStatus ?? self.paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
