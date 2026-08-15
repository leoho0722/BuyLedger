//
//  LedgerOrder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Static Properties

extension LedgerOrder {

    /// 單筆訂單可附加的照片張數上限
    static let maxPhotoCount = 5
}

// MARK: - Computed Properties

extension LedgerOrder {

    /// 訂單的財務摘要
    var summary: OrderSummary {
        OrderSummary(order: self)
    }

    /// 這筆訂單是否由多筆訂單合併而成 (合併後產生的新訂單)
    var isMergeResult: Bool {
        !mergedSourceIDs.isEmpty
    }

    /// 是否計入「類別收益」彙總
    var contributesToCategoryBreakdown: Bool {
        !isMergeResult && (OrderStatus.realizedStatuses.contains(status) || status == .merged)
    }

    /// 列表中的商品摘要，每項商品一行
    var itemSummary: String {
        guard !items.isEmpty else {
            return "未命名商品"
        }

        return items.map { "\($0.name) x\($0.quantity)" }.joined(separator: "\n")
    }

    /// 顯示用的訂單編號短碼
    var displayID: String {
        let maxDisplayLength = 15
        guard id.count > maxDisplayLength else {
            return id
        }
        return String(id.prefix(maxDisplayLength))
    }
}

// MARK: - Internal Method

extension LedgerOrder {

    /// 依付款方式主檔旗標正規化訂單上會影響損益的欄位
    /// - Parameters:
    ///   - isCardless: 付款方式是否屬於無卡類
    ///   - isBankTransfer: 付款方式是否屬於銀行匯款類
    ///   - isCashOnDelivery: 付款方式是否屬於貨到付款類
    /// - Returns: 套用旗標後的訂單
    func applyingPaymentMethodFlags(
        isCardless: Bool,
        isBankTransfer: Bool,
        isCashOnDelivery: Bool
    ) -> LedgerOrder {
        let normalizedChargedAmount = max(0, chargedAmount)
        let normalizedDeduction = isCardless
            ? min(normalizedChargedAmount, max(0, cardlessDeductionAmount))
            : 0
        let normalizedSupplement = isCardless
            ? max(0, cardlessSupplementAmount)
            : 0
        let normalizedReconciliationStatus = (isCardless || isBankTransfer)
            ? reconciliationStatus.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""

        return LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            cardlessDeductionAmount: normalizedDeduction,
            cardlessSupplementAmount: normalizedSupplement,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: normalizedReconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 只替換訂單引用的付款方式名稱，保留其餘欄位
    /// - Parameter name: 新付款方式名稱
    /// - Returns: 改名後的訂單
    func renamingPaymentMethod(to name: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            paymentMethod: name,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 只替換訂單引用的訂單來源，保留其餘欄位
    /// - Parameter name: 新訂單來源名稱
    /// - Returns: 改名後的訂單
    func renamingOrderSource(to name: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            orderSource: name,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 替換訂單中的指定類別
    /// - Parameters:
    ///   - oldName: 舊類別名稱
    ///   - newName: 新類別名稱
    /// - Returns: 改名後的訂單
    func renamingCategory(from oldName: String, to newName: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            categories: categories.map { $0 == oldName ? newName : $0 },
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 只替換訂單引用的對帳狀態，保留其餘欄位
    /// - Parameter name: 新對帳狀態名稱
    /// - Returns: 改名後的訂單
    func renamingReconciliationStatus(to name: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            reconciliationStatus: name,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 替換訂單中的指定開團名稱
    /// - Parameters:
    ///   - oldName: 舊開團名稱
    ///   - newName: 新開團名稱
    /// - Returns: 改名後的訂單
    func renamingCampaign(from oldName: String, to newName: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            campaignNames: campaignNames.map { $0 == oldName ? newName : $0 },
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 移除訂單中的指定開團名稱
    /// - Parameter name: 要移除的開團名稱
    /// - Returns: 移除後的訂單
    func removingCampaign(_ name: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
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
            campaignNames: campaignNames.filter { $0 != name },
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 總覽本月損益、分析走勢與成本結構、客戶累計消費共用的營收歸屬口徑
    /// - Parameter orders: 要篩選的訂單
    /// - Returns: 排除合併來源後的已實現訂單
    static func revenueAttributionOrders(from orders: [LedgerOrder]) -> [LedgerOrder] {
        let mergedSourceIDs = Set(orders.flatMap(\.mergedSourceIDs))
        return orders.filter {
            OrderStatus.realizedStatuses.contains($0.status) && !mergedSourceIDs.contains($0.id)
        }
    }
}
