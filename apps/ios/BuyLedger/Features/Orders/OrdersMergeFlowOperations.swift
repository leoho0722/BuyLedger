//
//  OrdersMergeFlowOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import SwiftUI

/// OrdersFeature 的合併流程
enum OrdersMergeFlowOperations {}

// MARK: - Internal Method

extension OrdersMergeFlowOperations {
    
    /// 開始合併訂單；已合併或取消的訂單不可作為主訂單
    static func mergeOrderTapped(_ orderID: LedgerOrder.ID, state: inout OrdersFeature.State) {
        guard let primary = state.orders.first(where: { $0.id == orderID }),
              primary.status != .merged,
              primary.status != .cancelled else {
            return
        }
        
        state.orderMerge = OrderMergeFeature.State(primary: primary, orders: state.orders)
    }
    
    /// 由候選訂單建立合併草稿，並關閉合併 sheet
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - secondary: 副訂單
    ///   - keptPhotos: 使用者保留的照片
    ///   - state: 將被修改的 ``OrdersFeature/State``
    ///   - now: 「現在」時間，供計算合併草稿使用
    /// - Returns: 合併草稿與使用者保留的照片
    static func mergeCandidateCompleted(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        keptPhotos: [Data],
        state: inout OrdersFeature.State,
        now: Date
    ) -> (draft: OrderMerge.Draft, keptPhotos: [Data]) {
        let cardlessNames = Set(state.availablePaymentMethods.filter(\.isCardless).map(\.name))
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: now,
            isCardless: { cardlessNames.contains($0) }
        )
        
        // 先關閉合併 sheet，再延遲開啟確認表單
        state.orderMerge = nil
        return (draft, keptPhotos)
    }
    
    /// 合併選取完成後開啟確認表單
    /// - Parameters:
    ///   - draft: 合併草稿
    ///   - keptPhotos: 使用者保留的照片
    ///   - state: 將被修改的 ``OrdersFeature/State``
    ///   - newFormID: 確認表單 instance 的穩定識別值
    ///   - currentDate: 「現在」時間，供表單初始化使用
    static func mergeConfirmationReady(
        draft: OrderMerge.Draft,
        keptPhotos: [Data],
        state: inout OrdersFeature.State,
        newFormID: UUID,
        currentDate: Date
    ) {
        var editState = OrderEditFeature.State(
            id: newFormID,
            availableOrderSources: state.availableOrderSources,
            availableCategories: state.availableCategories,
            availablePaymentMethods: state.availablePaymentMethods,
            availableReconciliationStatuses: state.availableReconciliationStatuses,
            availableCampaigns: state.availableCampaigns,
            currentDate: currentDate
        )
        editState.draft.customerName = draft.customer.name
        editState.draft.orderSource = draft.orderSource
        editState.draft.categories = draft.categories
        editState.draft.status = draft.status
        editState.draft.currency = draft.currency
        editState.draft.chargedAmount = draft.chargedAmount
        editState.draft.cardlessDeductionAmount = draft.cardlessDeductionAmount
        editState.draft.cardlessSupplementAmount = draft.cardlessSupplementAmount
        editState.draft.itemCost = draft.itemCost
        editState.draft.domesticShipping = draft.domesticShipping
        editState.draft.internationalShipping = draft.internationalShipping
        editState.draft.foreignDomesticShipping = draft.foreignDomesticShipping
        editState.draft.cardFeeRate = draft.cardFeeRate
        editState.draft.platformFeeRate = draft.platformFeeRate
        editState.draft.paymentFeeRate = draft.paymentFeeRate
        editState.draft.items = draft.items
        editState.draft.notes = draft.notes
        editState.draft.date = draft.date
        editState.draft.paymentMethod = draft.paymentMethod
        editState.draft.reconciliationStatus = draft.reconciliationStatus
        editState.draft.campaignNames = draft.campaignNames
        editState.draft.paymentReceiptStatus = draft.paymentReceiptStatus
        editState.draftPhotos = keptPhotos
        editState.mergeSourceIDs = draft.mergeSourceIDs
        state.editOrder = editState
    }
    
    /// 合併持久化失敗時，以快照回復訂單
    static func mergePersistenceFailed(
        _ previousOrders: [LedgerOrder],
        state: inout OrdersFeature.State
    ) {
        state.orders = previousOrders
        state.pruneDetailPath()
        state.writeFailureAlert = OrdersFeature.makeWriteFailureAlert("合併訂單儲存失敗，請稍後再試。")
    }
    
    /// 儲存合併訂單並標記來源訂單
    /// - Parameters:
    ///   - editState: 合併確認表單的草稿狀態
    ///   - state: 將被修改的 ``OrdersFeature/State``
    ///   - newOrderID: 新訂單的編號產生器
    /// - Returns: 合併訂單與回滾快照；找不到目標時為 `nil`
    static func mergeSaveTapped(
        _ editState: OrderEditFeature.State,
        state: inout OrdersFeature.State,
        newOrderID: () -> String
    ) -> (savedOrder: LedgerOrder, sourceIDs: [LedgerOrder.ID], previousOrders: [LedgerOrder])? {
        let previousOrders = state.orders
        guard let writeResult = OrderDraft.applyEditDraft(
                editState, to: &state, newOrderID: newOrderID) else {
            return nil
        }
        let savedOrder = writeResult.order
        
        let sourceIDs = editState.mergeSourceIDs
        state.orders = state.orders.map { order in
            guard sourceIDs.contains(order.id), order.id != savedOrder.id else {
                return order
            }
            return order.withStatus(.merged)
        }
        
        return (savedOrder, sourceIDs, previousOrders)
    }
}
