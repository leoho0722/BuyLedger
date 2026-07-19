//
//  OrderMerge.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation

/// 兩筆訂單合併為一筆新訂單的純函式計算
///
/// 只負責把主訂單 (P) 與副訂單 (S) 依合併規則整合成草稿值，不做任何持久化或 UI 呈現
/// 「現在」時間由 caller 以 `@Dependency(\.date)` 注入，付款方式是否屬無卡由 caller 以 predicate 注入 (主檔旗標在 feature 層)
/// 照片僅串接、不截斷，超過上限時由合併流程的照片挑選步驟決定保留集合
enum OrderMerge {}

// MARK: - Nested Types

extension OrderMerge {

    /// 合併計算的輸出：合併確認表單各欄位的草稿值
    ///
    /// 不含訂單編號——新訂單 id 由 ``OrdersFeature`` 在儲存流程比照一般新訂單產生
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
    ///
    /// 欄位規則：
    /// - 客戶、訂單來源、狀態、幣別、收款狀態：取主訂單值
    /// - 類別與開團：主訂單在前的保序聯集 (去重)
    /// - 訂購日期：合併當下時間 (`now`)
    /// - 金額七欄位 (客戶實付／無卡折抵／無卡補款／商品成本／外國國內運費／國際運費／國內運費)：逐項相加
    /// - 手續費三項：以兩筆客戶實付為權重做加權平均 (金額守恆)，clamp 至 [0, 1]；兩筆實付皆為 0 時沿用主訂單比例
    /// - 付款方式：兩筆相同取該值；不同時，恰有一筆屬無卡則取該筆 (保住折抵/補款加總不被歸零規則清掉)，其餘取主訂單。對帳狀態與貨到付款旗標一律隨付款方式來源那筆訂單
    /// - 商品明細與照片：主訂單在前、副訂單在後串接，內容不變動
    /// - 備註：兩筆皆非空時以獨立一行 dash line 分隔串接；任一邊為空則直接取非空者
    /// - Parameters:
    ///   - primary: 主訂單 (發起合併的那筆)
    ///   - secondary: 副訂單 (候選 sheet 選定的那筆)
    ///   - now: 合併當下時間；caller 應從 `@Dependency(\.date)` 取得
    ///   - isCardless: 判定付款方式名稱是否屬「無卡」類的 predicate；caller 從付款方式主檔旗標建構
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
            cardlessDeductionAmount: primary.cardlessDeductionAmount + secondary.cardlessDeductionAmount,
            cardlessSupplementAmount: primary.cardlessSupplementAmount + secondary.cardlessSupplementAmount,
            itemCost: primary.itemCost + secondary.itemCost,
            foreignDomesticShipping: primary.foreignDomesticShipping + secondary.foreignDomesticShipping,
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
                secondary.id
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

    /// 以兩筆客戶實付為權重的加權平均比例；分母為 0 時沿用主訂單比例，結果 clamp 至 [0, 1]
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

        let weighted = (primaryRate * primary.chargedAmount + secondaryRate * secondary.chargedAmount) / totalCharged
        return max(0, min(1, weighted))
    }

    /// 合併備註：兩筆皆非空 (trim 後) 以獨立一行 dash line 分隔串接；任一邊為空取非空者；皆空回傳空字串
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

    /// 解析付款方式來源：兩筆相同取主訂單；不同時恰有一筆屬無卡則取該筆；其餘取主訂單。回傳付款方式、對帳狀態與貨到付款旗標 (三者一律同源)
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
            // 恰有一筆 (副) 屬無卡：以無卡為主，保住折抵/補款加總不被非無卡的歸零規則清掉
            source = secondary
        } else {
            source = primary
        }

        return (source.paymentMethod, source.reconciliationStatus, source.isCashOnDelivery)
    }
}
