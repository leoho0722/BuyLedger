//
//  LedgerOrder+TestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/16.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Internal Method

extension LedgerOrder {

    /// 將持久化往返後重新產生的 `LedgerOrderItem.id` 改為固定值，以便整筆比較訂單
    ///
    /// - Parameter order: 要正規化的訂單
    /// - Returns: 品項識別值固定後的訂單
    static func normalizingItemIdentifiers(_ order: LedgerOrder) -> LedgerOrder {
        let placeholderID = UUID(0)
        return LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items.map {
                LedgerOrderItem(
                    id: placeholderID,
                    name: $0.name,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice
                )
            },
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
}
