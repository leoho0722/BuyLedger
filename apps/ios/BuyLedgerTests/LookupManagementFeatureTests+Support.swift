//
//  LookupManagementFeatureTests+Support.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Nested Types

extension LookupManagementFeatureTests {

    /// `classification(for:)` 查詢第一筆同名付款方式與非付款方式主檔的案例
    struct LookupClassificationExample: Sendable {

        /// 第一筆同名付款方式勝出，商品類別沒有付款方式分類
        nonisolated static let examples = [
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
                        isCardless: true,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
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

    /// 取得各主檔載入測試使用的固定名稱
    ///
    /// - Parameter kind: 要載入的主檔種類
    /// - Returns: 對應主檔的測試名稱
    static func loadedName(for kind: LookupKind) -> String {
        switch kind {
        case .orderSource:
            return "新來源"

        case .category:
            return "新類別"

        case .paymentMethod:
            return "新付款"

        case .reconciliationStatus:
            return "新狀態"
        }
    }

    /// 建立刪除確認 alert 的預期 Destination state
    ///
    /// - Parameter name: 要刪除的主檔名稱
    /// - Returns: 含刪除確認 alert 的 Destination state
    static func deleteConfirmationAlert(name: String) -> LookupManagementFeature.Destination.State {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("刪除項目")
            } actions: {
                ButtonState(
                    role: .destructive,
                    action: .confirmDelete(name: name)
                ) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(name)」後，引用它的既有訂單會失去這個欄位值。此操作無法復原。")
            }
        )
    }

    /// 建立操作失敗 alert 的預期 Destination state
    ///
    /// - Parameter message: 主檔操作失敗文案
    /// - Returns: 含操作失敗 alert 的 Destination state
    static func failureNotice(message: String) -> LookupManagementFeature.Destination.State {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState(message)
            }
        )
    }

    /// 建立付款方式回溯確認 alert 的預期 Destination state
    ///
    /// - Parameter count: 受影響的訂單筆數
    /// - Returns: 含付款方式確認 alert 的 Destination state
    static func confirmationAlert(count: Int) -> LookupManagementFeature.Destination.State {
        .alert(
            AlertState<LookupManagementFeature.Destination.Alert> {
                TextState("更正付款方式")
            } actions: {
                ButtonState(role: .destructive, action: .confirmPaymentMethodEdit) {
                    TextState("確認更正")
                }
                ButtonState(role: .cancel, action: .cancelPaymentMethodEdit) {
                    TextState("取消")
                }
            } message: {
                TextState("確認後將重算 \(count) 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。")
            }
        )
    }

    /// 建立含正規化欄位的付款方式測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - paymentMethod: 付款方式名稱
    /// - Returns: 固定內容的測試訂單
    static func makePaymentOrder(id: String, paymentMethod: String) -> LedgerOrder {
        LedgerOrder.fixture(
            id: id,
            chargedAmount: 40,
            cardlessDeductionAmount: 90,
            cardlessSupplementAmount: -5,
            paymentMethod: paymentMethod,
            reconciliationStatus: "  待對帳  "
        )
    }
}
