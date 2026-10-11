//
//  LookupManagementFeatureTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Nested Types

extension LookupManagementFeatureTests {

    /// 各類主檔的表單分類與新增後預期保存的旗標案例
    struct LookupAdditionExample: Sendable {

        /// 非付款方式會捨棄送入的旗標，付款方式會保留
        static let examples = [
            Self(kind: .orderSource, hasClassification: false, expectedFlags: .none),
            Self(kind: .category, hasClassification: false, expectedFlags: .none),
            Self(
                kind: .paymentMethod,
                hasClassification: true,
                expectedFlags: PaymentMethodFlags(
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                )
            ),
            Self(kind: .reconciliationStatus, hasClassification: false, expectedFlags: .none),
        ]

        /// 要新增的主檔種類
        let kind: LookupKind

        /// 此主檔種類是否保留付款方式分類
        let hasClassification: Bool

        /// 此案例新增後預期保存的付款方式旗標
        let expectedFlags: PaymentMethodFlags
    }

    /// `classification(for:)` 查詢第一筆同名付款方式與非付款方式主檔的案例
    struct LookupClassificationExample: Sendable {

        /// 第一筆同名付款方式勝出，商品類別沒有付款方式分類
        static let examples = [
            Self(
                expectedFlags: PaymentMethodFlags(
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                kind: .paymentMethod,
                name: "匯款",
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "匯款",
                        flags: PaymentMethodFlags(
                            isCardless: true,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ),
                    PaymentMethodInfo(
                        name: "匯款",
                        flags: PaymentMethodFlags(
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        )
                    ),
                ]
            ),
            Self(
                expectedFlags: nil,
                kind: .category,
                name: "匯款",
                paymentMethods: []
            ),
        ]

        /// 預期回傳的付款方式旗標
        let expectedFlags: PaymentMethodFlags?

        /// 要查詢的主檔種類
        let kind: LookupKind

        /// 查詢時使用的名稱
        let name: String

        /// 查詢前的付款方式目錄
        let paymentMethods: [PaymentMethodInfo]
    }
}

// MARK: - Internal Method

extension LookupManagementFeatureTests {

    /// 照正式畫面的標題、按鈕與文案另外組出刪除確認 alert，讓預期值不取自被測程式
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

    /// 照正式畫面的標題、按鈕與文案另外組出操作失敗 alert，讓預期值不取自被測程式
    ///
    /// - Parameter message: 主檔操作失敗文案
    /// - Returns: 含操作失敗 alert 的 `Destination.State`
    static func writeFailureAlert(message: LocalizedStringResource) -> LookupManagementFeature.Destination.State {
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

    /// 照正式畫面的標題、按鈕與文案另外組出付款方式確認 alert，讓預期值不取自被測程式
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
