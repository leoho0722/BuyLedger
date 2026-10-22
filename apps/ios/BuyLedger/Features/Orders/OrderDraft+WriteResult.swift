//
//  OrderDraft+WriteResult.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation

// MARK: - Nested Types

extension OrderDraft {

    /// 表單準備儲存時的訂單與照片寫入方式
    struct WriteResult: Equatable, Sendable {

        /// 套用後的訂單
        let order: LedgerOrder

        /// 是否要建立新訂單，建立時一併儲存照片
        let isNewOrder: Bool

        /// 是否應寫入照片；新訂單，或既有訂單照片載入完成且有變更時為 `true`
        let shouldWritePhotos: Bool
    }
}

// MARK: - Internal Method

extension OrderDraft {

    /// 依草稿與訂單清單計算寫入結果
    ///
    /// - Parameters:
    ///   - editState: 編輯表單狀態
    ///   - existingOrders: 用於比對既有訂單與合併主訂單客戶
    ///   - newOrderID: 新訂單的編號產生器
    /// - Returns: 整理後的訂單、是否要新建訂單與是否要儲存照片
    static func resolveWriteResult(
        _ editState: OrderEditFeature.State,
        existingOrders: [LedgerOrder],
        newOrderID: () -> String
    ) -> WriteResult {
        if let original = editState.original,
           let existing = existingOrders.first(where: { $0.id == original.id }) {
            // 照片完成載入且有變更時才寫入，避免覆蓋既有照片
            let shouldWritePhotos = editState.photos.photoLoadPhase == .loaded
                && editState.photos.hasEditedPhotos
            let order = editState.draft.makeOrder(
                existingOrder: existing,
                mergePrimaryCustomer: nil,
                draftPhotos: editState.photos.draftPhotos,
                shouldWritePhotos: shouldWritePhotos,
                mergeSourceIDs: editState.mergeSourceIDs,
                newOrderID: newOrderID
            )
            return WriteResult(
                order: order.applyingPaymentMethodFlags(
                    PaymentMethodFlags(
                        isCardless: editState.isSelectedPaymentMethodCardless,
                        isBankTransfer: editState.isSelectedPaymentMethodBankTransfer,
                        isCashOnDelivery: editState.isSelectedPaymentMethodCOD
                    )
                ),
                isNewOrder: false,
                shouldWritePhotos: shouldWritePhotos
            )
        } else {
            let mergePrimaryCustomer = editState.mergeSourceIDs.first
                .flatMap { primaryID in
                    existingOrders.first {
                        $0.id == primaryID
                    }?.customer
                }
            let order = editState.draft.makeOrder(
                existingOrder: nil,
                mergePrimaryCustomer: mergePrimaryCustomer,
                draftPhotos: editState.photos.draftPhotos,
                shouldWritePhotos: true,
                mergeSourceIDs: editState.mergeSourceIDs,
                newOrderID: newOrderID
            )
            // 新建訂單走插入分支，因此一定寫入照片
            return WriteResult(
                order: order.applyingPaymentMethodFlags(
                    PaymentMethodFlags(
                        isCardless: editState.isSelectedPaymentMethodCardless,
                        isBankTransfer: editState.isSelectedPaymentMethodBankTransfer,
                        isCashOnDelivery: editState.isSelectedPaymentMethodCOD
                    )
                ),
                isNewOrder: true,
                shouldWritePhotos: true
            )
        }
    }
}

// MARK: - Private Method

private extension OrderDraft {

    /// 去除每個名稱前後的空白，移除空名稱與重複名稱並保留原有順序
    ///
    /// - Parameter names: 草稿中的類別或開團名稱
    /// - Returns: 清理後且沒有重複的名稱
    static func normalizedNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// 將手續費比例限制在零至一之間，避免輸入超出有效範圍
    ///
    /// - Parameter value: 使用者輸入的手續費比例
    /// - Returns: 零至一之間的手續費比例
    static func clampRate(_ value: Decimal) -> Decimal {
        max(0, min(1, value))
    }

    /// 依草稿與編輯情境建立訂單
    ///
    /// - Parameters:
    ///   - existingOrder: 正在編輯的既有訂單；`nil` 代表新訂單
    ///   - mergePrimaryCustomer: 合併時沿用的主訂單客戶
    ///   - draftPhotos: 表單目前的照片草稿
    ///   - shouldWritePhotos: 既有訂單是否寫入照片；新訂單一律帶入 `draftPhotos`
    ///   - mergeSourceIDs: 合併來源訂單編號
    ///   - newOrderID: 新訂單的編號產生器
    /// - Returns: 尚未套用付款方式旗標的訂單
    func makeOrder(
        existingOrder: LedgerOrder?,
        mergePrimaryCustomer: LedgerCustomer?,
        draftPhotos: [Data],
        shouldWritePhotos: Bool,
        mergeSourceIDs: [LedgerOrder.ID],
        newOrderID: () -> String
    ) -> LedgerOrder {
        let trimmedName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOrderSource = orderSource.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCategories = Self.normalizedNames(categories)
        let trimmedPaymentMethod = paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        // 備註只清除首尾空白，保留內部換行
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCampaignNames = Self.normalizedNames(campaignNames)

        let normalizedAmount = max(0, chargedAmount)
        let normalizedItemCost = max(0, itemCost)
        let normalizedDom = max(0, domesticShipping)
        let normalizedIntl = max(0, internationalShipping)
        let normalizedForeignDom = max(0, foreignDomesticShipping)
        let normalizedCardFee = Self.clampRate(cardFeeRate)
        let normalizedPlatformFee = Self.clampRate(platformFeeRate)
        let normalizedPaymentFee = Self.clampRate(paymentFeeRate)

        if let existingOrder {
            let updatedCustomer = LedgerCustomer(
                name: trimmedName.isEmpty ? existingOrder.customer.name : trimmedName,
                initials: existingOrder.customer.initials,
                tier: existingOrder.customer.tier
            )

            // 未寫入照片時，記憶體中的訂單維持空陣列
            return LedgerOrder(
                id: existingOrder.id,
                customer: updatedCustomer,
                status: status,
                currency: currency,
                date: date,
                items: items,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDom,
                internationalShipping: normalizedIntl,
                foreignDomesticShipping: normalizedForeignDom,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                paymentFeeRate: normalizedPaymentFee,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: cardlessDeductionAmount,
                cardlessSupplementAmount: cardlessSupplementAmount,
                orderSource: trimmedOrderSource.isEmpty
                    ? existingOrder.orderSource : trimmedOrderSource,
                categories: normalizedCategories.isEmpty
                    ? existingOrder.categories : normalizedCategories,
                paymentMethod: trimmedPaymentMethod.isEmpty
                    ? existingOrder.paymentMethod : trimmedPaymentMethod,
                notes: trimmedNotes,
                reconciliationStatus: reconciliationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: paymentReceiptStatus,
                isCashOnDelivery: false,
                photos: shouldWritePhotos ? draftPhotos : [],
                mergedSourceIDs: existingOrder.mergedSourceIDs
            )
        } else {
            let resolvedName = trimmedName.isEmpty ? "未命名客戶" : trimmedName
            let resolvedOrderSource = trimmedOrderSource.isEmpty ? "未指定" : trimmedOrderSource
            let resolvedCategories = normalizedCategories.isEmpty ? ["未分類"] : normalizedCategories
            let initials = String(resolvedName.prefix(2)).uppercased()

            // 合併草稿沿用主訂單客戶，一般新訂單維持 `.new`
            let resolvedCustomer = mergePrimaryCustomer.map {
                LedgerCustomer(name: resolvedName, initials: $0.initials, tier: $0.tier)
            } ?? LedgerCustomer(name: resolvedName, initials: initials, tier: .new)

            // 使用完整隨機識別碼；顯示短碼由 `displayID` 產生
            return LedgerOrder(
                id: "BL-DRAFT-\(newOrderID())",
                customer: resolvedCustomer,
                status: status,
                currency: currency,
                date: date,
                items: items,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDom,
                internationalShipping: normalizedIntl,
                foreignDomesticShipping: normalizedForeignDom,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                paymentFeeRate: normalizedPaymentFee,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: cardlessDeductionAmount,
                cardlessSupplementAmount: cardlessSupplementAmount,
                orderSource: resolvedOrderSource,
                categories: resolvedCategories,
                paymentMethod: trimmedPaymentMethod,
                notes: trimmedNotes,
                reconciliationStatus: reconciliationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: paymentReceiptStatus,
                isCashOnDelivery: false,
                photos: draftPhotos,
                mergedSourceIDs: mergeSourceIDs
            )
        }
    }
}
