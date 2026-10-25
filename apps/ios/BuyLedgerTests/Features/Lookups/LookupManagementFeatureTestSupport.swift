//
//  LookupManagementFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 主檔管理測試共用的提示工廠，組出刪除確認、操作失敗與付款方式更正確認的 alert
enum LookupManagementFeatureTestSupport {}

// MARK: - Internal Method

extension LookupManagementFeatureTestSupport {

    /// 依正式畫面的標題、按鈕與文案組出刪除確認 alert，不借用被測程式的產生結果當預期值
    ///
    /// - Parameter name: 要刪除的主檔名稱
    /// - Returns: 含刪除確認 alert 的 `Destination.State`
    static func deleteConfirmationAlert(name: String) -> LookupManagementFeature.Destination.State {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("orders.detail.label.deleteItem")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(name: name)) {
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

    /// 依正式畫面的標題、按鈕與文案組出操作失敗 alert，不借用被測程式的產生結果當預期值
    ///
    /// - Parameter message: 主檔操作失敗文案
    /// - Returns: 含操作失敗 alert 的 `Destination.State`
    static func writeFailureAlert(
        message: LocalizedStringResource
    ) -> LookupManagementFeature.Destination.State {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState(message)
            }
        )
    }

    /// 依正式畫面的標題、按鈕與文案組出付款方式更正確認 alert，不借用被測程式的產生結果當預期值
    ///
    /// - Parameter count: 受影響的訂單筆數
    /// - Returns: 含付款方式確認 alert 的 `Destination.State`
    static func paymentMethodConfirmationAlert(
        count: Int
    ) -> LookupManagementFeature.Destination.State {
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
                        defaultValue: "\(count)"
                    )
                )
            }
        )
    }
}
