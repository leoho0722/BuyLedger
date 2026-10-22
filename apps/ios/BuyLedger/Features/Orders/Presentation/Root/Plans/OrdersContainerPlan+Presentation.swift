//
//  OrdersContainerPlan+Presentation.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

// MARK: - Internal Method

extension OrdersContainerPlan {

    /// 建立新增訂單表單，選項與預設幣別由容器的唯讀快照提供
    ///
    /// - Parameters:
    ///   - id: 表單識別值
    ///   - state: 容器的唯讀快照
    ///   - now: 新訂單日期與結單日判斷的現在時間
    ///   - calendar: 建立表單時的注入行事曆
    /// - Returns: 新增訂單表單的目的地
    static func newOrder(
        id: UUID,
        state: OrdersFeature.State,
        now: Date,
        calendar: Calendar
    ) -> OrdersPresentationFeature.Destination.State {
        .edit(
            OrderEditFeature.State(
                id: id,
                options: state.makeEditOptions(now: now, calendar: calendar),
                currentDate: now,
                defaultCurrency: state.defaultCurrency
            )
        )
    }

    /// 以完成選取的兩筆訂單組出合併草稿，付款方式取自容器的清單投影
    ///
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - secondary: 副訂單
    ///   - state: 容器的唯讀快照
    ///   - now: 「現在」時間，供計算合併草稿使用
    /// - Returns: 供確認表單預填的合併草稿
    static func mergeCandidateDraft(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        state: OrdersFeature.State,
        now: Date
    ) -> OrderMerge.Draft {
        OrdersMergeFlowOperations.mergeCandidateCompleted(
            primary: primary,
            secondary: secondary,
            paymentMethods: state.list.availablePaymentMethods,
            now: now
        )
    }

    /// 以合併草稿、保留照片與容器的選項建立確認表單
    ///
    /// - Parameters:
    ///   - draft: 合併草稿
    ///   - keptPhotos: 使用者保留的照片
    ///   - state: 容器的唯讀快照
    ///   - formID: 確認表單的識別值
    ///   - context: 建立表單時的現在時間與行事曆
    /// - Returns: 合併確認表單的目的地
    static func mergeConfirmation(
        draft: OrderMerge.Draft,
        keptPhotos: [Data],
        state: OrdersFeature.State,
        formID: UUID,
        context: OrderDateContext
    ) -> OrdersPresentationFeature.Destination.State {
        .edit(
            OrdersMergeFlowOperations.mergeConfirmationReady(
                draft: draft,
                keptPhotos: keptPhotos,
                options: state.makeEditOptions(now: context.now, calendar: context.calendar),
                newFormID: formID,
                currentDate: context.now,
                defaultCurrency: state.defaultCurrency
            )
        )
    }
}
