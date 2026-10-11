//
//  LookupManagementFeature+Destination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Nested Types

extension LookupManagementFeature {

    /// 主檔管理畫面可呈現的表單與 alert
    @Reducer
    enum Destination {

        /// 新增主檔表單
        ///
        /// - Parameter feature: 負責驗證新增名稱與旗標的 Feature
        case add(LookupAddFormFeature)

        /// 主檔管理畫面的 alert
        @ReducerCaseIgnored case alert(AlertState<Alert>)

        /// 編輯付款方式表單
        ///
        /// - Parameter feature: 負責驗證付款方式輸入的 Feature
        case editPaymentMethod(PaymentMethodEditFormFeature)

        /// 改名表單
        ///
        /// - Parameter feature: 負責驗證新名稱的 Feature
        case rename(LookupRenameFormFeature)

        /// Destination 可接收的子 Feature 與 alert action
        @CasePathable
        enum Action {

            /// 新增表單事件
            ///
            /// - Parameter action: 新增表單的事件
            case add(LookupAddFormFeature.Action)

            /// alert 按鈕事件
            ///
            /// - Parameter action: alert 的選項
            case alert(Alert)

            /// 付款方式編輯表單事件
            ///
            /// - Parameter action: 付款方式編輯表單的事件
            case editPaymentMethod(PaymentMethodEditFormFeature.Action)

            /// 改名表單事件
            ///
            /// - Parameter action: 改名表單的事件
            case rename(LookupRenameFormFeature.Action)
        }

        /// 主檔管理 alert 可執行的動作
        @CasePathable
        enum Alert: Equatable {

            /// 確認刪除主檔項目
            ///
            /// - Parameter name: 要刪除的主檔名稱
            case confirmDelete(name: String)

            /// 確認套用付款方式旗標
            case confirmPaymentMethodEdit

            /// 取消付款方式更正
            case cancelPaymentMethodEdit
        }

        /// 主檔寫入失敗的類型
        enum WriteFailure {

            /// 新增主檔失敗
            case add

            /// 刪除主檔失敗
            case delete

            /// 改名失敗
            case rename

            /// 付款方式更正失敗
            case paymentMethodEdit
        }
    }
}

// MARK: - Internal Method

extension LookupManagementFeature.Destination.State {

    /// 建立刪除主檔項目的確認 alert
    ///
    /// - Parameter name: 要刪除的主檔名稱
    /// - Returns: 包含刪除確認 alert 的 Destination state
    static func deleteConfirmation(name: String) -> Self {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("orders.detail.label.deleteItem")
            } actions: {
                ButtonState(
                    role: .destructive,
                    action: .confirmDelete(name: name)
                ) {
                    TextState("common.action.button.delete")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "orders.lookup.message.deleteUndoneNotice",
                        defaultValue: "\(name)"
                    )
                )
            }
        )
    }

    /// 建立付款方式更正的回溯確認 alert
    ///
    /// - Parameter affectedOrderCount: 會重新計算的既有訂單筆數
    /// - Returns: 包含付款方式更正確認 alert 的 Destination state
    static func retroactiveConfirmation(affectedOrderCount: Int) -> Self {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("orders.lookup.label.correctPaymentMethod")
            } actions: {
                ButtonState(role: .destructive, action: .confirmPaymentMethodEdit) {
                    TextState("orders.detail.label.confirmCorrection")
                }
                ButtonState(role: .cancel, action: .cancelPaymentMethodEdit) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "orders.lookup.message.confirmRecalculateNotice",
                        defaultValue: "\(affectedOrderCount)"
                    )
                )
            }
        )
    }

    /// 建立主檔寫入失敗的一次性 alert
    ///
    /// - Parameter failure: 失敗的主檔操作
    /// - Returns: 包含主檔寫入失敗 alert 的 Destination state
    static func writeFailure(_ failure: LookupManagementFeature.Destination.WriteFailure) -> Self {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                switch failure {
                case .add:
                    TextState("orders.lookup.message.itemAddedTry")

                case .delete:
                    TextState("orders.lookup.message.itemDeletedTry")

                case .rename:
                    TextState("orders.lookup.message.itemRenamedTry")

                case .paymentMethodEdit:
                    TextState("orders.lookup.message.paymentMethodEdit")
                }
            }
        )
    }
}

// MARK: - Equatable

extension LookupManagementFeature.Destination.State: Equatable {}
