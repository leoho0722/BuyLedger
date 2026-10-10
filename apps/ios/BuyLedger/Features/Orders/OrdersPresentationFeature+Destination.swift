//
//  OrdersPresentationFeature+Destination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

// MARK: - Nested Types

extension OrdersPresentationFeature {

    /// 訂單呈現子 Feature 可呈現的三種 sheet 與共用 alert，同一時間只有一個目的地
    @Reducer
    enum Destination {

        /// 新增、編輯或合併確認表單
        ///
        /// - Parameter feature: 訂單草稿與表單驗證的 Feature
        case edit(OrderEditFeature)

        /// 合併候選與照片選擇表單
        ///
        /// - Parameter feature: 合併來源選擇的 Feature
        case merge(OrderMergeFeature)

        /// AI 商品明細摘要
        ///
        /// - Parameter feature: 摘要串流與結果呈現的 Feature
        case aiSummary(AISummaryFeature)

        /// 確認刪除、寫入失敗或 AI 摘要未啟用的 alert
        ///
        /// - Parameter alert: 要呈現的確認或通知內容
        @ReducerCaseIgnored case alert(AlertState<Alert>)

        /// 子 Feature 與共用 alert 的事件
        @CasePathable
        enum Action {

            /// 訂單表單事件
            ///
            /// - Parameter action: 編輯與儲存草稿的事件
            case edit(OrderEditFeature.Action)

            /// 合併候選表單事件
            ///
            /// - Parameter action: 選擇合併來源的事件
            case merge(OrderMergeFeature.Action)

            /// AI 摘要事件
            ///
            /// - Parameter action: 摘要串流與關閉的事件
            case aiSummary(AISummaryFeature.Action)

            /// 共用 alert 的按鈕事件
            ///
            /// - Parameter action: 使用者選擇的按鈕
            case alert(Alert)
        }

        /// 確認刪除、寫入失敗與 AI 未啟用三種 alert 的按鈕動作
        @CasePathable
        enum Alert: Equatable {

            /// 確認刪除指定訂單
            ///
            /// - Parameter id: 要刪除的訂單識別值
            case confirmDelete(LedgerOrder.ID)

            /// 前往設定啟用 AI 商品明細摘要
            case goToAISettings
        }
    }
}

// MARK: - Computed Properties

extension OrdersPresentationFeature.Destination.State {

    /// AI 商品明細摘要尚未啟用時的說明與設定入口
    static var aiDisabled: Self {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("AI 商品明細總結")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("關閉")
                }
                ButtonState(action: .goToAISettings) {
                    TextState("前往開啟")
                }
            } message: {
                TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
            }
        )
    }
}

// MARK: - Internal Method

extension OrdersPresentationFeature.Destination.State {

    /// 建立刪除訂單前的確認 alert，清單與詳情共用
    ///
    /// - Parameter order: 要刪除的訂單
    /// - Returns: 帶有訂單識別值的刪除確認目的地
    static func deleteConfirmation(for order: LedgerOrder) -> Self {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("刪除訂單")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(order.id)) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(order.customer.name)」的這筆訂單後無法復原。")
            }
        )
    }

    /// 建立一次性寫入失敗通知
    ///
    /// - Parameter message: 已本地化的失敗原因
    /// - Returns: 只有「知道了」按鈕的失敗目的地
    static func writeFailure(_ message: TextState) -> Self {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                message
            }
        )
    }
}

// MARK: - Equatable

extension OrdersPresentationFeature.Destination.State: Equatable {

}
