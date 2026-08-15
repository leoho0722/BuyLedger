//
//  OrderMerge.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation

/// 兩筆訂單合併為一筆新訂單的純函式計算
enum OrderMerge {}

// MARK: - Nested Types

extension OrderMerge {
    
    /// 合併計算的輸出：合併確認表單各欄位的草稿值
    struct Draft: Equatable {
        
        // MARK: - Data Properties
        
        /// 合併後的客戶 (取主訂單；合併限同客戶名稱)
        let customer: LedgerCustomer
        
        /// 訂單來源 (取主訂單)
        let orderSource: String
        
        /// 訂單狀態 (取主訂單)
        let status: OrderStatus
        
        /// 幣別 (取主訂單；合併限同幣別)
        let currency: CurrencyCode
        
        /// 訂購日期 (合併當下時間)
        let date: Date
        
        /// 商品類別 (保序聯集)
        let categories: [String]
        
        /// 開團名稱 (保序聯集)
        let campaignNames: [String]
        
        /// 付款方式 (無卡優先規則)
        let paymentMethod: String
        
        /// 對帳狀態 (隨付款方式來源訂單)
        let reconciliationStatus: String
        
        /// 貨到付款旗標 (隨付款方式來源訂單)
        let isCashOnDelivery: Bool
        
        /// 收款狀態 (取主訂單)
        let paymentReceiptStatus: PaymentReceiptStatus
        
        /// 客戶實付加總
        let chargedAmount: Decimal
        
        /// 無卡折抵金額加總
        let cardlessDeductionAmount: Decimal
        
        /// 無卡補款金額加總
        let cardlessSupplementAmount: Decimal
        
        /// 商品成本加總
        let itemCost: Decimal
        
        /// 外國國內運費加總
        let foreignDomesticShipping: Decimal
        
        /// 國際運費加總
        let internationalShipping: Decimal
        
        /// 國內運費加總
        let domesticShipping: Decimal
        
        /// 刷卡手續費比例 (加權平均)
        let cardFeeRate: Decimal
        
        /// 平台手續費比例 (加權平均)
        let platformFeeRate: Decimal
        
        /// 金流手續費比例 (加權平均)
        let paymentFeeRate: Decimal
        
        /// 商品明細串接 (主前副後)
        let items: [LedgerOrderItem]
        
        /// 合併備註
        let notes: String
        
        /// 照片串接 (主前副後；未截斷)
        let photos: [Data]
        
        /// 合併來源訂單編號 [主, 副]
        let mergeSourceIDs: [String]
    }
}

// MARK: - Internal Method

extension OrderMerge {
    
    /// 依合併規則整合兩筆訂單，產生合併確認表單的草稿值
    /// - Parameters:
    ///   - primary: 主訂單 (發起合併的那筆)
    ///   - secondary: 副訂單 (候選 sheet 選定的那筆)
    ///   - now: 合併當下時間；caller 應從 `@Dependency(\.date)` 取得
    ///   - isCardless: 由付款方式旗標判定是否為無卡付款
    /// - Returns: 合併後的草稿值
    static func makeDraft(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        now: Date,
        isCardless: (String) -> Bool
    ) -> Draft {
        let paymentSource = paymentMethodSource(
            primary: primary,
            secondary: secondary,
            isCardless: isCardless
        )
        
        return Draft(
            customer: primary.customer,
            orderSource: primary.orderSource,
            status: primary.status,
            currency: primary.currency,
            date: now,
            categories: orderedUnion(
                primary.categories,
                secondary.categories
            ),
            campaignNames: orderedUnion(
                primary.campaignNames,
                secondary.campaignNames
            ),
            paymentMethod: paymentSource.paymentMethod,
            reconciliationStatus: paymentSource.reconciliationStatus,
            isCashOnDelivery: paymentSource.isCashOnDelivery,
            paymentReceiptStatus: primary.paymentReceiptStatus,
            chargedAmount: primary.chargedAmount + secondary.chargedAmount,
            cardlessDeductionAmount: primary.cardlessDeductionAmount
            + secondary.cardlessDeductionAmount,
            cardlessSupplementAmount: primary.cardlessSupplementAmount
            + secondary.cardlessSupplementAmount,
            itemCost: primary.itemCost + secondary.itemCost,
            foreignDomesticShipping: primary.foreignDomesticShipping
            + secondary.foreignDomesticShipping,
            internationalShipping: primary.internationalShipping + secondary.internationalShipping,
            domesticShipping: primary.domesticShipping + secondary.domesticShipping,
            cardFeeRate: weightedRate(
                primary.cardFeeRate,
                secondary.cardFeeRate,
                primary: primary,
                secondary: secondary
            ),
            platformFeeRate: weightedRate(
                primary.platformFeeRate,
                secondary.platformFeeRate,
                primary: primary,
                secondary: secondary
            ),
            paymentFeeRate: weightedRate(
                primary.paymentFeeRate,
                secondary.paymentFeeRate,
                primary: primary,
                secondary: secondary
            ),
            items: primary.items + secondary.items,
            notes: mergedNotes(
                primary.notes,
                secondary.notes
            ),
            photos: primary.photos + secondary.photos,
            mergeSourceIDs: [
                primary.id,
                secondary.id,
            ]
        )
    }
}

// MARK: - Private Method

private extension OrderMerge {
    
    /// 備註分隔線：獨立一行的多個 dash
    static let notesSeparator = "----------"
    
    /// 保序聯集：主訂單元素在前，去除重複
    /// - Parameters:
    ///   - primary: 主訂單的名稱陣列
    ///   - secondary: 副訂單的名稱陣列
    /// - Returns: 聯集結果
    static func orderedUnion(_ primary: [String], _ secondary: [String]) -> [String] {
        var seen = Set<String>()
        return (primary + secondary).filter { seen.insert($0).inserted }
    }
    
    /// 依客戶實付計算加權平均比例；分母為 0 時沿用主訂單
    /// - Parameters:
    ///   - primaryRate: 主訂單比例
    ///   - secondaryRate: 副訂單比例
    ///   - primary: 主訂單 (取實付作權重)
    ///   - secondary: 副訂單 (取實付作權重)
    /// - Returns: 合併後比例
    static func weightedRate(
        _ primaryRate: Decimal,
        _ secondaryRate: Decimal,
        primary: LedgerOrder,
        secondary: LedgerOrder
    ) -> Decimal {
        let totalCharged = primary.chargedAmount + secondary.chargedAmount
        guard totalCharged > 0 else {
            return primaryRate
        }
        
        let weighted =
        (primaryRate * primary.chargedAmount + secondaryRate * secondary.chargedAmount)
        / totalCharged
        return max(0, min(1, weighted))
    }
    
    /// 合併兩筆備註；以分隔線連接非空內容
    /// - Parameters:
    ///   - primaryNotes: 主訂單備註
    ///   - secondaryNotes: 副訂單備註
    /// - Returns: 合併後備註
    static func mergedNotes(_ primaryNotes: String, _ secondaryNotes: String) -> String {
        let trimmedPrimary = primaryNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecondary = secondaryNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch (trimmedPrimary.isEmpty, trimmedSecondary.isEmpty) {
        case (false, false):
            return "\(trimmedPrimary)\n\(notesSeparator)\n\(trimmedSecondary)"
        case (false, true):
            return trimmedPrimary
        case (true, false):
            return trimmedSecondary
        case (true, true):
            return ""
        }
    }
    
    /// 選擇合併後的付款方式、對帳狀態與貨到付款旗標
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - secondary: 副訂單
    ///   - isCardless: 無卡判定 predicate
    /// - Returns: 付款方式來源欄位組
    static func paymentMethodSource(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        isCardless: (String) -> Bool
    ) -> (paymentMethod: String, reconciliationStatus: String, isCashOnDelivery: Bool) {
        let source: LedgerOrder
        if primary.paymentMethod == secondary.paymentMethod {
            source = primary
        } else if isCardless(secondary.paymentMethod), !isCardless(primary.paymentMethod) {
            // 任一方為無卡付款時，以無卡規則計算。
            source = secondary
        } else {
            source = primary
        }
        
        return (source.paymentMethod, source.reconciliationStatus, source.isCashOnDelivery)
    }
}
