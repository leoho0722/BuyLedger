//
//  OrdersMergeFlowOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation

/// 依來源訂單與表單選項計算合併草稿，交給容器呈現
enum OrdersMergeFlowOperations {

}

// MARK: - Internal Method

extension OrdersMergeFlowOperations {

    /// 由選定的來源訂單與付款方式建立合併草稿
    ///
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - secondary: 副訂單
    ///   - paymentMethods: 目前可用的付款方式與無卡旗標
    ///   - now: 「現在」時間，供計算合併草稿使用
    /// - Returns: 供確認表單預填的合併草稿
    static func mergeCandidateCompleted(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        paymentMethods: [PaymentMethodInfo],
        now: Date
    ) -> OrderMerge.Draft {
        let cardlessNames = Set(paymentMethods.filter(\.isCardless).map(\.name))
        return OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: now,
            isCardless: { cardlessNames.contains($0) }
        )
    }

    /// 以合併草稿、保留照片與現有選項建立確認表單
    ///
    /// - Parameters:
    ///   - draft: 合併草稿
    ///   - keptPhotos: 使用者保留的照片
    ///   - options: 容器依現有主檔與注入行事曆建立的表單選項
    ///   - newFormID: 確認表單 instance 的穩定識別值
    ///   - currentDate: 「現在」時間，供表單初始化使用
    ///   - defaultCurrency: 容器提供的新訂單預設幣別
    /// - Returns: 尚未修改、含合併來源與保留照片的確認表單
    static func mergeConfirmationReady(
        draft: OrderMerge.Draft,
        keptPhotos: [Data],
        options: OrderEditOptions,
        newFormID: UUID,
        currentDate: Date,
        defaultCurrency: CurrencyCode
    ) -> OrderEditFeature.State {
        var editDraft = OrderDraft(
            original: nil,
            currentDate: currentDate,
            defaultCurrency: draft.currency
        )
        editDraft.customerName = draft.customer.name
        editDraft.orderSource = draft.orderSource
        editDraft.categories = draft.categories
        editDraft.status = draft.status
        editDraft.currency = draft.currency
        editDraft.chargedAmount = draft.chargedAmount
        editDraft.cardlessDeductionAmount = draft.cardlessDeductionAmount
        editDraft.cardlessSupplementAmount = draft.cardlessSupplementAmount
        editDraft.itemCost = draft.itemCost
        editDraft.domesticShipping = draft.domesticShipping
        editDraft.internationalShipping = draft.internationalShipping
        editDraft.foreignDomesticShipping = draft.foreignDomesticShipping
        editDraft.cardFeeRate = draft.cardFeeRate
        editDraft.platformFeeRate = draft.platformFeeRate
        editDraft.paymentFeeRate = draft.paymentFeeRate
        editDraft.items = draft.items
        editDraft.notes = draft.notes
        editDraft.date = draft.date
        editDraft.paymentMethod = draft.paymentMethod
        editDraft.reconciliationStatus = draft.reconciliationStatus
        editDraft.campaignNames = draft.campaignNames
        editDraft.paymentReceiptStatus = draft.paymentReceiptStatus
        return OrderEditFeature.State(
            id: newFormID,
            options: options,
            currentDate: currentDate,
            defaultCurrency: defaultCurrency,
            prefill: OrderEditFeature.State.Prefill(
                draft: editDraft,
                mergeSourceIDs: draft.mergeSourceIDs,
                keptPhotos: keptPhotos
            )
        )
    }
}
