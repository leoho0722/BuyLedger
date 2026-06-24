//
//  CloudSyncFieldMerge.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/22.
//

import Foundation

/// 跨裝置同步的逐欄合併工具：勝出欄位集內的欄位採遠端值，其餘保留本機
///
/// ``LedgerOrder`` 為 immutable struct，故以 memberwise init 重建整筆；欄位名對齊
/// ``CloudSyncEngine/fieldMap(_:)``。`photos` 另走 photoRefs 解析，
/// `id`/`mergedSourceIDs` 為 A 類唯讀不可合併
enum CloudSyncFieldMerge {

    // MARK: - Operations

    /// 以勝出欄位集把 `remote` 的對應欄位疊到 `baseline`；其餘欄位保留 `baseline`
    ///
    /// `baseline` 為 nil (新訂單) 時直接回 `remote`
    /// - Parameters:
    ///   - baseline: 本機目前版本；nil 表示新訂單
    ///   - remote: 解碼後的遠端訂單 (欄位值來源)
    ///   - winningFields: 本次判定為遠端勝出、需採用的欄位名集合
    /// - Returns: 合併後的訂單
    static func merged(
        baseline: LedgerOrder?,
        remote: LedgerOrder,
        winningFields: Set<String>
    ) -> LedgerOrder {
        guard let baseline else { return remote }

        func pick<T>(_ field: String, _ remoteValue: T, _ baselineValue: T) -> T {
            winningFields.contains(field) ? remoteValue : baselineValue
        }

        return LedgerOrder(
            id: baseline.id,
            customer: mergedCustomer(baseline: baseline, remote: remote, winningFields: winningFields),
            status: pick("status", remote.status, baseline.status),
            currency: pick("currency", remote.currency, baseline.currency),
            date: pick("date", remote.date, baseline.date),
            items: pick("items", remote.items, baseline.items),
            itemCost: pick("itemCost", remote.itemCost, baseline.itemCost),
            domesticShipping: pick("domesticShipping", remote.domesticShipping, baseline.domesticShipping),
            internationalShipping: pick("internationalShipping", remote.internationalShipping, baseline.internationalShipping),
            foreignDomesticShipping: pick("foreignDomesticShipping", remote.foreignDomesticShipping, baseline.foreignDomesticShipping),
            cardFeeRate: pick("cardFeeRate", remote.cardFeeRate, baseline.cardFeeRate),
            platformFeeRate: pick("platformFeeRate", remote.platformFeeRate, baseline.platformFeeRate),
            paymentFeeRate: pick("paymentFeeRate", remote.paymentFeeRate, baseline.paymentFeeRate),
            chargedAmount: pick("chargedAmount", remote.chargedAmount, baseline.chargedAmount),
            cardlessDeductionAmount: pick("cardlessDeductionAmount", remote.cardlessDeductionAmount, baseline.cardlessDeductionAmount),
            cardlessSupplementAmount: pick("cardlessSupplementAmount", remote.cardlessSupplementAmount, baseline.cardlessSupplementAmount),
            orderSource: pick("orderSource", remote.orderSource, baseline.orderSource),
            categories: pick("categories", remote.categories, baseline.categories),
            paymentMethod: pick("paymentMethod", remote.paymentMethod, baseline.paymentMethod),
            notes: pick("notes", remote.notes, baseline.notes),
            verificationStatus: pick("verificationStatus", remote.verificationStatus, baseline.verificationStatus),
            campaignNames: pick("campaignNames", remote.campaignNames, baseline.campaignNames),
            paymentReceiptStatus: pick("paymentReceiptStatus", remote.paymentReceiptStatus, baseline.paymentReceiptStatus),
            // isCashOnDelivery 為 B 類衍生欄位：跟隨勝出的 paymentMethod，不獨立合併
            isCashOnDelivery: pick("paymentMethod", remote.isCashOnDelivery, baseline.isCashOnDelivery),
            // photos 另走 photoRefs 解析覆寫，此處保留 baseline
            photos: baseline.photos,
            mergedSourceIDs: baseline.mergedSourceIDs
        )
    }
}

// MARK: - Private Method

private extension CloudSyncFieldMerge {

    /// 合併 `customer`：
    /// `customerName`、`customerTier` 各自決勝，
    /// `customerInitials` 跟隨勝出的 `customerName`
    /// - Parameters:
    ///   - baseline: 本機目前版本
    ///   - remote: 解碼後的遠端訂單
    ///   - winningFields: 遠端勝出的欄位名集合
    /// - Returns: 合併後的客戶資訊
    static func mergedCustomer(
        baseline: LedgerOrder,
        remote: LedgerOrder,
        winningFields: Set<String>
    ) -> LedgerCustomer {
        let nameWins = winningFields.contains("customerName")
        let tierWins = winningFields.contains("customerTier")
        return LedgerCustomer(
            name: nameWins ? remote.customer.name : baseline.customer.name,
            // initials 跟隨 name 一同採用 (衍生欄位不獨立決勝)
            initials: nameWins ? remote.customer.initials : baseline.customer.initials,
            tier: tierWins ? remote.customer.tier : baseline.customer.tier
        )
    }
}
